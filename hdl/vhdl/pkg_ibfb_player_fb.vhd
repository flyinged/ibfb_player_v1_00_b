------------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : pkg_ibfb_player_fb.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.2 $
------------------------------------------------------------------------------
-- Copyright© PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : Package containing the components used for the 
--           IBFB player feedback
------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--
--library ibfb_common_v1_00_b;
--use ibfb_common_v1_00_b.ibfb_comm_package.all; --ibfb packet data type
--
--package pkg_ibfb_player_fb is 
--   
--  --types from pkg_ibfb_types.vhd
--  type t_matrix_2x2_coeff is record
--    m11                       : std_logic_vector(31 downto 0);
--    m12                       : std_logic_vector(31 downto 0);
--    m21                       : std_logic_vector(31 downto 0);
--    m22                       : std_logic_vector(31 downto 0);
--  end record t_matrix_2x2_coeff;
--
--  type t_matrix_2x1_coeff is record
--    m11                       : std_logic_vector(31 downto 0);
--    m12                       : std_logic_vector(31 downto 0);
--  end record t_matrix_2x1_coeff;
--
--  type t_matrix_2x1_int16 is record
--    m11                       : std_logic_vector(15 downto 0);
--    m12                       : std_logic_vector(15 downto 0);
--  end record t_matrix_2x1_int16;
--
--  
--  
--  --out = in1*m11 + in2*m12
--  component matrix_2x1_mult_single
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_m_coeff                   : in  t_matrix_2x1_coeff            ;
--    i_nd                        : in  std_logic                     ;
--    i_in                        : in  t_matrix_2x1_coeff            ;
--    o_rfd                       : out std_logic                     ;
--    o_rdy                       : out std_logic                     ;
--    o_out                       : out std_logic_vector(31 downto 0)    
--  );
--  end component; 
--
--  --convert single precision to signed integer
--  component matrix_2x1_single2int
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_in                        : in  t_matrix_2x1_coeff            ;
--    o_overflow                  : out std_logic                     ;
--    o_rdy                       : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_int16            
--  );
--  end component; 
--
--  --convert signed integer to single precision
--  component matrix_2x1_int2single
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_in                        : in  t_matrix_2x1_int16            ;
--    o_rfd                       : out std_logic                     ;
--    o_rdy                       : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_coeff           
--  );
--  end component; 
--  
--  component matrix_2x1_addsub_single
--  generic (
--    c_op                        : std_logic := '0'  -- 0: add, 1: sub
--  );
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_a                         : in  t_matrix_2x1_coeff            ;
--    i_b                         : in  t_matrix_2x1_coeff            ;
--    o_rdy                       : out std_logic                     ;
--    o_rfd                       : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_coeff    
--  );
--  end component; 
  


--end package pkg_ibfb_player_fb;

