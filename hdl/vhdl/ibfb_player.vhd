
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.plbv46_slave_burst;

library ibfb_player_v1_00_b;
use ibfb_player_v1_00_b.user_logic;

--IP's TOP LEVEL
entity ibfb_player is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    C_USE_EXTERNAL_CLOCK : std_logic := '1'; --use external differential clock i_ext_clk instead of internal i_user_clk
    -- Packet protocol 
    C_K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
    C_K_EOP            : std_logic_vector(7 downto 0) := X"FD";
    --PLAYER --------------------------------------------------------------------------------
    --Select which MGT CHANNEL to use to receive correction packets (9:0 <=> B3 B2 B1 B0 P01 P00 Q3 Q2 Q1 Q0)
    C_FEEDBACK_RX_CHAN : integer range 0 to 9 := 4;
    --Enable player for each channel: Q0,Q1,Q2,Q3,P00,P01,B0,B1,B2,B3
    C_PLAYER_EN         : std_logic_vector(0 to 9) := "1111111111"; 
    --IBFB Packet CTRL field that causes the end of playback
    C_PLAYER_CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; 
    --RAM addr width. Let ADDR_W = log2(4*Npackets+2) to leave at least 2 words for END_OF_STREAM
    --ADDRESS(PLAYER_RAM_ADDR_W+3 downto PLAYER_RAM_ADDR_W) selects which RAM to address
    --(0x0 to 0x9 => Q0,Q1,Q2,Q3,P00,P01,B0,B1,B2,B3)
    C_PLAYER_RAM_ADDR_W : natural := 14; 
    -- Transceiver settings
    C_GTX_REFCLK_SEL    : std_logic_vector(4 downto 0) := "01100"; --BPM23, BPM01, P0, SFP02, SFP13
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
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_MEM0_BASEADDR                : std_logic_vector     := X"FFFFFFFF";
    C_MEM0_HIGHADDR                : std_logic_vector     := X"00000000";
    C_SPLB_AWIDTH                  : integer              := 32;
    C_SPLB_DWIDTH                  : integer              := 128;
    C_SPLB_NUM_MASTERS             : integer              := 8;
    C_SPLB_MID_WIDTH               : integer              := 3;
    C_SPLB_NATIVE_DWIDTH           : integer              := 32;
    C_SPLB_P2P                     : integer              := 0;
    C_SPLB_SUPPORT_BURSTS          : integer              := 1;
    C_SPLB_SMALLEST_MASTER         : integer              := 32;
    C_SPLB_CLK_PERIOD_PS           : integer              := 10000;
    C_INCLUDE_DPHASE_TIMER         : integer              := 1;
    C_FAMILY                       : string               := "virtex6"
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
    I_GTX_REFCLK1_IN              : in  std_logic;
    I_GTX_REFCLK2_IN              : in  std_logic;
    O_GTX_REFCLK_OUT              : out std_logic;
    I_GTX_RX_N                    : in  std_logic_vector(2*5-1 downto 0);
    I_GTX_RX_P                    : in  std_logic_vector(2*5-1 downto 0);
    O_GTX_TX_N                    : out std_logic_vector(2*5-1 downto 0);
    O_GTX_TX_P                    : out std_logic_vector(2*5-1 downto 0);
    O_CSP_CLK                     : out std_logic_vector(2 downto 0);
    O_CSP_DATA0                   : out std_logic_vector(383 downto 0);     
    O_CSP_DATA1                   : out std_logic_vector(319 downto 0);     
    O_CSP_DATA2                   : out std_logic_vector(255 downto 0);     
    i_user_clk                    : in  std_logic;
    i_ext_clk_p                   : in  std_logic;
    i_ext_clk_n                   : in  std_logic;
    --i_player_start                : in std_logic_vector(0 to 9); --pkt player triggers
    i_trigger_p                   : in std_logic;
    i_trigger_n                   : in std_logic;
    o_led_pulse                   : out std_logic;
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    SPLB_Clk                       : in  std_logic;
    SPLB_Rst                       : in  std_logic;
    PLB_ABus                       : in  std_logic_vector(0 to 31);
    PLB_UABus                      : in  std_logic_vector(0 to 31);
    PLB_PAValid                    : in  std_logic;
    PLB_SAValid                    : in  std_logic;
    PLB_rdPrim                     : in  std_logic;
    PLB_wrPrim                     : in  std_logic;
    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort                      : in  std_logic;
    PLB_busLock                    : in  std_logic;
    PLB_RNW                        : in  std_logic;
    PLB_BE                         : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
    PLB_MSize                      : in  std_logic_vector(0 to 1);
    PLB_size                       : in  std_logic_vector(0 to 3);
    PLB_type                       : in  std_logic_vector(0 to 2);
    PLB_lockErr                    : in  std_logic;
    PLB_wrDBus                     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst                    : in  std_logic;
    PLB_rdBurst                    : in  std_logic;
    PLB_wrPendReq                  : in  std_logic;
    PLB_rdPendReq                  : in  std_logic;
    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
    PLB_reqPri                     : in  std_logic_vector(0 to 1);
    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
    Sl_addrAck                     : out std_logic;
    Sl_SSize                       : out std_logic_vector(0 to 1);
    Sl_wait                        : out std_logic;
    Sl_rearbitrate                 : out std_logic;
    Sl_wrDAck                      : out std_logic;
    Sl_wrComp                      : out std_logic;
    Sl_wrBTerm                     : out std_logic;
    Sl_rdDBus                      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                    : out std_logic_vector(0 to 3);
    Sl_rdDAck                      : out std_logic;
    Sl_rdComp                      : out std_logic;
    Sl_rdBTerm                     : out std_logic;
    Sl_MBusy                       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ                        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of SPLB_Clk      : signal is "CLK";
  attribute SIGIS of SPLB_Rst      : signal is "RST";

