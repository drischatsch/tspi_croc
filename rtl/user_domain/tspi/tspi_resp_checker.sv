// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"




module tspi_resp_checker import tspi_pkg::*; #(
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

    input logic tspi_clk_i,

    // OBI request interface
    input  obi_req_t obi_req_i,
    output obi_rsp_t obi_rsp_o,

    // Shift register
    input logic [31:0] data_i,

    // Counter
    input logic [5:0] len_cmd_i,
    input logic [7:0] cnt_cmd_i,
    input logic en_write_i,
    input logic last_bit_i,

    input logic start_bit_i,

    output logic done_o, //TODO: Implement
    output logic [7:0] block_swap_first_read_word_o,

    output logic [31:0] read_data_o, // TODO
    output logic signal_next_read_data_o // TODO
);

  
    //-- Internal Signals ----------------------------------------------------------------
    logic [ObiCfg.DataWidth-1:0]  addr_offset_temp;
    logic [AddressBits-1:0] addr_offset;
    state_response_t resp_type_d, resp_type_q;

    logic [31:0] compare_data;

    logic correct_response;

    logic [7:0] block_swap_first_read_word_d, block_swap_first_read_word_q;
    
    //-- Assignments ---------------------------------------------------------------------



    // Signals for the OBI response
    // logic [ObiCfg.DataWidth-1:0] rsp_data;
    logic                        correct_d, correct_q;         // delayed for the response phase
    logic                        error_d, error_q;       // delayed for the response phase
    logic                        last_bit_d, last_bit_q;           // delayed for the block response phase  
    // logic                        req_d, req_q;               // delayed for the response phase
    //logic                        w_err_d, w_err_q;
    // logic [AddressBits-1:0]      word_addr_d, word_addr_q; // delayed for the response phase
    logic [ObiCfg.IdWidth-1:0]   id_d, id_q;               // delayed for the response phase
    

    // Wait and see if the data is read data
    logic data_is_read_d, data_is_read_q;

    always_comb begin
        if(start_bit_i) begin
            data_is_read_d = 1'b1;
        end else if(last_bit_i) begin
            data_is_read_d = 1'b0;
        end
    end

    `FF(data_is_read_q, data_is_read_d, '0, clk_i, rst_ni) 


    assign addr_offset_temp = obi_req_i.a.addr;
    assign addr_offset = addr_offset_temp[AddressBits-1:0];



    // Block swap signal the next read data

    //assign signal_next_read_data_o = (block_swap_first_read_word_q != 'd0) ? last_bit_i : 1'b0;

    always_comb begin
        if(addr_offset >= BLOCK_READWRITE_MIN_OFFSET && addr_offset <= BLOCK_READWRITE_MAX_OFFSET && obi_req_i.req && ~obi_req_i.a.we) begin
            if(cnt_cmd_i > 8'd1 && cnt_cmd_i < block_swap_first_read_word_q) begin // TODO: Check bc: Changed from <= to < WHY THE HELL????
                if(block_swap_first_read_word_q != 'd0) begin
                    signal_next_read_data_o = last_bit_i;
                end else begin
                    signal_next_read_data_o = 1'b0;
                end
            end
        end
    end
        

    // Wire the response
    // A channel
    // assign obi_rsp_o.gnt = done_o | ~obi_req_i.req;
    // R channel:
    

    // assign obi_rsp_o.r.rid = obi_req_i.a.aid;
    
    // assign obi_rsp_o.r.r_optional = '0;

    //TODO: Also stop when cnt_cmd_i == 0

    assign done_o = (correct_d | error_d); //TODO: Check was: & obi_req_i.req
    assign block_swap_first_read_word_o = block_swap_first_read_word_q;


    // OBI rsp Assignment
    always_comb begin
        obi_rsp_o         = '0;
        obi_rsp_o.r.rdata = data_i;  // TESTING: cnt_cmd_i;  //TODO: Implement bytewise
        obi_rsp_o.r.rid   = id_q;
        obi_rsp_o.r.err   = error_q; //TESTING TODO://error_q; //DONE: implement: error_q
        obi_rsp_o.gnt     = done_o | ~obi_req_i.req;
        obi_rsp_o.rvalid  = (correct_q | error_q); //TEST without req : Check
    end

    // id, valid and address handling
    assign id_d         = obi_req_i.a.aid;
    assign last_bit_d   = last_bit_i;
    // assign req_d        = obi_req_i.req;

    // FF for the obi rsp signals (id and valid)
    `FF(id_q, id_d, '0, clk_i, rst_ni)               // 5 Bits
    `FF(correct_q, correct_d, '0, clk_i, rst_ni)         // 1 Bit
    `FF(error_q, error_d, '0, clk_i, rst_ni)         // 1 Bit
    `FF(last_bit_q, last_bit_d, '0, clk_i, rst_ni)         // 1 Bit
    // `FF(word_addr_q, word_addr_d, '0, clk_i, rst_ni) // #AddressBits Bits
    // `FF(we_q, we_d, '0, clk_i, rst_ni)               // 1 Bit
    // `FF(w_err_q, w_err_d, '0, clk_i, rst_ni)         // 1 Bit
    // `FF(req_q, req_d, '0, clk_i, rst_ni)             // 1 Bit // TODO: Comment out

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // COMPARATOR //
    ////////////////////////////////////////////////////////////////////////////////////////////////

    logic [31:0] mask;
    // Right shift implementation for mask creation
    //assign mask = (32'hFFFF_FFFF >> (31 - len_cmd_i)); // Create a mask with len_cmd_i low bits set
    // assign mask = (32'hFFFF_FFFF << (31 - len_cmd_i)); // Create a mask with len_cmd_i high bits set
    assign correct_response = ((data_i & mask) == (compare_data & mask)); // DONE: Check if this is correct
    //assign correct_response = (data_i[31:(31-len_cmd_i)] == compare_data[31:(31-len_cmd_i)]); 

    //DONE: Take away the correct response_q

    always_comb begin
        if(last_bit_i && !en_write_i) begin // DONE: Change to check at the end
            case(resp_type_q)
                FINAL: begin
                    if(correct_response) begin
                        correct_d = 1'b1;
                        error_d = 1'b0;
                    end else begin
                        correct_d = 1'b0;
                        error_d = 1'b1;
                    end
                end
                CAUSE_ERROR: begin
                    if(correct_response) begin
                        correct_d = 1'b0;
                        error_d = 1'b0;
                    end else begin
                        correct_d = 1'b0;
                        error_d = 1'b1;
                    end
                end
                CAUSE_VALIDATION: begin
                    if(correct_response) begin
                        correct_d = 1'b1;
                        error_d = 1'b0;
                    end else begin
                        correct_d = 1'b0;
                        error_d = 1'b0;
                    end
                end
                PASSTHROUGH: begin
                    correct_d = 1'b0;
                    error_d = 1'b0;
                end
                VALIDATE: begin
                    correct_d = 1'b1;
                    error_d = 1'b0;

                end
                ERROR: begin
                    correct_d = 1'b0;
                    error_d = 1'b1;
                end
                CHECK_IF_DATA: begin
                    if(data_is_read_q) begin
                        correct_d = 1'b1;
                        error_d = 1'b0;
                    end else begin
                        correct_d = 1'b0;
                        error_d = 1'b0;
                    end
                end
                BLOCK_CHECK_IF_DATA: begin
                    if(data_is_read_q) begin
                        correct_d = 1'b0;
                        error_d = 1'b0;      
                    end else begin
                        correct_d = 1'b0;
                        error_d = 1'b0;
                    end
                end
                default: begin
                    correct_d = 1'b0;
                    error_d = 1'b0;
                end
            endcase
        end else begin
            correct_d = 1'b0;
            error_d = 1'b0;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // COMMAND SEQUENCE //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb begin  //DONE: Add the mask to be defined here too
        resp_type_d = PASSTHROUGH;
        compare_data = 32'hXXXX_XXXX; //DONE: X just becomes a fixed value
        mask = (32'hFFFF_FFFF >> (31 - len_cmd_i));

        case(addr_offset)
            BEGINNING_OFFSET: begin
                if(cnt_cmd_i == 1) begin
                    resp_type_d = VALIDATE;
                end else begin
                    resp_type_d = PASSTHROUGH;
                end
                compare_data = 32'hXXXX_XXXX;
            end
            BUFFER_OFFSET: begin
                if(cnt_cmd_i == 1) begin
                    resp_type_d = VALIDATE;
                end else begin
                    resp_type_d = PASSTHROUGH;
                end
                compare_data = 32'hXXXX_XXXX;
            end
            CHANGE_BAUDRATE_OFFSET: begin
                if(obi_req_i.a.we) begin
                    resp_type_d = VALIDATE;
                end else begin
                    resp_type_d = ERROR;
                end
                compare_data = 32'hXXXX_XXXX;
            end
            CMD0_OFFSET: begin
                if(~en_write_i) begin
                    resp_type_d = FINAL;
                    compare_data = 32'hXXXX_XX01; // TODO: Change maybe to also accept 0x00
                end
                
            end
            CMD8_OFFSET: begin
                if(~en_write_i) begin
                    if(cnt_cmd_i == 8'd2) begin
                        resp_type_d = CAUSE_ERROR;
                        compare_data = 32'h0100_0001; // TODO: Change maybe to also accept 0x00 also check if correct
                    end else begin
                        resp_type_d = FINAL;
                        compare_data = 32'hXXXX_XXaa;
                    end
                    
                end
            end
            CMD59_OFFSET: begin
                if(~en_write_i) begin
                    resp_type_d = FINAL;
                    compare_data = 32'hXXXX_XX01; // TODO: Change maybe to also accept 0x00
                end
            end
            CMD58_OFFSET: begin
                if(~en_write_i) begin
                    if(cnt_cmd_i == 8'd2) begin
                        resp_type_d = CAUSE_ERROR;
                        compare_data = 32'h0100_FF80; // TODO: Change maybe to also accept 0x00
                        mask = 32'hFF00_0000;
                    end else begin
                        resp_type_d = VALIDATE; // Support all cards
                        compare_data = 32'hXXXX_XX00;
                    end
                    
                end
            end
            ACMD41_OFFSET: begin
                // Loop needs to be asserted
                case(cnt_cmd_i[2:0])
                    8'd5: begin
                        compare_data = 32'hFFFF_FF01;
                        resp_type_d = PASSTHROUGH; //CAUSE_ERROR;
                    end
                    8'd2: begin
                        compare_data = 32'hFFFF_FF00;
                        resp_type_d = CAUSE_VALIDATION;
                    end
                    default: begin
                        compare_data = 32'hFFFF_FF00;
                        resp_type_d = PASSTHROUGH;
                        
                        if(cnt_cmd_i == 8'd1) begin
                            resp_type_d = CAUSE_ERROR;
                        end
                    
                    end
                endcase
            end
            //DONE: Add read, write commands
            default: begin
                if(addr_offset <= READWRITE_MAX_OFFSET && obi_req_i.req) begin
                    // Transparent command
                    if(obi_req_i.a.we) begin
                        // Write command
                        case(cnt_cmd_i)
                            8'd198: begin
                                compare_data = 32'hFFFF_FF00;
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd68: begin
                                compare_data = 32'hFFFF_FF05;
                                mask = 32'h0000_001F;
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd1: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = ERROR;
                            end
                            default: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;

                                if(cnt_cmd_i > 8'd1 && cnt_cmd_i < 8'd68) begin
                                    compare_data = 32'hFFFF_FFFF;
                                    mask = 32'h0000_0001;
                                    resp_type_d = CAUSE_VALIDATION; 
                                end                     
                            end
                        endcase
                    end else begin
                        // Read command
                        case(cnt_cmd_i)
                            8'd130: begin
                                compare_data = 32'hFFFF_FF00;
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd129: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;
                            end
                            8'd128: begin
                                compare_data = 32'hXXXX_XXXX;
                                resp_type_d = PASSTHROUGH;
                            end
                            8'd1: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = ERROR;
                            end
                            // 8'd128: begin
                            //     compare_data = 32'hXXXX_XXXX;
                            //     resp_type_d = VALIDATE; //TODO: HANDLE THE REST OF THE INCOMMING DATA
                            // end
                            default: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;
                                if(cnt_cmd_i > 8'd1 && cnt_cmd_i < 8'd128) begin
                                    compare_data = 32'hFFFF_FFFF;
                                    resp_type_d = CHECK_IF_DATA;
                                end
                            end
                        endcase
                    end

                end else if (addr_offset >= BLOCK_READWRITE_MIN_OFFSET && addr_offset <= BLOCK_READWRITE_MAX_OFFSET && obi_req_i.req) begin
                    // Block swap commands
                    if(obi_req_i.a.we) begin
                        // Write command
                        case(cnt_cmd_i)
                            8'd198: begin
                                compare_data = 32'hFFFF_FF00;
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd67: begin
                                compare_data = 32'hFFFF_28FF; // WAS 32'hFFFF_FF05
                                mask = 32'h0000_F800; // WAS 32'h0000_001F
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd1: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = ERROR;
                            end
                            default: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;

                                if(cnt_cmd_i > 8'd1 && cnt_cmd_i < 8'd67) begin
                                    compare_data = 32'hFFFF_FFFF;
                                    mask = 32'h0000_0001;
                                    resp_type_d = CAUSE_VALIDATION; 
                                end                     
                            end
                        endcase
                    end else begin
                        // Read command
                        block_swap_first_read_word_d = block_swap_first_read_word_q;
                        case(cnt_cmd_i)
                            8'd200: begin
                                block_swap_first_read_word_d = 'd0;
                            end
                            8'd198: begin
                                block_swap_first_read_word_d = 'd0;
                                compare_data = 32'hFFFF_FF00;
                                resp_type_d = CAUSE_ERROR;
                            end
                            8'd197: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;
                            end
                            // 8'd196: begin
                            //     compare_data = 32'hXXXX_XXXX;
                            //     resp_type_d = PASSTHROUGH;
                            // end
                            // ONLY CHANGED FOR VERILATOR
                            8'd1: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = ERROR;
                            end
                            // 8'd128: begin
                            //     compare_data = 32'hXXXX_XXXX;
                            //     resp_type_d = VALIDATE; //TODO: HANDLE THE REST OF THE INCOMMING DATA
                            // end
                            default: begin
                                compare_data = 32'hFFFF_FFFF;
                                resp_type_d = PASSTHROUGH;
                                if(cnt_cmd_i > 8'd1 && cnt_cmd_i <= 8'd196) begin
                                    if(block_swap_first_read_word_q == 'd0) begin
                                        if(data_is_read_q) begin
                                            block_swap_first_read_word_d = cnt_cmd_i;
                                        end
                                    end else begin
                                        read_data_o = data_i;
                                        if(cnt_cmd_i > (block_swap_first_read_word_q - 8'd128)) begin
                                            resp_type_d = PASSTHROUGH;
                                        end else begin
                                            resp_type_d = VALIDATE;
                                            block_swap_first_read_word_d = '0;                          
                                        end
                                    end
                                end
                            end
                        endcase
                    end
                end else begin
                    resp_type_d = PASSTHROUGH;
                    compare_data = 32'hXXXX_XXXX;
                end
                
            end
        endcase
    end


`FF(resp_type_q, resp_type_d, PASSTHROUGH, tspi_clk_i, rst_ni) //TODO: Include something like:  | obi_req_i.req
`FF(block_swap_first_read_word_q, block_swap_first_read_word_d, '0, tspi_clk_i, rst_ni) //TODO: Include something like:  | obi_req_i.req
    
endmodule
  