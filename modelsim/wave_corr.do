onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group parameters /ibfb_fb_apply_correction_tb/bpm_ids
add wave -noupdate -group parameters /ibfb_fb_apply_correction_tb/tr_kx0
add wave -noupdate -group parameters /ibfb_fb_apply_correction_tb/tr_kx1
add wave -noupdate -group parameters /ibfb_fb_apply_correction_tb/tr_ky0
add wave -noupdate -group parameters /ibfb_fb_apply_correction_tb/tr_ky1
add wave -noupdate /ibfb_fb_apply_correction_tb/trig
add wave -noupdate /ibfb_fb_apply_correction_tb/clk
add wave -noupdate -group PKT_GEN /ibfb_fb_apply_correction_tb/s
add wave -noupdate -group PKT_GEN -radix unsigned /ibfb_fb_apply_correction_tb/timer
add wave -noupdate -group PKT_GEN /ibfb_fb_apply_correction_tb/dcnt
add wave -noupdate /ibfb_fb_apply_correction_tb/rfd
add wave -noupdate -expand /ibfb_fb_apply_correction_tb/i_pkt_data
add wave -noupdate -color magenta /ibfb_fb_apply_correction_tb/i_pkt_valid
add wave -noupdate -group FB_GEN /ibfb_fb_apply_correction_tb/s2
add wave -noupdate -group FB_GEN -radix unsigned /ibfb_fb_apply_correction_tb/timer2
add wave -noupdate -group FB_GEN /ibfb_fb_apply_correction_tb/dcnt2
add wave -noupdate -color magenta /ibfb_fb_apply_correction_tb/fb_v
add wave -noupdate /ibfb_fb_apply_correction_tb/fb_kx
add wave -noupdate /ibfb_fb_apply_correction_tb/fb_ky
add wave -noupdate -color Cyan /ibfb_fb_apply_correction_tb/o_pkt_valid
add wave -noupdate /ibfb_fb_apply_correction_tb/o_pkt_data
add wave -noupdate -childformat {{/ibfb_fb_apply_correction_tb/o_pkt_data_r.xpos -radix unsigned} {/ibfb_fb_apply_correction_tb/o_pkt_data_r.ypos -radix unsigned}} -expand -subitemconfig {/ibfb_fb_apply_correction_tb/o_pkt_data_r.xpos {-height 15 -radix unsigned} /ibfb_fb_apply_correction_tb/o_pkt_data_r.ypos {-height 15 -radix unsigned}} /ibfb_fb_apply_correction_tb/o_pkt_data_r
add wave -noupdate -divider int
add wave -noupdate -color Cyan /ibfb_fb_apply_correction_tb/o_pkt_valid
add wave -noupdate /ibfb_fb_apply_correction_tb/tx_busy
add wave -noupdate /ibfb_fb_apply_correction_tb/tx_data
add wave -noupdate /ibfb_fb_apply_correction_tb/tx_isk
add wave -noupdate /ibfb_fb_apply_correction_tb/tx_sample
add wave -noupdate /ibfb_fb_apply_correction_tb/tx_vld
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/pkt_reg_full
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/pkt_reg_err
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/pkt_reg_rfd
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/i_fb_v
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/fb_kx_reg
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/fb_ky_reg
add wave -noupdate -group {internal signals} -color MAGENTA /ibfb_fb_apply_correction_tb/UUT/pkt_valid
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/fb_use
add wave -noupdate -group {internal signals} -color Yellow /ibfb_fb_apply_correction_tb/UUT/pkt_reg0
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/tr_kx
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/tr_ky
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/conv_kx_out
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/conv_kx_rdy
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/conv_ky_out
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/conv_ky_rdy
add wave -noupdate -group {internal signals} -color MAGENTA /ibfb_fb_apply_correction_tb/UUT/mult_start
add wave -noupdate -group {internal signals} -color Yellow /ibfb_fb_apply_correction_tb/UUT/pkt_reg1
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_kx_out
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_kx_rdy
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_kx_rfd
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_ky_out
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_ky_rdy
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_ky_rfd
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/mult_rfd
add wave -noupdate -group {internal signals} -color magenta /ibfb_fb_apply_correction_tb/UUT/add0_start
add wave -noupdate -group {internal signals} -color Yellow /ibfb_fb_apply_correction_tb/UUT/pkt_reg2
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/add0_out
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/add0_rdy
add wave -noupdate -group {internal signals} -color magenta /ibfb_fb_apply_correction_tb/UUT/add1_start
add wave -noupdate -group {internal signals} /ibfb_fb_apply_correction_tb/UUT/add1_out
add wave -noupdate -group {internal signals} -color cyan /ibfb_fb_apply_correction_tb/UUT/add1_rdy
add wave -noupdate -group {internal signals} -color Yellow /ibfb_fb_apply_correction_tb/UUT/pkt_reg3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {294088 ps} 0} {{Cursor 2} {8089507 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 16
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {9316044 ps} {10035998 ps}