---------------------------------------------------------------------------
-- END PACKAGED DEFINITION ------------------------------------------------
---------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- matrix_2x1_single2int
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.all;
--use ieee.std_logic_misc.ALL;
--
--use work.pkg_ibfb_player_fb.all;
--
--entity matrix_2x1_single2int is
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_in                        : in  t_matrix_2x1_coeff            ;
--    o_rdy                       : out std_logic                     ;
--    o_overflow                  : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_int16            
--  );
--end matrix_2x1_single2int;
--
--architecture behavioral of matrix_2x1_single2int is
--
--  COMPONENT ibfb_fp2int
--    PORT (
--      a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      operation_nd : IN STD_LOGIC;
--      clk : IN STD_LOGIC;
--      result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--      overflow : OUT STD_LOGIC;
--      rdy : OUT STD_LOGIC
--    );
--  END COMPONENT;
--
--  signal slv_rdy             : std_logic_vector(1 downto 0);
--  signal slv_overflow        : std_logic_vector(1 downto 0);
--  
--begin
--
--  inst_single_to_integer1 : ibfb_fp2int
--  PORT MAP (
--    a               => i_in.m11 ,
--    operation_nd    => i_nd     ,
--    clk             => i_clk    ,
--    result          => o_out.m11,
--    overflow        => slv_overflow(0),
--    rdy             => slv_rdy(0)
--  );
--  
--  inst_single_to_integer2 : ibfb_fp2int
--  PORT MAP (
--    a               => i_in.m12 ,
--    operation_nd    => i_nd     ,
--    clk             => i_clk    ,
--    result          => o_out.m12,
--    overflow        => slv_overflow(1),
--    rdy             => slv_rdy(1)
--  );
--  
--  o_rdy       <= and_reduce(     slv_rdy);
--  o_overflow  <=  or_reduce(slv_overflow);
--
--end architecture behavioral;
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- matrix_2x1_int2single
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.all;
--use ieee.std_logic_misc.ALL;
--
--
--entity matrix_2x1_int2single is
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_in                        : in  t_matrix_2x1_int16            ;
--    o_rfd                       : out std_logic                     ;
--    o_rdy                       : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_coeff            
--  );
--end matrix_2x1_int2single;
--
--architecture behavioral of matrix_2x1_int2single is
--
--  COMPONENT ibfb_int2fp
--    PORT (
--      a             : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--      operation_nd  : IN STD_LOGIC;
--      clk           : IN STD_LOGIC;
--      operation_rfd : OUT STD_LOGIC;
--      result        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--      rdy           : OUT STD_LOGIC
--    );
--  END COMPONENT;
--
--  signal slv_rdy : std_logic_vector(1 downto 0);
--  signal slv_rfd : std_logic_vector(1 downto 0);
--  
--begin
--
--  inst_single_to_integer1 : ibfb_int2fp
--  PORT MAP (
--    a               => i_in.m11 ,
--    operation_nd    => i_nd     ,
--    operation_rfd   => slv_rfd(0),
--    clk             => i_clk    ,
--    result          => o_out.m11,
--    rdy             => slv_rdy(0)
--  );
--  
--  inst_single_to_integer2 : ibfb_int2fp
--  PORT MAP (
--    a               => i_in.m12 ,
--    operation_nd    => i_nd     ,
--    operation_rfd   => slv_rfd(1),
--    clk             => i_clk    ,
--    result          => o_out.m12,
--    rdy             => slv_rdy(1)
--  );
--  
--  o_rdy <= and_reduce(slv_rdy);
--  o_rfd <= and_reduce(slv_rfd);
--
--end architecture behavioral;
--
--
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- matrix_2x1_mult_single
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- 
----    |       |   |               |   | in_1 |
----    | o_out | = |  m11     m12  | X |      | = m11*in1 + m12*in2
----    |       |   |               |   | in_2 |
----
----
--
--library ieee;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.all;
--
--
--entity matrix_2x1_mult_single is
--port(
--    i_clk     : in  std_logic;
--    i_nd      : in  std_logic;
--    i_in      : in  t_matrix_2x1_coeff;
--    i_m_coeff : in  t_matrix_2x1_coeff;
--    o_rfd     : out std_logic;
--    o_rdy     : out std_logic;
--    o_out     : out std_logic_vector(31 downto 0)    
--);
--end matrix_2x1_mult_single;
--
--architecture behavioral of matrix_2x1_mult_single is
--
--  COMPONENT fp_mult_player
--  PORT (
--    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    operation_nd : IN STD_LOGIC;
--    operation_rfd : OUT STD_LOGIC;
--    clk : IN STD_LOGIC;
--    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--    rdy : OUT STD_LOGIC
--  );
--  END COMPONENT;
--  
--  COMPONENT fp_add_player
--  PORT (
--    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    operation_nd : IN STD_LOGIC;
--    operation_rfd : OUT STD_LOGIC;
--    clk : IN STD_LOGIC;
--    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--    rdy : OUT STD_LOGIC
--  );
--  END COMPONENT;
--
--  signal slv_mult_rdy             : std_logic_vector(1 downto 0);
--  signal slv_mult_rfd             : std_logic_vector(1 downto 0);
--  signal sl_add1_nd               : std_logic;
--  signal r_mult_result            : t_matrix_2x1_coeff;
--  signal add_rfd                  : std_logic;
--  
--begin
--
--  MULT0_INST : fb_mult_player
--  PORT MAP (
--    clk           => i_clk,
--    operation_nd  => i_nd,
--    operation_rfd => slv_mult_rfd(0),
--    a             => i_m_coeff.m11,
--    b             => i_in.m11,
--    result        => r_mult_result.m11,
--    rdy           => slv_mult_rdy(0)        
--  );
--  
--  MULT1_INST : fb_mult_player
--  PORT MAP (
--    clk           => i_clk,
--    operation_nd  => i_nd,
--    operation_rfd => slc_mult_rfd(1),
--    a             => i_m_coeff.m12,
--    b             => i_in.m12,
--    result        => r_mult_result.m12,
--    rdy           => slv_mult_rdy(1)        
--  );
--
--  sl_add1_nd <= slv_mult_rdy(0) and slv_mult_rdy(1);
--  
--  ADDER_INST : fp_add_player
--  PORT MAP (
--    clk                 => i_clk,
--    operation_nd        => sl_add1_nd,
--    operation_rfd       => add_rfd,
--    a                   => r_mult_result.m11,
--    b                   => r_mult_result.m12,
--    result              => o_out,
--    rdy                 => o_rdy
--  );  
--
--  o_rfd <= slc_mult_rfd(0) and slc_mult_rfd(1) and add_rfd;
--
--end architecture behavioral;
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- matrix_2x1_addsub_single
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- 
----    |                        |   |                     |     |                    |
----    | o_out.m11    o_out.m12 | = | i_a.m11     i_b.m12 | +/- | i_b.m11    i_b.m12 |
----    |                        |   |                     |     |                    |
----
----
--
--library ieee;
--use ieee.std_logic_1164.ALL;
--use ieee.numeric_std.all;
--
--
--entity matrix_2x1_addsub_single is
--  generic (
--    c_op                        : std_logic := '0'  -- 0: add, 1: sub
--  );
--  port  (
--    i_clk                       : in  std_logic                     ;
--    i_nd                        : in  std_logic                     ;
--    i_a                         : in  t_matrix_2x1_coeff            ;
--    i_b                         : in  t_matrix_2x1_coeff            ;
--    o_rdy                       : out std_logic                     ;
--    o_out                       : out t_matrix_2x1_coeff    
--  );
--end matrix_2x1_addsub_single;
--
--architecture behavioral of matrix_2x1_addsub_single is
--  
--  COMPONENT fp_add_player
--  PORT (
--    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    operation_nd : IN STD_LOGIC;
--    operation_rfd : OUT STD_LOGIC;
--    clk : IN STD_LOGIC;
--    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--    rdy : OUT STD_LOGIC
--  );
--  END COMPONENT;
--
--  signal slv_add_rdy : std_logic_vector(1 downto 0);
--  signal slv_add_rfd : std_logic_vector(1 downto 0);
--  
--begin
--
--  ADD0_INST : fp_add_player
--  PORT MAP (
--    clk                 => i_clk,
--    a                   => i_a.m11,
--    b                   => i_b.m11,
--    operation_nd        => i_nd,
--    operation_rfd       => slv_add_rfd(0),
--    result              => o_out.m11,
--    rdy                 => slv_add_rdy(0)
--  );  
--
--  ADD1_INST : fp_add_player
--  PORT MAP (
--    clk                 => i_clk,
--    a                   => i_a.m12,
--    b                   => i_b.m12,
--    operation_nd        => i_nd,
--    operation_rfd       => slv_add_rfd(1),
--    result              => o_out.m12,
--    rdy                 => slv_add_rdy(1)
--  );  
--
--  o_rdy <= slv_add_rdy(0) and slv_add_rdy(1);
--  o_rfd <= slv_add_rfd(0) and slv_add_rfd(1);
--  
--end architecture behavioral;


