
vcom -work ibfb_common_v1_00_b -2002 -explicit -novopt ./pkg_crc.vhd
vcom -work ibfb_common_v1_00_b -2002 -explicit -novopt sim_components.vhd
vcom -work work -2002 -explicit -novopt ../hdl/vhdl/pkg_ibfb_player_fb.vhd
vcom -work work -2002 -explicit -novopt ./ibfb_fb_apply_correction_tb.vhd

vsim -gui -t ps -novopt work.ibfb_fb_apply_correction_tb

log -r *
radix hex

do wave_corr.do

alias WW "write format wave -window .main_pane.wave.interior.cs.body.pw.wf wave_corr.do"
