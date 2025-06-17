// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

 `include "common_cells/registers.svh"

// DONE: change name t_spi_host
 module tspi_host import tspi_pkg::*; #(
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


    //spi interface
    output logic tspi_clk_o,
    output logic tspi_cs_no,
    output logic tspi_mosi_o,
    input logic tspi_miso_i,

    // Block swap interface
    input logic [31:0] write_data_i,
    output logic [31:0] read_data_o,
    output logic signal_next_write_data_o,
    output logic signal_next_read_data_o
);


    //-- Internal Signals ----------------------------------------------------------------
    config_reg_t config_reg;
    logic [7:0] cnt_cmd_controller, cnt_cmd_counter;
    logic [5:0] len_cmd_controller, len_cmd_counter;
    logic en_write;
    logic [31:0] data_cmd_controller, data_cmd_shift_reg;
    logic new_req;
    logic new_cmd;
    logic last_bit;
    logic en_port_ctrl;
    logic beginning;
    logic start_bit;
    logic tspi_clk;
     logic [7:0] block_swap_first_read_word;
    logic done;


    logic tspi_mosi;
    logic tspi_miso;

    assign tspi_mosi = tspi_mosi_o;
    assign tspi_miso = tspi_miso_i;



    // assign config_reg = 8'h19; // 25
    
    // Instantiate the spi modules
    tspi_baudgeneration #() i_baudrate_gen (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .baudrate_o(tspi_clk),
        .run_i(en_port_ctrl),
        .new_req_i(new_req),
        .config_reg_i(config_reg)
    );

    tspi_cmd_ctrl #(// TODO: No parameters?
    .ObiCfg(ObiCfg),
    .obi_req_t(obi_req_t), 
    .obi_rsp_t(obi_rsp_t)
    ) i_cmd_ctrl (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .obi_req_i(obi_req_i),
        .en_write_o(en_write),
        .data_o(data_cmd_controller),
        .new_req_o(new_req),
        .config_reg_o(config_reg),
        .cnt_cmd_o(cnt_cmd_controller),
        .len_cmd_o(len_cmd_controller),
        .cnt_cmd_i(cnt_cmd_counter),
        .en_port_ctrl_o(en_port_ctrl),
        .beginning_o(beginning),
        .write_data_i(write_data_i),
        .signal_next_write_data_o(signal_next_write_data_o),
        .new_cmd_i(new_cmd),
        .block_swap_first_read_word_i(block_swap_first_read_word),
        .done_i(done)
    );


    tspi_counter #() i_counter (
        .clk_i(clk_i),
        .tspi_clk_i(tspi_clk),
        .rst_ni(rst_ni),
        .new_req_i(new_req),
        .cnt_cmd_i(cnt_cmd_controller),
        .len_cmd_i(len_cmd_controller),
        .cnt_cmd_o(cnt_cmd_counter),
        .len_cmd_o(len_cmd_counter),
        .new_cmd_o(new_cmd),
        .start_bit_i(start_bit),
        .last_bit_o(last_bit)
    );

    tspi_port_ctrl #() i_port_ctrl (
        .tspi_clk_i(tspi_clk),
        .rst_ni(rst_ni),
        .new_req_i(new_req),
        .en_port_ctrl_i(en_port_ctrl),
        .beginning_i(beginning),
        .tspi_clk_o(tspi_clk_o),
        .cs_o(tspi_cs_no)
    );

    tspi_shift_reg #() i_shift_reg (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .tspi_clk_i(tspi_clk),
        .len_cmd_i(len_cmd_counter),
        .new_cmd_i(new_cmd),
        .start_bit_o(start_bit),
        .miso_i(tspi_miso_i),
        .mosi_o(tspi_mosi_o),
        .en_write_i(en_write),
        .data_i(data_cmd_controller),
        .data_o(data_cmd_shift_reg)
    );

    tspi_resp_checker #(
        .ObiCfg(ObiCfg),
        .obi_req_t(obi_req_t), 
        .obi_rsp_t(obi_rsp_t)
    ) i_resp_checker (
        .clk_i(clk_i),
        .tspi_clk_i(tspi_clk),
        .rst_ni(rst_ni),
        .obi_req_i(obi_req_i),
        .obi_rsp_o(obi_rsp_o),
        .data_i(data_cmd_shift_reg),
        .len_cmd_i(len_cmd_counter),
        .cnt_cmd_i(cnt_cmd_counter),
        .en_write_i(en_write),
        .last_bit_i(last_bit),
        .start_bit_i(start_bit),
        .done_o(done),
        .block_swap_first_read_word_o(block_swap_first_read_word),
        .read_data_o(read_data_o),
        .signal_next_read_data_o(signal_next_read_data_o)
    );



 endmodule