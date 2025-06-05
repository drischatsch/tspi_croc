// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"


module req_blocker_ctrl import croc_pkg::*;  #(
) 
(
    input logic clk_i,
    input logic rst_ni,

    input logic [NUM_REQ_BLOCKS-1:0][20:0] req_addr_i,
    input logic [NUM_REQ_BLOCKS-1:0] valid_i,
    output logic [NUM_REQ_BLOCKS-1:0][$clog2(NUM_SRAM_ADDRESSES)-1:0] sram_addr_idx_o,
    output logic block_o,

    input logic block_swap_on_i,
    

    output logic swap_req_o,

    output logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] old_addr_idx_o,

    output logic [20:0] old_addr_o,
    output logic [20:0] new_addr_o,

    input logic done_i
);

// logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] idx_swap_block;
logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] idx_to_be_swapped_d, idx_to_be_swapped_q;
logic [NUM_SRAM_ADDRESSES-1:0][20:0] sram_addr_d, sram_addr_q;
logic [NUM_REQ_BLOCKS-1:0] match_found;
// logic [$clog2(NUM_REQ_BLOCKS)-1:0] current_mismatch_idx_d, current_mismatch_idx_q;



// Find req_addr in sram_addr
for (genvar i = 0; i < NUM_REQ_BLOCKS; i++) begin  
    always_comb begin
        match_found[i] = 1'b0;
        for (int j = 0; j < NUM_SRAM_ADDRESSES; j++) begin // Why int?
            if (valid_i[i]) begin
                if (req_addr_i[i] == sram_addr_q[j]) begin
                    match_found[i] = 1'b1;
                    sram_addr_idx_o[i] = j; 
                end
            end else begin
                match_found[i] = 1'b1;
            end
        end     
    end
end

// Check if there is a match
always_comb begin
    block_o = 1'b0;
    swap_req_o = 1'b0;
    for (int i = 0; i < NUM_REQ_BLOCKS; i++) begin
        if (match_found[i] == 1'b0 && block_swap_on_i) begin
            block_o = 1'b1;
            swap_req_o = 1'b1;
        end
    end
end

// Swap request

assign old_addr_idx_o = idx_to_be_swapped_d;

assign old_addr_o = sram_addr_q[idx_to_be_swapped_d];

// Inversed order to have the lowest index with the highest priority
always_comb begin
    for (int i = NUM_REQ_BLOCKS; i > 0; i--) begin
        if (match_found[i - 1] == 1'b0) begin
            new_addr_o = req_addr_i[i - 1];
        end
    end
end
// Inversed order to have the lowest index with the highest priority
// for (genvar i = NUM_REQ_BLOCKS; i > 0; i--) begin
//     always_comb begin
//         if (match_found[i - 1] == 1'b0) begin // TODO: check if fixed now
//             new_addr_o = req_addr_i[i - 1];
//         end
//     end
// end

// Update sram_addr TODO: Check if this is correct
always_comb begin
    // Set the default value
    if(block_swap_on_i == 1'b0) begin
        for (int i = 0; i < NUM_SRAM_ADDRESSES; i++) begin
            sram_addr_d[i] = 21'h1F_FFFF;
        end
    end else begin
        sram_addr_d = sram_addr_q;
        if(done_i) begin
            sram_addr_d[idx_to_be_swapped_q] = new_addr_o;
        end
    end
end



// Workaround because idx_swap_block changes instantly
always_comb begin
    if(done_i) begin
        if(idx_to_be_swapped_q == (NUM_SRAM_ADDRESSES - 1)) begin
            idx_to_be_swapped_d = '0;
        end else begin
            idx_to_be_swapped_d = idx_to_be_swapped_q + 1;
        end
    end else begin
        idx_to_be_swapped_d = idx_to_be_swapped_q;
    end
end


`FF(idx_to_be_swapped_q, idx_to_be_swapped_d, '0, clk_i, rst_ni)



// DONE: Initialize sram_addr with the addresses of the SRAM correctly
for (genvar i = 0; i < NUM_SRAM_ADDRESSES; i++) begin
    `FF(sram_addr_q[i], sram_addr_d[i], 'h1F_FFFF, clk_i, rst_ni)
end


endmodule