-------------------------------------------------------------------------
-- Apply correction to IBFB packet 
-- Xout = Xplay + (Tx0 * Fx0) + (Tx1 * Fx1)
-- Yout = Yplay + (Ty0 * Fy0) + (Ty1 * Fy1)
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library ibfb_common_v1_00_b;
use ibfb_common_v1_00_b.ibfb_comm_package.all; --ibfb packet data type

entity ibfb_fb_apply_correction is
port(
    --DEBUG
    o_dbg       : out std_logic_Vector(287 downto 0);
    --
    i_clk       : in std_logic;
    i_train_trg : in std_logic; --start of bunch (resets correction computation) 
    --feedback input
    i_fb_v      : in std_logic; --feedback valid
    --i_fb_kx     : in array16(0 to 1); --KX0,KX1
    --i_fb_ky     : in array16(0 to 1); --KY0,KY1
    i_fb_kx0    : in std_logic_Vector(15 downto 0);
    i_fb_kx1    : in std_logic_Vector(15 downto 0);
    i_fb_ky0    : in std_logic_Vector(15 downto 0);
    i_fb_ky1    : in std_logic_Vector(15 downto 0);
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
    --output data
    o_fb_use    : out std_logic_vector(0 to 3); --when X"0", current FB values have never been used
    o_pipe_err  : out std_logic_vector(0 to 3); --pipeline error (shall be always X"0")
    o_pkt_valid : out std_logic;
    o_pkt_data  : out ibfb_comm_packet  
);
end entity ibfb_fb_apply_correction;

