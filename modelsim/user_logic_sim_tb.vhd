
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ibfb_comm_package.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity user_logic_sim_tb is
end entity user_logic_sim_tb;


--FIRST TEST (SWITCH IN BPM1 configuration: receive data from QSFP, FILTER, FORWARD TO P0
architecture test_bpm1 of user_logic_sim_tb is

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

component ibfb_packet_gen is
generic(
    CTRL      : std_logic_vector(7 downto 0) := X"CC";
    PKT_CNT_W : natural := 8;
    DOWNCOUNT : std_logic := '0';
    SOP : std_logic_vector(7 downto 0);
    EOP : std_logic_vector(7 downto 0)
);
port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    --CTRL interface
    i_start     : in  std_logic;
    i_npackets  : in  std_logic_vector(PKT_CNT_W-1 downto 0); --number of packets to send 
    --TX Interface
    i_busy      : in  std_logic;
    o_tx_valid  : out std_logic;
    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
);
end component ibfb_packet_gen;

component user_logic is
generic (
    --Interconnection topology 
    SFP02_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 02
    SFP13_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 13
    OUTPUT_TO_P0     : std_logic := '1'; --when 1, packets are output on backplane P0 connector. 
                                         --Otherwise on BPM0 channel
    --Packet protocol 
    K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
    K_EOP            : std_logic_vector(7 downto 0) := X"FD";
    --Transceivers
    C_GTX_REFCLK_SEL    : std_logic_vector(7 downto 0); --BPM23, BPM01, P0, SFP02, SFP13
    --
    C_SFP13_REFCLK_FREQ : integer := 125; --MHz
    C_SFP02_REFCLK_FREQ : integer := 125; --MHz
    C_P0_REFCLK_FREQ    : integer := 125; --MHz
    C_BPM_REFCLK_FREQ   : integer := 125; --MHz
    --
    C_SFP13_BAUD_RATE   : integer := 3125000; --Kbps
    C_SFP02_BAUD_RATE   : integer := 3125000; --Kbps
    C_P0_BAUD_RATE      : integer := 3125000; --Kbps
    C_BPM_BAUD_RATE     : integer := 3125000; --Kbps
    --PLB 
    C_SLV_DWIDTH     : integer := 32;
    C_NUM_REG        : integer := 32
);
port (
    --RX channels
    qsfp_rxf_next    : out std_logic_vector(0 to 3);
    qsfp_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    qsfp_rxf_charisk : in array4(0 to 3);
    qsfp_rxf_data    : in array32(0 to 3);
  --
    bpm_rxf_next    : out std_logic_vector(0 to 3);
    bpm_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    bpm_rxf_charisk : in  array4(0 to 3);
    bpm_rxf_data    : in  array32(0 to 3);
  --TX channels
    p0_txf_full    : in  std_logic_vector(0 to 1) := "00";
    p0_txf_write   : out std_logic_vector(0 to 1);
    p0_txf_charisk : out array4(0 to 1);
    p0_txf_data    : out array32(0 to 1);
  --
    bpm_txf_full    : in  std_logic_vector(0 to 3) := X"0";
    bpm_txf_write   : out std_logic_vector(0 to 3);
    bpm_txf_charisk : out array4(0 to 3);
    bpm_txf_data    : out array32(0 to 3); 
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig : in std_logic; --filter connected to channels 1 and 3
    i_filt02_trig : in std_logic; --filter connected to channels 0 and 2
    user_clk                    : in    std_logic;
    Bus2IP_Reset                : in    std_logic
);
end component user_logic;

constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
constant K_EOP : std_logic_vector(7 downto 0) := X"FD";

signal clk, rst : std_logic;

signal qsfp_rxf_next    : std_logic_vector(0 to 3);
signal qsfp_rxf_empty   : std_logic_vector(0 to 3);
signal qsfp_rxf_charisk : array4(0 to 3);
signal qsfp_rxf_data    : array32(0 to 3);
--
signal bpm_rxf_next    : std_logic_vector(0 to 3);
signal bpm_rxf_empty   : std_logic_vector(0 to 3);
signal bpm_rxf_charisk : array4(0 to 3);
signal bpm_rxf_data    : array32(0 to 3);
--
signal p0_txf_full    : std_logic_vector(0 to 1);
signal p0_txf_write   : std_logic_vector(0 to 1);
signal p0_txf_charisk : array4(0 to 1);
signal p0_txf_data    : array32(0 to 1);
--
signal bpm_txf_full    : std_logic_vector(0 to 3);
signal bpm_txf_write   : std_logic_vector(0 to 3);
signal bpm_txf_charisk : array4(0 to 3);
signal bpm_txf_data    : array32(0 to 3);

