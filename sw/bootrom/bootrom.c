// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Cedric Hirschi <cehirschi@student.ethz.ch>

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

#define RETRY_COUNTER_ADDR 0x10000100
#define RETRY_COUNTER *reg32(RETRY_COUNTER_ADDR, 0)

#define BOOT_AFTER_ADDR_ADDR 0x03000018
#define BOOT_AFTER_ADDR *reg32(BOOT_AFTER_ADDR_ADDR, 0)
#define BOOT_AFTER_SD_ADDR_ADDR 0x0300001C
#define BOOT_AFTER_SD_ADDR *reg32(BOOT_AFTER_SD_ADDR_ADDR, 0)

int main() {

    *reg32(SET_BLOCK_SWAP, 0) = 0;

    
    uart_init();
    printf("BR>> Started\n");
    uart_write_flush();

    

    RETRY_COUNTER += 1;
    if (RETRY_COUNTER > NUM_RETRIES) {
        printf("BR>> Resetting retry counter\n");
        uart_write_flush();
        RETRY_COUNTER = 0;
    }
    
    if (RETRY_COUNTER == NUM_RETRIES) {
        printf("BR>> Too many retries, skipping initialization!\n");
        uart_write_flush();
    } else {
        printf("BR>> Try %x\n", RETRY_COUNTER + 1);
        uart_write_flush();

        
        *reg32(BEGINNING_OFFSET, 0);
        *reg32(CMD0_OFFSET, 0);
        *reg32(CMD8_OFFSET, 0);
        *reg32(CMD59_OFFSET, 0);
        *reg32(CMD58_OFFSET, 0);
        *reg32(ACMD41_OFFSET, 0);

        *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x20;

        printf("BR>> TSPI initialized\n");
        uart_write_flush();

        *reg32(SET_BLOCK_SWAP, 0) = 3;

        *reg32(READWRITE_OFFSET, 0x000); 
        *reg32(READWRITE_OFFSET, 0x200);
        *reg32(READWRITE_OFFSET, 0x400);
        *reg32(READWRITE_OFFSET, 0x600);
        *reg32(READWRITE_OFFSET, 0x800);
        *reg32(READWRITE_OFFSET, 0xA00);
        *reg32(READWRITE_OFFSET, 0xC00);
        *reg32(READWRITE_OFFSET, 0xE00);
        *reg32(READWRITE_OFFSET + 0x1000, 0x000);
        *reg32(READWRITE_OFFSET + 0x1000, 0x200);
        *reg32(READWRITE_OFFSET + 0x1000, 0x400);
        *reg32(READWRITE_OFFSET + 0x1000, 0x600);


        printf("BR>> Blocks loaded\n");
        uart_write_flush();

        *reg32(SET_BLOCK_SWAP, 0) = 1;

        printf("BR>> Done!\n");
        uart_write_flush();


        // Jump to start of SD-Card mapped SRAM
        printf("BR>> Jumping to 0x%x\n", BOOT_AFTER_SD_ADDR);
        uart_write_flush();
        asm volatile (
            "mv t0, %0\n"
            "jr t0\n"
            :
            : "r"(BOOT_AFTER_SD_ADDR)
            : "t0"
        );

        // Read a0 (return value)
        uint32_t a0;
        asm volatile (
            "mv %0, a0\n"
            : "=r"(a0)
        );
        printf("BR>> Return value from SD Card: 0x%x\n", a0);
        uart_write_flush();

        // Wait for interrupt indefinitely
        while (1) {
            asm volatile ("wfi");
        }
    }

    
    // Jump to start of SRAM
    printf("BR>> Jumping to 0x%x\n", BOOT_AFTER_ADDR);
    uart_write_flush();
    asm volatile (
        "mv t0, %0\n"
        "jr t0\n"
        :
        : "r"(BOOT_AFTER_ADDR)
        : "t0"
    );

    // Read a0 (return value)
    uint32_t a0;
    asm volatile (
        "mv %0, a0\n"
        : "=r"(a0)
    );
    printf("BR>> Return value from SRAM: 0x%x\n", a0);
    uart_write_flush();

    // Wait for interrupt indefinitely
    while (1) {
        asm volatile ("wfi");
    }

    return 1;
}