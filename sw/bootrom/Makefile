# Copyright (c) 2025 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Paul Scheffler <paulsc@iis.ee.ethz.ch>
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>
# - Cedric Hirschi <cehirschi@ethz.ch>

SRCDIR   ?= ../lib/src
INCDIR   ?= ../lib/inc
BUILDDIR ?= build

LINK ?= link.ld

# Toolchain

RISCV_XLEN    ?= 32
RISCV_MARCH   ?= rv$(RISCV_XLEN)im_zicsr_zba_zbb_zbc_zbs
RISCV_MABI    ?= ilp32
RISCV_PREFIX  ?= riscv64-unknown-elf-
RISCV_CC      ?= $(RISCV_PREFIX)gcc
RISCV_CXX     ?= $(RISCV_PREFIX)g++
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy
RISCV_AS      ?= $(RISCV_PREFIX)as
RISCV_AR      ?= $(RISCV_PREFIX)ar
RISCV_LD      ?= $(RISCV_PREFIX)ld
RISCV_STRIP   ?= $(RISCV_PREFIX)strip

PICOLIBC ?= /usr/lib/picolibc/riscv64-unknown-elf

RISCV_FLAGS    ?= -march=$(RISCV_MARCH) -mabi=$(RISCV_MABI) -mcmodel=medany -static -std=gnu99 -Os -nostdlib -fno-builtin -ffreestanding
RISCV_FLAGS    += -ffunction-sections -fdata-sections -fno-common -Wall -Wextra -Werror
RISCV_CCFLAGS  ?= $(RISCV_FLAGS) -I.. -I../include -I$(INCDIR) -I$(PICOLIBC)/include -I$(CURDIR)
RISCV_CXXFLAGS ?= $(RISCV_FLAGS)
RISCV_LDFLAGS  ?= -static -nostartfiles -Wl,--gc-sections -L$(PICOLIBC)/lib -lgcc $(RISCV_FLAGS)

# Get all directories in APPDIR
APPS = $(patsubst $(APPDIR)/%,%,$(shell find $(APPDIR) -mindepth 1 -maxdepth 1 -type d))
APPS += $(BUILDDIR)/bootrom_embed.hex

SRCOBJS = $(patsubst $(SRCDIR)/%.c,$(BUILDDIR)/%.o,$(wildcard $(SRCDIR)/*.c))
SRCOBJS += $(patsubst $(SRCDIR)/%.S,$(BUILDDIR)/%.o,$(wildcard $(SRCDIR)/*.S))
SRCOBJS += $(BUILDDIR)/bootrom.o

.PHONY: clean bootrom_hex

bootrom_hex: $(BUILDDIR)/bootrom_embed.hex

$(BUILDDIR)/bootrom.hex: $(SRCOBJS)
	$(info Building bootrom)
	$(info [CC] bootrom.elf)
	@$(RISCV_CC) $(RISCV_CCFLAGS) $(SRCOBJS) crt0.S -o $(BUILDDIR)/bootrom.elf $(RISCV_LDFLAGS) -T$(LINK)
	$(info [CP] bootrom.hex)
	@$(RISCV_OBJCOPY) -O verilog $(BUILDDIR)/bootrom.elf $(BUILDDIR)/bootrom.hex
	$(info [DP] bootrom.dump)
	@$(RISCV_OBJDUMP) -D -s $(BUILDDIR)/bootrom.elf > $(BUILDDIR)/bootrom.dump
	$(info DONE)

%.clean:
	rm -rf $(BUILDDIR)/$*.*

$(BUILDDIR)/%.o: $(SRCDIR)/%.c $(BUILDDIR)
	$(info [CC] $<)
	@$(RISCV_CC) $(RISCV_CCFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: %.c $(BUILDDIR)
	$(info [CC] $<)
	@$(RISCV_CC) $(RISCV_CCFLAGS) -c $< -o $@

$(BUILDDIR)/bootrom_embed.hex: $(BUILDDIR)/bootrom.hex
	$(info [GEN] bootrom_embed.hex)
	python3 gen_bootrom.py

clean:
	$(info Cleaning)
	@rm -rf $(BUILDDIR)

$(BUILDDIR):
	$(info Creating build directory)
	@mkdir -p $(BUILDDIR)

# Include all dependencies
-include $(wildcard $(BUILDDIR)/*.d)

.PRECIOUS: $(BUILDDIR)/%.o
.PREREQUISITES: $(BUILDDIR)