# Copyright (c) 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>

# Tools
BENDER	  ?= bender
PYTHON3   ?= python3
VERILATOR ?= /foss/tools/bin/verilator
YOSYS     ?= yosys
OPENROAD  ?= openroad
KLAYOUT   ?= klayout
VSIM      ?= vsim
REGTOOL    ?= $(PYTHON3) vendor/register_interface/vendor/lowrisc_opentitan/util/regtool.py

# Directories
# directory of the path to the last called Makefile (this one)
PROJ_DIR  := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))


default: help

reggen:
	$(REGTOOL) rtl/soc_ctrl/soc_ctrl_regs.hjson -d -o rtl/soc_ctrl/soc_ctrl.md
	$(REGTOOL) rtl/soc_ctrl/soc_ctrl_regs.hjson -D -o rtl/soc_ctrl/soc_ctrl.h
	$(REGTOOL) rtl/soc_ctrl/soc_ctrl_regs.hjson -r -t rtl/soc_ctrl

.PHONY: reggen

################
# Dependencies #
################
# Download RCX file used for parasitic extraction from ORFS (configuration got ok by IHP)
IHP_RCX_URL  := "https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/7747f88f70daaeb63f43ce36e71829707b7e3fa7/flow/platforms/ihp-sg13g2/IHP_rcx_patterns.rules"
IHP_RCX_FILE := $(PROJ_DIR)/openroad/IHP_rcx_patterns.rules

## Checkout/update dependencies using Bender
checkout: $(IHP_RCX_FILE)
	$(BENDER) checkout
	git submodule update --init --recursive

$(IHP_RCX_FILE): 
	curl -L -o $@ $(IHP_RCX_URL)

## Reset dependencies (without updating Bender.lock)
clean-deps:
	rm -rf .bender
	git submodule deinit -f --all

.PHONY: checkout clean-deps


############
# Software #
############
SW_HEX := sw/bin/helloworld_sram.hex

$(SW_HEX): sw/*.c sw/*.h sw/*.S sw/*.ld
	$(MAKE) -C sw/ compile
	$(MAKE) -C sw/bootrom

## Build all top-level programs in sw/
software: $(SW_HEX)

sw: $(SW_HEX)

.PHONY: software sw

##################
# RTL Simulation #
##################
# Questasim/Modelsim/vsim
VLOG_ARGS  = -svinputport=compat
VSIM_ARGS  = -t 1ns -voptargs=+acc
VSIM_ARGS += -suppress vsim-3009 -suppress vsim-8683 -suppress vsim-8386

vsim/compile_rtl.tcl: Bender.lock Bender.yml
	$(BENDER) script vsim -t rtl -t vsim -t simulation -t verilator -DSYNTHESIS -DSIMULATION  --vlog-arg="$(VLOG_ARGS)" > $@

vsim/compile_netlist.tcl: Bender.lock Bender.yml
	$(BENDER) script vsim -t ihp13 -t vsim -t simulation -t verilator -t netlist_yosys -DSYNTHESIS -DSIMULATION > $@

## Simulate RTL using Questasim/Modelsim/vsim
vsim: vsim/compile_rtl.tcl $(SW_HEX) bootrom
	rm -rf vsim/work
	cd vsim; $(VSIM) -c -do "source compile_rtl.tcl; exit"
	cd vsim; $(VSIM) +binary="$(realpath $(SW_HEX))" -gui tb_croc_soc $(VSIM_ARGS)

## Simulate netlist using Questasim/Modelsim/vsim
vsim-yosys: vsim/compile_netlist.tcl $(SW_HEX) yosys/out/croc_chip_yosys_debug.v
	rm -rf vsim/work
	cd vsim; $(VSIM) -c -do "source compile_netlist.tcl; source compile_tech.tcl; exit"
	cd vsim; $(VSIM) -gui tb_croc_soc $(VSIM_ARGS)


# Verilator
# Turn off style warnings and well-defined SystemVerilog warnings that should be part of -Wno-style
VERILATOR_ARGS = -Wno-fatal -Wno-style \
	-Wno-BLKANDNBLK -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-WIDTHCONCAT -Wno-ASCRANGE

VERILATOR_ARGS += --binary -j 0
VERILATOR_ARGS += --timing --autoflush --trace-fst --trace-threads 2 --trace-structs
VERILATOR_ARGS +=  --unroll-count 1 --unroll-stmts 1
VERILATOR_ARGS += --x-assign fast --x-initial fast
VERILATOR_CFLAGS += -O3 -march=native -mtune=native

verilator/croc.f: Bender.lock Bender.yml
	$(BENDER) script verilator -t rtl -t verilator -DSYNTHESIS -DVERILATOR > $@

verilator/obj_dir/Vtb_croc_soc: verilator/croc.f $(SW_HEX) bootrom
	cd verilator; $(VERILATOR) $(VERILATOR_ARGS) -O3 --top tb_croc_soc -f croc.f

## Simulate RTL using Verilator
verilator: verilator/obj_dir/Vtb_croc_soc
	cd verilator; obj_dir/Vtb_croc_soc +binary="$(realpath $(SW_HEX))"

.PHONY: verilator vsim vsim-yosys


####################
# Bootrom          #
####################
bootrom:
	make -C sw/bootrom

.PHONY: bootrom

####################
# Open Source Flow #
####################
# Bender manages the different IPs and can be used to generate file-lists for synthesis
TOP_DESIGN     ?= croc_chip
DUT_DESIGN	   ?= croc_soc
BENDER_TARGETS ?= asic ihp13 rtl synthesis
SV_DEFINES     ?= VERILATOR SYNTHESIS COMMON_CELLS_ASSERTS_OFF

## Generate croc.flist used to read design in yosys
yosys-flist: Bender.lock Bender.yml rtl/*/Bender.yml bootrom
	$(BENDER) script flist-plus $(foreach t,$(BENDER_TARGETS),-t $(t)) $(foreach d,$(SV_DEFINES),-D $(d)=1) > $(PROJ_DIR)/croc.flist

