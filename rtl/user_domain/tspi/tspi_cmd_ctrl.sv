// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"


module tspi_cmd_ctrl import tspi_pkg::*; #(
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


    // Shift register interface
    output logic en_write_o,
    output logic [ObiCfg.DataWidth-1:0] data_o,

    output logic new_req_o,

    output config_reg_t config_reg_o,

    output logic [7:0] cnt_cmd_o,
    output logic [5:0] len_cmd_o,
    input logic [7:0] cnt_cmd_i,

    output logic en_port_ctrl_o,
    output logic beginning_o,

    input logic [31:0] write_data_i, // DONE
    output logic signal_next_write_data_o, // DONE
    input logic new_cmd_i, // DONE

    input logic [7:0] block_swap_first_read_word_i,
    input logic done_i //initial part DONE: Implement
);

logic [31:0] addr_offset_temp;
logic [AddressBits-1:0] addr_offset;
logic tspi_on_d, tspi_on_q;
config_reg_t config_reg_d, config_reg_q;
// Detect positive edge of request
logic prev_req_q;

assign addr_offset_temp = obi_req_i.a.addr;
assign addr_offset = addr_offset_temp[AddressBits-1:0]; // DONE: Change to be variable dependent



assign new_req_o = obi_req_i.req && !prev_req_q;

assign config_reg_o = config_reg_q;

// Signal next write data
always_comb begin
    signal_next_write_data_o = 1'b0; // Default value
    if(addr_offset >= BLOCK_READWRITE_MIN_OFFSET && addr_offset <= BLOCK_READWRITE_MAX_OFFSET && obi_req_i.req && obi_req_i.a.we) begin
        if(8'd68 < cnt_cmd_i && cnt_cmd_i <= 8'd196) begin
            if(new_cmd_i) begin
                signal_next_write_data_o = 1'b1;
            end else begin
                signal_next_write_data_o = 1'b0;
            end
        end
    end
end

//DONE: Add port control
always_comb begin
    if(obi_req_i.req) begin
        tspi_on_d = 1'b1;
    end
    if(done_i) begin
        tspi_on_d = 1'b0;
    end
    
end

assign en_port_ctrl_o = obi_req_i.req;

