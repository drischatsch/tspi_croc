// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// gives us the `FF(...) macro making it easy to have properly defined flip-flops
`include "common_cells/registers.svh"

// simple ROM
module bootrom #(
  /// The OBI configuration for all ports.
  parameter obi_pkg::obi_cfg_t           ObiCfg      = obi_pkg::ObiDefaultConfig,
  /// The request struct.
  parameter type                         obi_req_t   = logic,
  /// The response struct.
  parameter type                         obi_rsp_t   = logic,

  /// Boot ROM base address
  parameter int                          BaseAddr = 32'h0300_D000,
  /// Boot ROM hex FileName
  parameter string                       FileName = "../sw/bootrom/build/bootrom_embed.hex",
  /// Boot ROM size in bytes
  parameter int                          SizeBytes = 'h1000
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
  localparam int AddressLSB = 2; // LSB offset (2 bits for the byte address)
  localparam int SizeWords = SizeBytes >> AddressLSB; // Size in words
  localparam int SizeWordsLog2 = $clog2(SizeWords); // Size in words log2
  localparam int AddressMSB = SizeWordsLog2 + AddressLSB; // Address MSB (2 bits for the byte address)

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
  logic [31:0] rom_data [0:SizeWords-1];
  initial begin
    // $display(">> Loading Boot ROM from: \"%s\"", FileName);

    $readmemh(FileName, rom_data);

    // for (int i = 0; i < SizeWords; i++) begin
    //   $display("   rom_data[%0d] = %08X", i, rom_data[i]);
    // end
  end

  logic [ObiCfg.AddrWidth-1:0] addr_q_offset = addr_q - BaseAddr;

  // Full-width checks:
  //   misaligned    = any low 2 bits non-zero
  //   out_of_range  = any high bits above MSB set (i.e. addr_q >= size in bytes (SizeWords*4))
  logic misaligned = |addr_q_offset[AddressLSB-1:0];
  logic out_of_bounds = |addr_q_offset[ObiCfg.AddrWidth-1:AddressMSB];

  // Assign the response data
  logic [SizeWordsLog2-1:0] word_addr = addr_q_offset[AddressMSB-1:AddressLSB];

  always_comb begin
    rsp_data = '0;
    rsp_err  = '0;

    if(req_q) begin
      if(we_q) begin
        // $display(">> Boot ROM: write access: addr_q_offset = 0x%0h", addr_q_offset);
        // rsp_err = '1;
      end else if (misaligned || out_of_bounds) begin
        // $display(">> Boot ROM: misaligned or out of bounds access: addr_q = 0x%0h", addr_q_offset);
        rsp_err = '1;
      end else begin
        // $display(">> Boot ROM: read access: addr_q_offset = 0x%0h", addr_q_offset);
        rsp_data = rom_data[word_addr];
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