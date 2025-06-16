source ../scripts/common.tcl

# Workaround needed until Zybo board is installed in /usr/pack
# set_param board.repoPaths {/home/sem25f15/.Xilinx/Vivado/2023.2/xhub/board_store/xilinx_board_store}

# Create new project (Change the project name if wanted)
create_project test ${vivado_dir} -force -part ${device}
# set_property board_part ${board} [current_project]


# Set constraints file
add_files -fileset constrs_1 -norecurse ${constr_dir}/zybo-z7.xdc

# set_property strategy ${synth_strategy} [get_runs synth_1]
# set_property strategy ${impl_strategy} [get_runs impl_1]

# Read in sources
source ${scripts_dir}/add_sources.tcl
set_property top ${top} [current_fileset]
update_compile_order -fileset sources_1

