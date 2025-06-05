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

  logic [ObiCfg.DataWidth-1:0] rsp_data; // data sent back
  logic obi_err;
  logic we_d, we_q;
  logic req_d, req_q;
  logic [2:0] word_addr_d, word_addr_q;  // relevant part of the word-aligned address
  logic [ObiCfg.IdWidth-1:0] id_d, id_q; // id of the request, must be same for response

  // Step 1: Request phase
  // grant the request (ROM is always ready so this can be assigned directly)
  assign obi_rsp_o.gnt = obi_req_i.req;
  // safe important info
  assign id_d          = obi_req_i.a.aid;
  assign word_addr_d   = obi_req_i.a.addr[4:2];
  assign we_d          = obi_req_i.a.we;
  assign req_d         = obi_req_i.req;

  `FF(req_q, req_d, '0, clk_i, rst_ni)
  `FF(we_q, we_d, '0, clk_i, rst_ni)
  `FF(word_addr_q, word_addr_d, '0, clk_i, rst_ni)
  `FF(id_q, id_d, '0, clk_i, rst_ni)

  // Step 2: Response phase
  // On the next cycle, send the response back with the same ID and the data
  always_comb begin
    obi_rsp_o.r.rdata      = rsp_data;
    obi_rsp_o.r.rid        = id_q;
    obi_rsp_o.r.err        = 1'b0;
    obi_rsp_o.r.r_optional = '0;
    obi_rsp_o.rvalid       = req_q;
    obi_rsp_o.r.err        = obi_err;
  end

  always_comb begin
    rsp_data = '0;
    obi_err  = '0;

    if (req_q) begin
      if (~we_q) begin
        case(word_addr_q)
          3'h0: rsp_data = {"e","m","u","D"};
          3'h1: rsp_data = {"C","&","i","n"};
          3'h2: rsp_data = {"i","r","d","e"};
          3'h3: rsp_data = {" ","s","'","c"};
          3'h4: rsp_data = {"C","I","S","A"};
          3'h5: rsp_data = {".","0","v"," "};
          3'h6: rsp_data = { 0, "0",".","1"};
          3'h7: rsp_data = 32'ha455_55a4;
          default: rsp_data = 32'h0;
        endcase
      end else begin
        obi_err = 1'b1;
      end
    end
  end

endmodule