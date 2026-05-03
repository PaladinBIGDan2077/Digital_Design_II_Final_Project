/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Sound Generator Top Module
// Filename:                        sound_generator_top.sv
// Version:                         6
// Author:                          Daniel J. Lomis 
// Date:                            4/6/2025  
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
//                                  4/6/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module sound_effects_generator_top
(
    input                                                                           clock_50,
    input                                                                           reset_active_low,
    input                                                                           sel_gameover,
    input                                                                           sel_dead1,
    input                                                                           sel_dead2,
    input                                                                           sel_burger,
    input                                                                           sel_bullet1,
    input                                                                           sel_bullet2,
    input                                                       [3:0]               enemy_kill,
    output                                  logic                                   AUD_XCK,
    output                                  logic                                   AUD_DACDAT,
    output                                  logic                                   FPGA_I2C_SCLK,
    output                                  logic                                   FPGA_I2C_SDAT,
    output                                  logic                                   AUD_BCLK,
    output                                  logic                                   AUD_DACLRCK
);
    // Internal Connections
                                            wire                                    reset_pll_line;
                                            wire                                    reset_active_high;
                                            wire                                    reset_phase_locked;
                                            wire                                    clock_12m288;
                                            wire                                    clock_bclk;
                                            wire                                    clock_sampling;
                                            wire                                    sampling_pulse;
                                            wire                                    sel_bath;
                                            wire                                    sel_door;
                                            wire                                    sel_postal;
                                            wire                                    sel_squirrel;
                                            wire                                    seq_playing;
                                            wire                                    start_play;
                                            wire                                    play_pulse;
    // Internal Register-derived Connections
                                            logic                                   sel_dead;
                                            logic                                   sel_bullet;
                                            logic                                   play;
                                            logic               [16:0]              rom_address_17bit;
                                            logic               [2:0]               sound_effect_selector;
    // ROM Connections
                                            logic               [15:0]              sfx_data;
                                            logic               [15:0]              rom_data;

    // Reset Circuits
    reset_inverter                          sound_clock_reset                       (
                                                                                    .a(reset_active_low),
                                                                                    .b(reset_active_high)
                                                                                    );

    // Clock Generation
    wm8731_clockgen                         sound_clock                             (
                                                                                    .audio_clk_clk(clock_12m288),
                                                                                    .ref_clk_clk(clock_50),
                                                                                    .ref_reset_reset(reset_active_high),
                                                                                    .reset_source_reset(reset_pll_line)
                                                                                    );

    audio_clk_divider                       clock_dividers                          (
                                                                                    .clock_12m288(clock_12m288),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .bclk(clock_bclk),
                                                                                    .lrclk(clock_sampling),
                                                                                    .sample_pulse(sampling_pulse)
                                                                                    );

    // Sound Codec Configuration
    wm8731_i2c_config                       configuration_codec                     (
                                                                                    .clock(clock_50),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .i2c_sclk(FPGA_I2C_SCLK),
                                                                                    .i2c_sdat(FPGA_I2C_SDAT)
                                                                                    );

    // Audio Stream
    i2s_transmitter                         audio_stream                            (
                                                                                    .clock_12m288(clock_12m288),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .bclk(clock_bclk),
                                                                                    .lrclk(clock_sampling),
                                                                                    .bit_sample_in(sfx_data),
                                                                                    .dacdat(AUD_DACDAT)
                                                                                    );

    sound_sequencer                         audio_player                            (
                                                                                    .clock_12m288(clock_12m288),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .sample_pulse(sampling_pulse),
                                                                                    .sfx_select(sound_effect_selector),
                                                                                    .play_trigger(play),
                                                                                    .rom_addr(rom_address_17bit),
                                                                                    .playing(seq_playing)
                                                                                    );

    // ROMs
    sfx_rom                                 sound_fx_rom                            (
                                                                                    .address(rom_address_17bit),
                                                                                    .clock(clock_12m288),
                                                                                    .q(rom_data)
                                                                                    );

    // Sound Effect Selector
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            sound_effect_selector <= 3'o0;
            play <= 1'b0;
        end
        else begin
            play <= 1'b0;
            if (play_pulse) begin
                if (sel_bullet) begin
                    sound_effect_selector <= 3'o0;
                    play <= 1'b1;
                end
                else if (sel_burger) begin
                    sound_effect_selector <= 3'o1;
                    play <= 1'b1;
                end
                else if (enemy_kill[0]) begin
                    sound_effect_selector <= 3'o2;
                    play <= 1'b1;
                end
                else if (enemy_kill[1]) begin
                    sound_effect_selector <= 3'o3;
                    play <= 1'b1;
                end
                else if (enemy_kill[2]) begin
                    sound_effect_selector <= 3'o4;
                    play <= 1'b1;
                end
                else if (enemy_kill[3]) begin
                    sound_effect_selector <= 3'o5;
                    play <= 1'b1;
                end
                else if (sel_dead) begin
                    sound_effect_selector <= 3'o6;
                    play <= 1'b1;
                end
                else if (sel_gameover) begin
                    sound_effect_selector <= 3'o7;
                    play <= 1'b1;
                end
                else begin
                    sound_effect_selector <= 3'o0;
                    play <= 1'b1;
                end
            end
        end
    end

    // Continous Assignments
    assign                                  AUD_XCK                                 = clock_12m288;
    assign                                  AUD_DACLRCK                             = clock_sampling;
    assign                                  AUD_BCLK                                = clock_bclk;
    assign                                  sel_dead                                = sel_dead1 || sel_dead2;
    assign                                  sel_bullet                              = sel_bullet1 || sel_bullet2;
    assign                                  sfx_data                                = seq_playing ? rom_data : 16'h0000;
    assign                                  play_pulse                              = ((enemy_kill[0] == 1'b1) || (enemy_kill[1] == 1'b1) || (enemy_kill[2] == 1'b1) || (enemy_kill[3] == 1'b1) || sel_bullet || sel_dead || sel_burger || sel_gameover);

endmodule