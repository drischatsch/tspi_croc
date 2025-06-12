// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "timer.h"
#include "gpio.h"
#include "util.h"

#define TB_FREQUENCY 6250000
#define TB_BAUDRATE    57600

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



int main() {
    uart_init();
    // Read 4 words from SPI base address

    // Test block swapping

    uint32_t temp;
    uint32_t count_mistakes = 0;


    temp = *reg32(BEGINNING_OFFSET, 0);
    // printf("  BEGINNING %x\n", temp);
    // uart_write_flush();


    temp = *reg32(CMD0_OFFSET, 0);
    // printf("  CMD0 %x\n", temp);
    // uart_write_flush();


    temp = *reg32(CMD8_OFFSET, 0);
    // printf("  CMD8 %x\n", temp);
    // uart_write_flush();

    // temp = *reg32(BUFFER_OFFSET, 0);
    // printf("  BUFFER %x\n", temp);
    // uart_write_flush();
    
    temp = *reg32(CMD59_OFFSET, 0);
    // printf("  CMD59 %x\n", temp);
    // uart_write_flush();


    temp = *reg32(CMD58_OFFSET, 0);
    // printf("  CMD58 %x\n", temp);
    // uart_write_flush();


    temp = *reg32(ACMD41_OFFSET, 0);
    // printf("  ACMD41 %x\n", temp);
    // uart_write_flush();

    *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x18;

    printf("    DONE INITIALIZATION SPI\n");
    uart_write_flush();

    // // *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x07;


    *reg32(SET_BLOCK_SWAP, 0) = 3;

    temp = *reg32(READWRITE_OFFSET, 0x000); 

    temp = *reg32(READWRITE_OFFSET, 0x200);

    temp = *reg32(READWRITE_OFFSET, 0x400);

    temp = *reg32(READWRITE_OFFSET, 0x600);

    printf("    BLOCKS LOADED\n");

    *reg32(SET_BLOCK_SWAP, 0) = 1;

    return 1;
}