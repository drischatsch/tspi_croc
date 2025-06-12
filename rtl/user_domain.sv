// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

module user_domain import user_pkg::*; import croc_pkg::*; #(
  parameter int unsigned GpioCount = 16
) (
  input  logic      clk_i,
  input  logic      ref_clk_i,
  input  logic      rst_ni,
  input  logic      testmode_i,
  
  input  sbr_obi_req_t user_sbr_obi_req_i, // User Sbr (rsp_o), Croc Mgr (req_i)
  output sbr_obi_rsp_t user_sbr_obi_rsp_o,

  output mgr_obi_req_t user_mgr_obi_req_o, // User Mgr (req_o), Croc Sbr (rsp_i)
  input  mgr_obi_rsp_t user_mgr_obi_rsp_i,

  input  logic [      GpioCount-1:0] gpio_in_sync_i, // synchronized GPIO inputs
  output logic [NumExternalIrqs-1:0] interrupts_o, // interrupts to core

  // SPI interface
  output logic      tspi_clk_o,
  output logic      tspi_mosi_o,
  input  logic      tspi_miso_i,
  output logic      tspi_cs_no,

  // Request Blocker interface
  input logic [NUM_REQ_BLOCKS-1:0][20:0] req_addr_i,
  input logic [NUM_REQ_BLOCKS-1:0] valid_i,
  output logic [NUM_REQ_BLOCKS-1:0][$clog2(NUM_SRAM_ADDRESSES)-1:0] sram_addr_idx_o,
  output logic block_o
);

  //-----------------------------------------------------------------------------------------------
  // Block Swap Parameters
  //-----------------------------------------------------------------------------------------------
  logic block_only_load_on;
  logic block_swap_on;

  logic [31:0] write_data;
  logic [31:0] read_data;
  logic signal_next_write_data;
  logic signal_next_read_data;

  logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] old_addr_idx;
  logic swap_req;
  logic [20:0] old_addr;
  logic [20:0] new_addr;
  logic done;


  mgr_obi_req_t sram_obi_req;
  mgr_obi_rsp_t sram_obi_rsp;

  sbr_obi_req_t sdcard_obi_req;
  sbr_obi_rsp_t sdcard_obi_rsp;
  
  sbr_obi_req_t tspi_obi_req; // Dependent on if block_swap_on is set
  sbr_obi_rsp_t tspi_obi_rsp; // Dependent on if block_swap_on is set

  assign interrupts_o = '0;  


  //////////////////////
  // User Manager MUX //
  /////////////////////

  // No manager so we don't need a obi_mux module and just terminate the request properly
  assign user_mgr_obi_req_o = sram_obi_req;
  assign sram_obi_rsp = user_mgr_obi_rsp_i;

  ////////////////////////////
  // User Subordinate DEMUX //
  ////////////////////////////

  // ----------------------------------------------------------------------------------------------
  // User Subordinate Buses
  // ----------------------------------------------------------------------------------------------
  
  // collection of signals from the demultiplexer
  sbr_obi_req_t [NumDemuxSbr-1:0] all_user_sbr_obi_req;
  sbr_obi_rsp_t [NumDemuxSbr-1:0] all_user_sbr_obi_rsp;

  // Error Subordinate Bus
  sbr_obi_req_t user_error_obi_req;
  sbr_obi_rsp_t user_error_obi_rsp;

  // ROM Subordinate Bus
  sbr_obi_req_t user_rom_obi_req;
  sbr_obi_rsp_t user_rom_obi_rsp;

  // SPI Subordinate Bus
  sbr_obi_req_t user_transparentspi_obi_req;
  sbr_obi_rsp_t user_transparentspi_obi_rsp;

  // Block Swapping Subordinate Bus
  sbr_obi_req_t user_block_swap_obi_req;
  sbr_obi_rsp_t user_block_swap_obi_rsp;

  // Fanout into more readable signals
  assign user_error_obi_req              = all_user_sbr_obi_req[UserError];
  assign all_user_sbr_obi_rsp[UserError] = user_error_obi_rsp;

  assign user_rom_obi_req                = all_user_sbr_obi_req[UserRom];
  assign all_user_sbr_obi_rsp[UserRom]   = user_rom_obi_rsp;

  // assign user_transparentspi_obi_req              = all_user_sbr_obi_req[UserTransparentSpi];
  // assign all_user_sbr_obi_rsp[UserTransparentSpi] = user_transparentspi_obi_rsp;


  // Transparent SPI OBI Cut (Only without Block Swap else direct access)
  obi_cut #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .Bypass      ( 1'b0          )
  ) i_user_transparentspi_obi_cut (
    .clk_i,
    .rst_ni,

    .sbr_port_req_i(all_user_sbr_obi_req[UserTransparentSpi]),
    .sbr_port_rsp_o(all_user_sbr_obi_rsp[UserTransparentSpi]),
    .mgr_port_req_o(user_transparentspi_obi_req),
    .mgr_port_rsp_i(user_transparentspi_obi_rsp)
    
    );

  assign user_block_swap_obi_req             = all_user_sbr_obi_req[UserBlockSwap];
  assign all_user_sbr_obi_rsp[UserBlockSwap] = user_block_swap_obi_rsp;

  //-----------------------------------------------------------------------------------------------
  // Demultiplex to User Subordinates according to address map
  //-----------------------------------------------------------------------------------------------

  logic [cf_math_pkg::idx_width(NumDemuxSbr)-1:0] user_idx;

  addr_decode #(
    .NoIndices ( NumDemuxSbr                    ),
    .NoRules   ( NumDemuxSbrRules               ),
    .addr_t    ( logic[SbrObiCfg.DataWidth-1:0] ),
    .rule_t    ( addr_map_rule_t                ),
    .Napot     ( 1'b0                           )
  ) i_addr_decode_periphs (
    .addr_i           ( user_sbr_obi_req_i.a.addr ),
    .addr_map_i       ( user_addr_map             ),
    .idx_o            ( user_idx                  ),
    .dec_valid_o      (),
    .dec_error_o      (),
    .en_default_idx_i ( 1'b1 ),
    .default_idx_i    ( '0   )
  );

  obi_demux #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .NumMgrPorts ( NumDemuxSbr   ),
    .NumMaxTrans ( 2             )
  ) i_obi_demux (
    .clk_i,
    .rst_ni,

    .sbr_port_select_i ( user_idx             ),
    .sbr_port_req_i    ( user_sbr_obi_req_i   ),
    .sbr_port_rsp_o    ( user_sbr_obi_rsp_o   ),

    .mgr_ports_req_o   ( all_user_sbr_obi_req ),
    .mgr_ports_rsp_i   ( all_user_sbr_obi_rsp )
  );


//-------------------------------------------------------------------------------------------------
// User Subordinates
//-------------------------------------------------------------------------------------------------

  // Error Subordinate
  obi_err_sbr #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .NumMaxTrans ( 1             ),
    .RspData     ( 32'hBADCAB1E  )
  ) i_user_err (
    .clk_i,
    .rst_ni,
    .testmode_i ( testmode_i      ),
    .obi_req_i  ( user_error_obi_req ),
    .obi_rsp_o  ( user_error_obi_rsp )
  );

  // User ROM
  user_rom #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t )
  ) i_user_rom (
    .clk_i,
    .rst_ni,
    .obi_req_i  ( user_rom_obi_req ),
    .obi_rsp_o  ( user_rom_obi_rsp )
  );

  // Transparent SPI
  tspi_host #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t )
  ) i_user_transparentspi (
    .clk_i,
    .rst_ni,

    // // OBI request interface
    // .obi_req_i(user_transparentspi_obi_req), // Changed for testing
    // .obi_rsp_o(user_transparentspi_obi_rsp), // Changed for testing
    .obi_req_i(tspi_obi_req),
    .obi_rsp_o(tspi_obi_rsp),

    //SPI interface
    .tspi_clk_o(tspi_clk_o),
    .tspi_cs_no(tspi_cs_no),
    .tspi_mosi_o(tspi_mosi_o),
    .tspi_miso_i(tspi_miso_i),

    // Block swap interface
    .write_data_i(write_data),
    .read_data_o(read_data),
    .signal_next_write_data_o(signal_next_write_data),
    .signal_next_read_data_o(signal_next_read_data)
  );

  // Block Swapping Configuration
  block_swap_config #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t )
  ) i_user_block_swap_config (
    .clk_i,
    .rst_ni,

    // OBI request interface
    .obi_req_i(user_block_swap_obi_req), // Changed for testing
    .obi_rsp_o(user_block_swap_obi_rsp),  // Changed for testing
    
    .block_only_load_on_o(block_only_load_on),
    .block_swap_on_o(block_swap_on)
  );

