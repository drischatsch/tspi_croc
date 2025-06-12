// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"



module tspi_baudgeneration import tspi_pkg::*; #() 
(
    input logic clk_i,
    input logic rst_ni,

    output logic baudrate_o,

    input logic run_i,

    input logic new_req_i,

    input config_reg_t config_reg_i
);


    //-- Configuration Signals ---------------------------------------------------------------------
    logic        divisor_valid;

    //-- Baud Signals ------------------------------------------------------------------------------
    logic       baud_clear;
    logic [7:0] baud_count;

    //-- Generate clk ------------------------------------------------------------------------------
    logic clk_state_d;
    logic clk_state_q;

    // Check if the divisor is valid (non-zero)
    assign divisor_valid = ~(config_reg_i.baudrate_div == 0) & run_i;

    // Output the current state of the clock
    assign baudrate_o = clk_state_q;

    // Always block to handle baud rate generation
    always_comb begin
        if(run_i) begin
            baud_clear = 1'b0; // Default value for baud_clear
            if (baud_count == config_reg_i.baudrate_div) begin
                clk_state_d = ~clk_state_q; // Toggle clock state
                baud_clear = 1'b1; // Clear the baud counter
            end else if(new_req_i) begin
                clk_state_d = 1'b1;
            end else begin
                clk_state_d = clk_state_q; // Maintain current clock state DONE: posedge on run_i posedge
            end
        end else begin
            baud_clear = 1'b1; //TODO: Change to not running during powerdown
            clk_state_d = 1'b0; 
        end
    end


    counter #(
    .WIDTH          (8), 
    .STICKY_OVERFLOW(0)
    ) i_baudrate_counter (
    .clk_i, 
    .rst_ni,
    .clear_i   ( baud_clear               ), // Synchronous clear: Sets Counter 0 in the next cycle
    .en_i      ( divisor_valid            ), // Count while valid divisor      
    .load_i    ( 1'b0                     ), 
    .down_i    ( 1'b0                     ), // Count upwards
    .d_i       ( '0                       ),
    .q_o       ( baud_count               ),
    .overflow_o(                          )
    );


    `FF(clk_state_q, clk_state_d, '0, clk_i, rst_ni)
    




endmodule
