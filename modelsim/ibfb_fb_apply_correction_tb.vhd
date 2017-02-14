
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library ibfb_common_v1_00_b;
use ibfb_common_v1_00_b.ibfb_comm_package.all; --ibfb packet data type

entity ibfb_fb_apply_correction_tb is
end entity ibfb_fb_apply_correction_tb;

architecture test of ibfb_fb_apply_correction_tb is

component ibfb_fb_apply_correction is
port(
    i_clk       : in std_logic;
    i_train_trg : in std_logic; --start of bunch (resets correction computation) 
    --feedback input
    i_fb_v      : in std_logic; --feedback valid
    i_fb_kx     : in array16(0 to 1); --KX0,KX1
    i_fb_ky     : in array16(0 to 1); --KY0,KY1
    --Transformation matrixes
    i_bpm_ids   : in array8(0 to 3); --BPM IDs corresponding to each of the 4 transformation sets
    i_tr_kx0    : in array32(0 to 3); --one value for each BPM id 
    i_tr_kx1    : in array32(0 to 3); --one value for each BPM id 
    i_tr_ky0    : in array32(0 to 3); --one value for each BPM id 
    i_tr_ky1    : in array32(0 to 3); --one value for each BPM id 
    --input data
    o_rfd       : out std_logic;
    i_pkt_valid : in  std_logic;
    i_pkt_data  : in  ibfb_comm_packet; 
    --
    o_pkt_valid : out std_logic;
    o_pkt_data  : out ibfb_comm_packet  
);
end component ibfb_fb_apply_correction;

component ibfb_packet_tx is
generic(
        K_SOP : std_logic_vector(7 downto 0);
        K_EOP : std_logic_vector(7 downto 0);
        EXTERNAL_CRC : std_logic := '0'
);
port(
        i_rst       : in  std_logic;
        i_clk       : in  std_logic;
        --user interface
        o_sample    : out std_logic; --'1' when sampling inputs (used for back to back transfers)
        o_busy      : out std_logic;
        i_tx_valid  : in  std_logic;
        i_tx_data   : in  ibfb_comm_packet; --tx data (packet fields)
        --MGT FIFO interface
        i_fifo_full : in  std_logic;
        o_valid     : out std_logic;
        o_charisk   : out std_logic_vector(3 downto 0);
        o_data      : out std_logic_vector(31 downto 0)
);
end component ibfb_packet_tx;

signal clk, trig : std_logic := '0';

signal fb_v    : std_logic := '0';
signal fb_kx   : array16(0 to 1); --KX0,KX1
signal fb_ky   : array16(0 to 1); --KY0,KY1

signal bpm_ids : array8(0 to 3); --BPM IDs corresponding to each of the 4 transformation sets
signal tr_kx0  : array32(0 to 3); --one value for each BPM id 
signal tr_kx1  : array32(0 to 3); --one value for each BPM id 
signal tr_ky0  : array32(0 to 3); --one value for each BPM id 
signal tr_ky1  : array32(0 to 3); --one value for each BPM id 
   
signal rfd          : std_logic;
signal i_pkt_valid  : std_logic := '0';
signal i_pkt_data   : ibfb_comm_packet; 
    --
signal o_pkt_valid  : std_logic;
signal o_pkt_data   : ibfb_comm_packet;  
signal o_pkt_data_r : ibfb_comm_packet; 

signal s, s2 : natural := 0;
signal bcnt, timer, timer2 : natural := 0;
signal dcnt, dcnt2 : unsigned(31 downto 0) := X"00000001";

signal tx_sample, tx_busy, tx_vld : std_logic;
signal tx_isk : std_logic_vector(3 downto 0);
signal tx_data : std_logic_vector(31 downto 0);

begin

clk <= '1' after 5 ns when clk = '0' else
       '0' after 5 ns;

trig <= '1' after 470 ns when trig = '0' else
        '0' after 10  ns;

---------------------------------------------------------------
--constants
---------------------------------------------------------------
bpm_ids(0) <= X"00";
tr_kx0(0)  <= X"00000001";
tr_kx1(0)  <= X"00000001";
tr_ky0(0)  <= X"00000001";
tr_ky1(0)  <= X"00000001";

bpm_ids(1) <= X"01";
tr_kx0(1)  <= X"00000002";
tr_kx1(1)  <= X"00000002";
tr_ky0(1)  <= X"00000002";
tr_ky1(1)  <= X"00000002";

bpm_ids(2) <= X"02";
tr_kx0(2)  <= X"00000003";
tr_kx1(2)  <= X"00000003";
tr_ky0(2)  <= X"00000003";
tr_ky1(2)  <= X"00000003";

bpm_ids(3) <= X"03";
tr_kx0(3)  <= X"00000004";
tr_kx1(3)  <= X"00000004";
tr_ky0(3)  <= X"00000004";
tr_ky1(3)  <= X"00000004";