architecture rtl of ibfb_fb_apply_correction is

COMPONENT ibfb_int2fp
PORT (
    a             : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    operation_nd  : IN STD_LOGIC;
    clk           : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    result        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy           : OUT STD_LOGIC
);
END COMPONENT;

COMPONENT fp_mult_player
PORT (
    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    operation_nd : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    clk : IN STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy : OUT STD_LOGIC
);
END COMPONENT;
  
COMPONENT fp_add_player
PORT (
    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    operation_nd : IN STD_LOGIC;
    operation_rfd : OUT STD_LOGIC;
    clk : IN STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy : OUT STD_LOGIC
);
END COMPONENT;

signal tr_kx : array32(0 to 1);
signal tr_ky : array32(0 to 1);

signal fb_kx_reg : array16(0 to 1); --KX0,KX1
signal fb_ky_reg : array16(0 to 1); --KY0,KY1


signal pkt_reg0, pkt_reg1, pkt_reg2, pkt_reg3 : ibfb_comm_packet;
signal pkt_reg_full : std_logic_vector(0 to 3) := X"0";
signal pkt_reg_rfd  : std_logic_vector(0 to 3) := X"F";
signal pkt_reg_err  : std_logic_vector(0 to 3) := X"0";

signal conv_rfd    : std_logic;
signal conv_kx_rfd : std_logic_vector(0 to 1);
signal conv_ky_rfd : std_logic_vector(0 to 1);
signal conv_kx_rdy : std_logic_vector(0 to 1);
signal conv_ky_rdy : std_logic_vector(0 to 1);
signal conv_kx_out : array32(0 to 1);
signal conv_ky_out : array32(0 to 1);

signal mult_start, mult_rfd : std_logic;
signal mult_kx_rfd : std_logic_vector(0 to 1);
signal mult_ky_rfd : std_logic_vector(0 to 1);
signal mult_kx_rdy : std_logic_vector(0 to 1);
signal mult_ky_rdy : std_logic_vector(0 to 1);
signal mult_kx_out : array32(0 to 1);
signal mult_ky_out : array32(0 to 1);

signal add0_start : std_logic;
signal add0_rfd : std_logic_vector(0 to 1);
signal add0_rdy : std_logic_vector(0 to 1);
signal add0_out : array32(0 to 1);

signal add1_start : std_logic;
signal add1_rfd : std_logic_vector(0 to 1);
signal add1_rdy : std_logic_vector(0 to 1);
signal add1_out : array32(0 to 1);
signal fb_use : std_logic_vector(0 to 3);

signal ipv_r, pkt_valid, ovalid : std_logic;

begin

--DEBUG-------------------------------------------------------------------------------
o_dbg(           000) <= i_fb_v;
o_dbg(           001) <= i_train_trg;
o_dbg(           002) <= pkt_valid;
o_dbg(           003) <= conv_rfd;
o_dbg(           004) <= mult_start;
o_dbg(           005) <= mult_rfd;
o_dbg(           006) <= add0_start;
o_dbg(           007) <= add1_start;
o_dbg(           008) <= ovalid;

o_dbg(   011 downto 009) <= (others => '0');