////////////////////////////////////////////////////////////////////////////////////////////////
// COMMAND SEQUENCE //
////////////////////////////////////////////////////////////////////////////////////////////////
always_comb begin : cmdSeq
    config_reg_d = config_reg_q;
    case(addr_offset)
        BEGINNING_OFFSET: begin
            data_o = 32'hFFFF_FFFF;
            en_write_o = 1'b0;
        end
        BUFFER_OFFSET: begin
            data_o = 32'hFFFF_FFFF;
            en_write_o = 1'b0;
        end
        CHANGE_BAUDRATE_OFFSET: begin
            data_o = 32'hFFFF_FFFF;
            en_write_o = 1'b0;
            config_reg_d.baudrate_div = obi_req_i.a.wdata[7:0];
        end
        CMD0_OFFSET: begin
            case(cnt_cmd_i)
                8'd3: begin
                    data_o = 32'hFF40_0000;
                    en_write_o = 1'b1;
                end
                8'd2: begin
                    data_o = 32'h0000_95FF;
                    en_write_o = 1'b1;
                end
                default: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                
                end
            endcase
        end
        CMD8_OFFSET: begin
            case(cnt_cmd_i)
                8'd4: begin
                    data_o = 32'hFF48_0000;
                    en_write_o = 1'b1;
                end
                8'd3: begin
                    data_o = 32'h01AA_87FF;
                    en_write_o = 1'b1;
                end
                default: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                
                end
            endcase
        end
        CMD59_OFFSET: begin
            case(cnt_cmd_i)
                8'd3: begin
                    data_o = 32'hFF7B_0000;
                    en_write_o = 1'b1;
                end
                8'd2: begin
                    data_o = 32'h0000_91FF;
                    en_write_o = 1'b1;
                end
                default: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                
                end
            endcase
        end
        CMD58_OFFSET: begin
            case(cnt_cmd_i)
                8'd4: begin
                    data_o = 32'hFF7A_0000;
                    en_write_o = 1'b1;
                end
                8'd3: begin
                    data_o = 32'h0000_01FF;
                    en_write_o = 1'b1;
                end
                default: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                
                end
            endcase
        end
        ACMD41_OFFSET: begin
            // Loop needs to be asserted
            case(cnt_cmd_i[2:0])
                3'd7: begin
                    data_o = 32'hFF77_0000;
                    en_write_o = 1'b1;
                end
                8'd6: begin
                    data_o = 32'h0000_01FF;
                    en_write_o = 1'b1;
                end
                8'd5: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                end
                8'd4: begin
                    data_o = 32'hFF69_4000;
                    en_write_o = 1'b1;
                end
                8'd3: begin
                    data_o = 32'h0000_01FF;
                    en_write_o = 1'b1;
                end
                8'd2: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                end
                8'd1: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                end
                8'd0: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                end
                default: begin
                    data_o = 32'hFFFF_FFFF;
                    en_write_o = 1'b0;
                
                end
            endcase
        end
        //DONE: Add read, write commands
        default: begin
            // Transparent command
            if(addr_offset <= READWRITE_MAX_OFFSET && obi_req_i.req) begin
                if(obi_req_i.a.we) begin
                    // Write command
                    case(cnt_cmd_i)
                        8'd200: begin
                            data_o = 32'hFF58_0000 | {21'd0, addr_offset[28:18]};
                            en_write_o = 1'b1;
                        end
                        8'd199: begin
                            data_o = 32'h0000_01FF | {addr_offset[17:2], 16'd0}; // Shifted by 2
                            en_write_o = 1'b1;
                        end
                        8'd198: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;
                        end
                        8'd197: begin
                            data_o = 32'hFFFE_0000 | {16'd0, obi_req_i.a.wdata[31:16]};
                            en_write_o = 1'b1;
                        end
                        8'd196: begin
                            data_o = 32'h0000_FFFF | {obi_req_i.a.wdata[15:0], 16'd0};
                            en_write_o = 1'b1;
                        end
                        8'd69: begin
                            data_o = 32'h0000_FFFF;
                            en_write_o = 1'b1;
                        end
                        8'd68: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;
                        end
                        default: begin
                            if(8'd69 < cnt_cmd_i && cnt_cmd_i < 8'd196) begin
                                data_o = obi_req_i.a.wdata;
                                en_write_o = 1'b1;
                            end else begin
                                data_o = 32'hFFFF_FFFF;
                                en_write_o = 1'b0;
                            end                      
                        end
                    endcase
                end else begin
                    // Read command
                    case(cnt_cmd_i)
                        8'd132: begin
                            data_o = 32'hFF51_0000 | {21'd0, addr_offset[28:18]};
                            en_write_o = 1'b1;
                        end
                        8'd131: begin
                            data_o = 32'h0000_01FF | {addr_offset[17:2], 16'd0}; // Shifted by 2
                            en_write_o = 1'b1;
                        end
                        8'd129: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b1;
                        end
                        default: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;                 
                        end
                    endcase
                end

            end else if(addr_offset >= BLOCK_READWRITE_MIN_OFFSET && addr_offset <= BLOCK_READWRITE_MAX_OFFSET && obi_req_i.req) begin
                // Block swap command
                if(obi_req_i.a.we) begin
                    // Write command
                    case(cnt_cmd_i)
                        8'd200: begin
                            data_o = 32'hFF58_0000 | {18'd0, addr_offset[28:16]}; // TODO: Check
                            en_write_o = 1'b1;
                        end
                        8'd199: begin
                            data_o = 32'h0000_01FF | {addr_offset[15:0], 16'd0}; // Shifted by 2
                            en_write_o = 1'b1;
                        end
                        8'd198: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;
                        end
                        8'd197: begin
                            data_o = 32'hFFFE_0000;// TODO: Check if the write works correctly for shorter command
                            en_write_o = 1'b1;
                        end
                        8'd196: begin
                            data_o = write_data_i; 
                            en_write_o = 1'b1;
                        end
                        8'd68: begin
                            data_o = 32'h0000_FFFF;
                            en_write_o = 1'b1;
                        end
                        8'd67: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;
                        end
                        default: begin
                            if(8'd68 < cnt_cmd_i && cnt_cmd_i < 8'd196) begin
                                data_o = write_data_i;
                                en_write_o = 1'b1;
                            end else begin
                                data_o = 32'hFFFF_FFFF;
                                en_write_o = 1'b0;
                            end                      
                        end
                    endcase
                end else begin
                    // Read command
                    case(cnt_cmd_i)
                        8'd200: begin
                            data_o = 32'hFF51_0000 | {18'd0, addr_offset[28:16]}; // TODO: Check
                            en_write_o = 1'b1;
                        end
                        8'd199: begin
                            data_o = 32'h0000_01FF | {addr_offset[15:0], 16'd0}; // Shifted by 2
                            en_write_o = 1'b1;
                        end
                        8'd197: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b1;
                        end
                        default: begin
                            data_o = 32'hFFFF_FFFF;
                            en_write_o = 1'b0;                 
                        end
                    endcase
                end

            end else begin
                data_o = 32'hFFFF_FFFF;
                en_write_o = 1'b0;
            end
        end
    endcase


    if(new_req_o) begin // Changed from obi_req_i.req
        en_write_o = 1'b1;
    end
    
