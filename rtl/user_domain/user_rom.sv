// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// gives us the `FF(...) macro making it easy to have properly defined flip-flops
`include "common_cells/registers.svh"

// simple ROM
module user_rom #(
  /// The OBI configuration for all ports.
  parameter obi_pkg::obi_cfg_t           ObiCfg      = obi_pkg::ObiDefaultConfig,
  /// The request struct.
  parameter type                         obi_req_t   = logic,
  /// The response struct.
  parameter type                         obi_rsp_t   = logic
) (
  /// Clock
  input  logic clk_i,
  /// Active-low reset
  input  logic rst_ni,

  /// OBI request interface
  input  obi_req_t obi_req_i,
  /// OBI response interface
  output obi_rsp_t obi_rsp_o
);

  // User ROM size in words
  localparam int ROM_SIZE_WORDS = 8;
  localparam int ROM_SIZE_WORDS_LOG2 = $ceil($clog2(ROM_SIZE_WORDS));

  // Define some registers to hold the requests fields
  logic req_d, req_q; // Request valid
  logic we_d, we_q; // Write enable
  logic [ObiCfg.AddrWidth-1:0] addr_d, addr_q; // Internal address of the word to read
  logic [ObiCfg.IdWidth-1:0] id_d, id_q; // Id of the request, must be same for the response

  // Signals used to create the response
  logic [ObiCfg.DataWidth-1:0] rsp_data; // Data field of the obi response
  logic rsp_err; // Error field of the obi response

  // Wire the registers holding the request
  assign req_d = obi_req_i.req;
  assign id_d = obi_req_i.a.aid;
  assign we_d = obi_req_i.a.we;
  assign addr_d = obi_req_i.a.addr;
  always_ff @(posedge (clk_i) or negedge (rst_ni)) begin
    if (!rst_ni) begin
      req_q <= '0;
      id_q <= '0;
      we_q <= '0;
      addr_q <= '0;
    end else begin
      req_q <= req_d;
      id_q <= id_d;
      we_q <= we_d;
      addr_q <= addr_d;
    end
  end

  // Load the response data into a buffer from rom.hex
  logic [31:0] rom_data [0:ROM_SIZE_WORDS-1] = {
    32'h656D7544,
    32'h4326696E,
    32'h69726465,
    32'h20732763,
    32'h43495341,
    32'h2E307620,
    32'h00302E31,
    32'h00000000
  };

  // Assign the response data
  logic [ROM_SIZE_WORDS_LOG2-1:0] word_addr;
  always_comb begin
    rsp_data = '0;
    rsp_err  = '0;
    word_addr = addr_q[ROM_SIZE_WORDS_LOG2+1:2];

    if(req_q) begin
      if(~we_q) begin
        if (word_addr > (ROM_SIZE_WORDS - 1)) begin
          // $display(">> User ROM: Read request out of bounds: addr_q = %0h, word_addr = %0d", addr_q, word_addr);
          rsp_data = 32'h0;
        end else begin
          rsp_data = rom_data[word_addr];
        end
      end else begin
        rsp_err = '1;
      end
    end
  end

  // Wire the response
  // A channel
  assign obi_rsp_o.gnt = obi_req_i.req;
  // R channel:
  assign obi_rsp_o.rvalid = req_q;
  assign obi_rsp_o.r.rdata = rsp_data;
  assign obi_rsp_o.r.rid = id_q;
  assign obi_rsp_o.r.err = rsp_err;
  assign obi_rsp_o.r.r_optional = '0;

endmodule