type array8 is array (natural range<>) of std_logic_vector(7 downto 0);
type arrayP is array (natural range<>) of ibfb_comm_packet;

constant CTRL_V      : array8(0 to 3) := (X"AA", X"BB", X"CC", X"DD");
constant DOWNCOUNT_V : std_logic_vector(0 to 3) := "0011";

signal qsfp_pkt_start : std_logic_vector(0 to 3);
signal qsfp_pkt_busy  : std_logic_vector(0 to 3);
signal qsfp_pkt_valid : std_logic_vector(0 to 3);
signal qsfp_pkt       : arrayP(0 to 3);

signal qsfp_txf_full    : std_logic_vector(0 to 3);
signal qsfp_txf_valid   : std_logic_vector(0 to 3);
signal qsfp_txf_charisk : array4(0 to 3);
signal qsfp_txf_data    : array32(0 to 3);

signal p0_txf_next : std_logic_vector(0 to 1);
signal p0_rx_bad_data : std_logic_vector(0 to 1);
signal p0_rx_eop      : std_logic_vector(0 to 1);
signal p0_rx_crc_good : std_logic_vector(0 to 1);
signal p0_rx_data     : arrayP(0 to 1);

signal p0_rx_eop_reg  : std_logic_vector(0 to 1);
signal p0_rx_good_reg : std_logic_vector(0 to 1);
signal p0_rx_data_reg : arrayP(0 to 1);

signal npackets : std_logic_vector(7 downto 0);

signal trig13, trig02 : std_logic;

begin

rst <= '1', '0' after 500 ns;
clk <= '1' after 5 ns when clk = '0' else 
       '0' after 5 ns;

trig13 <= '0';
trig02 <= '0';
npackets <= X"10";
qsfp_pkt_start <= "0000";

--EMULATE QSFP CHANNELS
QSFP_GEN : for i in 0 to 3 generate

    PKT_GEN_i : ibfb_packet_gen
    generic map(
        CTRL => CTRL_V(i),
        PKT_CNT_W => 8,
        DOWNCOUNT => DOWNCOUNT_V(i),
        SOP => K_SOP,
        EOP => K_EOP
    )
    port map(
        i_clk       => clk,
        i_rst       => rst,
        --CTRL interface
        i_start     => qsfp_pkt_start(i),
        i_npackets  => npackets,
        --PKT interface
        i_busy      => qsfp_pkt_busy(i),
        o_tx_valid  => qsfp_pkt_valid(i),
        o_tx_data   => qsfp_pkt(i)
    );

    PACK_TX_i : ibfb_packet_tx
    generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        EXTERNAL_CRC => '0'
    )
    port map(
        i_rst       => rst,
        i_clk       => clk,
        --user interface
        o_busy      => qsfp_pkt_busy(i),
        i_tx_valid  => qsfp_pkt_valid(i),
        i_tx_data   => qsfp_pkt(i),
        --MGT FIFO interface
        i_fifo_full => qsfp_txf_full(i),
        o_valid     => qsfp_txf_valid(i),
        o_charisk   => qsfp_txf_charisk(i),
        o_data      => qsfp_txf_data(i)
    );

    assert not(qsfp_txf_valid(i) = '1' and qsfp_txf_full(i) = '1')
           report "QSFP_PKT_TX : CRITICAL : Writing TX FIFO while FULL"
           severity error;

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
        FULL        => qsfp_txf_full(i),
        ALMOSTFULL  => open,
        WREN        => qsfp_txf_valid(i),
        WRCOUNT     => open,
        WRERR       => open,
        DIP         => qsfp_txf_charisk(i),
        DI          => qsfp_txf_data(i),

        RDCLK       => clk,
        EMPTY       => qsfp_rxf_empty(i),
        ALMOSTEMPTY => open,
        RDEN        => qsfp_rxf_next(i),
        RDCOUNT     => open,
        RDERR       => open,
        DOP         => qsfp_rxf_charisk(i),
        DO          => qsfp_rxf_data(i)
    );

end generate;

bpm_rxf_empty <= X"F";
bpm_txf_full  <= X"0";

