source ../scripts/common.tcl


# TODO: Add the clk_wiz_0.xci file here (Generated from the IP Catalog in Vivado)
set clkwiz_dir ${vivado_dir}/ips

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0 -dir ${clkwiz_dir}
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {80.0} \
  CONFIG.CLKOUT1_JITTER {172.798} \
  CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {20.000} \
  CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
  CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {50.000} \
  CONFIG.PRIM_IN_FREQ {125.000} \
] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files ${clkwiz_dir}/clk_wiz_0/clk_wiz_0.xci]
generate_target all [get_files  ${clkwiz_dir}/clk_wiz_0/clk_wiz_0.xci]
catch { config_ip_cache -export [get_ips -all clk_wiz_0] }
export_ip_user_files -of_objects [get_files ${clkwiz_dir}/clk_wiz_0/clk_wiz_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ${clkwiz_dir}/clk_wiz_0/clk_wiz_0.xci]
launch_runs clk_wiz_0_synth_1 -jobs 8
wait_on_run clk_wiz_0_synth_1
