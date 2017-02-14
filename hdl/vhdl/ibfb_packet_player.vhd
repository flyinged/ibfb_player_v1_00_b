--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : ibfb_packet_player.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.1 $
------------------------------------------------------------------------------
-- Copyright © PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : Playback packets from RAM
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library ibfb_common_v1_00_b;
use ibfb_common_v1_00_b.ibfb_comm_package.all;

--Playback packets from RAM
--Packets are stored in 32bit RAM as follows:
--    TIMESTAMP (32 bit counter @i_clk frequency)
--    CTRL(8) & BPM(8) & BUCKET(16)
--    X_POSITION(32)
--    Y_POSITION(32)
--From the user side, data is seen differently: RAM is divided in 4 sections, each containing data of the same kind.
--The 2 most-significant bits of the address (i_ram_a) select these sections:
--  First  section (MSB "00") contains all timestamps.
--  Second section (MSB "01") contains all CTL,BPM,BKT dwords.
--  Third  section (MSB "10") contains all XPOS dwords.
--  Fourth section (MSB "11") contains all YPOS dwords.
entity ibfb_packet_player is
generic(
    CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; --when this CTRL value is encountered, playback is stopped
    RAM_ADDR_W : natural := 13 --0x1FFF 32-bit words => 0x1FFF/3 = 2730 packets 
);
port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    --debug signals
    o_dbg : out std_logic_vector(15 downto 0); --"0000000" & sop_r & busy_r & eos & send_pkt & tmr_on & start_r & st
    --CTRL interface
    i_start     : in  std_logic; --just rising edge detection. no synchronization
    o_busy      : out std_logic;
    o_pkt_num   : out std_logic_vector(RAM_ADDR_W-1 downto 0);
    --RAM interface
    i_ram_clk : in  std_logic;
    i_ram_w   : in  std_logic;
    i_ram_a   : in  std_logic_vector(RAM_ADDR_W-1 downto 0);
    i_ram_d   : in  std_logic_vector(31 downto 0);
    o_ram_d   : out std_logic_vector(31 downto 0);
    --TX Interface
    i_sop       : in  std_logic;
    i_busy      : in  std_logic; --currently not used
    o_tx_valid  : out std_logic;
    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
);
end entity ibfb_packet_player;



-------------------------------------------------------------------------------------
--- ARCHITECTURE --------------------------------------------------------------------
-------------------------------------------------------------------------------------
architecture rtl of ibfb_packet_player is

-------------------------------------------------------------------------------------
--- COMPONENTS ----------------------------------------------------------------------
-------------------------------------------------------------------------------------
component ram_infer_dual is
generic(
    ADDR_W : natural := 12;
    DATA_W : natural := 36 
);
port(
    --port A (read/write)
    clka  : in  std_logic;
    ena   : in  std_logic;
    wea   : in  std_logic;
    addra : in  std_logic_vector(ADDR_W-1 downto 0);
    dia   : in  std_logic_vector(DATA_W-1 downto 0);
    doa   : out std_logic_vector(DATA_W-1 downto 0);
    --port B
    clkb  : in  std_logic;
    enb   : in  std_logic;
    addrb : in  std_logic_vector(ADDR_W-1 downto 0);
    dob   : out std_logic_vector(DATA_W-1 downto 0)
);
end component ram_infer_dual;

-------------------------------------------------------------------------------------
--- SIGNALS -------------------------------------------------------------------------
-------------------------------------------------------------------------------------
signal start_r, start_rr : std_logic;
signal busy_r     : std_logic;
signal s, s_r     : unsigned(3 downto 0);
signal ram_read_a : unsigned(RAM_ADDR_W-1 downto 0);
signal ram_read_d : std_logic_vector(31 downto 0);

alias b0 : std_logic_vector(7 downto 0) is ram_read_d( 7 downto  0);
alias b1 : std_logic_vector(7 downto 0) is ram_read_d(15 downto  8);
alias b2 : std_logic_vector(7 downto 0) is ram_read_d(23 downto 16);
alias b3 : std_logic_vector(7 downto 0) is ram_read_d(31 downto 24);

signal pkt_buf : ibfb_comm_packet;
signal pkt_out : ibfb_comm_packet;
signal sent    : unsigned(RAM_ADDR_W-1 downto 0);

signal end_of_sequence : std_logic;
signal timer_on, timer_MSB_r, send_packet : std_logic;
signal timer, start_time : unsigned(31 downto 0);

signal sop_r : std_logic;

signal ram_a : std_logic_vector(RAM_ADDR_W-1 downto 0);

--attribute safe_implementation : string;
--attribute safe_implementation of s : signal is "yes";

begin
-------------------------------------------------------------------------------------
--- IMPLEMENTATION ------------------------------------------------------------------
-------------------------------------------------------------------------------------

--move 2 MSb to position (1:0)
ram_a <= i_ram_a(RAM_ADDR_W-3 downto 0) & i_ram_a(RAM_ADDR_W-1 downto RAM_ADDR_W-2);