o_dbg( 3+012 downto 012) <= fb_use;       
o_dbg( 3+016 downto 016) <= pkt_reg_err;       
o_dbg( 7+020 downto 020) <= i_pkt_data.bpm;
o_dbg(   031 downto 028) <= (others => '0');
o_dbg(15+032 downto 032) <= fb_kx_reg(0);
o_dbg(15+048 downto 048) <= fb_kx_reg(1);
o_dbg(15+064 downto 064) <= fb_ky_reg(0);
o_dbg(15+080 downto 080) <= fb_ky_reg(1);
o_dbg(31+096 downto 096) <= add1_out(0);
o_dbg(31+128 downto 128) <= add1_out(1);
o_dbg(31+160 downto 160) <= tr_kx(0);
o_dbg(31+192 downto 192) <= tr_kx(1);
o_dbg(31+224 downto 224) <= tr_ky(0);
o_dbg(31+256 downto 256) <= tr_ky(1);

--------------------------------------------------------------------------------------

PKT_VALID_EDGE_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        ipv_r <= i_pkt_valid;
    end if;
end process;

pkt_valid <= i_pkt_valid and not ipv_r;

--register feedback inputs 
--registers are reset when a new packet is received
FB_INPUT_REG_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_fb_v = '1' then
            --fb_kx_reg <= i_fb_kx;
            --fb_ky_reg <= i_fb_ky;
            fb_kx_reg(0) <= i_fb_kx0;
            fb_kx_reg(1) <= i_fb_kx1;
            fb_ky_reg(0) <= i_fb_ky0;
            fb_ky_reg(1) <= i_fb_ky1;
        --change
        --elsif (pkt_valid = '1' and fb_use = X"F") or (i_train_trg = '1' ) then
        --    --reset feedback value when it has been used once by all allowed BPM_IDs
        --    fb_kx_reg <= (others => (others => '0'));
        --    fb_ky_reg <= (others => (others => '0'));
        end if; 
    end if;
end process;

--when an input packet is received, then register packet and start correction computation
PIPELINE_REG0_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if pkt_valid = '1' then
            pkt_reg0 <= i_pkt_data;
        end if;
    end if;
end process;

--select transformation parameters to use according to packet's BPM_ID
TRANSFORMATION_SEL_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if i_fb_v = '1' then
            fb_use <= X"0"; --feedback value never used
        elsif pkt_valid = '1' then
            if i_pkt_data.bpm = i_bpm_ids(0) then
                if fb_use(0) = '0' then
                    tr_kx(0) <= i_tr_kx0(0);
                    tr_kx(1) <= i_tr_kx1(0);
                    tr_ky(0) <= i_tr_ky0(0);
                    tr_ky(1) <= i_tr_ky1(0);
                else
                    tr_kx(0) <= (others => '0');
                    tr_kx(1) <= (others => '0');
                    tr_ky(0) <= (others => '0');
                    tr_ky(1) <= (others => '0');
                end if;
                fb_use(0) <= '1'; --feedback value used for BPM_ID0
            elsif i_pkt_data.bpm = i_bpm_ids(1) then
                if fb_use(1) = '0' then
                    tr_kx(0) <= i_tr_kx0(1);
                    tr_kx(1) <= i_tr_kx1(1);
                    tr_ky(0) <= i_tr_ky0(1);
                    tr_ky(1) <= i_tr_ky1(1);
                else
                    tr_kx(0) <= (others => '0');
                    tr_kx(1) <= (others => '0');
                    tr_ky(0) <= (others => '0');
                    tr_ky(1) <= (others => '0');
                end if;
                fb_use(1) <= '1'; --feedback value used for BPM_ID1
            elsif i_pkt_data.bpm = i_bpm_ids(2) then
                if fb_use(2) = '0' then
                    tr_kx(0) <= i_tr_kx0(2);
                    tr_kx(1) <= i_tr_kx1(2);
                    tr_ky(0) <= i_tr_ky0(2);
                    tr_ky(1) <= i_tr_ky1(2);
                else
                    tr_kx(0) <= (others => '0');
                    tr_kx(1) <= (others => '0');
                    tr_ky(0) <= (others => '0');
                    tr_ky(1) <= (others => '0');
                end if;
                fb_use(2) <= '1'; --feedback value used for BPM_ID2
            elsif i_pkt_data.bpm = i_bpm_ids(3) then
                if fb_use(3) = '0' then
                    tr_kx(0) <= i_tr_kx0(3);
                    tr_kx(1) <= i_tr_kx1(3);
                    tr_ky(0) <= i_tr_ky0(3);
                    tr_ky(1) <= i_tr_ky1(3);
                else
                    tr_kx(0) <= (others => '0');
                    tr_kx(1) <= (others => '0');
                    tr_ky(0) <= (others => '0');
                    tr_ky(1) <= (others => '0');
                end if;
                fb_use(3) <= '1'; --feedback value used for BPM_ID3
            else
                tr_kx(0) <= (others => '0');
                tr_kx(1) <= (others => '0');
                tr_ky(0) <= (others => '0');
                tr_ky(1) <= (others => '0');
            end if;
        end if;
    end if;
