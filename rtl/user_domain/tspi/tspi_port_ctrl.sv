// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module tspi_port_ctrl import tspi_pkg::*; #() 
(
    input logic tspi_clk_i,
    input logic rst_ni,

    input logic new_req_i,

    input logic en_port_ctrl_i,
    input logic beginning_i,
    output logic tspi_clk_o,
    output logic cs_o
);

    logic tspi_clk;
    logic cs;

    assign tspi_clk_o = tspi_clk | new_req_i;
    assign cs_o = cs | new_req_i;

    always_comb begin
        if(en_port_ctrl_i && beginning_i) begin
            tspi_clk = tspi_clk_i;
            cs = 1'b1;
        end else if (en_port_ctrl_i) begin
            tspi_clk = tspi_clk_i;
            cs = 1'b0;
        end else begin
            tspi_clk = 1'b1;
            cs = 1'b1;
        end
    end

endmodule

    