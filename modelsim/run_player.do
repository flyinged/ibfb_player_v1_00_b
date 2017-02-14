#vcom -work work -2002 -explicit -novopt C:/my_hdl/myfifo.vhd
vcom -work work -2002 -explicit -novopt ../hdl/vhdl/ram_infer.vhd
vcom -work work -2002 -explicit -novopt ../hdl/vhdl/pkg_crc.vhd
vcom -work work -2002 -explicit -novopt ../hdl/vhdl/ibfb_comm_package_sim.vhd
vcom -work work -2002 -explicit -novopt ../hdl/vhdl/ibfb_packet_player.vhd
vcom -work work -2002 -explicit -novopt ibfb_packet_player_tb.vhd

vsim -gui -t ps -novopt work.ibfb_packet_player_tb

log -r *
radix hex

#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(0) 01 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(1) 02 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(2) 03 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(3) 04 0

#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(0) 05 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(1) 06 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(2) 07 0
#force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(3) 08 0

do wave_player.do

alias TRIG "force -freeze sim:/user_logic_sim_tb/trig13 1 0 -cancel {100 ns}
            force -freeze sim:/user_logic_sim_tb/trig02 1 0 -cancel {100 ns}"
alias S "force -freeze sim:/ibfb_packet_player_tb/pl_start 1 0 -cancel {50 ns}"
alias WW "write format wave -window .main_pane.wave.interior.cs.body.pw.wf wave_player.do"