---------------------------------------------------------------
--stimulus
---------------------------------------------------------------

--generate train of 4 packets followed by a pause
--packet player has a max rate of 1 packet every 6 clock cycles
PKT_GEN_P : process(clk)
begin
    if rising_edge(clk) then
        case s is
            when 0 => --wait for trig
                i_pkt_valid       <= '0';
                if trig = '1' then
                    s <= 1;
                end if;
            when 1 => --delay from trig
                if timer < 5 then
                    timer <= timer+1;
                else
                    timer <= 0;
                    s <= 2;
                end if;
            when 2 => --send packet
                if rfd = '1' then --and dcnt < X"0000000A" then
                    i_pkt_valid       <= '1';
                    i_pkt_data.ctrl   <= std_logic_vector(dcnt( 7 downto 0));
                    i_pkt_data.bpm    <= std_logic_vector(TO_UNSIGNED(bcnt,8));
                    i_pkt_data.bucket <= std_logic_vector(dcnt(15 downto 0));
                    i_pkt_data.xpos   <= std_logic_vector(dcnt(31 downto 0));
                    i_pkt_data.ypos   <= std_logic_vector(dcnt(31 downto 0));
                    i_pkt_data.crc    <= std_logic_vector(dcnt( 7 downto 0));
                    --send 4 packets back to back, then wait for next trigger
                    if bcnt < 3 then 
                        bcnt <= bcnt+1;
                        s <= 3;
                    else
                        bcnt <= 0;
                        dcnt <= dcnt+1;
                        s <= 0;
                    end if;
                    timer <= 0;
                end if;
            when 3 => --pause between back-to-back packets 
                i_pkt_valid <= '0';
                if timer < 0 then
                    timer <= timer+1;
                else
                    timer <= 0;
                    s <= 2;
                end if;
            when others =>
                s <= 0;
        end case;
    end if;
end process;

--generate feedback data
FB_GEN_P : process(clk)
begin
    if rising_edge(clk) then
        case s2 is
            when 0 => --wait for trig
                fb_v <= '0';
                if trig = '1' then
                    s2 <= 1;
                end if;
            when 1 => --delay from trig
                if timer2 < 0 then
                    timer2 <= timer2+1;
                else
                    timer2 <= 0;
                    s2 <= 2;
                end if;
            when 2 =>
                --if dcnt2 < X"0000000A" then
                    fb_v <= '1'; -- and dcnt2(0); --every second value is missing
                    fb_kx(0) <= std_logic_vector(dcnt2(15 downto 0));
                    fb_kx(1) <= std_logic_vector(dcnt2(15 downto 0));
                    fb_ky(0) <= std_logic_vector(dcnt2(15 downto 0));
                    fb_ky(1) <= std_logic_vector(dcnt2(15 downto 0));
                    dcnt2 <= dcnt2+1;
                    s2 <= 0;
                --end if;
            when others =>
                s2 <= 0;
        end case;
    end if;
end process;


---------------------------------------------------------------
-- unit under test
---------------------------------------------------------------
UUT : ibfb_fb_apply_correction
port map(
    i_clk       => clk,
    i_train_trg => '0',
    --feedback input
    i_fb_v      => fb_v,
    i_fb_kx     => fb_kx,
    i_fb_ky     => fb_ky,
    --Transformation matrixes
    i_bpm_ids   => bpm_ids,
    i_tr_kx0    => tr_kx0,
    i_tr_kx1    => tr_kx1,
    i_tr_ky0    => tr_ky0,
    i_tr_ky1    => tr_ky1,
    --input data
    o_rfd       => rfd,
    i_pkt_valid => i_pkt_valid,
    i_pkt_data  => i_pkt_data,
    --
    o_pkt_valid => o_pkt_valid,
    o_pkt_data  => o_pkt_data
);

---------------------------------------------------------------
-- output register
---------------------------------------------------------------
OUT_R : process(clk)
begin
    if rising_edge(clk) then
        if o_pkt_valid = '1' then
            o_pkt_data_r <= o_pkt_data;
        end if;
    end if;
end process;

PACKET_TX_INST : ibfb_packet_tx
generic map(
    K_SOP => X"AA",
    K_EOP => X"BB",
    EXTERNAL_CRC => '1'
)
port map(
    i_rst       => '0',
    i_clk       => clk,
    --user interface
    o_sample    => tx_sample,
    o_busy      => tx_busy,
    i_tx_valid  => o_pkt_valid,
    i_tx_data   => o_pkt_data,
    --MGT FIFO interface
    i_fifo_full => '0',
    o_valid     => tx_vld,
    o_charisk   => tx_isk,
    o_data      => tx_data
);

end architecture test;
