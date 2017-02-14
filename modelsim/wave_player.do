onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ibfb_packet_player_tb/clk
add wave -noupdate /ibfb_packet_player_tb/rst
add wave -noupdate -expand -group {RAM INIT} /ibfb_packet_player_tb/ram_init_w
add wave -noupdate -expand -group {RAM INIT} /ibfb_packet_player_tb/ram_init_a
add wave -noupdate -expand -group {RAM INIT} /ibfb_packet_player_tb/ram_init_d
add wave -noupdate -expand -group {RAM INIT} /ibfb_packet_player_tb/ram_init_id
add wave -noupdate /ibfb_packet_player_tb/ram_init_done
add wave -noupdate /ibfb_packet_player_tb/ram_read_a
add wave -noupdate /ibfb_packet_player_tb/ram_read_d
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/b0
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/b1
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/b2
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/b3
add wave -noupdate -group {player inner} -color magenta /ibfb_packet_player_tb/PLAYER_I/i_start
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/end_of_sequence
add wave -noupdate -group {player inner} -color tan /ibfb_packet_player_tb/PLAYER_I/i_busy
add wave -noupdate -group {player inner} -color blue /ibfb_packet_player_tb/PLAYER_I/s
add wave -noupdate -group {player inner} -color orange /ibfb_packet_player_tb/PLAYER_I/ram_read_a
add wave -noupdate -group {player inner} -color yellow /ibfb_packet_player_tb/PLAYER_I/ram_read_d
add wave -noupdate -group {player inner} -expand /ibfb_packet_player_tb/PLAYER_I/pkt_buf
add wave -noupdate -group {player inner} -expand /ibfb_packet_player_tb/PLAYER_I/pkt_out
add wave -noupdate -group {player inner} -color cyan /ibfb_packet_player_tb/PLAYER_I/o_tx_valid
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/sent
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/start_r
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/timer_on
add wave -noupdate -group {player inner} /ibfb_packet_player_tb/PLAYER_I/send_packet
add wave -noupdate -group {player inner} -radix unsigned /ibfb_packet_player_tb/PLAYER_I/start_time
add wave -noupdate -group {player inner} -radix unsigned /ibfb_packet_player_tb/PLAYER_I/timer
add wave -noupdate -expand -group PLAYER -color gold /ibfb_packet_player_tb/pl_start
add wave -noupdate -expand -group PLAYER -color cyan /ibfb_packet_player_tb/pl_busy
add wave -noupdate -expand -group PLAYER /ibfb_packet_player_tb/pkt_tx_busy
add wave -noupdate -expand -group PLAYER /ibfb_packet_player_tb/pkt_tx_sop
add wave -noupdate -expand -group PLAYER /ibfb_packet_player_tb/player_odata
add wave -noupdate -expand -group PLAYER -color magenta /ibfb_packet_player_tb/player_ovalid
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/b0
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/b1
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/crc_rst
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/i_fifo_full
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/i_rst
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/i_tx_data
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/o_busy
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/o_charisk
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/o_data
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/o_valid
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/ocharisk
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/ocharisk_r
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/odata
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/odata_r
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/start_r
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/valid
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/valid_r
add wave -noupdate -group {pkt tx inner} -color gold /ibfb_packet_player_tb/PKT_TX_I/i_tx_valid
add wave -noupdate -group {pkt tx inner} -color blue /ibfb_packet_player_tb/PKT_TX_I/s
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/x0
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/x1
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/x2
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/x3
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/y0
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/y1
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/y2
add wave -noupdate -group {pkt tx inner} /ibfb_packet_player_tb/PKT_TX_I/y3
add wave -noupdate -expand -group PKT_TX /ibfb_packet_player_tb/txf_charisk
add wave -noupdate -expand -group PKT_TX /ibfb_packet_player_tb/txf_data
add wave -noupdate -expand -group PKT_TX /ibfb_packet_player_tb/txf_full
add wave -noupdate -expand -group PKT_TX -color magenta /ibfb_packet_player_tb/txf_write
add wave -noupdate -expand -group {RX FIFO} /ibfb_packet_player_tb/rx_next
add wave -noupdate -expand -group {RX FIFO} -color magenta /ibfb_packet_player_tb/rx_valid
add wave -noupdate -expand -group {RX FIFO} /ibfb_packet_player_tb/rx_empty
add wave -noupdate -expand -group {RX FIFO} /ibfb_packet_player_tb/rx_isk
add wave -noupdate -expand -group {RX FIFO} /ibfb_packet_player_tb/rx_data
add wave -noupdate -group {PKT RX} /ibfb_packet_player_tb/rx_eop
add wave -noupdate -group {PKT RX} /ibfb_packet_player_tb/rx_bad
add wave -noupdate -group {PKT RX} /ibfb_packet_player_tb/rx_good
add wave -noupdate -group {PKT RX} /ibfb_packet_player_tb/rx_pkt
add wave -noupdate /ibfb_packet_player_tb/rx_eop_r
add wave -noupdate /ibfb_packet_player_tb/rx_good_r
add wave -noupdate -expand /ibfb_packet_player_tb/rx_pkt_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12398027 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {4200 ns}
