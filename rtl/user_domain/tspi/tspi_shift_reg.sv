// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module tspi_shift_reg import tspi_pkg::*; #() 
(
    input logic clk_i,
    input logic rst_ni,

    input logic tspi_clk_i,

    input logic [5:0] len_cmd_i,
    input logic new_cmd_i,

    output logic start_bit_o,

    input logic miso_i,
    output logic mosi_o,

    input logic en_write_i,
    input logic [31:0] data_i,

    output logic [31:0] data_o
);

//-- Internal Signals ---------------------------------------------------------------------
logic [31:0] data_d, data_q;
logic en_write_d, en_write_q;
logic waiting_for_start_bit_d, waiting_for_start_bit_q;

// for (genvar i = 0; i < 32; i ++) begin 
//     assign data_o[i] = data_d[31-i]; // TODO: Check if this is correct
// end
assign data_o = data_q;


// Support for start bit
assign en_write_d = en_write_i;

always_comb begin
    start_bit_o = 1'b0;
    waiting_for_start_bit_d = waiting_for_start_bit_q;
    if(!en_write_i && en_write_q) begin
        waiting_for_start_bit_d = 1'b1;
    end 
    if (waiting_for_start_bit_d && !miso_i) begin // TODO: Check maybe dangerous
        start_bit_o = 1'b1;
        waiting_for_start_bit_d = 1'b0;
    end
    
end




//DONE: Change so that the output isn't delayed by one clock cycle
// logic [31:0] valid_d, valid_q;
always_comb begin
    if(en_write_i && new_cmd_i) begin
        mosi_o = data_i[31];
    end else begin
        // Send data or stall
        mosi_o = (en_write_i) ? data_q[31] : 'b1;
    end
    
end


for (genvar i = 0; i < 32; i++) begin : gen_regs
    // TODO: Change the the index of the len_cmd_i MAYBE DONE
    // Prepare D port for each shift register.
    if (i == 0) begin : gen_shift_in
        always_comb begin
            //assign valid_d[i] = valid_i;
            if(en_write_i && new_cmd_i && (i >= 31 - len_cmd_i)) begin
                data_d[i] = data_i[i];

            end else begin
                data_d[i]  = miso_i; // Testing: 1'b1;
            end
        end
    end else begin : gen_shift
        //assign valid_d[i] = valid_q[i-1];
        always_comb begin
            if(en_write_i && new_cmd_i && (i >= 31 - len_cmd_i)) begin
                data_d[i] = data_i[i - 1]; // Shift data for first bit to be written directly
            end else begin
                data_d[i]  = data_q[i - 1];
            end
        end
    end

    // // shift valid flag without clock gate
    // `FF(data_q[i], data_d[i], '1, tspi_clk_i, rst_ni)
    `FFL(data_q[i], data_d[i], enable, '1, tspi_clk_i, rst_ni)
end

logic edge_detect_d, edge_detect_q;
logic enable;
assign edge_detect_d = tspi_clk_i;
assign enable = edge_detect_q == 1'b0 && tspi_clk_i == 1'b1;
`FF(edge_detect_q, edge_detect_d, '0, clk_i, rst_ni)

//`FFL(cnt_cmd_q, cnt_cmd_d, enable, '0, clk_i, rst_ni)

// TODO: Check if still working
// `FF(en_write_q, en_write_d, '0, tspi_clk_i, rst_ni)
// `FF(waiting_for_start_bit_q, waiting_for_start_bit_d, '0, tspi_clk_i, rst_ni)
`FFL(en_write_q, en_write_d, enable, '0, clk_i, rst_ni)
`FFL(waiting_for_start_bit_q, waiting_for_start_bit_d, enable, '0, clk_i, rst_ni)

endmodule