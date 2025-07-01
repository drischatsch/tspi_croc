# Copyright (c) 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Authors:
# - Paul Scheffler <paulsc@iis.ee.ethz.ch>
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>
# - Cedric Hirschi <cehirschi@student.ethz.ch>

.globl _start
.section .text._start
_start:
  .option push
  .option norelax
  la    x3, __global_pointer$
  .option pop
  la    x2, __stack_pointer$

  /* 2) Copy .data */
  la    t0, __data_load_start    /* Load‐address in BOOTROM */
  la    t1, __data_start         /* Run‐address in SRAM */
  la    t2, __data_end
1:
  beq   t1, t2, 2f              /* done when run‐addr == end */
  lw    t3, 0(t0)
  sw    t3, 0(t1)
  addi  t0, t0, 4
  addi  t1, t1, 4
  j     1b
2:
  /* 3) Zero .bss */
  la    t0, __bss_start
  la    t1, __bss_end
3:
  beq   t0, t1, 4f
  sw    zero, 0(t0)
  addi  t0, t0, 4
  j     3b
4:
  /* 4) Clear caller‐saved regs for a clean C ABI frame */
  li    x1, 0
  li    x4, 0
  li    x5, 0
  li    x6, 0
  li    x7, 0
  li    x8, 0
  li    x9, 0
  li    x10,0
  li    x11,0
  li    x12,0
  li    x13,0
  li    x14,0
  li    x15,0

  /* 5) Call main() */
  call  main

/* 6) If main returns, write its return into ‘status’ and halt */
_eoc:
  la    t0, status
  sw    a0, 0(t0)
  wfi