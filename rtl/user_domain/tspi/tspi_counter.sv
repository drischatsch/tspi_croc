// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module tspi_counter import tspi_pkg::*; #()
(   
    input logic clk_i,
    input logic tspi_clk_i,
    input logic rst_ni,

    input logic new_req_i,
    input logic [7:0] cnt_cmd_i,
    input logic [5:0] len_cmd_i,

    output logic [7:0] cnt_cmd_o,

    output logic [5:0] len_cmd_o,
    output logic new_cmd_o,

    input logic start_bit_i,

    output logic last_bit_o
);


    // Internal signals for the counter command and count
    logic [7:0] cnt_cmd_d, cnt_cmd_q; 
    logic new_req_d, new_req_q;
    logic short_new_cmd;

    //logic [7:0] fast_cnt_cmd_d, fast_cnt_cmd_q;
    //logic [5:0] len_cmd_d, len_cmd_q;
    logic [5:0] count;

    logic counter_done;



    // Determine if the counter has completed its operation
    assign counter_done = (len_cmd_i == count);

    // Assignments for outputs
    assign len_cmd_o = len_cmd_i;

    assign short_new_cmd = counter_done | new_req_q | start_bit_i;
    assign new_cmd_o = (count == 0); // TODO: Maybe dependent on cnt_cmt_d and cnt_cmd_q
    assign last_bit_o = counter_done; // TODO: Check: | new_req_q



    assign cnt_cmd_o = cnt_cmd_q;

    // Assignment to delay new request
    assign new_req_d = new_req_i;

    // Update the next state of the counter command
    always_comb begin
        if(new_req_q) begin
            cnt_cmd_d = cnt_cmd_i;
        end else begin
            cnt_cmd_d = cnt_cmd_q - (counter_done & 8'd1);
        end
    end
    // Instantiate counter module
    // counter #(
    // .WIDTH          (6),
    // .STICKY_OVERFLOW(0)   
    // ) i_baudrate_counter (
    // .clk_i(clk_i),                
    // .rst_ni,               
    // .clear_i   ( short_new_cmd            ), // Synchronous clear: Sets Counter 0 in the next cycle
    // .en_i      ( enable                     ), // Enable counting
    // .load_i    ( 1'b0                     ), 
    // .down_i    ( 1'b0                     ), // Count upwards
    // .d_i       ( '0                       ),
    // .q_o       ( count                    ), // Counter output
    // .overflow_o(                          ) 
    // );

    // Own counter:
    logic [5:0] count_d, count_q;
    always_comb begin
        if(short_new_cmd && enable) begin
            count_d = 6'd0; // Reset the counter on new request or start bit
        end else if (enable) begin
            count_d = count_q + 6'd1; // Increment the counter
        end else begin
            count_d = count_q; // Hold the current value
        end
    end
    assign count = count_q; // Assign the current count value to the output
    `FFL(count_q, count_d, enable, '0, clk_i, rst_ni)


    // Flip-flop to store the current state of the counter command
    // `FF(fast_cnt_cmd_q, fast_cnt_cmd_d, '0, clk_i, rst_ni)
    // `FF(cnt_cmd_q, cnt_cmd_d, '0, tspi_clk_i, rst_ni)
    logic edge_detect_d, edge_detect_q;
    logic enable;
    assign edge_detect_d = tspi_clk_i;
    assign enable = edge_detect_q == 1'b0 && tspi_clk_i == 1'b1;
    `FF(edge_detect_q, edge_detect_d, '0, clk_i, rst_ni)

    // `FF(cnt_cmd_q, cnt_cmd_d, '0, tspi_clk_i, rst_ni)
    `FFL(cnt_cmd_q, cnt_cmd_d, enable, '0, clk_i, rst_ni)
    
    `FF(new_req_q, new_req_d, '0, clk_i, rst_ni)

    //`FF(len_cmd_q, len_cmd_d, '0, clk_i, rst_ni)
    
    

endmodule
