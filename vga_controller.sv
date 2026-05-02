/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           VGA Controller Module
// Filename:                        vga_controller.sv
// Version:                         6
// Author:                          Daniel J. Lomis 
// Date:                            4/8/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4514 - Digital Design II 
// Instructor:                      Professor Jason Thweatt 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
// 
// Description:                     This module represents the colmination of several modules.
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/8/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module vga_controller (
    input                                   logic                                   vga_clock,
    input                                   logic                                   reset_active_low,
    output                                  logic                                   sync_n,
    output                                  logic                                   blank_n,
    output                                  logic                                   hsync_n,
    output                                  logic                                   vsync_n,
    output                                  logic               [10:0]              hcount_out,
    output                                  logic               [9:0]               vcount_out,
    output                                  logic                                   frame_tick
);
    // Internal Register-derived Connections
                                            logic               [31:0]              h_next;
                                            logic               [31:0]              v_next;
                                            logic               [31:0]              hcount;
                                            logic               [31:0]              vcount;
                                            logic                                   vsync_r;

    // HD 1280x720 @ 60Hz timing parameters
    localparam                              H_TOTAL                                 = 1650;
    localparam                              H_ACTIVE                                = 1280;
    localparam                              H_FP                                    = 110;
    localparam                              H_SYNC                                  = 40;
    localparam                              H_BP                                    = 220;
    localparam                              V_TOTAL                                 = 750;
    localparam                              V_ACTIVE                                = 720;
    localparam                              V_FP                                    = 5;
    localparam                              V_SYNC                                  = 5;
    localparam                              V_BP                                    = 20;

    // Horizontal counter
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            hcount <= 0;
        end
        else begin
            hcount <= h_next;
        end
    end

    always_comb begin
        if (hcount == H_TOTAL - 1) begin
            h_next = 0;
        end
        else begin
            h_next = hcount + 1;
        end
    end

    // Vertical counter
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            vcount <= 0;
        end
        else if (hcount == H_TOTAL - 1) begin
            if (vcount == V_TOTAL - 1) begin
                vcount <= 0;
            end
            else begin
                vcount <= vcount + 1;
            end
        end
    end

    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            sync_n <= 1;
        end
        else begin
            sync_n <= 0;
        end
    end

    // Frame Tick
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            vsync_r <= 1'b1;
        end
        else begin
            vsync_r <= vsync_n;
        end
    end

    assign                                  hsync_n                                 = (hcount >= H_ACTIVE + H_FP && hcount < H_ACTIVE + H_FP + H_SYNC) ? 1'b0 : 1'b1;
    assign                                  vsync_n                                 = (vcount >= V_ACTIVE + V_FP && vcount < V_ACTIVE + V_FP + V_SYNC) ? 1'b0 : 1'b1;
    assign                                  blank_n                                 = (hcount < H_ACTIVE && vcount < V_ACTIVE) ? 1'b1 : 1'b0;
    assign                                  hcount_out                              = hcount[10:0];
    assign                                  vcount_out                              = vcount[9:0];
    assign                                  frame_tick                              = vsync_r & ~vsync_n;

endmodule