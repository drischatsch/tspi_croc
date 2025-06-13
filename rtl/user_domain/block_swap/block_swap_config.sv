// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

// SPI baudrate generation module
typedef struct packed {
    // Configuration registers
    logic block_only_load_on;
    logic  block_swap_on;
} block_swap_config_reg_t;

module block_swap_config  #(
    // The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t           ObiCfg      = obi_pkg::ObiDefaultConfig,
    // The request struct.
    parameter type                         obi_req_t   = logic,
    // The response struct.
    parameter type                         obi_rsp_t   = logic
)
(
    input logic clk_i,
    input logic rst_ni,

    // OBI request interface
    input  obi_req_t obi_req_i,
    output obi_rsp_t obi_rsp_o,

    output logic block_only_load_on_o,
    output logic block_swap_on_o
);

block_swap_config_reg_t config_reg_d, config_reg_q;
logic req_d, req_q;
logic [2:0] id_d, id_q;

assign block_only_load_on_o = config_reg_q.block_only_load_on;
assign block_swap_on_o = config_reg_q.block_swap_on;

always_comb begin
    config_reg_d = config_reg_q; // Default to keep the current value
    if (obi_req_i.req && obi_req_i.a.addr[3:0] == 4'h0 && obi_req_i.a.we == 1'b1) begin
        config_reg_d.block_only_load_on = obi_req_i.a.wdata[1];
        config_reg_d.block_swap_on = obi_req_i.a.wdata[0];
    end
end

// Response to the OBI request
always_comb begin
    req_d = obi_req_i.req;
    id_d = obi_req_i.a.aid;

    obi_rsp_o.gnt = obi_req_i.req;
    obi_rsp_o.rvalid = req_q;
    obi_rsp_o.r.rid = id_q;
end


`FF(config_reg_q, config_reg_d, '0, clk_i, rst_ni)
`FF(req_q, req_d, '0, clk_i, rst_ni)
`FF(id_q, id_d, '0, clk_i, rst_ni)



endmodule