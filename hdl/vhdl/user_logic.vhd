------------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : user_logic.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.3 $
------------------------------------------------------------------------------
-- Copyright© PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : IBFB Packet Player
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ibfb_common_v1_00_b;
use ibfb_common_v1_00_b.virtex5_gtx_package.all;
use ibfb_common_v1_00_b.ibfb_comm_package.all;
use ibfb_common_v1_00_b.pkg_ibfb_timing.all;

--library ibfb_player_v1_00_b;
--use ibfb_player_v1_00_b.pkg_ibfb_player_fb.all;

entity user_logic is
	generic(
		USE_EXTERNAL_CLOCK  : std_logic                    := '1'; --use external differential clock i_ext_clk instead of internal i_user_clk
		--Packet protocol ----------------------------------------------------------------------- 
		K_SOP               : std_logic_vector(7 downto 0) := X"FB"; --Start of packet characted 
		K_EOP               : std_logic_vector(7 downto 0) := X"FD"; --End of packet character
		--PLAYER --------------------------------------------------------------------------------
		--Select which MGT CHANNEL to use to receive correction packets (9:0 <=> B3 B2 B1 B0 P01 P00 Q3 Q2 Q1 Q0)
		FEEDBACK_RX_CHAN    : integer range 0 to 9         := 4;
		--Enable player for each channel: B3 B2 B1 B0 P01 P00 Q3 Q2 Q1 Q0
		PLAYER_EN           : std_logic_vector(9 downto 0) := "1111111111";
		--IBFB Packet CTRL field that causes the end of playback
		PLAYER_CTRL_EOS     : std_logic_vector(7 downto 0) := X"FF";
		--Address width for RAM player (Byte address). 
		--1packet = 4x32bit = 16B = 2^4B ***** Npackets = 2^(AW-4) 
		--AW = log2(Npackets)+4
		--IMPORTANTANT: leave always room for 1 spare packet to store END-OF-SEQUENCE symbol.
		--Address bits (PLAYER_RAM_ADDR_W+3 downto PLAYER_RAM_ADDR_W) are used to select which RAM to address (0x0 to 0x9 => Q0 to B3)
		PLAYER_RAM_ADDR_W   : natural                      := 16;
		--Transceivers --------------------------------------------------------------------------
		C_GTX_REFCLK_SEL    : std_logic_vector(4 downto 0) := "01100"; --BPM23, BPM01, P0, SFP02, SFP13
		--
		C_SFP13_REFCLK_FREQ : integer                      := 125; --MHz
		C_SFP02_REFCLK_FREQ : integer                      := 125; --MHz
		C_P0_REFCLK_FREQ    : integer                      := 125; --MHz
		C_BPM_REFCLK_FREQ   : integer                      := 125; --MHz
		--
		C_SFP13_BAUD_RATE   : integer                      := 3125000; --Kbps
		C_SFP02_BAUD_RATE   : integer                      := 3125000; --Kbps
		C_P0_BAUD_RATE      : integer                      := 3125000; --Kbps
		C_BPM_BAUD_RATE     : integer                      := 3125000; --Kbps
		--PLB ----------------------------------------------------------------------------------- 
		C_SLV_AWIDTH        : integer                      := 32;
		C_SLV_DWIDTH        : integer                      := 32;
		C_NUM_REG           : integer                      := 64;
		C_NUM_MEM           : integer                      := 1
	);
	port(
		------------------------------------------------------------------------
		-- CHIPSCOPE
		------------------------------------------------------------------------
		O_CSP_CLK          : out std_logic_vector(2 downto 0);
		O_CSP_DATA0        : out std_logic_vector(383 downto 0);
		O_CSP_DATA1        : out std_logic_vector(319 downto 0);
		O_CSP_DATA2        : out std_logic_vector(255 downto 0);
		------------------------------------------------------------------------
		-- GTX INTERFACE
		------------------------------------------------------------------------
		I_GTX_REFCLK1_IN   : in  std_logic;
		I_GTX_REFCLK2_IN   : in  std_logic;
		O_GTX_REFCLK_OUT   : out std_logic;
		I_GTX_RX_N         : in  std_logic_vector(2 * 5 - 1 downto 0);
		I_GTX_RX_P         : in  std_logic_vector(2 * 5 - 1 downto 0);
		O_GTX_TX_N         : out std_logic_vector(2 * 5 - 1 downto 0);
		O_GTX_TX_P         : out std_logic_vector(2 * 5 - 1 downto 0);
		------------------------------------------------------------------------
		-- Core signals
		------------------------------------------------------------------------
		i_user_clk         : in  std_logic; --either internal or external clock
		i_player_start     : in  std_logic; --trigger connected to timing component
		o_led_pulse        : out std_logic;
		------------------------------------------------------------------------
		-- Bus ports
		------------------------------------------------------------------------
		Bus2IP_Clk         : in  std_logic;
		Bus2IP_Reset       : in  std_logic;
		Bus2IP_Addr        : in  std_logic_vector(0 to C_SLV_AWIDTH - 1);
		Bus2IP_CS          : in  std_logic_vector(0 to C_NUM_MEM - 1);
		Bus2IP_RNW         : in  std_logic;
		Bus2IP_Data        : in  std_logic_vector(0 to C_SLV_DWIDTH - 1);
		Bus2IP_BE          : in  std_logic_vector(0 to C_SLV_DWIDTH / 8 - 1);
		Bus2IP_RdCE        : in  std_logic_vector(0 to C_NUM_REG - 1);
		Bus2IP_WrCE        : in  std_logic_vector(0 to C_NUM_REG - 1);
		Bus2IP_Burst       : in  std_logic;
		Bus2IP_BurstLength : in  std_logic_vector(0 to 8);
		Bus2IP_RdReq       : in  std_logic;
		Bus2IP_WrReq       : in  std_logic;
		IP2Bus_AddrAck     : out std_logic;
		IP2Bus_Data        : out std_logic_vector(0 to C_SLV_DWIDTH - 1);
		IP2Bus_RdAck       : out std_logic;
		IP2Bus_WrAck       : out std_logic;
		IP2Bus_Error       : out std_logic
	);

	attribute MAX_FANOUT : string;
	attribute SIGIS : string;
	attribute SIGIS of Bus2IP_Clk : signal is "CLK";
	attribute SIGIS of Bus2IP_Reset : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------