end process;

o_fb_use <= fb_use;

----------------------------------------------------------------------------------------
-- Convert feedback values to single precision floating point 
----------------------------------------------------------------------------------------

conv_rfd <= conv_kx_rfd(0) and conv_kx_rfd(1) and conv_ky_rfd(0) and conv_ky_rfd(1);
o_rfd <= pkt_reg_rfd(0);

INT2FP_FBX0_INST : ibfb_int2fp
PORT map(
    clk           => i_clk,
    operation_nd  => pkt_valid,
    operation_rfd => conv_kx_rfd(0),
    a             => fb_kx_reg(0),
    rdy           => conv_kx_rdy(0),
    result        => conv_kx_out(0) --Fx0
);

INT2FP_FBX1_INST : ibfb_int2fp
PORT map(
    clk           => i_clk,
    operation_nd  => pkt_valid,
    operation_rfd => conv_kx_rfd(1),
    a             => fb_kx_reg(1),
    rdy           => conv_kx_rdy(1),
    result        => conv_kx_out(1) --Fx1
);

INT2FP_FBY0_INST : ibfb_int2fp
PORT map(
    clk           => i_clk,
    operation_nd  => pkt_valid,
    operation_rfd => conv_ky_rfd(0),
    a             => fb_ky_reg(0),
    rdy           => conv_ky_rdy(0),
    result        => conv_ky_out(0) --Fy0
);

INT2FP_FBY1_INST : ibfb_int2fp
PORT map(
    clk           => i_clk,
    operation_nd  => pkt_valid,
    operation_rfd => conv_ky_rfd(1),
    a             => fb_ky_reg(1),
    rdy           => conv_ky_rdy(1),
    result        => conv_ky_out(1) --Fy1
);

mult_start <= conv_kx_rdy(0) and conv_kx_rdy(1) and conv_ky_rdy(0) and conv_ky_rdy(1);

PIPELINE_REG1_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if mult_start = '1' then
            pkt_reg1 <= pkt_reg0;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------
-- Compute multiplications
----------------------------------------------------------------------------------------

mult_rfd <= mult_kx_rfd(0) and mult_kx_rfd(1) and mult_ky_rfd(0) and mult_ky_rfd(1);

MULT_KX0_INST : fp_mult_player
port map(
    clk           => i_clk,
    operation_rfd => mult_kx_rfd(0),
    operation_nd  => mult_start,
    a             => conv_kx_out(0), 
    b             => tr_kx(0), 
    rdy           => mult_kx_rdy(0),
    result        => mult_kx_out(0) --Tx0 * Fx0
);

MULT_KX1_INST : fp_mult_player
port map(
    clk           => i_clk,
    operation_rfd => mult_kx_rfd(1),
    operation_nd  => mult_start,
    a             => conv_kx_out(1), 
    b             => tr_kx(1), 
    rdy           => mult_kx_rdy(1),
    result        => mult_kx_out(1) --Tx1 * Fx1 
);

MULT_KY0_INST : fp_mult_player
port map(
    clk           => i_clk,
    operation_rfd => mult_ky_rfd(0),
    operation_nd  => mult_start,
    a             => conv_ky_out(0), 
    b             => tr_ky(0), 
    rdy           => mult_ky_rdy(0),
    result        => mult_ky_out(0) --Ty0 * Fy0
);

MULT_KY1_INST : fp_mult_player
port map(
    clk           => i_clk,
    operation_rfd => mult_ky_rfd(1),
    operation_nd  => mult_start,
    a             => conv_ky_out(1), 
    b             => tr_ky(1), 
    rdy           => mult_ky_rdy(1),
    result        => mult_ky_out(1) --Ty1 * Fy1
);