include yosys/yosys.mk
include openroad/openroad.mk

yosys: yosys-flist yosys_synth

klayout/croc_chip.gds: $(OR_OUT)/croc.def klayout/*.sh klayout/*.py
	./klayout/def2gds.sh

## Generate merged .gds from openroads .def output
klayout: klayout/croc_chip.gds

.PHONY: klayout yosys-flist


#################
# Documentation #
#################

help: Makefile
	@printf "Available targets:\n------------------\n"
	@for mkfile in $(MAKEFILE_LIST); do \
		awk '/^[a-zA-Z\-\_0-9]+:/ { \
			helpMessage = match(lastLine, /^## (.*)/); \
			if (helpMessage) { \
				helpCommand = substr($$1, 0, index($$1, ":")-1); \
				helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
				printf "%-20s %s\n", helpCommand, helpMessage; \
			} \
		} \
		{ lastLine = $$0 }' $$mkfile; \
	done

.PHONY: help

# .zip file to submit, includes:
# - Everything in openroad/out/
# - klayout/*.gds
# - Everything in sw/
submit:
	@echo "Creating submission archive..."
	@rm -rf submit
	@mkdir -p submit
	@echo * > submit/.gitignore
	@echo " - openroad/out/"
	@cp -r openroad/out/ submit/
	@echo " - klayout/croc_chip.gds"
	@cp klayout/croc_chip.gds submit/
	@echo " - sw/"
	@cp -r sw/ submit/
	@zip -r submission.zip submit
	@echo "Submission archive created: croc_chip_submission.zip"

.PHONY: submit


###########
# Cleanup #
###########

## Delete generated files and directories
clean: 
	rm -f $(SV_FLIST)
	rm -f klayout/croc_chip.gds
	rm -rf verilator/obj_dir/
	rm -f verilator/croc.f
	rm -f verilator/croc.vcd
	$(MAKE) ys_clean
	$(MAKE) or_clean
	$(MAKE) -C sw clean
	$(MAKE) -C sw/bootrom clean

.PHONY: clean
