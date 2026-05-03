/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Stereo Sound Chip Streamer Module (I2S)
// Filename:                        i2s_transmitter.sv
// Version:                         7
// Author:                          Daniel J. Lomis 
// Date:                            4/20/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4514 - Digital Design II 
// Instructor:                      Professor Jason Thweatt 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
// 
// Description:                     Configures the WM8731 over I2C (2-wire, 100 kHz) on power-up.
//                                  Runs on 50 MHz sysclock.
//
//                                  I2C transaction format for WM8731:
//                                      [START] [0x34 (device addr, R/W=0)] [ACK] [B15:B8] [ACK] [B7:B0] [ACK] [STOP]
//                                      where B[15:9] = register address, B[8:0] = register data.
//
//                                  The controller steps through CONFIG_REGS[] automatically from reset.
//                                  config_done goes high and stays high once all registers are written.
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/20/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module i2s_transmitter
(
    input                                   logic                                   clock_12m288,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   bclk,
    input                                   logic                                   lrclk,
    input                                   logic               [15:0]              bit_sample_in,
    output                                  logic                                   dacdat
);
    // Internal Wire Connections
                                            wire                                    bclk_fall;
                                            wire                                    lrclk_rise;
                                            wire                                    lrclk_fall;
    // Internal Register-based Connections
                                            logic                                   bclk_prev;
                                            logic                                   lrclk_prev;
                                            logic               [15:0]              left_sample;
                                            logic               [15:0]              right_sample;
                                            logic               [15:0]              left_shift;
                                            logic               [15:0]              right_shift;
                                            logic               [4:0]               bit_cnt;
                                            logic                                   i2s_delay;
                                            logic                                   tx_left;
    // Buffer
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            bclk_prev <= 1'b1;
            lrclk_prev <= 1'b0;
        end else begin
            bclk_prev <= bclk;
            lrclk_prev <= lrclk;
        end
    end
    // Main Bit Shifter Transmitter
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            left_shift <= '0;
            right_shift <= '0;
            bit_cnt <= '0;
            i2s_delay <= 1'b0;
            tx_left <= 1'b1;
            dacdat <= 1'b0;
        end
        else begin
            // Preload Payload
            if (lrclk_rise) begin
                left_shift <= left_sample;
                tx_left <= 1'b0;
                bit_cnt <= '0;
                i2s_delay <= 1'b1;
            end
            else if (lrclk_fall) begin
                right_shift <= right_sample;
                tx_left <= 1'b1;
                bit_cnt <= '0;
                i2s_delay <= 1'b1;
            end
            // Bit Shift Out
            else if (bclk_fall) begin
                if (i2s_delay) begin
                    dacdat <= 1'b0;
                    i2s_delay <= 1'b0;
                end 
                else if (bit_cnt < 16) begin
                    if (tx_left) begin
                        dacdat <= left_shift[15];
                        left_shift <= {left_shift[14:0], 1'b0};
                    end 
                    else begin
                        dacdat <= right_shift[15];
                        right_shift <= {right_shift[14:0], 1'b0};
                    end
                    bit_cnt <= bit_cnt + 1'b1;
                end
                else begin
                    dacdat <= 1'b0;
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
        end
    end

    // Continous Assignments
    assign                                  bclk_fall                               = ~bclk & bclk_prev;
    assign                                  lrclk_rise                              = lrclk & ~lrclk_prev;
    assign                                  lrclk_fall                              = ~lrclk & lrclk_prev;
    assign                                  left_sample                             = bit_sample_in;
    assign                                  right_sample                            = bit_sample_in;

endmodule