PKT_RAM_I : ram_infer_dual
generic map(
    ADDR_W => RAM_ADDR_W,
    DATA_W => 32
)
port map(
    --port A (read/write)
    clka  => i_ram_clk,
    ena   => '1',
    wea   => i_ram_w,
    addra => ram_a,
    dia   => i_ram_d,
    doa   => o_ram_d,
    --port B
    clkb  => i_clk,
    enb   => '1',
    addrb => std_logic_vector(ram_read_a),
    dob   => ram_read_d
);


--debug outputs
o_dbg(10)         <= start_rr;
o_dbg(9)          <= sop_r;
o_dbg(8)          <= busy_r;
o_dbg(7)          <= end_of_sequence;
o_dbg(6)          <= send_packet;
o_dbg(5)          <= timer_on;
o_dbg(4)          <= start_r;
o_dbg(3 downto 0) <= std_logic_vector(s);

--start timer on <start> rising edge. Reset timer on <end_of_sequence>
TIMER_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_rst = '1' or end_of_sequence = '1' then
            timer_MSB_r <= '0';
            timer_on    <= '0';
            timer       <= (others => '0');
        else

            if timer_on = '0' then
                timer_MSB_r <= '0';
                if start_rr = '0' and start_r = '1' then 
                    timer    <= X"00000001";
                    timer_on <= '1';
                end if;
            else --timer running
                timer_MSB_r <= timer(timer'left);
                if timer_MSB_r = '1' and timer(timer'left) = '0' then --avoid counter flip
                    timer_on <= '0';
                else
                    timer <= timer+1;
                end if;
            end if;
        end if;
    end if;
end process;

--send packet when its start_time is elapsed
send_packet <= '1' when (start_time < timer) else '0';

--Main FSM
MAIN_P : process(i_clk)
begin   
    if rising_edge(i_clk) then
        if i_rst = '1' or end_of_sequence = '1' then
            --start_r         <= '0';
            end_of_sequence <= '0';
            s               <= (others => '1');
        else
            start_r  <= i_start;
            start_rr <= start_r;
            busy_r   <= i_busy;
            sop_r    <= i_sop;

            case s is
            when X"0" =>
                --wait for start (a=0/3, d=not valid)
                if start_rr = '0' and start_r = '1' then
                    --sent       <= (others => '0'); --reset on start (keep memory of previous sequence)
                    ram_read_a <= ram_read_a+1;
                    s          <= s+1;
                end if;
            when X"1" =>
                --1st data word: TIMESTAMP
                --(a=1/3, d=0/3)
                start_time <= unsigned(b3)&unsigned(b2)&unsigned(b1)&unsigned(b0);
                ram_read_a     <= ram_read_a+1;
                s <= s+1;

            when X"2" =>
                --2nd data word: CTRL,BPM,BUCKET
                --(a=2/3, d=1/3)
                if (b3 = CTRL_EOS) then
                    end_of_sequence <= '1';
                else
                    end_of_sequence <= '0';
                end if;

                --if end_of_sequence = '1' then
                --    s <= (others => '1');
                --else
                    pkt_buf.ctrl   <= b3;
                    pkt_buf.bpm    <= b2;
                    pkt_buf.bucket <= b1 & b0;
                    ram_read_a     <= ram_read_a+1;
                    s              <= s+1;
                --end if;
            when X"3" =>
                --3rd data word: XPOS
                --(a=3/3, d=2/3)
                pkt_buf.xpos <= b3&b2&b1&b0;
                --ram_read_a   <= ram_read_a+1;
                s            <= s+1;
            when X"4" =>
                --3rd data word: YPOS
                --(a=3/3, d=3/3)
                --Update output, set output valid and wait for data to be sampled
                pkt_out.ctrl   <= pkt_buf.ctrl;
                pkt_out.bpm    <= pkt_buf.bpm; 
                pkt_out.bucket <= pkt_buf.bucket; 
                pkt_out.xpos   <= pkt_buf.xpos; 
                pkt_out.ypos   <= b3&b2&b1&b0;

                if send_packet = '1' then
                    o_tx_valid <= '1';
                end if;

                --if i_sop = '1' then --i_busy = '1' and busy_r = '0' then --data was sampled: go on
                if sop_r = '1' then --i_busy = '1' and busy_r = '0' then --data was sampled: go on
                    ram_read_a     <= ram_read_a+1;
                    --sent <= sent+1;
                    s <= s+1;
                end if;
            when X"5" =>
                --wait for data to show on RAM's output
                --(a=0/3, d=OLD)
                o_tx_valid <= '0';
                ram_read_a     <= ram_read_a+1;
                s              <= X"1";
            when others =>
                o_tx_valid <= '0';
                ram_read_a <= (others => '0');
                s          <= X"0";
            end case;
        end if;
    end if;
end process;

--moved counter here to improve timing closure
SENT_PKT_CNT_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        s_r <= s;
        if (s = X"1" and s_r = X"0") then
            sent <= (others => '0');
        elsif (s = X"5" and s_r = X"4") then
            sent <= sent+1;
        end if;
    end if;
end process;

o_tx_data <= pkt_out;
o_busy    <= '0' when (s = X"0") else '1';
o_pkt_num <= std_logic_vector(sent);

end architecture rtl;


-------------------------------------------
---- END OF FILE
-------------------------------------------