end entity ibfb_player;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of ibfb_player is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
  constant USER_SLV_BASEADDR              : std_logic_vector     := C_BASEADDR;
  constant USER_SLV_HIGHADDR              : std_logic_vector     := C_HIGHADDR;

  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & USER_SLV_BASEADDR,  -- user logic slave space base address
      ZERO_ADDR_PAD & USER_SLV_HIGHADDR,  -- user logic slave space high address
      ZERO_ADDR_PAD & C_MEM0_BASEADDR,    -- user logic memory space 0 base address
      ZERO_ADDR_PAD & C_MEM0_HIGHADDR     -- user logic memory space 0 high address
    );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_SLV_NUM_REG               : integer              := 128;
  constant USER_NUM_REG                   : integer              := USER_SLV_NUM_REG;
  constant USER_NUM_MEM                   : integer              := 1;

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(USER_SLV_NUM_REG), -- number of ce for user logic slave space
      1  => 1                             -- number of ce for user logic memory space 0 (always 1 chip enable)
    );

  ------------------------------------------
  -- Cache line addressing mode (for cacheline read operations)
  -- 0 = target word first on reads
  -- 1 = line word first on reads
  ------------------------------------------
  constant IPIF_CACHLINE_ADDR_MODE        : integer              := 0;

  ------------------------------------------
  -- Number of storage locations for the write buffer
  -- Valid depths are 0, 16, 32, or 64
  -- 0 = no write buffer implemented
  ------------------------------------------
  constant IPIF_WR_BUFFER_DEPTH           : integer              := 16;

  ------------------------------------------
  -- The type out of the Bus2IP_BurstLength signal
  -- 0 = length is in actual byte number
  -- 1 = length is in data beats - 1
  ------------------------------------------
  constant IPIF_BURSTLENGTH_TYPE          : integer              := 0;

 
  ------------------------------------------
  -- Width of the slave data bus (32, 64, or 128)
  ------------------------------------------
  constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the slave address bus (32 only)
  ------------------------------------------
  constant USER_SLV_AWIDTH                : integer              := C_SPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant USER_SLV_CS_INDEX              : integer              := 0;
  constant USER_SLV_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_SLV_CS_INDEX);
  constant USER_MEM0_CS_INDEX             : integer              := 1;
  constant USER_CS_INDEX                  : integer              := USER_MEM0_CS_INDEX;

  constant USER_CE_INDEX                  : integer              := USER_SLV_CE_INDEX;

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Reset              : std_logic;
  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_AddrAck            : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_Bus2IP_RNW                : std_logic;
  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
  signal ipif_Bus2IP_Burst              : std_logic;
  signal ipif_Bus2IP_BurstLength        : std_logic_vector(0 to log2(16*(C_SPLB_DWIDTH/8)));
  signal ipif_Bus2IP_WrReq              : std_logic;
  signal ipif_Bus2IP_RdReq              : std_logic;
  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal user_Bus2IP_RdCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_Bus2IP_WrCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_Bus2IP_BurstLength        : std_logic_vector(0 to 8)   := (others => '0');
  signal user_IP2Bus_AddrAck            : std_logic;
  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;

  --trigger resync
  --type   array10 is array (natural range <>) of std_logic_vector(9 downto 0);
  signal player_start_sr : std_logic_vector(3 downto 0);
  signal user_clk, trigger : std_logic;

