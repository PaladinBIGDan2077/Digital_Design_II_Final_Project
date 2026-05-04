/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           VGA Display Raster Generator Top Module
// Filename:                        vga_generator_output_top.sv
// Version:                         2
// Author:                          Daniel J. Lomis
// Date:                            4/10/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Integrates VGA clock generation (PLL), reset synchronization,
//                                  and VGA timing controller. Derives the VGA pixel clock from
//                                  the 50 MHz system clock via a Quartus-generated PLL IP core
//                                  (vga_pll_widescreen). The PLL lock signal is gated with the
//                                  active-low reset via pll_reset module to gate downstream logic.
//                                  Outputs include VGA sync/blank/HS/VS signals, pixel clock,
//                                  and scan position counters (hcount_out, vcount_out) for the
//                                  renderer, along with frame_tick (60 Hz strobe) for game logic.
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/10/2025   DJL  1        Original Code; basic PLL instantiation
//                                  4/14/2025   DJL  2        Added pll_reset gating; separated reset synchronization from clock generation for cleaner timing
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module vga_generator_output_top
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    output                                  logic                                   VGA_SYNC_N,
    output                                  logic                                   VGA_BLANK_N,
    output                                  logic                                   VGA_HS_N,
    output                                  logic                                   VGA_VS_N,
    output                                  logic                                   VGA_CLK,
    output                                  logic               [10:0]              hcount_out,
    output                                  logic               [9:0]               vcount_out,
    output                                  logic                                   frame_tick
);
    // Internal Connections
                                            wire                                    reset_pll_line;
                                            wire                                    reset_active_high;
                                            wire                                    reset_phase_locked;
                                            wire                                    clock_vga;
    // Internal Register-based Connections
                                            logic               [15:0]              data_stream_16bit;
                                            logic               [16:0]              rom_address_17bit;
                                            logic               [15:0]              sound_stream;
    // Reset Circuits
    reset_inverter                          vga_clock_reset                         (
                                                                                    .a(reset_active_low),
                                                                                    .b(reset_active_high)
                                                                                    );
    // Reset Circuits
    pll_reset                               pll_vga_reset                           (
                                                                                    .pll_locked(reset_pll_line),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .clock_signal_ready(reset_phase_locked)
                                                                                    );

    // Clock Generation
    vga_pll_widescreen                      vga_pll_clock                           (
                                                                                    .refclk(clock),
                                                                                    .rst(reset_active_high),
                                                                                    .outclk_0(clock_vga),
                                                                                    .locked(reset_pll_line)
                                                                                    );
    // VGA Controller
    vga_controller                          video_module                            (
                                                                                    .vga_clock(clock_vga),
                                                                                    .reset_active_low(reset_phase_locked),
                                                                                    .sync_n(VGA_SYNC_N),
                                                                                    .blank_n(VGA_BLANK_N),
                                                                                    .hsync_n(VGA_HS_N),
                                                                                    .vsync_n(VGA_VS_N),
                                                                                    .hcount_out(hcount_out),
                                                                                    .vcount_out(vcount_out),
                                                                                    .frame_tick(frame_tick)
                                                                                    );
    // Continous Assignment
    assign                                  VGA_CLK                                 = clock_vga;

endmodule