SWITCH_UUT : user_logic
generic map(
    --BPM1 FPGA 
    SFP02_FILT_EN    => '1',
    SFP13_FILT_EN    => '1',
    OUTPUT_TO_P0     => '1',
    --Packet protocol 
    K_SOP            => K_SOP,
    K_EOP            => K_EOP,
    --Transceivers
    C_GTX_REFCLK_SEL    => X"00"
)
port map(
    --RX channels
    qsfp_rxf_next    => qsfp_rxf_next,
    qsfp_rxf_empty   => qsfp_rxf_empty,
    qsfp_rxf_charisk => qsfp_rxf_charisk,
    qsfp_rxf_data    => qsfp_rxf_data,
  --
    bpm_rxf_next    => bpm_rxf_next,
    bpm_rxf_empty   => bpm_rxf_empty,
    bpm_rxf_charisk => bpm_rxf_charisk,
    bpm_rxf_data    => bpm_rxf_data,
  --TX channels
    p0_txf_full    => p0_txf_full,
    p0_txf_write   => p0_txf_write,
    p0_txf_charisk => p0_txf_charisk,
    p0_txf_data    => p0_txf_data,
  --
    bpm_txf_full    => bpm_txf_full,
    bpm_txf_write   => bpm_txf_write,
    bpm_txf_charisk => bpm_txf_charisk,
    bpm_txf_data    => bpm_txf_data,
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig => trig13,
    i_filt02_trig => trig02,
    user_clk      => clk,
    Bus2IP_Reset  => rst
);

PKT_RX_GEN : for i in 0 to 1 generate
    
    p0_txf_full(i) <= not p0_txf_next(i);

    PKT_RX_i : ibfb_packet_rx
    generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP
    )
    port map(
        i_rst => rst,
        i_clk => clk,
        --MGT FIFO interface
        o_next     => p0_txf_next(i),
        i_valid    => p0_txf_write(i),
        i_charisk  => p0_txf_charisk(i),
        i_data     => p0_txf_data(i),
        --user interface
        o_bad_data => p0_rx_bad_data(i),
        o_eop      => p0_rx_eop(i),
        o_crc_good => p0_rx_crc_good(i),
        o_rx_data  => p0_rx_data(i)
    );

    RX_PKT_REG_P : process(clk)
    begin
        if rising_edge(clk) then
            p0_rx_eop_reg(i)  <= p0_rx_eop(i);
            p0_rx_good_reg(i) <= p0_rx_crc_good(i);
            if p0_rx_eop(i) = '1' then
                p0_rx_data_reg(i) <= p0_rx_data(i);
            end if;
        end if;
    end process;

end generate;

end architecture test_bpm1;


--SECOND TEST (SWITCH IN BPM2 configuration: receive data from QSFP, FILTER only one couple, FORWARD TO BPM0
architecture test_bpm2 of user_logic_sim_tb is

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

component ibfb_packet_gen is
generic(
    CTRL      : std_logic_vector(7 downto 0) := X"CC";
    PKT_CNT_W : natural := 8;
    DOWNCOUNT : std_logic := '0';
    SOP : std_logic_vector(7 downto 0);
    EOP : std_logic_vector(7 downto 0)
);
port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    --CTRL interface
    i_start     : in  std_logic;
    i_npackets  : in  std_logic_vector(PKT_CNT_W-1 downto 0); --number of packets to send 
    --TX Interface
    i_busy      : in  std_logic;
    o_tx_valid  : out std_logic;
    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
);
end component ibfb_packet_gen;

component user_logic is
generic (
    --Interconnection topology 
    SFP02_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 02
    SFP13_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 13
    OUTPUT_TO_P0     : std_logic := '1'; --when 1, packets are output on backplane P0 connector. 
                                         --Otherwise on BPM0 channel
    --Packet protocol 
    K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
    K_EOP            : std_logic_vector(7 downto 0) := X"FD";
    --Transceivers
    C_GTX_REFCLK_SEL    : std_logic_vector(7 downto 0); --BPM23, BPM01, P0, SFP02, SFP13
    --
    C_SFP13_REFCLK_FREQ : integer := 125; --MHz
    C_SFP02_REFCLK_FREQ : integer := 125; --MHz
    C_P0_REFCLK_FREQ    : integer := 125; --MHz
    C_BPM_REFCLK_FREQ   : integer := 125; --MHz
    --
    C_SFP13_BAUD_RATE   : integer := 3125000; --Kbps
    C_SFP02_BAUD_RATE   : integer := 3125000; --Kbps
    C_P0_BAUD_RATE      : integer := 3125000; --Kbps
    C_BPM_BAUD_RATE     : integer := 3125000; --Kbps
    --PLB 
    C_SLV_DWIDTH     : integer := 32;
    C_NUM_REG        : integer := 32
);
port (
    --RX channels
    qsfp_rxf_next    : out std_logic_vector(0 to 3);
    qsfp_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    qsfp_rxf_charisk : in array4(0 to 3);
    qsfp_rxf_data    : in array32(0 to 3);
  --
    bpm_rxf_next    : out std_logic_vector(0 to 3);
    bpm_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    bpm_rxf_charisk : in  array4(0 to 3);
    bpm_rxf_data    : in  array32(0 to 3);
  --TX channels
    p0_txf_full    : in  std_logic_vector(0 to 1) := "00";
    p0_txf_write   : out std_logic_vector(0 to 1);
    p0_txf_charisk : out array4(0 to 1);
    p0_txf_data    : out array32(0 to 1);
  --
    bpm_txf_full    : in  std_logic_vector(0 to 3) := X"0";
    bpm_txf_write   : out std_logic_vector(0 to 3);
    bpm_txf_charisk : out array4(0 to 3);
    bpm_txf_data    : out array32(0 to 3); 
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig : in std_logic; --filter connected to channels 1 and 3
    i_filt02_trig : in std_logic; --filter connected to channels 0 and 2
    user_clk                    : in    std_logic;
    Bus2IP_Reset                : in    std_logic
);
end component user_logic;

constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
constant K_EOP : std_logic_vector(7 downto 0) := X"FD";

signal clk, rst : std_logic;

signal qsfp_rxf_next    : std_logic_vector(0 to 3);
signal qsfp_rxf_empty   : std_logic_vector(0 to 3);
signal qsfp_rxf_charisk : array4(0 to 3);
signal qsfp_rxf_data    : array32(0 to 3);
--
signal bpm_rxf_next    : std_logic_vector(0 to 3);
signal bpm_rxf_empty   : std_logic_vector(0 to 3);
signal bpm_rxf_charisk : array4(0 to 3);
signal bpm_rxf_data    : array32(0 to 3);
--
signal p0_txf_full    : std_logic_vector(0 to 1);
signal p0_txf_write   : std_logic_vector(0 to 1);
signal p0_txf_charisk : array4(0 to 1);
signal p0_txf_data    : array32(0 to 1);
--
signal bpm_txf_full    : std_logic_vector(0 to 3);
signal bpm_txf_write   : std_logic_vector(0 to 3);
signal bpm_txf_charisk : array4(0 to 3);
signal bpm_txf_data    : array32(0 to 3);
signal bpm_txf_next    : std_logic_vector(0 to 3);

type array8 is array (natural range<>) of std_logic_vector(7 downto 0);
type arrayP is array (natural range<>) of ibfb_comm_packet;

constant CTRL_V      : array8(0 to 3) := (X"AA", X"BB", X"CC", X"DD");
constant DOWNCOUNT_V : std_logic_vector(0 to 3) := "0011";

signal qsfp_pkt_start : std_logic_vector(0 to 3);
signal qsfp_pkt_busy  : std_logic_vector(0 to 3);
signal qsfp_pkt_valid : std_logic_vector(0 to 3);
signal qsfp_pkt       : arrayP(0 to 3);

signal qsfp_txf_full    : std_logic_vector(0 to 3);
signal qsfp_txf_valid   : std_logic_vector(0 to 3);
signal qsfp_txf_charisk : array4(0 to 3);
signal qsfp_txf_data    : array32(0 to 3);

signal bpm_rx_bad_data : std_logic;
signal bpm_rx_eop      : std_logic;
signal bpm_rx_crc_good : std_logic;
signal bpm_rx_data     : ibfb_comm_packet;

signal bpm_rx_eop_reg  : std_logic;
signal bpm_rx_good_reg : std_logic;
signal bpm_rx_data_reg : ibfb_comm_packet;

signal npackets : std_logic_vector(7 downto 0);

signal trig13, trig02 : std_logic;

begin

rst <= '1', '0' after 500 ns;
clk <= '1' after 5 ns when clk = '0' else 
       '0' after 5 ns;

trig13 <= '0';
trig02 <= '0';
npackets <= X"10";
qsfp_pkt_start <= "0000";

