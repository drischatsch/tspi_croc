// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>

#include "uart.h"
#include "print.h"
#include "timer.h"
#include "gpio.h"
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



int main() {
    uart_init();
    // Read 4 words from SPI base address

    // Test block swapping

    uint32_t temp;

    printf("  STARTING SPI TEST\n");
    uart_write_flush();

    temp = *reg32(BEGINNING_OFFSET, 0);
    printf("  BEGINNING %x\n", temp);
    uart_write_flush();

    *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x18;

    temp = *reg32(CMD0_OFFSET, 0);
    printf("  CMD0 %x\n", temp);
    uart_write_flush();


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

    printf("    DONE INITIALIZATION\n");
    uart_write_flush();

    // // *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x07;


    *reg32(SET_BLOCK_SWAP, 0) = 3;

    temp = *reg32(READWRITE_OFFSET, 0x000); 

    temp = *reg32(READWRITE_OFFSET, 0x200);

    temp = *reg32(READWRITE_OFFSET, 0x400);

    temp = *reg32(READWRITE_OFFSET, 0x600);

    printf("    BLOCKS LOADED\n");




    *reg32(SET_BLOCK_SWAP, 0) = 1;

    // temp = *reg32(READWRITE_OFFSET, 0x800); 
    // printf("  READWRITE NORMAL %x\n", temp);
    // uart_write_flush();

    for(uint32_t i = 0; i <128; i++) {
        *reg32(READWRITE_OFFSET | 0x800, 4*i) = (i * 5 + 7);

    }



    temp = *reg32(READWRITE_OFFSET, 0x000);  

    temp = *reg32(READWRITE_OFFSET, 0x200);

    temp = *reg32(READWRITE_OFFSET, 0x400);

    temp = *reg32(READWRITE_OFFSET, 0x600);

    printf("  DONE RESET\n");
    uart_write_flush();


    uint32_t count_mistakes = 0;


    for(uint32_t i = 0; i <128; i++) {
        temp = *reg32(READWRITE_OFFSET| 0x800, 4*i);
        if(temp != (i * 5 + 7)) {
            count_mistakes++;
        }
    }


    if(count_mistakes == 0) {
        printf("  No mistakes\n");
    } else {
        printf("  %x mistakes\n", count_mistakes);
    }
    uart_write_flush();

    // count_mistakes = 0;

    // for(uint32_t i = 0; i <128; i++) {
    //     temp = *reg32(READWRITE_OFFSET | 0xA00, 4*i);
    //     printf("  READ FROM 0xA00 %x\n", temp);
    //     uart_write_flush();
    //     if(temp != (i * 2 + 5)) {
    //         count_mistakes++;
    //     }
    // }
    // if(count_mistakes == 0) {
    //     printf("  No mistakes\n");
    // } else {
    //     printf("  %x mistakes\n", count_mistakes);
    // }
    // uart_write_flush();







    


    // *reg32(SET_BLOCK_SWAP, 0) = 3;
    // printf("Set load only and Block_swap \n");
    // uart_write_flush();

    // // *reg32(TRANSPARENT_READWRITE_OFFSET, 0) = 0x888;

    // // temp = *reg32(READWRITE_OFFSET, 0); 

    // temp = *reg32(READWRITE_OFFSET, 0x200);
    // printf("  READWRITE1 %x\n", temp);
    // uart_write_flush();

    // temp = *reg32(READWRITE_OFFSET, 0x400);
    // printf("  READWRITE2 %x\n", temp);
    // uart_write_flush();


    // temp = *reg32(READWRITE_OFFSET, 0x600);
    // printf("  READWRITE3 %x\n", temp);
    // uart_write_flush();


    // // *reg32(READWRITE_OFFSET, 0) = 0x888;
    // // printf("Successfully wrote 0x888 to READWRITE\n");


    // // *reg32(READWRITE_OFFSET, 0) = 0x888; 


    // // temp = *reg32(READWRITE_OFFSET, 0);
    

    // *reg32(SET_BLOCK_SWAP, 0) = 1;
    // printf("Set only Block_swap \n");
    // uart_write_flush();


    // *reg32(READWRITE_OFFSET, 0x800) = 0x888;

    // temp = *reg32(READWRITE_OFFSET, 0x800); 
    // printf("  READWRITE NORMAL %x\n", temp);
    // uart_write_flush();




    // temp = *reg32(READWRITE_OFFSET, 0x1000);
    // printf("  Second readwrite %x\n", temp);
    // uart_write_flush();




    
    // uint32_t temp;
    // temp = *reg32(BEGINNING_OFFSET, 0);
    // printf("  BEGINNING %x\n", temp);
    // uart_write_flush();

    // *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x18;

    // temp = *reg32(CMD0_OFFSET, 0);
    // printf("  CMD0 %x\n", temp);
    // uart_write_flush();


    // temp = *reg32(CMD8_OFFSET, 0);
    // printf("  CMD8 %x\n", temp);
    // uart_write_flush();

    // // temp = *reg32(BUFFER_OFFSET, 0);
    // // printf("  BUFFER %x\n", temp);
    // // uart_write_flush();
    
    // temp = *reg32(CMD59_OFFSET, 0);
    // printf("  CMD59 %x\n", temp);
    // uart_write_flush();


    // temp = *reg32(CMD58_OFFSET, 0);
    // printf("  CMD58 %x\n", temp);
    // uart_write_flush();


    // // Configure SPI: Set clock divider (register at offset 12).
    // temp = *reg32(ACMD41_OFFSET, 0);
    // printf("  ACMD41 %x\n", temp);
    // uart_write_flush();

    // *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x07;


   


    // uint32_t count_mistakes = 0;
    // uint32_t write_value;
    // uint32_t read_value;

    // printf("  Write 16 in series \n");
    // uart_write_flush();

    // for(uint32_t i = 0; i < 16; i++) {
    //     write_value = i * 7 + 10;
    //     *reg32(READWRITE_OFFSET, i * 4 + 0x1000) = write_value;
    // }

    // printf("  Read 16 in series \n");
    // uart_write_flush();

    // *reg32(CHANGE_BAUDRATE_OFFSET, 0) = 0x02;

    // for(uint32_t i = 0; i < 16; i++) {
    //     write_value = i * 7 + 10;
    //     read_value = *reg32(READWRITE_OFFSET, i * 4 + 0x1000);
    //     for(uint32_t j = 0; j < 128; j++) {
    //         temp = *reg32(BUFFER_OFFSET, 0);
    //     }
    //     if(read_value != write_value) {
    //         count_mistakes++;
    //     }
    // }
    // if(count_mistakes == 0) {
    //     printf("  No mistakes\n");
    // } else {
    //     printf("  %x mistakes\n", count_mistakes);
    // }
    // uart_write_flush();

    return 1;
}
