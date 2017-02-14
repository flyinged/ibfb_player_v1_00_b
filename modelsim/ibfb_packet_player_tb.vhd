library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.ibfb_comm_package.all;

entity ibfb_packet_player_tb is
end entity ibfb_packet_player_tb;

architecture test of ibfb_packet_player_tb is

--Playback packets from RAM
--Packets are stored in 32bit RAM as follows:
--    CTRL(8) & BPM(8) & BUCKET(16)
--    X_POSITION(32)
--    Y_POSITION(32)
component ibfb_packet_player is
generic(
    CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; --when this CTRL value is encountered, playback is stopped
    RAM_ADDR_W : natural := 13 --0x1FFF 32-bit words => 0x1FFF/3 = 2730 packets 
);
port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    --debug signals
    o_dbg_ram_raddr : out std_logic_vector(RAM_ADDR_W-1 downto 0);
    o_dbg_ram_rdata : out std_logic_vector(31 downto 0);
    --CTRL interface
    i_start     : in  std_logic;
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
    i_eop       : in  std_logic;
    i_busy      : in  std_logic;
    o_tx_valid  : out std_logic;
    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
);
end component ibfb_packet_player;

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

component FIFO36
   generic
   (
      DATA_WIDTH                  : integer := 4;
      ALMOST_FULL_OFFSET          : bit_vector := X"0080";
      ALMOST_EMPTY_OFFSET         : bit_vector := X"0080";
      DO_REG                      : integer := 1;
      EN_SYN                      : boolean := FALSE;
      FIRST_WORD_FALL_THROUGH     : boolean := FALSE
   );
   port
   (
      RST                         : in   std_ulogic;

      WRCLK                       : in    std_ulogic;
      FULL                        : out   std_ulogic;
      ALMOSTFULL                  : out   std_ulogic;
      WREN                        : in    std_ulogic;
      WRCOUNT                     : out   std_logic_vector(12 downto  0);
      WRERR                       : out   std_ulogic;
      DIP                         : in    std_logic_vector( 3 downto  0);
      DI                          : in    std_logic_vector(31 downto  0);

      RDCLK                       : in    std_ulogic;
      EMPTY                       : out   std_ulogic;
      ALMOSTEMPTY                 : out   std_ulogic;
      RDEN                        : in    std_ulogic;
      RDCOUNT                     : out   std_logic_vector(12 downto  0);
      RDERR                       : out   std_ulogic;
      DOP                         : out   std_logic_vector( 3 downto  0);
      DO                          : out   std_logic_vector(31 downto  0)
   );
end component;

constant RAM_ADDR_W    : natural := 14;
constant RAM_INIT_SIZE : natural := 44;

signal clk, rst : std_logic;
signal ram_init_w : std_logic;
signal ram_init_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal ram_read_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal ram_init_d, ram_read_d : std_logic_vector(31 downto 0);
signal ram_init_id : natural;
signal ram_init_done : std_logic;

signal pl_start, player_ovalid, pl_busy : std_logic;
signal player_odata : ibfb_comm_packet;

signal pkt_tx_busy, txf_write, pkt_tx_sop, txf_full : std_logic;
signal txf_charisk : std_logic_vector(3 downto 0);
signal txf_data : std_logic_vector(31 downto 0);

signal rx_next, rx_valid, rx_empty : std_logic;
signal rx_isk : std_logic_vector(3 downto 0);
signal rx_data : std_logic_vector(31 downto 0);

signal rx_bad, rx_eop, rx_good, rx_good_r, rx_eop_r : std_logic;
signal rx_pkt, rx_pkt_r : ibfb_comm_packet;

signal dbg_ram_raddr : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal dbg_ram_rdata : std_logic_vector(31 downto 0);

type ram_t is array (0 to RAM_INIT_SIZE-1) of std_logic_vector(31 downto 0);
constant ram_init_data : ram_t := ( 
    X"00000010",X"1A"&X"01"&X"0010", X"11110001", X"22220001", --PACKET 0 (00:03)
    X"00000020",X"1B"&X"01"&X"0011", X"11110002", X"22220002", --PACKET 1 (04:07)
    X"00000030",X"1C"&X"01"&X"0012", X"11110003", X"22220003", --PACKET 2 (08:11)
    X"00000040",X"1D"&X"01"&X"0013", X"11110004", X"22220004", --PACKET 3 (12:15)
    X"00000000",X"FF"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 4 (16:19)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 5 (20:23)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 6 (24:27)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 7 (28:31)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 8 (32:35)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 9 (36:39)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000"  --END OF SEQUENCE (40:43)
);

