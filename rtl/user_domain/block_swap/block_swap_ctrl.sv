// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Dumeni Rischatsch <drischatsch@student.ethz.ch>
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

typedef enum bit [1:0] {
    IDLE,
    WRITE_TO_SRAM_FROM_SD_CARD,
    WAIT_ONE_CYCLE,
    WRITE_TO_SD_CARD_FROM_SRAM
} block_swap_state_t;

module block_swap_ctrl import croc_pkg::*; import tspi_pkg::*; import user_pkg::*; #(

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

    input logic swap_req_i,

    input logic [$clog2(NUM_SRAM_ADDRESSES)-1:0] old_addr_idx_i,

    input logic [20:0] old_addr_i,
    input logic [20:0] new_addr_i,

    output logic done_o,

    input logic block_only_load_on_i,

    // OBI request interface
    output  obi_req_t sram_obi_req_o,
    input obi_rsp_t sram_obi_rsp_i,

    output  sbr_obi_req_t sdcard_obi_req_o,
    input sbr_obi_rsp_t sdcard_obi_rsp_i,

    // tspi interface
    output logic [31:0] write_data_o,
    input logic [31:0] read_data_i,
    input logic signal_next_write_data_i,
    input logic signal_next_read_data_i
);

logic [31:0] sram_addr;

logic [31:0] data_d, data_q;

block_swap_state_t state_d, state_q;

logic edge_detection_d, edge_detection_q;

logic [6:0] count_d, count_q; // Count up to 128
logic counter_done;

// logic sram_req_d, sram_req_q;
// logic sdcard_req_d, sdcard_req_q;


assign sram_addr = FIRST_USABLE_SRAM_ADDR + (old_addr_idx_i<<9);



// Change between states
always_comb begin
    done_o = 1'b0;
    state_d = state_q;

    case (state_q)
        IDLE: begin
            if (swap_req_i) begin
                if(block_only_load_on_i) begin
                    state_d = WRITE_TO_SRAM_FROM_SD_CARD;
                end else begin
                    state_d = WRITE_TO_SD_CARD_FROM_SRAM;
                end
                // count_d = 0; TODO: check if count_d works as expected
            end
        end

        WRITE_TO_SD_CARD_FROM_SRAM: begin
            if (counter_done) begin //DONE: change to correct condition was:sdcard_obi_rsp_i.rvalid
                state_d = WAIT_ONE_CYCLE;
                // count_d = 0;
            end
        end

        WAIT_ONE_CYCLE: begin

            state_d = WRITE_TO_SRAM_FROM_SD_CARD;

        end

        WRITE_TO_SRAM_FROM_SD_CARD: begin
            if (counter_done) begin //DONE: change to correct condition
                state_d = IDLE;
                done_o = 1'b1;
            end
        end
        default: begin
            state_d = IDLE;
        end
    endcase    
end

