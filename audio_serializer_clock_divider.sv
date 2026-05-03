/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Clock Dividers for Audio Subsystem
// Filename:                        audio_serializer_clock_divider.sv
// Version:                         3
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
//                                  Target: 8 kHz sample rate
//                                  BCLK   = 12.288 MHz / 24 = 512 kHz   (64 × 8 kHz)
//                                  LRCLK  = 512 kHz / 64   = 8 kHz
//
//                                  All outputs are registered on clock_12_288, so they are safe
//                                  synchronous signals without any gated clocks.
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/8/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module audio_clk_divider
(
    input                                   logic                                           clock_12m288,
    input                                   logic                                           reset_active_low,
    output                                  logic                                           bclk,
    output                                  logic                                           lrclk,
    output                                  logic                                           sample_pulse
);
    // Fraction Divider Parameters
    localparam                              BCLK_DIV                                        = 12;
    localparam                              LRCLK_DIV                                       = 32;
    // Internal Register-based Connections
                                            logic               [$clog2(BCLK_DIV)-1:0]      bclk_cnt;
                                            logic               [$clog2(LRCLK_DIV)-1:0]     lrclk_cnt;
                                            logic                                           bclk_int;
                                            logic                                           lrclk_int;
                                            logic                                           lrclk_prev;
                                            logic                                           sample_pulse_int;
                                            logic                                           bclk_prev;
                                            logic                                           bclk_rise;
    // BCLK Divider
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            bclk_cnt  <= '0;
            bclk_int  <= 1'b0;
        end 
        else begin
            if (bclk_cnt == BCLK_DIV - 1) begin
                bclk_cnt <= '0;
                bclk_int <= ~bclk_int;
            end 
            else begin
                bclk_cnt <= bclk_cnt + 1'b1;
            end
        end
    end
    
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            bclk_prev <= 1'b0;
        end
        else begin
            bclk_prev <= bclk_int;
        end
    end

    // LRCLK Divider
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            lrclk_cnt  <= '0;
            lrclk_int  <= 1'b0;
        end 
        else if (bclk_rise) begin
            if (lrclk_cnt == LRCLK_DIV - 1) begin
                lrclk_cnt <= '0;
                lrclk_int <= ~lrclk_int;
            end 
            else begin
                lrclk_cnt <= lrclk_cnt + 1'b1;
            end
        end
    end

    // Sample Pulse
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            lrclk_prev   <= 1'b0;
            sample_pulse <= 1'b0;
        end 
        else begin
            lrclk_prev   <= lrclk_int;
            sample_pulse <= lrclk_int & ~lrclk_prev;
        end
    end

    // Continous Assignments
    assign                                  bclk                                    = bclk_int;
    assign                                  lrclk                                   = lrclk_int;
    assign                                  bclk_rise                               = bclk_int & ~bclk_prev;

endmodule