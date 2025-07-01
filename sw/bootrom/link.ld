/* Copyright (c) 2024 ETH Zurich and University of Bologna.
 * Licensed under the Apache License, Version 2.0, see LICENSE for details.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Authors:
 * - Paul Scheffler <paulsc@iis.ee.ethz.ch>
 * - Philippe Sauter <phsauter@iis.ee.ethz.ch> 
 * - Cedric Hirschi <cehirschi@student.ethz.ch>
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY 
{
   USERROM (r)      : ORIGIN = 0x02000000, LENGTH = 32
   BOOTROM (rx)     : ORIGIN = 0x0300D000, LENGTH = 4K
   SRAM    (rwxail) : ORIGIN = 0x10000000, LENGTH = 2K
}

SECTIONS
{
  /DISCARD/ : { 
    *(.riscv.attributes)
    *(.comment)
  }

  /* Entry point and text in BOOTROM */
  .text._start :
  {
    *(.text._start)
  } > BOOTROM

  .text : {
    *(.text)
    *(.text.*)
  } > BOOTROM

  /* Read-only data in BOOTROM */
  .rodata :
  {
    *(.rodata)
    *(.rodata.*)
  } > BOOTROM

  /* Initialized data: load from BOOTROM, run in RAM */
  .data :
  {
    *(.data)
    *(.data.*)
  } >SRAM AT>BOOTROM

  /* Small‐data: same as .data */
  .sdata :
  {
    *(.sdata)
    *(.sdata.*)
  } >SRAM AT>BOOTROM

  /* Uninitialized data (bss) in RAM */
  .bss :
  {
    *(.bss)
    *(COMMON)
  } > SRAM

  /* Global and stack pointers */
  __global_pointer$ = ADDR(.sdata) + SIZEOF(.sdata) / 2;
  __stack_pointer$  = ORIGIN(SRAM) + LENGTH(SRAM);

  /* Status or other symbols */
  status = 0x03000008;

  __data_load_start = LOADADDR(.data);
  __data_start      = ADDR(.data);
  __data_end        = ADDR(.data) + SIZEOF(.data) + SIZEOF(.sdata);
  __bss_start       = ADDR(.bss);
  __bss_end         = ADDR(.bss) + SIZEOF(.bss);
}