begin

  ------------------------------------------
  -- instantiate plbv46_slave_burst
  ------------------------------------------
  PLBV46_SLAVE_BURST_I : entity plbv46_slave_burst_v1_01_a.plbv46_slave_burst
    generic map
    (
      C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
      C_SPLB_P2P                     => C_SPLB_P2P,
      C_CACHLINE_ADDR_MODE           => IPIF_CACHLINE_ADDR_MODE,
      C_WR_BUFFER_DEPTH              => IPIF_WR_BUFFER_DEPTH,
      C_BURSTLENGTH_TYPE             => IPIF_BURSTLENGTH_TYPE,
      C_SPLB_MID_WIDTH               => C_SPLB_MID_WIDTH,
      C_SPLB_NUM_MASTERS             => C_SPLB_NUM_MASTERS,
      C_SPLB_SMALLEST_MASTER         => C_SPLB_SMALLEST_MASTER,
      C_SPLB_AWIDTH                  => C_SPLB_AWIDTH,
      C_SPLB_DWIDTH                  => C_SPLB_DWIDTH,
      C_SIPIF_DWIDTH                 => IPIF_SLV_DWIDTH,
      C_INCLUDE_DPHASE_TIMER         => C_INCLUDE_DPHASE_TIMER,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      SPLB_Clk                       => SPLB_Clk,
      SPLB_Rst                       => SPLB_Rst,
      PLB_ABus                       => PLB_ABus,
      PLB_UABus                      => PLB_UABus,
      PLB_PAValid                    => PLB_PAValid,
      PLB_SAValid                    => PLB_SAValid,
      PLB_rdPrim                     => PLB_rdPrim,
      PLB_wrPrim                     => PLB_wrPrim,
      PLB_masterID                   => PLB_masterID,
      PLB_abort                      => PLB_abort,
      PLB_busLock                    => PLB_busLock,
      PLB_RNW                        => PLB_RNW,
      PLB_BE                         => PLB_BE,
      PLB_MSize                      => PLB_MSize,
      PLB_size                       => PLB_size,
      PLB_type                       => PLB_type,
      PLB_lockErr                    => PLB_lockErr,
      PLB_wrDBus                     => PLB_wrDBus,
      PLB_wrBurst                    => PLB_wrBurst,
      PLB_rdBurst                    => PLB_rdBurst,
      PLB_wrPendReq                  => PLB_wrPendReq,
      PLB_rdPendReq                  => PLB_rdPendReq,
      PLB_wrPendPri                  => PLB_wrPendPri,
      PLB_rdPendPri                  => PLB_rdPendPri,
      PLB_reqPri                     => PLB_reqPri,
      PLB_TAttribute                 => PLB_TAttribute,
      Sl_addrAck                     => Sl_addrAck,
      Sl_SSize                       => Sl_SSize,
      Sl_wait                        => Sl_wait,
      Sl_rearbitrate                 => Sl_rearbitrate,
      Sl_wrDAck                      => Sl_wrDAck,
      Sl_wrComp                      => Sl_wrComp,
      Sl_wrBTerm                     => Sl_wrBTerm,
      Sl_rdDBus                      => Sl_rdDBus,
      Sl_rdWdAddr                    => Sl_rdWdAddr,
      Sl_rdDAck                      => Sl_rdDAck,
      Sl_rdComp                      => Sl_rdComp,
      Sl_rdBTerm                     => Sl_rdBTerm,
      Sl_MBusy                       => Sl_MBusy,
      Sl_MWrErr                      => Sl_MWrErr,
      Sl_MRdErr                      => Sl_MRdErr,
      Sl_MIRQ                        => Sl_MIRQ,
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      IP2Bus_Data                    => ipif_IP2Bus_Data,
      IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
      IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
      IP2Bus_AddrAck                 => ipif_IP2Bus_AddrAck,
      IP2Bus_Error                   => ipif_IP2Bus_Error,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_Burst                   => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength             => ipif_Bus2IP_BurstLength,
      Bus2IP_WrReq                   => ipif_Bus2IP_WrReq,
      Bus2IP_RdReq                   => ipif_Bus2IP_RdReq,
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE
    );

  --PLAYER's clock selection (external or internal) --------------------------------
  USR_CLK_G : if C_USE_EXTERNAL_CLOCK = '1' generate
      XCLK_IBUF_I : IBUFGDS
      port map(
          I  => i_ext_clk_p,
          IB => i_ext_clk_n,
          O  => user_clk
      );
  end generate;
  --
  USR_CLK_G_N : if C_USE_EXTERNAL_CLOCK = '0' generate
      user_clk <= i_user_clk;
  end generate;


  ---------------------------------------------------------------------------------
  -- INPUT TRIGGER RESYNCHRONIZATION ----------------------------------------------
  ---------------------------------------------------------------------------------
  TRIG_IBUF_I : IBUFDS
  port map(
      I  => i_trigger_p,
      IB => i_trigger_n,
      O  => trigger
  );

  --ML84 20.6.16: trigger connected directly to timin component
  --START_TRIG_RESYNC_P : process(user_clk) 
  --begin
  --    if rising_edge(user_clk) then
  --        player_start_sr(3 downto 1) <= player_start_sr(2 downto 0); --shift left
  --        --player_start_sr(0)          <= i_player_start;
  --        player_start_sr(0)          <= trigger;
  --    end if;
  --end process;

  ------------------------------------------
  -- instantiate User Logic
  ------------------------------------------
  USER_LOGIC_I : entity ibfb_player_v1_00_b.user_logic
    generic map  (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      USE_EXTERNAL_CLOCK  => C_USE_EXTERNAL_CLOCK,
      -- Packet protocol 
      K_SOP               => C_K_SOP,
      K_EOP               => C_K_EOP,
      --PLAYER --------------------------------------------
      FEEDBACK_RX_CHAN    => C_FEEDBACK_RX_CHAN,
      PLAYER_EN           => C_PLAYER_EN,
      PLAYER_CTRL_EOS     => C_PLAYER_CTRL_EOS,
      PLAYER_RAM_ADDR_W   => C_PLAYER_RAM_ADDR_W,
      -- Transceiver settings
      C_GTX_REFCLK_SEL    => C_GTX_REFCLK_SEL,
      --
      C_SFP13_REFCLK_FREQ => C_SFP13_REFCLK_FREQ,
      C_SFP02_REFCLK_FREQ => C_SFP02_REFCLK_FREQ,
      C_P0_REFCLK_FREQ    => C_P0_REFCLK_FREQ,
      C_BPM_REFCLK_FREQ   => C_BPM_REFCLK_FREQ,
      --
      C_SFP13_BAUD_RATE   => C_SFP13_BAUD_RATE,
      C_SFP02_BAUD_RATE   => C_SFP02_BAUD_RATE,
      C_P0_BAUD_RATE      => C_P0_BAUD_RATE,
      C_BPM_BAUD_RATE     => C_BPM_BAUD_RATE,
      -- MAP USER GENERICS ABOVE THIS LINE ---------------

      C_SLV_AWIDTH        => USER_SLV_AWIDTH,
      C_SLV_DWIDTH        => USER_SLV_DWIDTH,
      C_NUM_REG           => USER_NUM_REG,
      C_NUM_MEM           => USER_NUM_MEM
    )
    port map  (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      --chipscope 
      O_CSP_CLK            => O_CSP_CLK,
      O_CSP_DATA0          => O_CSP_DATA0,
      O_CSP_DATA1          => O_CSP_DATA1,
      O_CSP_DATA2          => O_CSP_DATA2,
      --MGT interface
      I_GTX_REFCLK1_IN     => I_GTX_REFCLK1_IN,
      I_GTX_REFCLK2_IN     => I_GTX_REFCLK2_IN,
      O_GTX_REFCLK_OUT     => O_GTX_REFCLK_OUT,
      I_GTX_RX_N           => I_GTX_RX_N,
      I_GTX_RX_P           => I_GTX_RX_P,
      O_GTX_TX_N           => O_GTX_TX_N,
      O_GTX_TX_P           => O_GTX_TX_P,
      --core interface
      i_user_clk           => user_clk,
      i_player_start       => trigger, --(ML84 20.6.16) player_start_sr(3), --can choose between registers 3:0
      o_led_pulse          => o_led_pulse,
      -- MAP USER PORTS ABOVE THIS LINE ------------------
      Bus2IP_Clk           => ipif_Bus2IP_Clk,
      Bus2IP_Reset         => ipif_Bus2IP_Reset,
      Bus2IP_Addr          => ipif_Bus2IP_Addr,
      Bus2IP_CS            => ipif_Bus2IP_CS(USER_CS_INDEX to USER_CS_INDEX+USER_NUM_MEM-1),
      Bus2IP_RNW           => ipif_Bus2IP_RNW,
      Bus2IP_Data          => ipif_Bus2IP_Data,
      Bus2IP_BE            => ipif_Bus2IP_BE,
      Bus2IP_RdCE          => user_Bus2IP_RdCE,
      Bus2IP_WrCE          => user_Bus2IP_WrCE,
      Bus2IP_Burst         => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength   => user_Bus2IP_BurstLength,
      Bus2IP_RdReq         => ipif_Bus2IP_RdReq,
      Bus2IP_WrReq         => ipif_Bus2IP_WrReq,
      IP2Bus_AddrAck       => user_IP2Bus_AddrAck,
      IP2Bus_Data          => user_IP2Bus_Data,
      IP2Bus_RdAck         => user_IP2Bus_RdAck,
      IP2Bus_WrAck         => user_IP2Bus_WrAck,
      IP2Bus_Error         => user_IP2Bus_Error
    );

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data ) is
  begin

    case ipif_Bus2IP_CS is
      when "10" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "01" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when others => ipif_IP2Bus_Data <= (others => '0');
    end case;

  end process IP2BUS_DATA_MUX_PROC;

  ipif_IP2Bus_AddrAck <= ipif_Bus2IP_Burst and user_IP2Bus_AddrAck;
  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error;

  user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);
  user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);

  user_Bus2IP_BurstLength(8-log2(16*(C_SPLB_DWIDTH/8)) to 8) <= ipif_Bus2IP_BurstLength;

end IMP;