--EMULATE QSFP CHANNELS (leave channel 3 unconnected)
QSFP_GEN : for i in 0 to 2 generate

    PKT_GEN_i : ibfb_packet_gen
    generic map(
        CTRL => CTRL_V(i),
        PKT_CNT_W => 8,
        DOWNCOUNT => DOWNCOUNT_V(i),
        SOP => K_SOP,
        EOP => K_EOP
    )
    port map(
        i_clk       => clk,
        i_rst       => rst,
        --CTRL interface
        i_start     => qsfp_pkt_start(i),
        i_npackets  => npackets,
        --PKT interface
        i_busy      => qsfp_pkt_busy(i),
        o_tx_valid  => qsfp_pkt_valid(i),
        o_tx_data   => qsfp_pkt(i)
    );

    PACK_TX_i : ibfb_packet_tx
    generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        EXTERNAL_CRC => '0'
    )
    port map(
        i_rst       => rst,
        i_clk       => clk,
        --user interface
        o_busy      => qsfp_pkt_busy(i),
        i_tx_valid  => qsfp_pkt_valid(i),
        i_tx_data   => qsfp_pkt(i),
        --MGT FIFO interface
        i_fifo_full => qsfp_txf_full(i),
        o_valid     => qsfp_txf_valid(i),
        o_charisk   => qsfp_txf_charisk(i),
        o_data      => qsfp_txf_data(i)
    );

    assert not(qsfp_txf_valid(i) = '1' and qsfp_txf_full(i) = '1')
           report "QSFP_PKT_TX : CRITICAL : Writing TX FIFO while FULL"
           severity error;

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
        FULL        => qsfp_txf_full(i),
        ALMOSTFULL  => open,
        WREN        => qsfp_txf_valid(i),
        WRCOUNT     => open,
        WRERR       => open,
        DIP         => qsfp_txf_charisk(i),
        DI          => qsfp_txf_data(i),

        RDCLK       => clk,
        EMPTY       => qsfp_rxf_empty(i),
        ALMOSTEMPTY => open,
        RDEN        => qsfp_rxf_next(i),
        RDCOUNT     => open,
        RDERR       => open,
        DOP         => qsfp_rxf_charisk(i),
        DO          => qsfp_rxf_data(i)
    );

end generate;

qsfp_rxf_empty(3) <= '0'; --channel not used

bpm_rxf_empty <= "1111";

SWITCH_UUT : user_logic
generic map(
    --BPM1 FPGA 
    SFP02_FILT_EN    => '1',
    SFP13_FILT_EN    => '0',
    OUTPUT_TO_P0     => '0',
    --Packet protocol 
    K_SOP            => K_SOP,
    K_EOP            => K_EOP,
    --Transceivers
    C_GTX_REFCLK_SEL    => X"00"
)
port map(
    --RX channels
    qsfp_rxf_next    => qsfp_rxf_next,
    qsfp_rxf_empty   => qsfp_rxf_empty,
    qsfp_rxf_charisk => qsfp_rxf_charisk,
    qsfp_rxf_data    => qsfp_rxf_data,
  --
    bpm_rxf_next    => bpm_rxf_next,
    bpm_rxf_empty   => bpm_rxf_empty,
    bpm_rxf_charisk => bpm_rxf_charisk,
    bpm_rxf_data    => bpm_rxf_data,
  --TX channels
    p0_txf_full    => p0_txf_full,
    p0_txf_write   => p0_txf_write,
    p0_txf_charisk => p0_txf_charisk,
    p0_txf_data    => p0_txf_data,
  --
    bpm_txf_full    => bpm_txf_full,
    bpm_txf_write   => bpm_txf_write,
    bpm_txf_charisk => bpm_txf_charisk,
    bpm_txf_data    => bpm_txf_data,
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig => trig13,
    i_filt02_trig => trig02,
    user_clk      => clk,
    Bus2IP_Reset  => rst
);

    bpm_txf_next(1 to 3) <= "000";
    bpm_txf_full <= not bpm_txf_next;

    PKT_RX : ibfb_packet_rx
    generic map(
        K_SOP => K_SOP,
        K_EOP => K_EOP
    )
    port map(
        i_rst => rst,
        i_clk => clk,
        --MGT FIFO interface
        o_next     => bpm_txf_next(0),
        i_valid    => bpm_txf_write(0),
        i_charisk  => bpm_txf_charisk(0),
        i_data     => bpm_txf_data(0),
        --user interface
        o_bad_data => bpm_rx_bad_data,
        o_eop      => bpm_rx_eop,
        o_crc_good => bpm_rx_crc_good,
        o_rx_data  => bpm_rx_data
    );

    RX_PKT_REG_P : process(clk)
    begin
        if rising_edge(clk) then
            bpm_rx_eop_reg  <= bpm_rx_eop;
            bpm_rx_good_reg <= bpm_rx_crc_good;
            if bpm_rx_eop = '1' then
                bpm_rx_data_reg <= bpm_rx_data;
            end if;
        end if;
    end process;

end architecture test_bpm2;