--for PLAYER_I : ibfb_packet_player use entity work.ibfb_packet_player(rtl2);

begin

rst <= '1', '0' after 500 ns;
clk <= '1' after 5 ns when clk = '0' else
       '0' after 5 ns;
pl_start <= '0';

--initialize ram content
RAM_INIT_P : process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            ram_init_id <= 0;
            ram_init_w  <= '0';
            ram_init_done <= '0';
        else
            if ram_init_id < RAM_INIT_SIZE then
                ram_init_d <= ram_init_data(ram_init_id);
                ram_init_a <= std_logic_vector(to_unsigned(ram_init_id,RAM_ADDR_W));
                ram_init_w <= '1';
                ram_init_id <= ram_init_id+1;
            else
                ram_init_done <= '1';
                ram_init_w <= '0';
            end if;
        end if;
    end if;
end process;

PLAYER_I : ibfb_packet_player
generic map(
    CTRL_EOS   => X"FF",
    RAM_ADDR_W => RAM_ADDR_W
)
port map(
    i_clk      => clk,
    i_rst      => rst,
    o_dbg_ram_raddr => dbg_ram_raddr,
    o_dbg_ram_rdata => dbg_ram_rdata,
    --CTRL interface
    i_start    => pl_start,
    o_busy     => pl_busy,
    o_pkt_num  => open,
    --RAM interface
    i_ram_clk  => clk,
    i_ram_w    => ram_init_w,
    i_ram_a    => ram_init_a,
    i_ram_d    => ram_init_d,
    o_ram_d    => open,
    --TX Interface
    i_sop      => pkt_tx_sop,
    i_eop      => open,
    i_busy     => pkt_tx_busy,
    o_tx_valid => player_ovalid,
    o_tx_data  => player_odata
);


PKT_TX_I : ibfb_packet_tx
generic map(
    K_SOP => X"FB",
    K_EOP => X"FD",
    EXTERNAL_CRC => '0'
)
port map(
    i_rst       => rst,
    i_clk       => clk,
    --user interface
    o_sample    => pkt_tx_sop,
    o_busy      => pkt_tx_busy,
    i_tx_valid  => player_ovalid,
    i_tx_data   => player_odata,
    --MGT FIFO interface
    i_fifo_full => txf_full,
    o_valid     => txf_write,
    o_charisk   => txf_charisk,
    o_data      => txf_data
 );

FIFO_i : FIFO36
    generic map(
        DATA_WIDTH              => 36, --36 bit width
        ALMOST_FULL_OFFSET      => X"080", --almost full when FIFO contains more than 128 (1/8)
        ALMOST_EMPTY_OFFSET     => X"080", --almost empty when FIFO contains less than 128 (1/8)
        DO_REG                  => 1, --enable data pipeline register
        EN_SYN                  => FALSE, --no multirate
        FIRST_WORD_FALL_THROUGH => TRUE 
    )
    port map(
        RST         => rst,

        WRCLK       => clk,
        FULL        => txf_full,
        ALMOSTFULL  => open,
        WREN        => txf_write,
        WRCOUNT     => open,
        WRERR       => open,
        DIP         => txf_charisk,
        DI          => txf_data,

        RDCLK       => clk,
        EMPTY       => rx_empty,
        ALMOSTEMPTY => open,
        RDEN        => rx_next,
        RDCOUNT     => open,
        RDERR       => open,
        DOP         => rx_isk,
        DO          => rx_data
    );

rx_valid <= not rx_empty;

PKT_RX_I : ibfb_packet_rx
generic map(
    K_SOP => X"FB",
    K_EOP => X"FD"
)
port map(
    i_rst => rst,
    i_clk => clk,
    --MGT FIFO interface
    o_next      => rx_next,
    i_valid     => rx_valid,
    i_charisk   => rx_isk,
    i_data      => rx_data,
    --user interface
    o_bad_data => rx_bad,
    o_eop      => rx_eop,
    o_crc_good => rx_good,
    o_rx_data  => rx_pkt
 );


RXREG_P : process(clk)
begin
    if rising_Edge(clk) then
        rx_eop_r <= rx_eop;
        rx_good_r <= rx_good;
        if rx_eop = '1' then
            rx_pkt_r <= rx_pkt;
        end if;
    end if;
end process;

end architecture test;