//-------------------------------------------------------------------------------------------------
// Block Swapping
//-------------------------------------------------------------------------------------------------
req_blocker_ctrl  #(
) i_req_blocker_ctrl (
    .clk_i,
    .rst_ni,

    .req_addr_i(req_addr_i),
    .valid_i(valid_i),
    .sram_addr_idx_o(sram_addr_idx_o),
    .block_o(block_o),

    .block_swap_on_i(block_swap_on),
    

    .old_addr_idx_o(old_addr_idx),

    .swap_req_o(swap_req),

    .old_addr_o(old_addr),
    .new_addr_o(new_addr),

    .done_i(done)
);


logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] old_addr_idx_d, old_addr_idx_q;
logic swap_req_d, swap_req_q;
logic [20:0] old_addr_d, old_addr_q;
logic [20:0] new_addr_d, new_addr_q;
`FF(old_addr_idx_q, old_addr_idx_d, '0, clk_i, rst_ni)
`FF(swap_req_q, swap_req_d, '0, clk_i, rst_ni)
`FF(old_addr_q, old_addr_d, '0, clk_i, rst_ni)
`FF(new_addr_q, new_addr_d, '0, clk_i, rst_ni)
assign old_addr_idx_d = old_addr_idx;
assign swap_req_d = swap_req;
assign old_addr_d = old_addr;
assign new_addr_d = new_addr;

block_swap_ctrl #(
    .ObiCfg      ( MgrObiCfg     ),
    .obi_req_t   ( mgr_obi_req_t ),
    .obi_rsp_t   ( mgr_obi_rsp_t )
) i_block_swap_ctrl (
    .clk_i,
    .rst_ni,

    .swap_req_i(swap_req_q),

    .old_addr_idx_i(old_addr_idx_q),

    .old_addr_i(old_addr_q),
    .new_addr_i(new_addr_q),

    .done_o(done),

    .block_only_load_on_i(block_only_load_on),

    // OBI request interface
    .sdcard_obi_req_o(sdcard_obi_req), // DONE: MAYBE sbr config
    .sdcard_obi_rsp_i(sdcard_obi_rsp),

    .sram_obi_req_o(sram_obi_req),
    .sram_obi_rsp_i(sram_obi_rsp),

    // tspi interface
    .write_data_o(write_data),
    .read_data_i(read_data),
    .signal_next_write_data_i(signal_next_write_data),
    .signal_next_read_data_i(signal_next_read_data)
);

// Switch between block swap and transparent SPI
always_comb begin
  tspi_obi_req = (block_swap_on)?  sdcard_obi_req : user_transparentspi_obi_req;

  if(block_swap_on) begin
    sdcard_obi_rsp = tspi_obi_rsp;
    user_transparentspi_obi_rsp = '0;
  end else begin
    sdcard_obi_rsp = '0;
    user_transparentspi_obi_rsp = tspi_obi_rsp;
  end
   
end

endmodule