end

////////////////////////////////////////////////////////////////////////////////////////////////
// COMMAND LENGTH //
////////////////////////////////////////////////////////////////////////////////////////////////

always_comb begin : cmdLen
    beginning_o = 1'b0;
    case(addr_offset)
        BEGINNING_OFFSET: begin
            cnt_cmd_o = 8'd4;
            len_cmd_o = 6'd31;
            beginning_o = 1'b1;
        end
        BUFFER_OFFSET: begin
            cnt_cmd_o = 8'd2;
            len_cmd_o = 6'd31;
        end
        CHANGE_BAUDRATE_OFFSET: begin
            cnt_cmd_o = 8'd2;
            len_cmd_o = 6'd5;
        end
        CMD0_OFFSET: begin
            cnt_cmd_o = 8'd3;
            if(cnt_cmd_i > 8'd1) begin
                len_cmd_o = 6'd31;
            end else begin
                len_cmd_o = 6'd7;
            end
        end
        CMD8_OFFSET: begin
            cnt_cmd_o = 8'd4;
            if(cnt_cmd_i > 8'd1) begin
                len_cmd_o = 6'd31;
            end else begin
                len_cmd_o = 6'd7;
            end
        end
        CMD59_OFFSET: begin
            cnt_cmd_o = 8'd3;
            if(cnt_cmd_i > 8'd1) begin
                len_cmd_o = 6'd31;
            end else begin
                len_cmd_o = 6'd7;
            end
        end
        CMD58_OFFSET: begin
            cnt_cmd_o = 8'd4;
            if(cnt_cmd_i > 8'd1) begin
                len_cmd_o = 6'd31;
            end else begin
                len_cmd_o = 6'd7;
            end
        end
        ACMD41_OFFSET: begin
            // Loop needs to be asserted
            cnt_cmd_o = 8'd79;
            if(cnt_cmd_i > 8'd1) begin
                len_cmd_o = 6'd31;
            end else begin
                len_cmd_o = 6'd7;
            end
            case(cnt_cmd_i[2:0])
                3'd7: begin
                    len_cmd_o = 6'd31;
                end
                8'd6: begin
                    len_cmd_o = 6'd31;
                end
                8'd5: begin
                    len_cmd_o = 6'd7;
                end
                8'd4: begin
                     len_cmd_o = 6'd31;
                end
                8'd3: begin
                     len_cmd_o = 6'd31;
                end
                8'd2: begin
                     len_cmd_o = 6'd7;
                end
                8'd1: begin
                    len_cmd_o = 6'd31;
                end
                8'd0: begin
                    len_cmd_o = 6'd31;
                end
                default: begin
                    len_cmd_o = 6'd31;
                
                end
            endcase
        end
        //DONE: Add read, write commands
        default: begin
            // Transparent command
            if(addr_offset <= READWRITE_MAX_OFFSET && obi_req_i.req) begin
                if(obi_req_i.a.we) begin
                    // Write command
                    cnt_cmd_o = 8'd200;
                    if(cnt_cmd_i == 8'd198 || (8'd0 < cnt_cmd_i && cnt_cmd_i < 8'd68)) begin
                        len_cmd_o = 6'd7;
                    end else if(cnt_cmd_i == 8'd69) begin
                        len_cmd_o = 6'd31; // Was 6'd31
                    end else if(cnt_cmd_i == 8'd68) begin
                        len_cmd_o = 6'd4; // Change this maybe to wait longer (len_cmd_o = 6'd31, mask = 32'hF800_0000)
                    end else begin
                        len_cmd_o = 6'd31;
                    end
                end else begin
                    // Read command
                    cnt_cmd_o = 8'd132;
                    if(cnt_cmd_i >= 8'd131) begin
                        len_cmd_o = 6'd31;
                    end else if(cnt_cmd_i == 8'd130) begin
                        len_cmd_o = 6'd7;
                    end else if(cnt_cmd_i == 8'd129) begin
                        len_cmd_o = 6'd7;
                    end else begin
                        len_cmd_o = 6'd32; // TODO: Adapt this once we read multiple words
                    end
                end

            end else if(addr_offset >= BLOCK_READWRITE_MIN_OFFSET && addr_offset <= BLOCK_READWRITE_MAX_OFFSET && obi_req_i.req) begin
                // Block swap command
                if(obi_req_i.a.we) begin
                    // Write command
                    cnt_cmd_o = 8'd200;
                    if(cnt_cmd_i == 8'd198 || (8'd0 < cnt_cmd_i && cnt_cmd_i < 8'd68)) begin
                        len_cmd_o = 6'd7;
                    end else if(cnt_cmd_i == 8'd197) begin
                        len_cmd_o = 6'd15;
                    end else if(cnt_cmd_i == 8'd68) begin
                        len_cmd_o = 6'd27; // Was 6'd31 MAYBE 15
                    end else if(cnt_cmd_i == 8'd67) begin
                        len_cmd_o = 6'd15; // Change this maybe to wait longer (len_cmd_o = 6'd31, mask = 32'hF800_0000) TODO: WAS 4
                    end else begin
                        len_cmd_o = 6'd31;
                    end
                end else begin
                    // Read command
                    cnt_cmd_o = 8'd200;
                    if(cnt_cmd_i >= 8'd199) begin
                        len_cmd_o = 6'd31;
                    end else if(cnt_cmd_i == 8'd198) begin
                        len_cmd_o = 6'd7;
                    end else if(cnt_cmd_i == 8'd197) begin
                        len_cmd_o = 6'd7;
                    end else begin
                        len_cmd_o = 6'd32; // DONE: Adapt this once we read multiple words
                    
                        if(cnt_cmd_i <  8'd196) begin
                            if(block_swap_first_read_word_i != 8'd0 && cnt_cmd_i != block_swap_first_read_word_i) begin
                                len_cmd_o = 6'd31;
                            end
                        end
                    end
                end


            end else begin
                cnt_cmd_o = 8'h00;
                len_cmd_o = 6'h0;
            end
        end
    endcase
end

`FF(tspi_on_q ,tspi_on_d , '0, clk_i, rst_ni)
`FF(prev_req_q, obi_req_i.req, '0, clk_i, rst_ni)
`FF(config_reg_q ,config_reg_d , 8'h19, clk_i, rst_ni)

endmodule