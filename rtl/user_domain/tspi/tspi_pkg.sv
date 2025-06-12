// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "register_interface/typedef.svh"
`include "obi/typedef.svh"

package tspi_pkg;

// SPI baudrate generation module
typedef struct packed {
    // Configuration registers
    logic [7:0] baudrate_div;
} config_reg_t;



// SPI command controller module
localparam int AddressBits   = 30;

localparam bit [AddressBits-1:0] CMD0_OFFSET = 30'h1FFF_FFFC;
localparam bit [AddressBits-1:0] CMD8_OFFSET = 30'h1FFF_FFF8;
localparam bit [AddressBits-1:0] CMD59_OFFSET = 30'h1FFF_FFF4;
localparam bit [AddressBits-1:0] CMD58_OFFSET = 30'h1FFF_FFF0;
localparam bit [AddressBits-1:0] ACMD41_OFFSET = 30'h1FFF_FFEC;
localparam bit [AddressBits-1:0] BEGINNING_OFFSET = 30'h1FFF_FFE8;
localparam bit [AddressBits-1:0] BUFFER_OFFSET = 30'h1FFF_FFE4;
localparam bit [AddressBits-1:0] CHANGE_BAUDRATE_OFFSET = 30'h1FFF_FFE0;

localparam bit [AddressBits-1:0] READWRITE_MAX_OFFSET = 30'h1FFF_FFD0;

localparam bit [AddressBits-1:0] BLOCK_READWRITE_MIN_OFFSET = 30'h2000_0000;
localparam bit [AddressBits-1:0] BLOCK_READWRITE_MAX_OFFSET = 30'h3FFF_FFFF;

// SPI response checker module
typedef enum bit [2:0] {
    FINAL, // err_o = 1 if not the same, only rvalid_o = 1 if response is correct
    CAUSE_ERROR,  // Continue if the same, err_o = 1 if response is wrong
    CAUSE_VALIDATION,  // Continue if not the same, rvalid_o = 1 if response is correct
    PASSTHROUGH,   // Continue
    VALIDATE,    // Accept any response
    ERROR,        // Overflow or similar
    CHECK_IF_DATA,
    BLOCK_CHECK_IF_DATA
} state_response_t;



endpackage