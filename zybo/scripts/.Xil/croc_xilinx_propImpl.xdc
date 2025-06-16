set_property SRC_FILE_INFO {cfile:/usr/scratch/badile38/sem25f15/croc_tspi/zybo/vivado/test.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc rfile:../../vivado/test.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc id:1 order:EARLY scoped_inst:i_clkwiz/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/usr/scratch/badile38/sem25f15/croc_tspi/zybo/vivado/constraints/zybo-z7.xdc rfile:../../vivado/constraints/zybo-z7.xdc id:2} [current_design]
current_instance i_clkwiz/inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.08
current_instance
set_property src_info {type:XDC file:2 line:250 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -from [get_ports {fetch_en_i}]
set_property src_info {type:XDC file:2 line:278 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter clk_jtag 1.000
set_property src_info {type:XDC file:2 line:300 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -from [get_ports uart_rx_i]
set_property src_info {type:XDC file:2 line:303 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -to [get_ports uart_tx_o]
set_property src_info {type:XDC file:2 line:312 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -through [get_pins -of_objects [get_cells -hier -filter {ORIG_REF_NAME=="sync" || REF_NAME=="sync"}] -filter {NAME=~*serial_i}]
set_property src_info {type:XDC file:2 line:315 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -through [get_pins -of_objects [get_cells -hier -filter {ORIG_REF_NAME =~ cdc_*src* || REF_NAME =~ cdc_*src*}] -filter {NAME =~ *async*}]
set_property src_info {type:XDC file:2 line:317 export:INPUT save:INPUT read:READ} [current_design]
set_false_path -hold -through [get_pins -of_objects [get_cells -hier -filter {ORIG_REF_NAME =~ cdc_*dst* || REF_NAME =~ cdc_*dst*}] -filter {NAME =~ *async*}]