architecture behavioral of user_logic is
	component ibfb_packet_player is
		generic(
			CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; --when this CTRL value is encountered, playback is stopped
			RAM_ADDR_W : natural                      := 13 --0x1FFF 32-bit words => 0x1FFF/3 = 2730 packets 
		);
		port(
			i_clk      : in  std_logic;
			i_rst      : in  std_logic;
			--debug signals
			o_dbg      : out std_logic_vector(15 downto 0);
			--CTRL interface
			i_start    : in  std_logic; --just risi9ng edge detection. no synchronization
			o_busy     : out std_logic;
			o_pkt_num  : out std_logic_vector(RAM_ADDR_W - 1 downto 0);
			--RAM interface
			i_ram_clk  : in  std_logic;
			i_ram_w    : in  std_logic;
			i_ram_a    : in  std_logic_vector(RAM_ADDR_W - 1 downto 0);
			i_ram_d    : in  std_logic_vector(31 downto 0);
			o_ram_d    : out std_logic_vector(31 downto 0);
			--TX Interface
			i_sop      : in  std_logic;
			i_busy     : in  std_logic;
			o_tx_valid : out std_logic;
			o_tx_data  : out ibfb_comm_packet --tx data (packet fields)
		);
	end component ibfb_packet_player;

	component ibfb_fb_apply_correction is
		port(
            o_dbg       : out std_logic_Vector(287 downto 0);
			i_clk       : in  std_logic;
			i_train_trg : in  std_logic; --start of bunch (resets correction computation) 
			--feedback input
			i_fb_v      : in  std_logic; --feedback valid
			--i_fb_kx     : in array16(0 to 1); --KX0,KX1
			--i_fb_ky     : in array16(0 to 1); --KY0,KY1
			i_fb_kx0    : in  std_logic_Vector(15 downto 0);
			i_fb_kx1    : in  std_logic_Vector(15 downto 0);
			i_fb_ky0    : in  std_logic_Vector(15 downto 0);
			i_fb_ky1    : in  std_logic_Vector(15 downto 0);
			--Transformation matrixes
			i_bpm_ids   : in  array8(0 to 3); --BPM IDs corresponding to each of the 4 transformation sets
			i_tr_kx0    : in  array32(0 to 3); --one value for each BPM id 
			i_tr_kx1    : in  array32(0 to 3); --one value for each BPM id 
			i_tr_ky0    : in  array32(0 to 3); --one value for each BPM id 
			i_tr_ky1    : in  array32(0 to 3); --one value for each BPM id 
			--input data
			o_rfd       : out std_logic;
			i_pkt_valid : in  std_logic;
			i_pkt_data  : in  ibfb_comm_packet;
			--output data
			o_fb_use    : out std_logic_vector(0 to 3);
			o_pipe_err  : out std_logic_vector(0 to 3); --pipeline error (shall be always X"0")
			o_pkt_valid : out std_logic;
			o_pkt_data  : out ibfb_comm_packet
		);
	end component ibfb_fb_apply_correction;

	---------------------------------------------------------------------------
	-- Bus protocol signals
	---------------------------------------------------------------------------
	-- Types ------------------------------------------------------------------
	type slv_reg_type is array (0 to C_NUM_REG - 1) of std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
	type array16 is array (natural range <>) of std_logic_vector(15 downto 0);
	-- Constants --------------------------------------------------------------
	constant LOW_REG       : std_logic_vector(0 to C_NUM_REG - 1) := (others => '0');
	-- Signals ----------------------------------------------------------------
	signal slv_reg_rd      : slv_reg_type;
	signal slv_reg_rd_ack  : std_logic                            := '0';
	signal slv_reg_wr      : slv_reg_type;
	signal slv_reg_wr_ack  : std_logic                            := '0';
	signal slv_ip2bus_data : std_logic_vector(0 to C_SLV_DWIDTH - 1);
	-- Memory access               
	signal mem_address     : std_logic_vector(31 downto 0)        := (others => '0');
	signal mem_rd_addr_ack : std_logic                            := '0';
	signal mem_rd_req      : std_logic_vector(4 downto 0)         := (others => '0');
	signal mem_rd_ack      : std_logic                            := '0';
	signal mem_rd_data     : std_logic_vector(31 downto 0)        := (others => '0');
	signal mem_wr_ack      : std_logic                            := '0';
	signal mem_wr_data     : std_logic_vector(31 downto 0)        := (others => '0');

	--Per-GTX-Tile signals
	signal qsfp13_mgt_o    : mgt_out_type;
	signal qsfp02_mgt_o    : mgt_out_type;
	signal p0_mgt_o        : mgt_out_type;
	signal bpm01_mgt_o     : mgt_out_type;
	signal bpm23_mgt_o     : mgt_out_type;
	signal qsfp_fifo_rst_c : std_logic_vector(3 downto 0);
	signal bpm_fifo_rst_c  : std_logic_vector(3 downto 0);
	signal p0_fifo_rst_c   : std_logic_vector(1 downto 0);

	--Per-GTX-channel signals
	signal qsfp_loopback : array3(3 downto 0);
	signal qsfp_fifo_rst : std_logic_vector(3 downto 0);
	signal bpm_loopback  : array3(3 downto 0);
	signal bpm_fifo_rst  : std_logic_vector(3 downto 0);
	signal p0_loopback   : array3(1 downto 0);
	signal p0_fifo_rst   : std_logic_vector(1 downto 0);

	--RX channels
	--not used, just debug
	signal qsfp_rx_sync     : std_logic_vector(3 downto 0);
	signal qsfp_rx_vld      : std_logic_vector(3 downto 0);
	signal qsfp_rxf_next    : std_logic_vector(3 downto 0);
	signal qsfp_rxf_empty   : std_logic_vector(3 downto 0);
	signal qsfp_rxf_charisk : array4(3 downto 0);
	signal qsfp_rxf_data    : array32(3 downto 0);

	signal bpm_rx_sync     : std_logic_vector(3 downto 0);
	signal bpm_rx_vld      : std_logic_vector(3 downto 0);
	signal bpm_rxf_next    : std_logic_vector(3 downto 0);
	signal bpm_rxf_empty   : std_logic_vector(3 downto 0);
	signal bpm_rxf_charisk : array4(3 downto 0);
	signal bpm_rxf_data    : array32(3 downto 0);

	signal p0_rx_sync     : std_logic_vector(1 downto 0);
	signal p0_rx_vld      : std_logic_vector(1 downto 0);
	signal p0_rxf_next    : std_logic_vector(1 downto 0);
	signal p0_rxf_empty   : std_logic_vector(1 downto 0);
	signal p0_rxf_valid   : std_logic_vector(1 downto 0);
	signal p0_rxf_charisk : array4(1 downto 0);
	signal p0_rxf_data    : array32(1 downto 0);

	--TX channels
	signal qsfp_tx_vld      : std_logic_vector(3 downto 0);
	signal qsfp_txf_full    : std_logic_vector(3 downto 0);
	signal qsfp_txf_write   : std_logic_vector(3 downto 0);
	signal qsfp_txf_charisk : array4(3 downto 0);
	signal qsfp_txf_data    : array32(3 downto 0);
	--
	signal p0_tx_vld        : std_logic_vector(1 downto 0);
	signal p0_txf_full      : std_logic_vector(1 downto 0);
	signal p0_txf_write     : std_logic_vector(1 downto 0);
	signal p0_txf_charisk   : array4(1 downto 0);
	signal p0_txf_data      : array32(1 downto 0);
	--
	signal bpm_tx_vld       : std_logic_vector(3 downto 0);
	signal bpm_txf_full     : std_logic_vector(3 downto 0);
	signal bpm_txf_write    : std_logic_vector(3 downto 0);
	signal bpm_txf_charisk  : array4(3 downto 0);
	signal bpm_txf_data     : array32(3 downto 0);

	--Players
	type ram_addr_vec_t is array (natural range <>) of std_logic_vector(PLAYER_RAM_ADDR_W - 3 downto 0);
	type ibfb_comm_pkt_vec is array (natural range <>) of ibfb_comm_packet;
	signal player_busy       : std_logic_vector(9 downto 0);
	signal player_ram_w      : std_logic_vector(9 downto 0);
	signal player_ovalid     : std_logic_vector(9 downto 0);
	signal player_n_sent_pkt : ram_addr_vec_t(9 downto 0);
	signal player_ram_rdata  : array32(9 downto 0);
	signal player_odata      : ibfb_comm_pkt_vec(9 downto 0);
	signal player_start      : std_logic_vector(9 downto 0);
	signal player_start_c    : std_logic_vector(9 downto 0);
	signal pkt_tx_sop        : std_logic_vector(9 downto 0);
	signal pkt_tx_busy       : std_logic_vector(9 downto 0);

	signal mem_select : unsigned(3 downto 0);
	signal mem_cs     : std_logic_vector(9 downto 0);

	signal dbg_pl : array16(9 downto 0);

	--LOS counters
	type uarray16 is array (natural range <>) of unsigned(15 downto 0);
	signal los_cnt                                  : uarray16(9 downto 0);
	signal rxrecclk, los_c, los, los_r, los_cnt_rst : std_logic_vector(9 downto 0);

	signal int_trig_en, trig_cnt_en, trig_cnt_en_r, player_start_r, player_start_d : std_logic             := '0';
	signal trig_delay_cnt, trig_delay                                              : unsigned(31 downto 0) := (others => '0');
	constant ZERO                                                                  : unsigned(31 downto 0) := (others => '0');

	constant CSP_SET : natural := 0;

	--TIMING COMPONENT (ML84 20.6.16)
	--type t_cpu_timing_rd is record
	--  ext_trg_missing : std_logic;
	--  read_ready      : std_logic;
	--end record t_cpu_timing_rd;
	signal r_timing_param_rd : t_cpu_timing_rd;

	--type t_cpu_timing_wr is record
	--  global_trg_ena : std_logic;
	--  trg_mode       : std_logic;
	--  trg_source     : std_logic_vector(2 downto 0);
	--  b_delay        : std_logic_vector(27 downto  0);    
	--  b_number       : std_logic_vector(15 downto  0);    
	--  b_space        : std_logic_vector(15 downto  0);    
	--  trg_rate       : std_logic_vector( 2 downto  0);    -- 0x2C -- unsigned char
	--  trg_once       : std_logic;                         -- 0x00 -- unsigned int
	--  end record t_cpu_timing_wr;
	signal r_timing_param_wr : t_cpu_timing_wr;

	--type t_timing is record
	--  sl_global_pulse_trg           : std_logic;
	--  sl_global_bunch_trg           : std_logic;
	--  sl_global_pulse               : std_logic;
	--end record t_timing;
	signal r_ibfb_timing : t_timing;

	--Feedback data
	signal fb_rxf_next                                             : std_logic;
	signal fb_rxf_valid                                            : std_logic_vector(0 to 9);
	signal fb_rxf_charisk                                          : array4(0 to 9);
	signal fb_rxf_data                                             : array32(0 to 9);
	signal fb_rx_error, fb_data_valid, fb_data_good, fb_data_avail : std_logic;
	signal fb_bkt_id                                               : std_logic_vector(15 downto 0);
	signal fb_kx, fb_ky                                            : array16(0 to 1);
	signal fb_data_r0, fb_data_r1, fb_data_r2, fb_data_r3          : std_logic_vector(15 downto 0);
	signal fb_pkt_cnt, fb_err_cnt                                  : unsigned(15 downto 0);
	signal fb_use0                                                 : std_logic_vector(0 to 3);

	signal pkt_rx_csp_data                  : std_logic_vector(63 downto 0);
	signal mon_pkt_rx_rst, mon_pkt_rx_rst_c : std_logic;

	signal corr_ovalid : std_logic_vector(0 to 9);
	signal corr_rfd    : std_logic_vector(0 to 9);
	signal corr_sop    : std_logic_vector(9 downto 0);
	signal corr_odata  : ibfb_comm_pkt_vec(9 downto 0);
	signal bpm_ids     : array8(0 to 3);

	signal tr_kx0_0 : array32(0 to 3);
	signal tr_kx1_0 : array32(0 to 3);
	signal tr_ky0_0 : array32(0 to 3);
	signal tr_ky1_0 : array32(0 to 3);

	signal tr_kx0_1 : array32(0 to 3);
	signal tr_kx1_1 : array32(0 to 3);
	signal tr_ky0_1 : array32(0 to 3);
	signal tr_ky1_1 : array32(0 to 3);

	signal tr_kx0_2 : array32(0 to 3);
	signal tr_kx1_2 : array32(0 to 3);
	signal tr_ky0_2 : array32(0 to 3);
	signal tr_ky1_2 : array32(0 to 3);

	signal tr_kx0_3 : array32(0 to 3);
	signal tr_kx1_3 : array32(0 to 3);
	signal tr_ky0_3 : array32(0 to 3);
	signal tr_ky1_3 : array32(0 to 3);

	signal tr_kx0_4 : array32(0 to 3);
	signal tr_kx1_4 : array32(0 to 3);
	signal tr_ky0_4 : array32(0 to 3);
	signal tr_ky1_4 : array32(0 to 3);

	signal tr_kx0_5 : array32(0 to 3);
	signal tr_kx1_5 : array32(0 to 3);
	signal tr_ky0_5 : array32(0 to 3);
	signal tr_ky1_5 : array32(0 to 3);

	--Rev 7: added bkt_id to monitor data
	--Rev 8: added correction component
    --Rev 9: fixed bug in correction logic, changed transform parameters selection logic
	constant FW_VERSION : std_logic_vector(31 downto 0) := X"00000009";

    signal q0_corr_debug : std_logic_vector(287 downto 0);
    signal debug_timer : unsigned(31 downto 0);

