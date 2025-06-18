// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
// #include "timer.h"
// #include "gpio.h"
#include "util.h"

// #define TB_FREQUENCY 6250000
// #define TB_BAUDRATE    57600

// #define SPI_BASE_ADDR 0x0300D000

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

// How do I store this at the beginning of the Bootrom?
// Also don't erase the value main_cancelled_count
static int main_cancelled_count = 0;

// Error handler function
void error_handler(const char* msg) {
    main_cancelled_count++;
    printf("Error: %s. Main cancelled. Cancel count: %d\n", msg, main_cancelled_count);
    uart_write_flush();
    // Optionally, reset or halt here
}



int main() {
    uart_init();
    printf("Bootrom started\n");
    uart_write_flush();

    *reg32(SET_BLOCK_SWAP, 0) = 0;

    if (0 && main_cancelled_count < 3) {
       uint32_t temp;

        temp = *reg32(BEGINNING_OFFSET, 0);

        temp = *reg32(CMD0_OFFSET, 0);

        temp = *reg32(CMD8_OFFSET, 0);

        temp = *reg32(CMD59_OFFSET, 0);

        temp = *reg32(CMD58_OFFSET, 0);

        temp = *reg32(ACMD41_OFFSET, 0);


        *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x18;

        printf("    DONE INITIALIZATION SPI\n");
        uart_write_flush();


        *reg32(SET_BLOCK_SWAP, 0) = 3;

        temp = *reg32(READWRITE_OFFSET, 0x000); 

        temp = *reg32(READWRITE_OFFSET, 0x200);

        temp = *reg32(READWRITE_OFFSET, 0x400);

        temp = *reg32(READWRITE_OFFSET, 0x600);

        printf("    BLOCKS LOADED\n");

        *reg32(SET_BLOCK_SWAP, 0) = 1;

        printf("Bootrom finished successfully\n");
        uart_write_flush();
    }

    // Jump to start of SRAM (0x10000000)
    asm volatile (
        "la a0, 0x10000000\n" // Load address of SRAM start into a0
        "jr a0\n"            // Jump to the address in a0
    );


    return 1;
}