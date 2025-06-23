// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>

#include "uart.h"
#include "print.h"
#include "util.h"

#define TEST_FPGA 0
#define NUM_RETRIES 3

#if TEST_FPGA
// Reduce frequency to 6.25 MHz for FPGA testing
#define TB_FREQUENCY 6250000
#define TB_BAUDRATE    57600
#endif

#define CMD0_OFFSET 0x5FFFFFFC
#define CMD8_OFFSET 0x5FFFFFF8
#define CMD59_OFFSET 0x5FFFFFF4
#define CMD58_OFFSET 0x5FFFFFF0
#define ACMD41_OFFSET 0x5FFFFFEC
#define BEGINNING_OFFSET 0x5FFFFFE8
#define BUFFER_OFFSET 0x5FFFFFE4
#define CHANGE_BAUDRATE_OFFSET  0x5FFFFFE0
#define READWRITE_OFFSET        0x60000000
#define TRANSPARENT_READWRITE_OFFSET 0x40000000

#define SET_BLOCK_SWAP 0x20010000

#define BOOT_AFTER_ADDR 0x10000000

#define ERROR_VARIABLE_ADDR 0x10000100
#define ERROR_VARIABLE *reg32(ERROR_VARIABLE_ADDR, 0)


int main() {
    uart_init();
    printf("BR>> Started\n");
    uart_write_flush();

    ERROR_VARIABLE += 1;
    if (ERROR_VARIABLE > NUM_RETRIES) {
        printf("BR>> Resetting ERROR_VARIABLE\n");
        uart_write_flush();
        ERROR_VARIABLE = 0;
    }

    printf("BR>> Try %x\n", ERROR_VARIABLE);
    uart_write_flush();
    if (ERROR_VARIABLE < NUM_RETRIES) {
        *reg32(SET_BLOCK_SWAP, 0) = 0;


        uint32_t temp;

        temp = *reg32(BEGINNING_OFFSET, 0);
        temp = *reg32(CMD0_OFFSET, 0);
        temp = *reg32(CMD8_OFFSET, 0);
        temp = *reg32(CMD59_OFFSET, 0);
        temp = *reg32(CMD58_OFFSET, 0);
        temp = *reg32(ACMD41_OFFSET, 0);

        *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x18;

        printf("BR>> TSPI initialized\n");
        uart_write_flush();

        *reg32(SET_BLOCK_SWAP, 0) = 3;

        temp = *reg32(READWRITE_OFFSET, 0x000); 
        temp = *reg32(READWRITE_OFFSET, 0x200);
        temp = *reg32(READWRITE_OFFSET, 0x400);
        temp = *reg32(READWRITE_OFFSET, 0x600);

        printf("BR>> Blocks loaded\n");
        uart_write_flush();

        *reg32(SET_BLOCK_SWAP, 0) = 1;

        printf("BR>> Done!\n");
        uart_write_flush();
    }

    if (ERROR_VARIABLE == NUM_RETRIES)
    {
        printf("BR>> Unused!\n");
        uart_write_flush();
    }

    // Jump to start of SRAM
    printf("BR>> Jumping to 0x%x\n", BOOT_AFTER_ADDR);
    uart_write_flush();
    asm volatile (
        "mv a0, %0\n"
        "jr a0\n"
        :
        : "r"(BOOT_AFTER_ADDR)
        : "a0"
    );

    return 1;
}