add0_start <= mult_kx_rdy(0) and mult_kx_rdy(1) and mult_ky_rdy(0) and mult_ky_rdy(1);
       
PIPELINE_REG2_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if add0_start = '1' then
            pkt_reg2 <= pkt_reg1;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------
-- Compute correction values
----------------------------------------------------------------------------------------

XCORR_ADD0_INST : fp_add_player
port map(
    clk           => i_clk,
    operation_nd  => add0_start,
    operation_rfd => add0_rfd(0),
    a             => mult_kx_out(0),
    b             => mult_kx_out(1),
    rdy           => add0_rdy(0),
    result        => add0_out(0) --Kx0*Fx0 + Kx1*Fx1
);            

YCORR_ADD0_INST : fp_add_player
port map(
    clk           => i_clk,
    operation_nd  => add0_start,
    operation_rfd => add0_rfd(1),
    a             => mult_ky_out(0),
    b             => mult_ky_out(1),
    rdy           => add0_rdy(1),
    result        => add0_out(1) --Ky0*Fy0 + Ky1*Fy1
);        

add1_start <= add0_rdy(0) and add0_rdy(1);

PIPELINE_REG3_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if add1_start = '1' then
            pkt_reg3 <= pkt_reg2;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------
-- Apply correction to packet data stored in pipeline
----------------------------------------------------------------------------------------

XOUT_ADD1_INST : fp_add_player
port map(
    clk           => i_clk,
    operation_nd  => add1_start,
    operation_rfd => add1_rfd(0),
    a             => add0_out(0),
    b             => pkt_reg2.xpos,
    rdy           => add1_rdy(0),
    result        => add1_out(0) --Xplay + Xcorr
);            

YOUT_ADD1_INST : fp_add_player
port map(
    clk           => i_clk,
    operation_nd  => add1_start,
    operation_rfd => add1_rfd(1),
    a             => add0_out(1),
    b             => pkt_reg2.ypos,
    rdy           => add1_rdy(1),
    result        => add1_out(1) --Yplay + Ycorr
);        

ovalid           <= add1_rdy(0) and add1_rdy(1);
o_pkt_valid      <= ovalid;
o_pkt_data.ctrl  <= pkt_reg3.ctrl;
o_pkt_data.bpm   <= pkt_reg3.bpm;
o_pkt_data.bucket<= pkt_reg3.bucket;
o_pkt_data.xpos  <= add1_out(0);
o_pkt_data.ypos  <= add1_out(1);
o_pkt_data.crc   <= pkt_reg3.crc;

--pipeline control
PIPE_P : process(i_clk)
begin
    if rising_edge(i_clk) then
        if pkt_valid = '1' then
            pkt_reg_full(0) <= '1';
        elsif mult_start = '1' then 
            pkt_reg_full(0) <= '0';
        end if;

        if mult_start = '1' then
            pkt_reg_full(1) <= '1';
        elsif add0_start = '1' then 
            pkt_reg_full(1) <= '0';
        end if;

        if add0_start = '1' then
            pkt_reg_full(2) <= '1';
        elsif add1_start = '1' then 
            pkt_reg_full(2) <= '0';
        end if;

        if add1_start = '1' then
            pkt_reg_full(3) <= '1';
        elsif ovalid = '1' then
            pkt_reg_full(3) <= '0';
        end if;
    end if;
end process;

pkt_reg_rfd(0) <= not(pkt_reg_full(0) and not(mult_start));
pkt_reg_rfd(1) <= not(pkt_reg_full(1) and not(add0_start));
pkt_reg_rfd(2) <= not(pkt_reg_full(2) and not(add1_start));
pkt_reg_rfd(3) <= not(pkt_reg_full(3) and not(ovalid));

pkt_reg_err(0) <= pkt_valid  and not(pkt_reg_rfd(0));
pkt_reg_err(1) <= mult_start and not(pkt_reg_rfd(1));
pkt_reg_err(2) <= add0_start and not(pkt_reg_rfd(2));
pkt_reg_err(3) <= add1_start and not(pkt_reg_rfd(3));

o_pipe_err <= pkt_reg_err;

end architecture rtl; --of ibfb_fb_apply_correction