// Operations for each state
always_comb begin
    data_d = data_q;

    write_data_o = '0;
    sram_obi_req_o = '0;
    sdcard_obi_req_o = '0;

    count_d = count_q;
    counter_done = 1'b0;

    // sram_req_d = sram_req_q;
    // sdcard_req_d = sdcard_req_q;

    // sram_obi_req_o.req = sram_req_q;
    // sdcard_obi_req_o.req = sdcard_req_q;

    case (state_q)
        IDLE: begin
            sram_obi_req_o = '0;
            sdcard_obi_req_o = '0;
            edge_detection_d = '0;
        end

        WRITE_TO_SD_CARD_FROM_SRAM: begin

            edge_detection_d = signal_next_write_data_i;
            
            sram_obi_req_o = '0;

            write_data_o = data_q;

            sdcard_obi_req_o.req = 1'b1;
            // sdcard_req_d = 1'b1;

            // Address Phase Signals
            sdcard_obi_req_o.a.addr = UserTransparentSpiAddrOffset + BLOCK_READWRITE_MIN_OFFSET + old_addr_i; // DONE: Change when addresses are shorter
            sdcard_obi_req_o.a.we = 1'b1;
            sdcard_obi_req_o.a.be = 4'b1111;
            sdcard_obi_req_o.a.wdata = data_q;
            sdcard_obi_req_o.a.aid = '1; // TODO: put proper id


            if(sdcard_obi_rsp_i.r.err == 1'b1 && sdcard_obi_rsp_i.rvalid) begin
                    // TODO: Handle error
                    counter_done = 1'b1;
            end
            // TODO: Mistake is in here
            if (sdcard_obi_rsp_i.rvalid && count_q >= 50) begin //TESTING
                sdcard_obi_req_o = '0;
                sdcard_obi_req_o.req = 1'b0;
                // sdcard_req_d = 1'b0;

                counter_done = 1'b1; //TESTING
            end

            if(edge_detection_q == 1'b0 && signal_next_write_data_i == 1'b1) begin
                sram_obi_req_o.req = 1'b1;

                // Directly stop req signal
                // sram_req_d = 1'b0;

                // Address Phase Signals
                sram_obi_req_o.a.addr = sram_addr | (count_q << 2); // TODO: Check if correct
                sram_obi_req_o.a.we = 1'b0;
                sram_obi_req_o.a.be = 4'b1111;
                sram_obi_req_o.a.wdata = '0;
                sram_obi_req_o.a.aid = '1; // TODO: put proper id
            end


            if(sram_obi_rsp_i.rvalid) begin
                data_d = sram_obi_rsp_i.r.rdata;
                // TODO: Check additional response signals
                sram_obi_req_o = '0;
                // sram_req_d = 1'b0;
                
                count_d = count_q + 1;

            end
        end

        WAIT_ONE_CYCLE: begin
            sram_obi_req_o = '0;
            sdcard_obi_req_o = '0;
            edge_detection_d = '0;
        end

        WRITE_TO_SRAM_FROM_SD_CARD: begin

            edge_detection_d = signal_next_read_data_i;

            sram_obi_req_o = '0;
            
            data_d = read_data_i;

            sdcard_obi_req_o.req = 1'b1;
            // sdcard_req_d = 1'b1;

            // Address Phase Signals
            sdcard_obi_req_o.a.addr = UserTransparentSpiAddrOffset + BLOCK_READWRITE_MIN_OFFSET + new_addr_i; // DONE: Change when addresses are shorter
            sdcard_obi_req_o.a.we = 1'b0;
            sdcard_obi_req_o.a.be = 4'b1111;
            sdcard_obi_req_o.a.wdata = '0;
            sdcard_obi_req_o.a.aid = '1; // TODO: put proper id

            if (sdcard_obi_rsp_i.rvalid && count_q >= 50) begin
                sdcard_obi_req_o = '0;
                sdcard_obi_req_o.req = 1'b0;
                // sdcard_req_d = 1'b0;

                if(sdcard_obi_rsp_i.r.err == 1'b1) begin
                    // TODO: Handle error
                end
            end

            if (edge_detection_q == 1'b0 && signal_next_read_data_i == 1'b1) begin
                sram_obi_req_o.req = 1'b1;

                // Directly stop req signal
                // sram_req_d = 1'b0;

                // Address Phase Signals
                sram_obi_req_o.a.addr = sram_addr | (count_q << 2); // TODO: Check if correct
                sram_obi_req_o.a.we = 1'b1;
                sram_obi_req_o.a.be = 4'b1111;
                sram_obi_req_o.a.wdata = data_q;
                sram_obi_req_o.a.aid = '1; // TODO: put proper id
            end



            if(sram_obi_rsp_i.rvalid) begin
                // TODO: Check additional response signals
                sram_obi_req_o = '0;
                // sram_req_d = 1'b0;

                if(count_q == 127) begin
                    counter_done = 1'b1;
                end else begin
                    counter_done = 1'b0;
                end
                count_d = count_q + 1;
            end
        end
        default: begin

        end
    endcase
end






`FF(state_q, state_d, IDLE, clk_i, rst_ni)
`FF(data_q, data_d, '0, clk_i, rst_ni)
`FF(count_q, count_d, '0, clk_i, rst_ni)
`FF(edge_detection_q, edge_detection_d, '0, clk_i, rst_ni)

// `FF(sram_req_q, sram_req_d, '0, clk_i, rst_ni)
// `FF(sdcard_req_q, sdcard_req_d, '0, clk_i, rst_ni)

endmodule
