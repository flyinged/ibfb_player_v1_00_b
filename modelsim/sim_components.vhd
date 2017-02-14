--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package ibfb_comm_package is

    constant BPM_BITS : natural := 2; --number of used BPMs will be 2**BPM_BITS
    type bpm_id_t is array (0 to 2**BPM_BITS-1) of std_logic_vector(7 downto 0);
    type array3  is array (natural range <>) of std_logic_vector(2 downto 0);
    type array4  is array (natural range <>) of std_logic_vector(3 downto 0);
    type array8  is array (natural range <>) of std_logic_vector(7 downto 0);
    type array16 is array (natural range <>) of std_logic_vector(15 downto 0);
    type array32 is array (natural range <>) of std_logic_vector(31 downto 0);


    --Record that contains all the fields in the IBFB packet
    --Packet TX/RX sequence:
    -- D.00 K.SOP | D.CTRL D.BPM | D.BK0 D.BK1 | 4x(D.XPOS) | 4x(D.YPOS) | D.CRC K.EOP
    type ibfb_comm_packet is record
        ctrl   : std_logic_vector( 7 downto 0);
        bpm    : std_logic_vector( 7 downto 0);
        bucket : std_logic_vector(15 downto 0);
        xpos   : std_logic_vector(31 downto 0);
        ypos   : std_logic_vector(31 downto 0);
        crc    : std_logic_vector( 7 downto 0);
    end record ibfb_comm_packet;

end package;
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;
use work.pkg_crc.all;

entity ibfb_packet_tx is
generic(
    K_SOP : std_logic_vector(7 downto 0); --start of packet k-character
    K_EOP : std_logic_vector(7 downto 0); --end of packet k-character
    EXTERNAL_CRC : std_logic := '0'       --enable internal CRC calulation (if 0, then input CRC value is used)
);
port(
    i_rst       : in  std_logic;
    i_clk       : in  std_logic;
    --user interface
    o_sample    : out std_logic; --'1' when sampling inputs
    o_busy      : out std_logic; --inputs not sampled when busy = '1'
    i_tx_valid  : in  std_logic; --when asserted and busy = '0', then i_tx_data is sampled and transmitted
    i_tx_data   : in  ibfb_comm_packet; --tx data (packet fields)
    --MGT FIFO interface
    i_fifo_full : in  std_logic; 
    o_valid     : out std_logic; --connect to FIFO write-enable
    o_charisk   : out std_logic_vector(3 downto 0);
    o_data      : out std_logic_vector(31 downto 0)
 );
end entity ibfb_packet_tx;

architecture rtl of ibfb_packet_tx is

signal start_r, valid, valid_r, crc_rst : std_logic;
signal s         : unsigned(2 downto 0);
signal b0, b1, x0, x1, x2, x3, y0, y1, y2, y3, crc_out, checksum : std_logic_vector(7 downto 0);
signal ocharisk, ocharisk_r : std_logic_vector(3 downto 0);
signal odata, odata_r : std_logic_vector(31 downto 0);

begin

--name data bytes
REG_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_tx_valid = '1' and s = "000" then
            b0 <= std_logic_vector(i_tx_data.bucket( 7 downto  0));
            b1 <= std_logic_vector(i_tx_data.bucket(15 downto  8));
            x0 <= std_logic_vector(i_tx_data.xpos( 7 downto  0));
            x1 <= std_logic_vector(i_tx_data.xpos(15 downto  8));
            x2 <= std_logic_vector(i_tx_data.xpos(23 downto 16));
            x3 <= std_logic_vector(i_tx_data.xpos(31 downto 24));
            y0 <= std_logic_vector(i_tx_data.ypos( 7 downto  0));
            y1 <= std_logic_vector(i_tx_data.ypos(15 downto  8));
            y2 <= std_logic_vector(i_tx_data.ypos(23 downto 16));
            y3 <= std_logic_vector(i_tx_data.ypos(31 downto 24));
        end if;
    end if;
end process;

o_sample <= '1' when s = "000" and i_tx_valid = '1' and i_fifo_full = '0' else '0';
o_busy   <= valid or valid_r; --'0' when (s = "000") and i_fifo_full = '0' else '1';

