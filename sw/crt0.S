# Copyright (c) 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0/
#
# Authors:
# - Cedric Hirschi <cehirschi@student.ethz.ch>

.globl _start
.section .text._start
_start:
  call main
_eoc:
  la      t0, status
  sw      a0, 0(t0)
  wfi
