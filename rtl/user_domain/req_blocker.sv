// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"


module req_blocker import tspi_pkg::*; import user_pkg::*; import croc_pkg::*;  #(
    
    // // The OBI configuration for all ports.
    // parameter obi_pkg::obi_cfg_t           ObiCfg      = obi_pkg::ObiDefaultConfig,
    // // The request struct.
    // parameter type                         obi_req_t   = logic,
    // // The response struct.
    // parameter type                         obi_rsp_t   = logic
) 
(
    input logic clk_i,
    input logic rst_ni,

    // OBI request interface
    input  mgr_obi_req_t in_obi_req_i,
    output mgr_obi_rsp_t in_obi_rsp_o,

    output  mgr_obi_req_t out_obi_req_o,
    input mgr_obi_rsp_t out_obi_rsp_i,



    output logic [20:0] req_addr_o,
    output logic valid_o,

    input logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] sram_addr_idx_i,

    input logic block_i
);

logic [31:0] addr_offset_temp;

assign addr_offset_temp = in_obi_req_i.a.addr;

assign req_addr_o = addr_offset_temp[28:9];



// Only check the addresses in range
always_comb begin
    valid_o = 1'b0;
    if (in_obi_req_i.a.addr >= UserTransparentSpiAddrOffset + BLOCK_READWRITE_MIN_OFFSET && in_obi_req_i.a.addr <= UserTransparentSpiAddrOffset + BLOCK_READWRITE_MAX_OFFSET) begin
        // TODO: To not have a new mismatch while switching of higher priority
        if(in_obi_req_i.req) begin
            valid_o = in_obi_req_i.req;
        end
    end
end


// Forward the corrected request
always_comb begin
    if (block_i) begin
        out_obi_req_o = '0;
    end else begin
        out_obi_req_o = in_obi_req_i;
        // DONE: Variable dependent
        if (in_obi_req_i.a.addr >= UserTransparentSpiAddrOffset + BLOCK_READWRITE_MIN_OFFSET && in_obi_req_i.a.addr <= UserTransparentSpiAddrOffset + BLOCK_READWRITE_MAX_OFFSET) begin
            out_obi_req_o.a.addr = FIRST_USABLE_SRAM_ADDR + ((sram_addr_idx_i<<9) | (in_obi_req_i.a.addr[8:0])); // DONE: Check correctness
        end
    end
end



// response to the request
always_comb begin
    in_obi_rsp_o = out_obi_rsp_i; // Test: (block_i) ? '0 : out_obi_rsp_i;
    in_obi_rsp_o.gnt = (block_i) ? 1'b0 : out_obi_rsp_i.gnt;
end





endmodule