begin

	---------------------------------------------------------------------------
	-- Status
	---------------------------------------------------------------------------
	IP2Bus_AddrAck <= slv_reg_rd_ack or mem_rd_addr_ack or slv_reg_wr_ack or mem_wr_ack;
	IP2Bus_RdAck   <= slv_reg_rd_ack or mem_rd_ack;
	IP2Bus_WrAck   <= slv_reg_wr_ack or mem_wr_ack;
	IP2Bus_Error   <= '0';

	---------------------------------------------------------------------------
	-- IP to Bus data
	---------------------------------------------------------------------------
	IP2Bus_Data <= slv_ip2bus_data when (slv_reg_rd_ack = '1') else mem_rd_data when (mem_rd_ack = '1') else (others => '0');

	---------------------------------------------------------------------------
	-- Register read
	---------------------------------------------------------------------------
	slv_reg_rd_proc : process(Bus2IP_RdCE, slv_reg_rd) is
	begin
		slv_ip2bus_data <= (others => '0');
		for register_index in 0 to C_NUM_REG - 1 loop
			if (Bus2IP_RdCE(register_index) = '1') then
				slv_ip2bus_data <= slv_reg_rd(register_index);
			end if;
		end loop;
	end process slv_reg_rd_proc;

	slv_reg_rd_ack <= '1' when (Bus2IP_RdCE /= LOW_REG) else '0';

	---------------------------------------------------------------------------
	-- Register write
	---------------------------------------------------------------------------
	slv_reg_wr_proc : process(Bus2IP_Clk) is
	begin
		if rising_edge(Bus2IP_Clk) then
			slv_reg_wr_gen : for register_index in 0 to C_NUM_REG - 1 loop
				if Bus2IP_Reset = '1' then
					slv_reg_wr(register_index) <= (others => '0');
				else
					if (Bus2IP_WrCE(register_index) = '1') then
						--for byte_index in 0 to (C_SLV_DWIDTH / 8) - 1 loop
						if (Bus2IP_BE(0) = '1') then
							slv_reg_wr(register_index)(31 downto 24) <= Bus2IP_Data(0 to 7);
						end if;
						if (Bus2IP_BE(1) = '1') then
							slv_reg_wr(register_index)(23 downto 16) <= Bus2IP_Data(8 to 15);
						end if;
						if (Bus2IP_BE(2) = '1') then
							slv_reg_wr(register_index)(15 downto 8) <= Bus2IP_Data(16 to 23);
						end if;
						if (Bus2IP_BE(3) = '1') then
							slv_reg_wr(register_index)(7 downto 0) <= Bus2IP_Data(24 to 31);
						end if;
					--end loop;
					end if;
				end if;
			end loop;
		end if;
	end process slv_reg_wr_proc;

	slv_reg_wr_ack <= '1' when (Bus2IP_WrCE /= LOW_REG) else '0';

	---------------------------------------------------------------------------
	-- Memory Read
	---------------------------------------------------------------------------
	mem_rd_req_proc : process(Bus2IP_Clk) is
	begin
		if rising_edge(Bus2IP_Clk) then
			if (Bus2IP_Reset = '1') then
				mem_rd_req <= (others => '0');
			else
				if (Bus2IP_CS(0) = '1') then
					mem_rd_req <= mem_rd_req(3 downto 0) & Bus2IP_RdReq;
				else
					mem_rd_req <= (others => '0');
				end if;
			end if;
		end if;
	end process mem_rd_req_proc;

	mem_rd_addr_ack <= '1' when ((Bus2IP_CS(0) = '1') and (Bus2IP_RdReq = '1')) else '0';
	mem_rd_ack      <= '1' when (mem_rd_req(4) = '1') else '0';

	---------------------------------------------------------------------------
	-- Memory write
	---------------------------------------------------------------------------
	mem_wr_ack <= '1' when ((Bus2IP_CS(0) = '1') and (Bus2IP_WrReq = '1')) else '0';

	---------------------------------------------------------------------------
	-- Memory Interface
	---------------------------------------------------------------------------

	mem_address <= Bus2IP_Addr;
	--KW84 added modification / ML84 moved modification to ibfb_packet_player
	--mem_address( 1 downto  0)                    <= Bus2IP_Addr(30 to 31);  -- byte addressing stays the same
	--mem_address( 3 downto  2)                    <= Bus2IP_Addr(16 to 17);  -- memory subarray
	--mem_address(15 downto  4)                    <= Bus2IP_Addr(18 to 29);  -- memory subarray element 
	--mem_address(19 downto 16)                    <= Bus2IP_Addr(12 to 15);  -- memory select
	--mem_address(31 downto 20)                    <= Bus2IP_Addr( 0 to 11);  -- not used

	mem_rd_data <= player_ram_rdata(to_integer(mem_select));
	mem_wr_data <= Bus2IP_Data(0 to 31);

	--NAMING convention for QSFP (ignoring QSFP schematic naming)
	--Connectors named left to right q0,q1,q2,q3 
	--TILE0, GTX0 => q3
	--TILE0, GTX1 => q1
	--TILE1, GTX0 => q2
	--TILE1, GTX1 => q0
	--
	--TILE0 = QSFP13
	--TILE1 = QSFP02

	---------------------------------------------------------------------------
	-- CHIPSCOPE connections
	---------------------------------------------------------------------------

	--player.cpj
	CSP0_GEN : if CSP_SET = 0 generate
		O_CSP_CLK(0) <= i_user_clk;     --Bus2IP_Clk;

		--Register for speed
		O_CSP_REG_P0 : process(i_user_clk)
		begin
			if rising_edge(i_user_clk) then

                if r_ibfb_timing.sl_global_pulse_trg = '1' then
                    debug_timer <= (others => '0');
                else
                    debug_timer <= debug_timer+1;
                end if; 

				O_CSP_DATA0(015 downto 000) <= fb_kx(0);
				O_CSP_DATA0(031 downto 016) <= fb_kx(1);
				O_CSP_DATA0(047 downto 032) <= fb_ky(0);
				O_CSP_DATA0(063 downto 048) <= fb_ky(1);
				O_CSP_DATA0(079 downto 064) <= std_logic_vector(fb_pkt_cnt);
				O_CSP_DATA0(095 downto 080) <= std_logic_vector(fb_err_cnt);
				O_CSP_DATA0(096)            <= fb_data_avail;
				O_CSP_DATA0(097)            <= fb_data_good;
				O_CSP_DATA0(098)            <= fb_rx_error;
				O_CSP_DATA0(099)            <= fb_rxf_next;
				O_CSP_DATA0(115 downto 100) <= fb_bkt_id;
				O_CSP_DATA0(119 downto 116) <= fb_use0;
				--O_CSP_DATA0(125 downto 116) <= player_start;
			    O_CSP_DATA0(           126) <= player_ovalid(0);      
			    O_CSP_DATA0(           127) <= corr_ovalid(0);      
			    O_CSP_DATA0(159 downto 128) <= player_odata(0).xpos; 
			    O_CSP_DATA0(191 downto 160) <= player_odata(0).ypos;
			    O_CSP_DATA0(223 downto 192) <= corr_odata(0).xpos;
			    O_CSP_DATA0(255 downto 224) <= corr_odata(0).ypos;
                O_CSP_DATA0(287 downto 256) <= tr_kx0_0(0); 
			    O_CSP_DATA0(319 downto 288) <= tr_kx1_0(0); 
			    O_CSP_DATA0(351 downto 320) <= tr_ky0_0(0); 
			    O_CSP_DATA0(383 downto 352) <= tr_ky1_0(0); 

		        O_CSP_CLK(1) <= i_user_clk;     --Bus2IP_Clk;
                O_CSP_DATA1(287 downto 000) <= q0_corr_debug(287 downto 0);
                O_CSP_DATA1(319 downto 288) <= std_logic_vector(debug_timer);
			end if;
		end process;

	end generate;                       --CSP0_GEN


	---------------------------------------------------------------------------
	-- REGISTER MAP
	---------------------------------------------------------------------------

	REGMAP_P : process(Bus2IP_Clk)
	begin
		if rising_edge(Bus2IP_Clk) then
			---------------------------------------------------------------------------
			-- COMMANDS ---------------------------------------------------------------
			---------------------------------------------------------------------------
			--
			qsfp_fifo_rst_c                  <= slv_reg_wr(0)(03 downto 00);
			p0_fifo_rst_c                    <= slv_reg_wr(0)(05 downto 04);
			bpm_fifo_rst_c                   <= slv_reg_wr(0)(09 downto 06);
			mon_pkt_rx_rst_c                 <= slv_reg_wr(0)(10);
			los_cnt_rst                      <= slv_reg_wr(0)(21 downto 12);
			int_trig_en                      <= slv_reg_wr(0)(24);
			--free              <= slv_reg_wr(0)(31 downto 25);
			--
			qsfp_loopback(0)                 <= slv_reg_wr(1)(02 downto 00);
			qsfp_loopback(1)                 <= slv_reg_wr(1)(06 downto 04);
			qsfp_loopback(2)                 <= slv_reg_wr(1)(10 downto 08);
			qsfp_loopback(3)                 <= slv_reg_wr(1)(14 downto 12);
			bpm_loopback(0)                  <= slv_reg_wr(1)(18 downto 16);
			bpm_loopback(1)                  <= slv_reg_wr(1)(22 downto 20);
			bpm_loopback(2)                  <= slv_reg_wr(1)(26 downto 24);
			bpm_loopback(3)                  <= slv_reg_wr(1)(30 downto 28);
			--
			p0_loopback(0)                   <= slv_reg_wr(2)(02 downto 00);
			p0_loopback(1)                   <= slv_reg_wr(2)(06 downto 04);
			--free              <= slv_reg_wr(2)(31 downto 08);
			--
			--READ_ONLY         <= slv_reg_wr(3 to 4);
			--
			player_start_c                   <= slv_reg_wr(5)(9 downto 0);
			--
			--READ_ONLY         <= slv_reg_wr(6 to 20);
			--
			--TIMING COMPONENT (ML84 20.6.16)
			r_timing_param_wr.global_trg_ena <= slv_reg_wr(21)(0); --21
			r_timing_param_wr.trg_mode       <= slv_reg_wr(21)(8); --21
			r_timing_param_wr.trg_source     <= slv_reg_wr(21)(18 downto 16); --21
			--r_cpu_ibfb_wr.kick2_delay        <= slv_reg_wr(21)(28 downto 24); --21
			r_timing_param_wr.b_delay        <= slv_reg_wr(22)(27 downto 0); --22
			r_timing_param_wr.b_number       <= slv_reg_wr(23)(15 downto 0); --23
			r_timing_param_wr.b_space        <= slv_reg_wr(23)(31 downto 16); --23
			r_timing_param_wr.trg_rate       <= slv_reg_wr(24)(2 downto 0); --24
			r_timing_param_wr.trg_once       <= Bus2IP_WrCE(25); --25
			--
			--READ_ONLY 27 to 30
			--
			--WRITE ONLY:
			bpm_ids(0)                       <= slv_reg_wr(30)(31 downto 24);
			bpm_ids(1)                       <= slv_reg_wr(30)(23 downto 16);
			bpm_ids(2)                       <= slv_reg_wr(30)(15 downto 8);
			bpm_ids(3)                       <= slv_reg_wr(30)(7 downto 0);

			tr_kx0_0(0) <= slv_reg_wr(32);
			tr_kx0_0(1) <= slv_reg_wr(33);
			tr_kx0_0(2) <= slv_reg_wr(34);
			tr_kx0_0(3) <= slv_reg_wr(35);
			tr_kx1_0(0) <= slv_reg_wr(36);
			tr_kx1_0(1) <= slv_reg_wr(37);
			tr_kx1_0(2) <= slv_reg_wr(38);
			tr_kx1_0(3) <= slv_reg_wr(39);
			tr_ky0_0(0) <= slv_reg_wr(40);
			tr_ky0_0(1) <= slv_reg_wr(41);
			tr_ky0_0(2) <= slv_reg_wr(42);
			tr_ky0_0(3) <= slv_reg_wr(43);
			tr_ky1_0(0) <= slv_reg_wr(44);
			tr_ky1_0(1) <= slv_reg_wr(45);
			tr_ky1_0(2) <= slv_reg_wr(46);
			tr_ky1_0(3) <= slv_reg_wr(47);

			tr_kx0_1(0) <= slv_reg_wr(48);
			tr_kx0_1(1) <= slv_reg_wr(49);
			tr_kx0_1(2) <= slv_reg_wr(50);
			tr_kx0_1(3) <= slv_reg_wr(51);
			tr_kx1_1(0) <= slv_reg_wr(52);
			tr_kx1_1(1) <= slv_reg_wr(53);
			tr_kx1_1(2) <= slv_reg_wr(54);
			tr_kx1_1(3) <= slv_reg_wr(55);
			tr_ky0_1(0) <= slv_reg_wr(56);
			tr_ky0_1(1) <= slv_reg_wr(57);
			tr_ky0_1(2) <= slv_reg_wr(58);
			tr_ky0_1(3) <= slv_reg_wr(59);
			tr_ky1_1(0) <= slv_reg_wr(60);
			tr_ky1_1(1) <= slv_reg_wr(61);
			tr_ky1_1(2) <= slv_reg_wr(62);
			tr_ky1_1(3) <= slv_reg_wr(63);

			tr_kx0_2(0) <= slv_reg_wr(64);
			tr_kx0_2(1) <= slv_reg_wr(65);
			tr_kx0_2(2) <= slv_reg_wr(66);
			tr_kx0_2(3) <= slv_reg_wr(67);
			tr_kx1_2(0) <= slv_reg_wr(68);
			tr_kx1_2(1) <= slv_reg_wr(69);
			tr_kx1_2(2) <= slv_reg_wr(70);
			tr_kx1_2(3) <= slv_reg_wr(71);
			tr_ky0_2(0) <= slv_reg_wr(72);
			tr_ky0_2(1) <= slv_reg_wr(73);
			tr_ky0_2(2) <= slv_reg_wr(74);
			tr_ky0_2(3) <= slv_reg_wr(75);
			tr_ky1_2(0) <= slv_reg_wr(76);
			tr_ky1_2(1) <= slv_reg_wr(77);
			tr_ky1_2(2) <= slv_reg_wr(78);
			tr_ky1_2(3) <= slv_reg_wr(79);

			tr_kx0_3(0) <= slv_reg_wr(80);
			tr_kx0_3(1) <= slv_reg_wr(81);
			tr_kx0_3(2) <= slv_reg_wr(82);
			tr_kx0_3(3) <= slv_reg_wr(83);
			tr_kx1_3(0) <= slv_reg_wr(84);
			tr_kx1_3(1) <= slv_reg_wr(85);
			tr_kx1_3(2) <= slv_reg_wr(86);
			tr_kx1_3(3) <= slv_reg_wr(87);
			tr_ky0_3(0) <= slv_reg_wr(88);
			tr_ky0_3(1) <= slv_reg_wr(89);
			tr_ky0_3(2) <= slv_reg_wr(90);
			tr_ky0_3(3) <= slv_reg_wr(91);
			tr_ky1_3(0) <= slv_reg_wr(92);
			tr_ky1_3(1) <= slv_reg_wr(93);
			tr_ky1_3(2) <= slv_reg_wr(94);
			tr_ky1_3(3) <= slv_reg_wr(95);

			tr_kx0_4(0) <= slv_reg_wr(96);
			tr_kx0_4(1) <= slv_reg_wr(97);
			tr_kx0_4(2) <= slv_reg_wr(98);
			tr_kx0_4(3) <= slv_reg_wr(99);
			tr_kx1_4(0) <= slv_reg_wr(100);
			tr_kx1_4(1) <= slv_reg_wr(101);
			tr_kx1_4(2) <= slv_reg_wr(102);
			tr_kx1_4(3) <= slv_reg_wr(103);
			tr_ky0_4(0) <= slv_reg_wr(104);
			tr_ky0_4(1) <= slv_reg_wr(105);
			tr_ky0_4(2) <= slv_reg_wr(106);
			tr_ky0_4(3) <= slv_reg_wr(107);
			tr_ky1_4(0) <= slv_reg_wr(108);
			tr_ky1_4(1) <= slv_reg_wr(109);
			tr_ky1_4(2) <= slv_reg_wr(110);
			tr_ky1_4(3) <= slv_reg_wr(111);

			tr_kx0_5(0) <= slv_reg_wr(112);
			tr_kx0_5(1) <= slv_reg_wr(113);
			tr_kx0_5(2) <= slv_reg_wr(114);
			tr_kx0_5(3) <= slv_reg_wr(115);
			tr_kx1_5(0) <= slv_reg_wr(116);
			tr_kx1_5(1) <= slv_reg_wr(117);
			tr_kx1_5(2) <= slv_reg_wr(118);
			tr_kx1_5(3) <= slv_reg_wr(119);
			tr_ky0_5(0) <= slv_reg_wr(120);
			tr_ky0_5(1) <= slv_reg_wr(121);
			tr_ky0_5(2) <= slv_reg_wr(122);
			tr_ky0_5(3) <= slv_reg_wr(123);
			tr_ky1_5(0) <= slv_reg_wr(124);
			tr_ky1_5(1) <= slv_reg_wr(125);
			tr_ky1_5(2) <= slv_reg_wr(126);
			tr_ky1_5(3) <= slv_reg_wr(127);

			---------------------------------------------------------------------------
			-- STATUS
			---------------------------------------------------------------------------
			slv_reg_rd(0)                                  <= slv_reg_wr(0);
			slv_reg_rd(1)                                  <= slv_reg_wr(1);
			slv_reg_rd(2)                                  <= K_SOP & K_EOP & slv_reg_wr(2)(15 downto 0);
			--
			slv_reg_rd(3)(0)                               <= qsfp13_mgt_o.ctrl.PLLLKDET;
			slv_reg_rd(3)(1)                               <= qsfp13_mgt_o.ctrl.RESETDONE0;
			slv_reg_rd(3)(2)                               <= qsfp13_mgt_o.ctrl.RESETDONE1;
			slv_reg_rd(3)(3)                               <= '0';
			slv_reg_rd(3)(5 downto 4)                      <= qsfp13_mgt_o.rx(0).RXLOSSOFSYNC;
			slv_reg_rd(3)(7 downto 6)                      <= qsfp13_mgt_o.rx(1).RXLOSSOFSYNC;
			--
			slv_reg_rd(3)(8)                               <= qsfp02_mgt_o.ctrl.PLLLKDET;
			slv_reg_rd(3)(9)                               <= qsfp02_mgt_o.ctrl.RESETDONE0;
			slv_reg_rd(3)(10)                              <= qsfp02_mgt_o.ctrl.RESETDONE1;
			slv_reg_rd(3)(11)                              <= '0';
			slv_reg_rd(3)(13 downto 12)                    <= qsfp02_mgt_o.rx(0).RXLOSSOFSYNC;
			slv_reg_rd(3)(15 downto 14)                    <= qsfp02_mgt_o.rx(1).RXLOSSOFSYNC;
			--
			slv_reg_rd(3)(16)                              <= bpm01_mgt_o.ctrl.PLLLKDET;
			slv_reg_rd(3)(17)                              <= bpm01_mgt_o.ctrl.RESETDONE0;
			slv_reg_rd(3)(18)                              <= bpm01_mgt_o.ctrl.RESETDONE1;
			slv_reg_rd(3)(19)                              <= '0';
			slv_reg_rd(3)(21 downto 20)                    <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC;
			slv_reg_rd(3)(23 downto 22)                    <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC;
			--
			slv_reg_rd(3)(24)                              <= bpm23_mgt_o.ctrl.PLLLKDET;
			slv_reg_rd(3)(25)                              <= bpm23_mgt_o.ctrl.RESETDONE0;
			slv_reg_rd(3)(26)                              <= bpm23_mgt_o.ctrl.RESETDONE1;
			slv_reg_rd(3)(27)                              <= '0';
			slv_reg_rd(3)(29 downto 28)                    <= bpm23_mgt_o.rx(0).RXLOSSOFSYNC;
			slv_reg_rd(3)(31 downto 30)                    <= bpm23_mgt_o.rx(1).RXLOSSOFSYNC;
			--
			slv_reg_rd(4)(0)                               <= p0_mgt_o.ctrl.PLLLKDET;
			slv_reg_rd(4)(1)                               <= p0_mgt_o.ctrl.RESETDONE0;
			slv_reg_rd(4)(2)                               <= p0_mgt_o.ctrl.RESETDONE1;
			slv_reg_rd(4)(3)                               <= '0';
			slv_reg_rd(4)(5 downto 4)                      <= p0_mgt_o.rx(0).RXLOSSOFSYNC;
			slv_reg_rd(4)(7 downto 6)                      <= p0_mgt_o.rx(1).RXLOSSOFSYNC;
			slv_reg_rd(4)(17 downto 8)                     <= PLAYER_EN;
			slv_reg_rd(4)(20)                              <= USE_EXTERNAL_CLOCK;
			slv_reg_rd(4)(31 downto 24)                    <= std_logic_vector(to_unsigned(PLAYER_RAM_ADDR_W, 8));
			--
			slv_reg_rd(5)(31 downto 24)                    <= PLAYER_CTRL_EOS;
			slv_reg_rd(5)(19 downto 10)                    <= bpm_rx_sync & p0_rx_sync & qsfp_rx_sync;
			slv_reg_rd(5)(9 downto 0)                      <= slv_reg_wr(5)(9 downto 0); --player start
			--6 to 15
			--PLB_NPKT_GEN : for i in 0 to 9 generate
			--    slv_reg_rd(i+6)(PLAYER_RAM_ADDR_W-1 downto 0) <= player_n_sent_pkt(i);
			--    slv_reg_rd(i+6)(31 downto PLAYER_RAM_ADDR_W)  <= (others => '0');
			--end generate;
			slv_reg_rd(06)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(0);
			slv_reg_rd(06)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(07)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(1);
			slv_reg_rd(07)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(08)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(2);
			slv_reg_rd(08)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(09)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(3);
			slv_reg_rd(09)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(10)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(4);
			slv_reg_rd(10)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(11)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(5);
			slv_reg_rd(11)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(12)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(6);
			slv_reg_rd(12)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(13)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(7);
			slv_reg_rd(13)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(14)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(8);
			slv_reg_rd(14)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');
			slv_reg_rd(15)(PLAYER_RAM_ADDR_W - 1 downto 0) <= player_n_sent_pkt(9);
			slv_reg_rd(15)(31 downto PLAYER_RAM_ADDR_W)    <= (others => '0');

			slv_reg_rd(16)    <= std_logic_vector(los_cnt(1)) & std_logic_vector(los_cnt(0));
			slv_reg_rd(17)    <= std_logic_vector(los_cnt(3)) & std_logic_vector(los_cnt(2));
			slv_reg_rd(18)    <= std_logic_vector(los_cnt(5)) & std_logic_vector(los_cnt(4));
			slv_reg_rd(19)    <= std_logic_vector(los_cnt(7)) & std_logic_vector(los_cnt(6));
			slv_reg_rd(20)    <= std_logic_vector(los_cnt(9)) & std_logic_vector(los_cnt(8));
			--slv_reg_rd(21)               <= slv_reg_wr(21); --timing
			--slv_reg_rd(22)               <= slv_reg_wr(22); --timing
			--slv_reg_rd(23)               <= slv_reg_wr(23); --timing
			--slv_reg_rd(24)               <= slv_reg_wr(24); --timing
			--slv_reg_rd(25)               <= slv_reg_wr(25); --timing
			--
			--TIMING COMPONENT (ML84 20.6.16)
			slv_reg_rd(26)(0) <= r_timing_param_rd.ext_trg_missing; --26
			slv_reg_rd(26)(8) <= r_timing_param_rd.read_ready; --26
			--
			slv_reg_rd(27)    <= fb_data_r0 & fb_data_r1;
			slv_reg_rd(28)    <= fb_data_r2 & fb_data_r3;
			slv_reg_rd(29)    <= std_logic_vector(fb_pkt_cnt) & std_logic_vector(fb_err_cnt);
			slv_reg_rd(30)    <= slv_reg_wr(30); --bpm_ids
			--
			slv_reg_rd(31)    <= FW_VERSION;

		end if;
	end process;                        --REGMAP_P

	---------------------------------------------------------------------------
	-- trigger delay
	---------------------------------------------------------------------------

	--ML84 20.6.16 (added timing component)
	ibfb_timing_inst : ibfb_timing
		port map(
			i_dac_clk     => i_user_clk,
			-- Sampling interface
			i_cpu_clk     => Bus2IP_Clk,
			i_cpu_fsm_wr  => r_timing_param_wr,
			o_cpu_fsm_rd  => r_timing_param_rd,
			-- BPM interface
			i_ext_trg     => i_player_start,
			o_ibfb_timing => r_ibfb_timing,
			o_led_pulse   => o_led_pulse,
			-- debug
			o_csp_clk     => open,      --o_csp_clk         
			o_csp_data    => open       --o_csp_data
		);

	player_start_d <= r_ibfb_timing.sl_global_pulse_trg; 


	---------------------------------------------------------------------------
	-- Loss of sync counters
	---------------------------------------------------------------------------

	rxrecclk(0) <= qsfp02_mgt_o.rx(1).RXRECCLK; --qsfp0
	rxrecclk(1) <= qsfp13_mgt_o.rx(1).RXRECCLK; --qsfp1
	rxrecclk(2) <= qsfp02_mgt_o.rx(0).RXRECCLK; --qsfp2
	rxrecclk(3) <= qsfp13_mgt_o.rx(0).RXRECCLK; --qsfp3
	rxrecclk(4) <= p0_mgt_o.rx(0).RXRECCLK;
	rxrecclk(5) <= p0_mgt_o.rx(1).RXRECCLK;
	rxrecclk(6) <= bpm01_mgt_o.rx(0).RXRECCLK;
	rxrecclk(7) <= bpm01_mgt_o.rx(1).RXRECCLK;
	rxrecclk(8) <= bpm23_mgt_o.rx(0).RXRECCLK;
	rxrecclk(9) <= bpm23_mgt_o.rx(1).RXRECCLK;

	los_c(0) <= qsfp02_mgt_o.rx(1).RXLOSSOFSYNC(1); --qsfp0
	los_c(1) <= qsfp13_mgt_o.rx(1).RXLOSSOFSYNC(1); --qsfp1
	los_c(2) <= qsfp02_mgt_o.rx(0).RXLOSSOFSYNC(1); --qsfp2
	los_c(3) <= qsfp13_mgt_o.rx(0).RXLOSSOFSYNC(1); --qsfp3
	los_c(4) <= p0_mgt_o.rx(0).RXLOSSOFSYNC(1);
	los_c(5) <= p0_mgt_o.rx(1).RXLOSSOFSYNC(1);
	los_c(6) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC(1);
	los_c(7) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC(1);
	los_c(8) <= bpm23_mgt_o.rx(0).RXLOSSOFSYNC(1);
	los_c(9) <= bpm23_mgt_o.rx(1).RXLOSSOFSYNC(1);

	--Increment counters on rising edge of LOSSOFSYNC(1)
	LOS_CNT_GEN : for i in 0 to 9 generate
		LOS_CNT_P : process(rxrecclk(i))
		begin
			if rising_edge(rxrecclk(i)) then
				los(i)   <= los_c(i);
				los_r(i) <= los(i);

				if Bus2IP_Reset = '1' or los_cnt_rst(i) = '1' then
					los_cnt(i) <= (others => '0');
				else
					if los(i) = '1' and los_r(i) = '0' then
						los_cnt(i) <= los_cnt(i) + 1;
					end if;
				end if;
			end if;
		end process;
	end generate;

	---------------------------------------------------------------------------
	-- GTX components & Players
	---------------------------------------------------------------------------

	qsfp_fifo_rst(0) <= Bus2IP_Reset or qsfp_fifo_rst_c(0);
	qsfp_fifo_rst(1) <= Bus2IP_Reset or qsfp_fifo_rst_c(1);
	qsfp_fifo_rst(2) <= Bus2IP_Reset or qsfp_fifo_rst_c(2);
	qsfp_fifo_rst(3) <= Bus2IP_Reset or qsfp_fifo_rst_c(3);
	p0_fifo_rst(0)   <= Bus2IP_Reset or p0_fifo_rst_c(0);
	p0_fifo_rst(1)   <= Bus2IP_Reset or p0_fifo_rst_c(1);
	bpm_fifo_rst(0)  <= Bus2IP_Reset or bpm_fifo_rst_c(0);
	bpm_fifo_rst(1)  <= Bus2IP_Reset or bpm_fifo_rst_c(1);
	bpm_fifo_rst(2)  <= Bus2IP_Reset or bpm_fifo_rst_c(2);
	bpm_fifo_rst(3)  <= Bus2IP_Reset or bpm_fifo_rst_c(3);
	-------------------------------------------------------

	QSFP13_TILE : gtx_tile
		generic map(
			--mgt
			G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(0),
			G_GTX_TILE_REFCLK_FREQ => C_SFP13_REFCLK_FREQ,
			G_GTX_BAUD_RATE        => C_SFP13_BAUD_RATE
		)
		port map(
			------------------------------------------------------------------------
			-- GTX INTERFACE
			------------------------------------------------------------------------
			I_GTX_REFCLK1_IN  => I_GTX_REFCLK1_IN,
			I_GTX_REFCLK2_IN  => I_GTX_REFCLK2_IN,
			I_GTX_RX_N        => I_GTX_RX_N(1 downto 0),
			I_GTX_RX_P        => I_GTX_RX_P(1 downto 0),
			O_GTX_TX_N        => O_GTX_TX_N(1 downto 0),
			O_GTX_TX_P        => O_GTX_TX_P(1 downto 0),
			------------------------------------------------------------------------
			-- GTX SETTINGS & STATUS
			------------------------------------------------------------------------
			i_loopback0       => qsfp_loopback(3),
			i_loopback1       => qsfp_loopback(1),
			o_mgt             => qsfp13_mgt_o,
			------------------------------------------------------------------------
			-- FIFO interface
			------------------------------------------------------------------------
			i_clk             => i_user_clk, --Bus2IP_Clk,
			--Channel 3
			i_fifo_reset0     => qsfp_fifo_rst(3),
			--TX
			o_tx_vld0         => qsfp_tx_vld(3), --debug
			o_txfifo_full0    => qsfp_txf_full(3),
			i_txfifo_write0   => qsfp_txf_write(3),
			i_txfifo_charisk0 => qsfp_txf_charisk(3),
			i_txfifo_data0    => qsfp_txf_data(3),
			--RX
			o_rx_sync_done0   => qsfp_rx_sync(3),
			o_rx_vld0         => qsfp_rx_vld(3),
			i_rxfifo_next0    => qsfp_rxf_next(3),
			o_rxfifo_empty0   => qsfp_rxf_empty(3),
			o_rxfifo_charisk0 => qsfp_rxf_charisk(3),
			o_rxfifo_data0    => qsfp_rxf_data(3),
			--Channel 1
			i_fifo_reset1     => qsfp_fifo_rst(1),
			--TX
			o_tx_vld1         => qsfp_tx_vld(1),
			o_txfifo_full1    => qsfp_txf_full(1),
			i_txfifo_write1   => qsfp_txf_write(1),
			i_txfifo_charisk1 => qsfp_txf_charisk(1),
			i_txfifo_data1    => qsfp_txf_data(1),
			--RX
			o_rx_sync_done1   => qsfp_rx_sync(1),
			o_rx_vld1         => qsfp_rx_vld(1),
			i_rxfifo_next1    => qsfp_rxf_next(1),
			o_rxfifo_empty1   => qsfp_rxf_empty(1),
			o_rxfifo_charisk1 => qsfp_rxf_charisk(1),
			o_rxfifo_data1    => qsfp_rxf_data(1)
		);

	QSFP02_TILE : gtx_tile
		generic map(
			G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(1),
			G_GTX_TILE_REFCLK_FREQ => C_SFP02_REFCLK_FREQ,
			G_GTX_BAUD_RATE        => C_SFP02_BAUD_RATE
		)
		port map(
			------------------------------------------------------------------------
			-- GTX INTERFACE
			------------------------------------------------------------------------
			I_GTX_REFCLK1_IN  => I_GTX_REFCLK1_IN,
			I_GTX_REFCLK2_IN  => I_GTX_REFCLK2_IN,
			O_GTX_REFCLK_OUT  => open,
			I_GTX_RX_N        => I_GTX_RX_N(3 downto 2),
			I_GTX_RX_P        => I_GTX_RX_P(3 downto 2),
			O_GTX_TX_N        => O_GTX_TX_N(3 downto 2),
			O_GTX_TX_P        => O_GTX_TX_P(3 downto 2),
			------------------------------------------------------------------------
			-- GTX SETTINGS & STATUS
			------------------------------------------------------------------------
			i_loopback0       => qsfp_loopback(2),
			i_loopback1       => qsfp_loopback(0),
			o_mgt             => qsfp02_mgt_o,
			------------------------------------------------------------------------
			-- FIFO interface
			------------------------------------------------------------------------
			i_clk             => i_user_clk, --Bus2IP_Clk,
			--Channel 2
			i_fifo_reset0     => qsfp_fifo_rst(2),
			--TX
			o_tx_vld0         => qsfp_tx_vld(2), --debug
			o_txfifo_full0    => qsfp_txf_full(2),
			i_txfifo_write0   => qsfp_txf_write(2),
			i_txfifo_charisk0 => qsfp_txf_charisk(2),
			i_txfifo_data0    => qsfp_txf_data(2),
			--RX
			o_rx_sync_done0   => qsfp_rx_sync(2),
			o_rx_vld0         => qsfp_rx_vld(2),
			i_rxfifo_next0    => qsfp_rxf_next(2),
			o_rxfifo_empty0   => qsfp_rxf_empty(2),
			o_rxfifo_charisk0 => qsfp_rxf_charisk(2),
			o_rxfifo_data0    => qsfp_rxf_data(2),
			--Channel 0
			i_fifo_reset1     => qsfp_fifo_rst(0),
			--TX
			o_tx_vld1         => qsfp_tx_vld(0),
			o_txfifo_full1    => qsfp_txf_full(0),
			i_txfifo_write1   => qsfp_txf_write(0),
			i_txfifo_charisk1 => qsfp_txf_charisk(0),
			i_txfifo_data1    => qsfp_txf_data(0),
			--RX
			o_rx_sync_done1   => qsfp_rx_sync(0),
			o_rx_vld1         => qsfp_rx_vld(0),
			i_rxfifo_next1    => qsfp_rxf_next(0),
			o_rxfifo_empty1   => qsfp_rxf_empty(0),
			o_rxfifo_charisk1 => qsfp_rxf_charisk(0),
			o_rxfifo_data1    => qsfp_rxf_data(0)
		);

	P0_TILE : gtx_tile
		generic map(
			--mgt
			G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(2),
			G_GTX_TILE_REFCLK_FREQ => C_P0_REFCLK_FREQ,
			G_GTX_BAUD_RATE        => C_P0_BAUD_RATE
		)
		port map(
			--MGT
			I_GTX_REFCLK1_IN  => I_GTX_REFCLK1_IN,
			I_GTX_REFCLK2_IN  => I_GTX_REFCLK2_IN,
			I_GTX_RX_N        => I_GTX_RX_N(5 downto 4),
			I_GTX_RX_P        => I_GTX_RX_P(5 downto 4),
			O_GTX_TX_N        => O_GTX_TX_N(5 downto 4),
			O_GTX_TX_P        => O_GTX_TX_P(5 downto 4),
			--
			i_loopback0       => p0_loopback(0),
			i_loopback1       => p0_loopback(1),
			o_mgt             => p0_mgt_o,
			------------------------------------------------------------------------
			-- FIFO interface
			------------------------------------------------------------------------
			i_clk             => i_user_clk, --Bus2IP_Clk,
			--Channel 0
			i_fifo_reset0     => p0_fifo_rst(0),
			--TX
			o_tx_vld0         => p0_tx_vld(0), --debug
			o_txfifo_full0    => p0_txf_full(0),
			i_txfifo_write0   => p0_txf_write(0),
			i_txfifo_charisk0 => p0_txf_charisk(0),
			i_txfifo_data0    => p0_txf_data(0),
			--RX
			o_rx_sync_done0   => p0_rx_sync(0),
			o_rx_vld0         => p0_rx_vld(0),
			i_rxfifo_next0    => p0_rxf_next(0),
			o_rxfifo_empty0   => p0_rxf_empty(0),
			o_rxfifo_charisk0 => p0_rxf_charisk(0),
			o_rxfifo_data0    => p0_rxf_data(0),
			--Channel 1
			i_fifo_reset1     => p0_fifo_rst(1),
			--TX
			o_tx_vld1         => p0_tx_vld(1), --debug
			o_txfifo_full1    => p0_txf_full(1),
			i_txfifo_write1   => p0_txf_write(1),
			i_txfifo_charisk1 => p0_txf_charisk(1),
			i_txfifo_data1    => p0_txf_data(1),
			--RX
			o_rx_sync_done1   => p0_rx_sync(1),
			o_rx_vld1         => p0_rx_vld(1),
			i_rxfifo_next1    => p0_rxf_next(1),
			o_rxfifo_empty1   => p0_rxf_empty(1),
			o_rxfifo_charisk1 => p0_rxf_charisk(1),
			o_rxfifo_data1    => p0_rxf_data(1)
		);

	BPM01_TILE : gtx_tile
		generic map(
			--mgt
			G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(3),
			G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
			G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
		)
		port map(
			--MGT
			I_GTX_REFCLK1_IN  => I_GTX_REFCLK1_IN,
			I_GTX_REFCLK2_IN  => I_GTX_REFCLK2_IN,
			I_GTX_RX_N        => I_GTX_RX_N(7 downto 6),
			I_GTX_RX_P        => I_GTX_RX_P(7 downto 6),
			O_GTX_TX_N        => O_GTX_TX_N(7 downto 6),
			O_GTX_TX_P        => O_GTX_TX_P(7 downto 6),
			--
			i_loopback0       => bpm_loopback(0),
			i_loopback1       => bpm_loopback(1),
			o_mgt             => bpm01_mgt_o,
			------------------------------------------------------------------------
			-- FIFO interface
			------------------------------------------------------------------------
			i_clk             => i_user_clk, --Bus2IP_Clk,
			--Channel 0
			i_fifo_reset0     => bpm_fifo_rst(0),
			--TX
			o_tx_vld0         => bpm_tx_vld(0), --debug
			o_txfifo_full0    => bpm_txf_full(0),
			i_txfifo_write0   => bpm_txf_write(0),
			i_txfifo_charisk0 => bpm_txf_charisk(0),
			i_txfifo_data0    => bpm_txf_data(0),
			--RX
			o_rx_sync_done0   => bpm_rx_sync(0),
			o_rx_vld0         => bpm_rx_vld(0),
			i_rxfifo_next0    => bpm_rxf_next(0),
			o_rxfifo_empty0   => bpm_rxf_empty(0),
			o_rxfifo_charisk0 => bpm_rxf_charisk(0),
			o_rxfifo_data0    => bpm_rxf_data(0),
			--Channel 1
			i_fifo_reset1     => bpm_fifo_rst(1),
			--TX
			o_tx_vld1         => bpm_tx_vld(1), --debug
			o_txfifo_full1    => bpm_txf_full(1),
			i_txfifo_write1   => bpm_txf_write(1),
			i_txfifo_charisk1 => bpm_txf_charisk(1),
			i_txfifo_data1    => bpm_txf_data(1),
			--RX
			o_rx_sync_done1   => bpm_rx_sync(1),
			o_rx_vld1         => bpm_rx_vld(1),
			i_rxfifo_next1    => bpm_rxf_next(1),
			o_rxfifo_empty1   => bpm_rxf_empty(1),
			o_rxfifo_charisk1 => bpm_rxf_charisk(1),
			o_rxfifo_data1    => bpm_rxf_data(1)
		);

	BPM23_TILE : gtx_tile
		generic map(
			--mgt
			G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(4),
			G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
			G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
		)
		port map(
			--MGT
			I_GTX_REFCLK1_IN  => I_GTX_REFCLK1_IN,
			I_GTX_REFCLK2_IN  => I_GTX_REFCLK2_IN,
			I_GTX_RX_N        => I_GTX_RX_N(9 downto 8),
			I_GTX_RX_P        => I_GTX_RX_P(9 downto 8),
			O_GTX_TX_N        => O_GTX_TX_N(9 downto 8),
			O_GTX_TX_P        => O_GTX_TX_P(9 downto 8),
			--
			i_loopback0       => bpm_loopback(0),
			i_loopback1       => bpm_loopback(1),
			o_mgt             => bpm23_mgt_o,
			------------------------------------------------------------------------
			-- FIFO interface
			------------------------------------------------------------------------
			i_clk             => i_user_clk, --Bus2IP_Clk,
			--Channel 0
			i_fifo_reset0     => bpm_fifo_rst(2),
			--TX
			o_tx_vld0         => bpm_tx_vld(2), --debug
			o_txfifo_full0    => bpm_txf_full(2),
			i_txfifo_write0   => bpm_txf_write(2),
			i_txfifo_charisk0 => bpm_txf_charisk(2),
			i_txfifo_data0    => bpm_txf_data(2),
			--RX 
			o_rx_sync_done0   => bpm_rx_sync(2),
			o_rx_vld0         => bpm_rx_vld(2),
			i_rxfifo_next0    => bpm_rxf_next(2),
			o_rxfifo_empty0   => bpm_rxf_empty(2),
			o_rxfifo_charisk0 => bpm_rxf_charisk(2),
			o_rxfifo_data0    => bpm_rxf_data(2),
			--Channel 1
			i_fifo_reset1     => bpm_fifo_rst(3),
			--TX
			o_tx_vld1         => bpm_tx_vld(3), --debug
			o_txfifo_full1    => bpm_txf_full(3),
			i_txfifo_write1   => bpm_txf_write(3),
			i_txfifo_charisk1 => bpm_txf_charisk(3),
			i_txfifo_data1    => bpm_txf_data(3),
			--RX
			o_rx_sync_done1   => bpm_rx_sync(3),
			o_rx_vld1         => bpm_rx_vld(3),
			i_rxfifo_next1    => bpm_rxf_next(3),
			o_rxfifo_empty1   => bpm_rxf_empty(3),
			o_rxfifo_charisk1 => bpm_rxf_charisk(3),
			o_rxfifo_data1    => bpm_rxf_data(3)
		);

	------------------------------------------------------------------------------
	-- Players
	------------------------------------------------------------------------------

	mem_select <= unsigned(mem_address(PLAYER_RAM_ADDR_W + 3 downto PLAYER_RAM_ADDR_W));

	mem_cs(0) <= '1' when mem_select = X"0" else '0';
	mem_cs(1) <= '1' when mem_select = X"1" else '0';
	mem_cs(2) <= '1' when mem_select = X"2" else '0';
	mem_cs(3) <= '1' when mem_select = X"3" else '0';
	mem_cs(4) <= '1' when mem_select = X"4" else '0';
	mem_cs(5) <= '1' when mem_select = X"5" else '0';
	mem_cs(6) <= '1' when mem_select = X"6" else '0';
	mem_cs(7) <= '1' when mem_select = X"7" else '0';
	mem_cs(8) <= '1' when mem_select = X"8" else '0';
	mem_cs(9) <= '1' when mem_select = X"9" else '0';

	-----------------------------------------------------------------------
	--QSFP0 Packet player
	-----------------------------------------------------------------------
	PLAYER_Q0_GEN : if PLAYER_EN(0) = '1' generate
		player_start(0) <= player_start_d when int_trig_en = '0' else player_start_c(0);

		--RAM write enable
		player_ram_w(0) <= mem_wr_ack and mem_cs(0);

		-------------------------------------------------------------------
		--The packet player
		-------------------------------------------------------------------
		PLAYER_Q0_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => qsfp_fifo_rst(0), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(0),
				--CTRL interface
				i_start    => player_start(0),
				o_busy     => player_busy(0),
				o_pkt_num  => player_n_sent_pkt(0),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(0),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(0),
				--TX Interface
				i_sop      => corr_sop(0), --pkt_tx_sop(0),
				i_busy     => '0',      --pkt_tx_busy(0), --not used
				o_tx_valid => player_ovalid(0),
				o_tx_data  => player_odata(0)
			);

        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(0) <= corr_rfd(0) and player_ovalid(0);

		-------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_Q0_i : ibfb_fb_apply_correction
			port map(
                o_dbg       => q0_corr_debug,
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_0,
				i_tr_kx1    => tr_kx1_0,
				i_tr_ky0    => tr_ky0_0,
				i_tr_ky1    => tr_ky1_0,
				--input data
				o_rfd       => corr_rfd(0),
				i_pkt_valid => player_ovalid(0),
				i_pkt_data  => player_odata(0),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => fb_use0,
				o_pkt_valid => corr_ovalid(0),
				o_pkt_data  => corr_odata(0)
			);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_Q0_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => qsfp_fifo_rst(0), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(0),
				o_busy      => pkt_tx_busy(0),
				i_tx_valid  => corr_ovalid(0), --player_ovalid(0),
				i_tx_data   => corr_odata(0), --player_odata(0),
				--MGT FIFO interface
				i_fifo_full => qsfp_txf_full(0),
				o_valid     => qsfp_txf_write(0),
				o_charisk   => qsfp_txf_charisk(0),
				o_data      => qsfp_txf_data(0)
			);
	end generate;                       --PLAYER_Q0_GEN
	PLAYER_Q0_GEN_N : if PLAYER_EN(0) = '0' generate
		player_ram_w(0)      <= '0';
		player_busy(0)       <= '0';
		player_n_sent_pkt(0) <= (others => '0');
		player_ram_rdata(0)  <= (others => '0');
		pkt_tx_sop(0)        <= '0';
		player_ovalid(0)     <= '0';
		pkt_tx_busy(0)       <= '0';
		qsfp_txf_write(0)    <= '0';    --needed
	end generate;                       --PLAYER_Q0_GEN_N

	-----------------------------------------------------------------------
	--QSFP1 Packet player
	-----------------------------------------------------------------------
	PLAYER_Q1_GEN : if PLAYER_EN(1) = '1' generate
		player_start(1) <= player_start_d when int_trig_en = '0' else player_start_c(1);

		--RAM write enable
		player_ram_w(1) <= mem_wr_ack and mem_cs(1);

		-------------------------------------------------------------------
		--The packet player
		-------------------------------------------------------------------
		PLAYER_Q1_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => qsfp_fifo_rst(1), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(1),
				--CTRL interface
				i_start    => player_start(1),
				o_busy     => player_busy(1),
				o_pkt_num  => player_n_sent_pkt(1),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(1),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(1),
				--TX Interface
				i_sop      => corr_sop(1), --pkt_tx_sop(1),
				i_busy     => '0', --pkt_tx_busy(1),
				o_tx_valid => player_ovalid(1),
				o_tx_data  => player_odata(1)
			);
        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(1) <= corr_rfd(1) and player_ovalid(1);

		-------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_Q1_i : ibfb_fb_apply_correction
			port map(
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_1,
				i_tr_kx1    => tr_kx1_1,
				i_tr_ky0    => tr_ky0_1,
				i_tr_ky1    => tr_ky1_1,
				--input data
				o_rfd       => corr_rfd(1),
				i_pkt_valid => player_ovalid(1),
				i_pkt_data  => player_odata(1),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => open,
				o_pkt_valid => corr_ovalid(1),
				o_pkt_data  => corr_odata(1)
			);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_Q1_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => qsfp_fifo_rst(1), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(1),
				o_busy      => pkt_tx_busy(1),
				i_tx_valid  => corr_ovalid(1), --player_ovalid(1),
				i_tx_data   => corr_odata(1), --player_odata(1),
				--MGT FIFO interface
				i_fifo_full => qsfp_txf_full(1),
				o_valid     => qsfp_txf_write(1),
				o_charisk   => qsfp_txf_charisk(1),
				o_data      => qsfp_txf_data(1)
			);
	end generate;                       --PLAYER_Q1_GEN
	PLAYER_Q1_GEN_N : if PLAYER_EN(1) = '0' generate
		player_ram_w(1)      <= '0';
		player_busy(1)       <= '0';
		player_n_sent_pkt(1) <= (others => '0');
		player_ram_rdata(1)  <= (others => '0');
		pkt_tx_sop(1)        <= '0';
		player_ovalid(1)     <= '0';
		pkt_tx_busy(1)       <= '0';
		qsfp_txf_write(1)    <= '0';    --needed
	end generate;                       --PLAYER_Q1_GEN_N

	-----------------------------------------------------------------------
	--QSFP2 Packet player
	-----------------------------------------------------------------------
	PLAYER_Q2_GEN : if PLAYER_EN(2) = '1' generate
		player_start(2) <= player_start_d when int_trig_en = '0' else player_start_c(2);

		--RAM write enable
		player_ram_w(2) <= mem_wr_ack and mem_cs(2);

		-------------------------------------------------------------------
		--The packet player
		-------------------------------------------------------------------
		PLAYER_Q2_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => qsfp_fifo_rst(2), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(2),
				--CTRL interface
				i_start    => player_start(2),
				o_busy     => player_busy(2),
				o_pkt_num  => player_n_sent_pkt(2),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(2),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(2),
				--TX Interface
				i_sop      => corr_sop(2), --pkt_tx_sop(2),
				i_busy     => '0', --pkt_tx_busy(2),
				o_tx_valid => player_ovalid(2),
				o_tx_data  => player_odata(2)
			);
        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(2) <= corr_rfd(2) and player_ovalid(2);

        -------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_Q2_i : ibfb_fb_apply_correction
			port map(
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_2,
				i_tr_kx1    => tr_kx1_2,
				i_tr_ky0    => tr_ky0_2,
				i_tr_ky1    => tr_ky1_2,
				--input data
				o_rfd       => corr_rfd(2),
				i_pkt_valid => player_ovalid(2),
				i_pkt_data  => player_odata(2),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => open,
				o_pkt_valid => corr_ovalid(2),
				o_pkt_data  => corr_odata(2)
		);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_Q2_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => qsfp_fifo_rst(2), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(2),
				o_busy      => pkt_tx_busy(2),
				i_tx_valid  => corr_ovalid(2),
				i_tx_data   => corr_odata(2),
				--MGT FIFO interface
				i_fifo_full => qsfp_txf_full(2),
				o_valid     => qsfp_txf_write(2),
				o_charisk   => qsfp_txf_charisk(2),
				o_data      => qsfp_txf_data(2)
			);
	end generate;                       --PLAYER_Q2_GEN
	PLAYER_Q2_GEN_N : if PLAYER_EN(2) = '0' generate
		player_ram_w(2)      <= '0';
		player_busy(2)       <= '0';
		player_n_sent_pkt(2) <= (others => '0');
		player_ram_rdata(2)  <= (others => '0');
		pkt_tx_sop(2)        <= '0';
		player_ovalid(2)     <= '0';
		pkt_tx_busy(2)       <= '0';
		qsfp_txf_write(2)    <= '0';    --needed
	end generate;                       --PLAYER_Q2_GEN_N

	--QSFP3 Packet player
	PLAYER_Q3_GEN : if PLAYER_EN(3) = '1' generate
		player_start(3) <= player_start_d when int_trig_en = '0' else player_start_c(3);

		--RAM write enable
		player_ram_w(3) <= mem_wr_ack and mem_cs(3);

		-------------------------------------------------------------------
		--The packet player
		-------------------------------------------------------------------
		PLAYER_Q3_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => qsfp_fifo_rst(3), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(3),
				--CTRL interface
				i_start    => player_start(3),
				o_busy     => player_busy(3),
				o_pkt_num  => player_n_sent_pkt(3),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(3),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(3),
				--TX Interface
				i_sop      => corr_sop(3), --pkt_tx_sop(3),
				i_busy     => '0', --pkt_tx_busy(3),
				o_tx_valid => player_ovalid(3),
				o_tx_data  => player_odata(3)
			);
        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(3) <= corr_rfd(3) and player_ovalid(3);

		-------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_Q0_i : ibfb_fb_apply_correction
			port map(
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_3,
				i_tr_kx1    => tr_kx1_3,
				i_tr_ky0    => tr_ky0_3,
				i_tr_ky1    => tr_ky1_3,
				--input data
				o_rfd       => corr_rfd(3),
				i_pkt_valid => player_ovalid(3),
				i_pkt_data  => player_odata(3),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => open,
				o_pkt_valid => corr_ovalid(3),
				o_pkt_data  => corr_odata(3)
			);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_Q3_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => qsfp_fifo_rst(3), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(3),
				o_busy      => pkt_tx_busy(3),
				i_tx_valid  => corr_ovalid(3),
				i_tx_data   => corr_odata(3),
				--MGT FIFO interface
				i_fifo_full => qsfp_txf_full(3),
				o_valid     => qsfp_txf_write(3),
				o_charisk   => qsfp_txf_charisk(3),
				o_data      => qsfp_txf_data(3)
			);
	end generate;                       --PLAYER_Q3_GEN
	PLAYER_Q3_GEN_N : if PLAYER_EN(3) = '0' generate
		player_ram_w(3)      <= '0';
		player_busy(3)       <= '0';
		player_n_sent_pkt(3) <= (others => '0');
		player_ram_rdata(3)  <= (others => '0');
		pkt_tx_sop(3)        <= '0';
		player_ovalid(3)     <= '0';
		pkt_tx_busy(3)       <= '0';
		qsfp_txf_write(3)    <= '0';    --needed
	end generate;                       --PLAYER_Q3_GEN_N

	--P0.0 Packet player
	PLAYER_P00_GEN : if PLAYER_EN(4) = '1' generate
		player_start(4) <= player_start_d when int_trig_en = '0' else player_start_c(4);

		--RAM write enable
		player_ram_w(4) <= mem_wr_ack and mem_cs(4);

		-------------------------------------------------------------------
		--The packet player
		-------------------------------------------------------------------
		PLAYER_P00_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => p0_fifo_rst(0), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(4),
				--CTRL interface
				i_start    => player_start(4),
				o_busy     => player_busy(4),
				o_pkt_num  => player_n_sent_pkt(4),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(4),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(4),
				--TX Interface
				i_sop      => corr_sop(4), --pkt_tx_sop(4),
				i_busy     => '0', --pkt_tx_busy(4),
				o_tx_valid => player_ovalid(4),
				o_tx_data  => player_odata(4)
			);
        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(4) <= corr_rfd(4) and player_ovalid(4);

        -------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_P00_i : ibfb_fb_apply_correction
			port map(
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_4,
				i_tr_kx1    => tr_kx1_4,
				i_tr_ky0    => tr_ky0_4,
				i_tr_ky1    => tr_ky1_4,
				--input data
				o_rfd       => corr_rfd(4),
				i_pkt_valid => player_ovalid(4),
				i_pkt_data  => player_odata(4),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => open,
				o_pkt_valid => corr_ovalid(4),
				o_pkt_data  => corr_odata(4)
			);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_P00_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => p0_fifo_rst(0), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(4),
				o_busy      => pkt_tx_busy(4),
				i_tx_valid  => corr_ovalid(4),
				i_tx_data   => corr_odata(4),
				--MGT FIFO interface
				i_fifo_full => p0_txf_full(0),
				o_valid     => p0_txf_write(0),
				o_charisk   => p0_txf_charisk(0),
				o_data      => p0_txf_data(0)
			);
	end generate;                       --PLAYER_P00_GEN
	PLAYER_P00_GEN_N : if PLAYER_EN(4) = '0' generate
		player_ram_w(4)      <= '0';
		player_busy(4)       <= '0';
		player_n_sent_pkt(4) <= (others => '0');
		player_ram_rdata(4)  <= (others => '0');
		pkt_tx_sop(4)        <= '0';
		player_ovalid(4)     <= '0';
		pkt_tx_busy(4)       <= '0';
		p0_txf_write(0)      <= '0';    --needed
	end generate;                       --PLAYER_P00_GEN_N

	--P0.1 Packet player
	PLAYER_P01_GEN : if PLAYER_EN(5) = '1' generate
		player_start(5) <= player_start_d when int_trig_en = '0' else player_start_c(5);

		--RAM write enable
		player_ram_w(5) <= mem_wr_ack and mem_cs(5);

        -------------------------------------------------------------------
		--The packet player
        -------------------------------------------------------------------
		PLAYER_P01_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => p0_fifo_rst(1), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(5),
				--CTRL interface
				i_start    => player_start(5),
				o_busy     => player_busy(5),
				o_pkt_num  => player_n_sent_pkt(5),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(5),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(5),
				--TX Interface
				i_sop      => corr_sop(5), --pkt_tx_sop(5),
				i_busy     => '0', --pkt_tx_busy(5),
				o_tx_valid => player_ovalid(5),
				o_tx_data  => player_odata(5)
			);
        --needed to avoid data acknowledge when player_ovalid is still '0'
        corr_sop(5) <= corr_rfd(5) and player_ovalid(5);

        -------------------------------------------------------------------
		-- The correction component
		-------------------------------------------------------------------
		FB_CORR_P01_i : ibfb_fb_apply_correction
			port map(
				i_clk       => i_user_clk,
				i_train_trg => r_ibfb_timing.sl_global_pulse_trg,
				--feedback input
				i_fb_v      => fb_data_valid, --high only when received data is good
				--i_fb_kx     => fb_kx,
				--i_fb_ky     => fb_ky,
				i_fb_kx0    => fb_kx(0),
				i_fb_kx1    => fb_kx(1),
				i_fb_ky0    => fb_ky(0),
				i_fb_ky1    => fb_ky(1),
				--Transformation matrixes
				i_bpm_ids   => bpm_ids,
				i_tr_kx0    => tr_kx0_5,
				i_tr_kx1    => tr_kx1_5,
				i_tr_ky0    => tr_ky0_5,
				i_tr_ky1    => tr_ky1_5,
				--input data
				o_rfd       => corr_rfd(5),
				i_pkt_valid => player_ovalid(5),
				i_pkt_data  => player_odata(5),
				--output data
				o_pipe_err  => open,
			    o_fb_use    => open,
				o_pkt_valid => corr_ovalid(5),
				o_pkt_data  => corr_odata(5)
			);

		-------------------------------------------------------------------
		--The packet transmitter
		-------------------------------------------------------------------
		PKT_TX_P01_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => p0_fifo_rst(1), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(5),
				o_busy      => pkt_tx_busy(5),
				i_tx_valid  => corr_ovalid(5),
				i_tx_data   => corr_odata(5),
				--MGT FIFO interface
				i_fifo_full => p0_txf_full(1),
				o_valid     => p0_txf_write(1),
				o_charisk   => p0_txf_charisk(1),
				o_data      => p0_txf_data(1)
			);
	end generate;                       --PLAYER_P01_GEN
	PLAYER_P01_GEN_N : if PLAYER_EN(5) = '0' generate
		player_ram_w(5)      <= '0';
		player_busy(5)       <= '0';
		player_n_sent_pkt(5) <= (others => '0');
		player_ram_rdata(5)  <= (others => '0');
		pkt_tx_sop(5)        <= '0';
		player_ovalid(5)     <= '0';
		pkt_tx_busy(5)       <= '0';
		p0_txf_write(1)      <= '0';    --needed
	end generate;                       --PLAYER_P01_GEN_N

	--BPM0 Packet player
	PLAYER_BPM0_GEN : if PLAYER_EN(6) = '1' generate
		player_start(6) <= player_start_d when int_trig_en = '0' else player_start_c(6);

		--RAM write enable
		player_ram_w(6) <= mem_wr_ack and mem_cs(6);

		--The packet player
		PLAYER_BPM0_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => bpm_fifo_rst(0), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(6),
				--CTRL interface
				i_start    => player_start(6),
				o_busy     => player_busy(6),
				o_pkt_num  => player_n_sent_pkt(6),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(6),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(6),
				--TX Interface
				i_sop      => pkt_tx_sop(6),
				i_busy     => pkt_tx_busy(6),
				o_tx_valid => player_ovalid(6),
				o_tx_data  => player_odata(6)
			);

		--The packet transmitter
		PKT_TX_BPM0_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => bpm_fifo_rst(0), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(6),
				o_busy      => pkt_tx_busy(6),
				i_tx_valid  => player_ovalid(6),
				i_tx_data   => player_odata(6),
				--MGT FIFO interface
				i_fifo_full => bpm_txf_full(0),
				o_valid     => bpm_txf_write(0),
				o_charisk   => bpm_txf_charisk(0),
				o_data      => bpm_txf_data(0)
			);
	end generate;                       --PLAYER_BPM0_GEN
	PLAYER_BPM0_GEN_N : if PLAYER_EN(6) = '0' generate
		player_ram_w(6)      <= '0';
		player_busy(6)       <= '0';
		player_n_sent_pkt(6) <= (others => '0');
		player_ram_rdata(6)  <= (others => '0');
		pkt_tx_sop(6)        <= '0';
		player_ovalid(6)     <= '0';
		pkt_tx_busy(6)       <= '0';
		bpm_txf_write(0)     <= '0';    --needed
	end generate;                       --PLAYER_BPM0_GEN_N

	--BPM1 Packet player
	PLAYER_BPM1_GEN : if PLAYER_EN(7) = '1' generate
		player_start(7) <= player_start_d when int_trig_en = '0' else player_start_c(7);

		--RAM write enable
		player_ram_w(7) <= mem_wr_ack and mem_cs(7);

		--The packet player
		PLAYER_BPM1_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => bpm_fifo_rst(1), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(7),
				--CTRL interface
				i_start    => player_start(7),
				o_busy     => player_busy(7),
				o_pkt_num  => player_n_sent_pkt(7),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(7),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(7),
				--TX Interface
				i_sop      => pkt_tx_sop(7),
				i_busy     => pkt_tx_busy(7),
				o_tx_valid => player_ovalid(7),
				o_tx_data  => player_odata(7)
			);

		--The packet transmitter
		PKT_TX_BPM1_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => bpm_fifo_rst(1), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(7),
				o_busy      => pkt_tx_busy(7),
				i_tx_valid  => player_ovalid(7),
				i_tx_data   => player_odata(7),
				--MGT FIFO interface
				i_fifo_full => bpm_txf_full(1),
				o_valid     => bpm_txf_write(1),
				o_charisk   => bpm_txf_charisk(1),
				o_data      => bpm_txf_data(1)
			);
	end generate;                       --PLAYER_BPM1_GEN
	PLAYER_BPM1_GEN_N : if PLAYER_EN(7) = '0' generate
		player_ram_w(7)      <= '0';
		player_busy(7)       <= '0';
		player_n_sent_pkt(7) <= (others => '0');
		player_ram_rdata(7)  <= (others => '0');
		pkt_tx_sop(7)        <= '0';
		player_ovalid(7)     <= '0';
		pkt_tx_busy(7)       <= '0';
		bpm_txf_write(1)     <= '0';    --needed
	end generate;                       --PLAYER_BPM1_GEN_N

	--BPM2 Packet player
	PLAYER_BPM2_GEN : if PLAYER_EN(8) = '1' generate
		player_start(8) <= player_start_d when int_trig_en = '0' else player_start_c(8);

		--RAM write enable
		player_ram_w(8) <= mem_wr_ack and mem_cs(8);

		--The packet player
		PLAYER_BPM2_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => bpm_fifo_rst(2), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(8),
				--CTRL interface
				i_start    => player_start(8),
				o_busy     => player_busy(8),
				o_pkt_num  => player_n_sent_pkt(8),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(8),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(8),
				--TX Interface
				i_sop      => pkt_tx_sop(8),
				i_busy     => pkt_tx_busy(8),
				o_tx_valid => player_ovalid(8),
				o_tx_data  => player_odata(8)
			);

		--The packet transmitter
		PKT_TX_BPM2_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => bpm_fifo_rst(2), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(8),
				o_busy      => pkt_tx_busy(8),
				i_tx_valid  => player_ovalid(8),
				i_tx_data   => player_odata(8),
				--MGT FIFO interface
				i_fifo_full => bpm_txf_full(2),
				o_valid     => bpm_txf_write(2),
				o_charisk   => bpm_txf_charisk(2),
				o_data      => bpm_txf_data(2)
			);
	end generate;                       --PLAYER_BPM2_GEN
	PLAYER_BPM2_GEN_N : if PLAYER_EN(8) = '0' generate
		player_ram_w(8)      <= '0';
		player_busy(8)       <= '0';
		player_n_sent_pkt(8) <= (others => '0');
		player_ram_rdata(8)  <= (others => '0');
		pkt_tx_sop(8)        <= '0';
		player_ovalid(8)     <= '0';
		pkt_tx_busy(8)       <= '0';
		bpm_txf_write(2)     <= '0';    --needed
	end generate;                       --PLAYER_BPM2_GEN_N

	--BPM3 Packet player
	PLAYER_BPM3_GEN : if PLAYER_EN(9) = '1' generate
		player_start(9) <= player_start_d when int_trig_en = '0' else player_start_c(9);

		--RAM write enable
		player_ram_w(9) <= mem_wr_ack and mem_cs(9);

		--The packet player
		PLAYER_BPM3_i : ibfb_packet_player
			generic map(
				CTRL_EOS   => PLAYER_CTRL_EOS,
				RAM_ADDR_W => (PLAYER_RAM_ADDR_W - 2) --word-addressing
			)
			port map(
				i_clk      => i_user_clk,
				i_rst      => bpm_fifo_rst(3), --Bus2IP_Reset,
				--
				o_dbg      => dbg_pl(9),
				--CTRL interface
				i_start    => player_start(9),
				o_busy     => player_busy(9),
				o_pkt_num  => player_n_sent_pkt(9),
				--RAM interface
				i_ram_clk  => Bus2IP_Clk,
				i_ram_w    => player_ram_w(9),
				i_ram_a    => mem_address(PLAYER_RAM_ADDR_W - 1 downto 2),
				i_ram_d    => mem_wr_data,
				o_ram_d    => player_ram_rdata(9),
				--TX Interface
				i_sop      => pkt_tx_sop(9),
				i_busy     => pkt_tx_busy(9),
				o_tx_valid => player_ovalid(9),
				o_tx_data  => player_odata(9)
			);

		--The packet transmitter
		PKT_TX_BPM3_i : ibfb_packet_tx
			generic map(
				K_SOP        => K_SOP,
				K_EOP        => K_EOP,
				EXTERNAL_CRC => '0'
			)
			port map(
				i_rst       => bpm_fifo_rst(3), --Bus2IP_Reset,
				i_clk       => i_user_clk,
				--user interface
				o_sample    => pkt_tx_sop(9),
				o_busy      => pkt_tx_busy(9),
				i_tx_valid  => player_ovalid(9),
				i_tx_data   => player_odata(9),
				--MGT FIFO interface
				i_fifo_full => bpm_txf_full(3),
				o_valid     => bpm_txf_write(3),
				o_charisk   => bpm_txf_charisk(3),
				o_data      => bpm_txf_data(3)
			);
	end generate;                       --PLAYER_BPM3_GEN
	PLAYER_BPM3_GEN_N : if PLAYER_EN(9) = '0' generate
		player_ram_w(9)      <= '0';
		player_busy(9)       <= '0';
		player_n_sent_pkt(9) <= (others => '0');
		player_ram_rdata(9)  <= (others => '0');
		pkt_tx_sop(9)        <= '0';
		player_ovalid(9)     <= '0';
		pkt_tx_busy(9)       <= '0';
		bpm_txf_write(3)     <= '0';    --needed
	end generate;                       --PLAYER_BPM3_GEN_N

	------------------------------------------------------------------------------
	-- Receive correction data
	------------------------------------------------------------------------------

	fb_rxf_valid(0)   <= not qsfp_rxf_empty(0);
	fb_rxf_valid(1)   <= not qsfp_rxf_empty(1);
	fb_rxf_valid(2)   <= not qsfp_rxf_empty(2);
	fb_rxf_valid(3)   <= not qsfp_rxf_empty(3);
	fb_rxf_valid(4)   <= not p0_rxf_empty(0);
	fb_rxf_valid(5)   <= not p0_rxf_empty(1);
	fb_rxf_valid(6)   <= not bpm_rxf_empty(0);
	fb_rxf_valid(7)   <= not bpm_rxf_empty(1);
	fb_rxf_valid(8)   <= not bpm_rxf_empty(2);
	fb_rxf_valid(9)   <= not bpm_rxf_empty(3);
	--
	fb_rxf_charisk(0) <= qsfp_rxf_charisk(0);
	fb_rxf_charisk(1) <= qsfp_rxf_charisk(1);
	fb_rxf_charisk(2) <= qsfp_rxf_charisk(2);
	fb_rxf_charisk(3) <= qsfp_rxf_charisk(3);
	fb_rxf_charisk(4) <= p0_rxf_charisk(0);
	fb_rxf_charisk(5) <= p0_rxf_charisk(1);
	fb_rxf_charisk(6) <= bpm_rxf_charisk(0);
	fb_rxf_charisk(7) <= bpm_rxf_charisk(1);
	fb_rxf_charisk(8) <= bpm_rxf_charisk(2);
	fb_rxf_charisk(9) <= bpm_rxf_charisk(3);
	--
	fb_rxf_data(0)    <= qsfp_rxf_data(0);
	fb_rxf_data(1)    <= qsfp_rxf_data(1);
	fb_rxf_data(2)    <= qsfp_rxf_data(2);
	fb_rxf_data(3)    <= qsfp_rxf_data(3);
	fb_rxf_data(4)    <= p0_rxf_data(0);
	fb_rxf_data(5)    <= p0_rxf_data(1);
	fb_rxf_data(6)    <= bpm_rxf_data(0);
	fb_rxf_data(7)    <= bpm_rxf_data(1);
	fb_rxf_data(8)    <= bpm_rxf_data(2);
	fb_rxf_data(9)    <= bpm_rxf_data(3);
	--
	qsfp_rxf_next(0)  <= fb_rxf_next when FEEDBACK_RX_CHAN = 0 else '0';
	qsfp_rxf_next(1)  <= fb_rxf_next when FEEDBACK_RX_CHAN = 1 else '0';
	qsfp_rxf_next(2)  <= fb_rxf_next when FEEDBACK_RX_CHAN = 2 else '0';
	qsfp_rxf_next(3)  <= fb_rxf_next when FEEDBACK_RX_CHAN = 3 else '0';
	p0_rxf_next(0)    <= fb_rxf_next when FEEDBACK_RX_CHAN = 4 else '0';
	p0_rxf_next(1)    <= fb_rxf_next when FEEDBACK_RX_CHAN = 5 else '0';
	bpm_rxf_next(0)   <= fb_rxf_next when FEEDBACK_RX_CHAN = 6 else '0';
	bpm_rxf_next(1)   <= fb_rxf_next when FEEDBACK_RX_CHAN = 7 else '0';
	bpm_rxf_next(2)   <= fb_rxf_next when FEEDBACK_RX_CHAN = 8 else '0';
	bpm_rxf_next(3)   <= fb_rxf_next when FEEDBACK_RX_CHAN = 9 else '0';

	mon_pkt_rx_rst <= Bus2IP_Reset or mon_pkt_rx_rst_c;

	FB_PACKET_RX : ibfb_mon_packet_rx
		generic map(
			K_SOP => K_SOP,
			K_EOP => K_EOP
		)
		port map(
			i_rst      => mon_pkt_rx_rst,
			i_clk      => i_user_clk,   -- Bus2IP_Clk,
			--MGT FIFO interface
			o_next     => fb_rxf_next,
			i_valid    => fb_rxf_valid(FEEDBACK_RX_CHAN),
			i_charisk  => fb_rxf_charisk(FEEDBACK_RX_CHAN),
			i_data     => fb_rxf_data(FEEDBACK_RX_CHAN),
			--user interface
			o_bad_data => fb_rx_error,
			o_eop      => fb_data_avail,
			o_crc_good => fb_data_good,
			o_bkt_id   => fb_bkt_id,
			o_data_0   => fb_ky(0),
			o_data_1   => fb_ky(1),
			o_data_2   => fb_kx(0),
			o_data_3   => fb_kx(1),
			--debug
			o_csp_clk  => open,
			o_csp_data => pkt_rx_csp_data
		);

	fb_data_valid <= fb_data_avail and fb_data_good;

	--Register RX DATA
	FB_DATA_REG_P : process(i_user_clk)
	begin
		if rising_edge(i_user_clk) then
			if (Bus2IP_Reset = '1') then
				fb_pkt_cnt <= (others => '0');
				fb_err_cnt <= (others => '0');
				fb_data_r0 <= (others => '1');
				fb_data_r1 <= (others => '1');
				fb_data_r2 <= (others => '1');
				fb_data_r3 <= (others => '1');
			elsif fb_data_avail = '1' then
				fb_pkt_cnt <= fb_pkt_cnt + 1;
				if fb_data_good = '1' then
					fb_data_r0 <= fb_ky(0);
					fb_data_r1 <= fb_ky(1);
					fb_data_r2 <= fb_kx(0);
					fb_data_r3 <= fb_kx(1);
				else
					fb_err_cnt <= fb_err_cnt + 1;
					fb_data_r0 <= X"DEAD";
					fb_data_r1 <= X"DEAD";
					fb_data_r2 <= X"DEAD";
					fb_data_r3 <= X"DEAD";
				end if;
			end if;
		end if;
	end process;

end architecture behavioral;

------------------------------------------------------------------------------
-- End of file
------------------------------------------------------------------------------