--TX process
TX_P : process(i_clk)
begin   
    if rising_edge(i_clk) then
        if i_rst = '1' then
            s <= (others => '1');
        else
            case s is
                when "000" => --send SOP, CTRL, BPM
                    if i_tx_valid = '1' and i_fifo_full = '0' then
                        valid   <= '1';
                        ocharisk <= "0100";
                        odata    <= X"00" & K_SOP & i_tx_data.ctrl & i_tx_data.bpm;
                        s         <= s+1;
                    else
                        valid     <= '0';
                    end if;
                when "001" => --send bucket, xpos MSBs
                    if i_fifo_full = '0' then
                        valid     <= '1';
                        ocharisk <= "0000";
                        odata    <= b0 & b1 & x0 & x1;
                        s         <= s+1;
                    end if;
                when "010" => --send xpos MSBs, ypos LSBs
                    if i_fifo_full = '0' then
                        valid     <= '1';
                        ocharisk <= "0000";
                        odata    <= x2 & x3 & y0 & y1;
                        s         <= s+1;
                    end if;
                when "011" => --send ypos MSBs, Checksum, EOP 
                    if i_fifo_full = '0' then
                        valid     <= '1';
                        ocharisk <= "0001";
                        odata    <= y2 & y3 & X"00" & K_EOP;
                        s <= s+1;
                    end if;
                when "100" =>
                    valid <= '0';
                    s     <= "000";
                when others => --reset state
                    s        <= (others => '0');
                    valid    <= '0';
            end case;
        end if;
    end if;
end process;

crc_rst <= not valid;

CRC_CALC_I : crc8_in32
port map( 
    data_in => odata,
    crc_en  => valid,
    rst     => crc_rst,
    clk     => i_clk,
    crc_out => crc_out
);

OUTPUT_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        valid_r    <= valid;
        odata_r    <= odata;
        ocharisk_r <= ocharisk;
    end if;
end process;

checksum <= crc_out when EXTERNAL_CRC = '0' else
            i_tx_data.crc;

o_valid <= valid_r and not i_fifo_full;
o_charisk <= ocharisk_r;
o_data(31 downto 16) <= odata_r(31 downto 16);
o_data(15 downto  8) <= checksum when s = "000" else
                        odata_r(15 downto  8);
o_data( 7 downto  0) <= odata_r( 7 downto  0);

end architecture rtl;

----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--DUMMY. Not used in simulation
entity ibfb_fp2int is
PORT (
      a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      operation_nd : IN STD_LOGIC;
      clk : IN STD_LOGIC;
      result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      overflow : OUT STD_LOGIC;
      rdy : OUT STD_LOGIC
);
END entity ibfb_fp2int;

architecture sim of ibfb_fp2int is

begin

result <= (others => '0');
overflow <= '0';
rdy <= '0';

end architecture sim;


---------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;

entity ibfb_int2fp is
PORT (
    a             : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    operation_nd  : IN STD_LOGIC;
    clk           : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    result        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy           : OUT STD_LOGIC
);
END entity ibfb_int2fp;

architecture sim of ibfb_int2fp is

signal delay_sr : std_logic_vector(0 to 31) := X"00000000";
signal data_sr  : array32(0 to 31);

constant DLY : natural := 6;

begin


CTRL : process(clk)
begin
    if rising_edge(clk) then
        delay_sr <= operation_nd & delay_sr(0 to 30); --IN>>OUT
        data_sr(0)       <= std_logic_vector(RESIZE( signed(a) , 32));
        data_sr(1 to 31) <= data_sr(0 to 30);
    end if;
end process;


operation_rfd <= '1'; --rate = 1
rdy           <= delay_sr(DLY-1); 
result        <= data_sr(DLY-1) when delay_sr(DLY-1) = '1' else (others => 'X'); 

end architecture sim;

---------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;

entity fp_mult_player is
  PORT (
    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    operation_nd : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    clk : IN STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy : OUT STD_LOGIC
  );
END entity fp_mult_player;

architecture sim of fp_mult_player is

signal delay_sr : std_logic_vector(0 to 31) := (others => '0');
signal data_sr  : array32(0 to 31);

constant DLY : natural := 5;

begin


CTRL : process(clk)
begin
    if rising_edge(clk) then
        delay_sr <= operation_nd & delay_sr(0 to 30); --IN>>OUT
        data_sr(0)       <= std_logic_vector(resize(signed(a)*signed(b),32));
        data_sr(1 to 31) <= data_sr(0 to 30);
    end if;
end process;

operation_rfd <= '1'; --rate = 1
rdy           <= delay_sr(DLY-1);
result        <= data_sr(DLY-1) when delay_sr(DLY-1) = '1' else (others => 'X'); 

end architecture sim;
  
---------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ibfb_comm_package.all;

entity fp_add_player is
PORT (
    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    operation_nd : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    clk : IN STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy : OUT STD_LOGIC
);
END entity fp_add_player;

architecture sim of fp_add_player is

signal delay_sr : std_logic_vector(0 to 31) := (others => '0');
signal data_sr  : array32(0 to 31);

constant DLY : natural := 5;

begin


CTRL : process(clk)
begin
    if rising_edge(clk) then
        delay_sr <= operation_nd & delay_sr(0 to 30); --IN>>OUT
        data_sr(0) <= std_logic_vector(signed(a)+signed(b));
        data_sr(1 to 31) <= data_sr(0 to 30);
    end if;
end process;

operation_rfd <= '1'; --rate = 1
rdy           <= delay_sr(DLY-1); 
result        <= data_sr(DLY-1) when delay_sr(DLY-1) = '1' else (others => 'X'); 

end architecture sim;


