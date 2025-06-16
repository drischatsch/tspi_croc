transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr  +define+TARGET_FPGA=  +define+TARGET_RTL=  +define+TARGET_SYNTHESIS=  +define+TARGET_VIVADO=  +define+TARGET_XILINX= "+incdir+../../../ipstatic" -l xpm -l xil_defaultlib \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"/usr/pack/vitis-2023.2-zr/Vivado/2023.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5  +define+TARGET_FPGA=  +define+TARGET_RTL=  +define+TARGET_SYNTHESIS=  +define+TARGET_VIVADO=  +define+TARGET_XILINX= "+incdir+../../../ipstatic" -l xpm -l xil_defaultlib \
"../../../../test.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../test.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

