vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv  +define+TARGET_FPGA=  +define+TARGET_RTL=  +define+TARGET_SYNTHESIS=  +define+TARGET_VIVADO=  +define+TARGET_XILINX= "+incdir+../../../ipstatic" \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93  \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu   +define+TARGET_FPGA=  +define+TARGET_RTL=  +define+TARGET_SYNTHESIS=  +define+TARGET_VIVADO=  +define+TARGET_XILINX= "+incdir+../../../ipstatic" \
"../../../../test.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../test.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

