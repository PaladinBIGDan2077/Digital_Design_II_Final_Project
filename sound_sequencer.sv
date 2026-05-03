/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Audio Sequencer Module for SoundFx
// Filename:                        sound_sequencer.sv
// Version:                         7
// Author:                          Daniel J. Lomis 
// Date:                            4/22/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4514 - Digital Design II 
// Instructor:                      Professor Jason Thweatt 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
// 
// Description:                     Lorem Ipsum
//
//                                  SFX table:
//                                  Index  Name              Start addr   Length (samples @ 8 kHz)
//                                  0      fire              0x00000      2,402
//                                  1      burger            0x0112E      4,303
//                                  2      kill_squirrel     0x02818      5,566
//                                  3      kill_truck        0x04833      4,783
//                                  4      kill_bathtub      0x0629E      14,997
//                                  5      kill_door         0x0A502      6,193
//                                  6      die               0x0CC33      7,586
//                                  7      game_over         0x0F316      18,397
//
//                                  Total ROM depth = 45,200 samples = 17-bit address space
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/22/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module sound_sequencer
(
    input                                   logic                                           clock_12m288,
    input                                   logic                                           reset_active_low,
    input                                   logic                                           sample_pulse,
    input                                   logic               [2:0]                       sfx_select,
    input                                   logic                                           play_trigger,
    output                                  logic               [16:0]                      rom_addr,
    output                                  logic                                           playing
);
    // Local Parameters
    localparam          sfx_entry_t         SFX_TABLE           [0:7]                       = '{
        '{17'h0_0000, 17'd02_402},   // 0: fire          (~0.300 s)
        '{17'h0_112E, 17'd04_303},   // 1: burger        (~0.538 s)
        '{17'h0_2818, 17'd05_566},   // 2: kill squrriel (~0.696 s)
        '{17'h0_4833, 17'd04_783},   // 3: kill truck    (~0.598 s)
        '{17'h0_629E, 17'd14_997},   // 4: kill bath     (~1.875 s)
        '{17'h0_A502, 17'd06_193},   // 5: kill door     (~0.774 s)
        '{17'h0_CC33, 17'd07_586},   // 6: die           (~0.948 s)
        '{17'h0_F316, 17'd18_397}    // 7: game over     (~2.299 s)
    };
    // Type Definitions of Structures/Enumerators
    typedef             struct              packed                                          {
                                            logic               [16:0]                      start;
                                            logic               [16:0]                      length;
    }   sfx_entry_t;

    sfx_entry_t     selected;

    typedef             enum                logic               [1:0]                       {
                                            IDLE                                            = 2'b00,
                                            PLAYING                                         = 2'b01,
                                            DONE                                            = 2'b10
    }   state_t;

    state_t         state, state_next;

    // Internal Register-based Connections
                                            logic               [16:0]                      addr;
                                            logic               [16:0]                      end_addr;
                                            logic               [16:0]                      addr_next;
                                            logic               [16:0]                      end_addr_next;

    // Selection Wheel for SoundFx
    always_comb begin
        selected = SFX_TABLE[sfx_select];
    end

    // Combiunational Logic FSM
    always_comb begin
        state_next = state;
        addr_next = addr;
        end_addr_next = end_addr;
        case (state)
            IDLE: begin
                if (play_trigger) begin
                    state_next = PLAYING;
                    addr_next = selected.start;
                    end_addr_next = selected.start + selected.length - 17'd1;
                end 
                else begin
                    addr_next = 17'd0;
                end
            end

            PLAYING: begin
                if (sample_pulse) begin
                    if (addr >= end_addr) begin
                        state_next = DONE;
                        addr_next = 17'd0;
                    end 
                    else begin
                        addr_next = addr + 17'd1;
                    end
                end
                else begin
                    addr_next = addr;
                end
            end

            DONE: begin
                state_next = IDLE;
                addr_next = 17'd0;
            end

            default: begin
                state_next = IDLE;
                addr_next = 17'd0;
            end
        endcase
    end

    // State Transition Registers
    always_ff @(posedge clock_12m288, negedge reset_active_low) begin
        if (!reset_active_low) begin
            state <= IDLE;
            addr <= 17'd0;
            end_addr <= 17'd0;
        end 
        else begin
            state <= state_next;
            addr <= addr_next;
            end_addr <= end_addr_next;
        end
    end

    // Continous Assignments
    assign                                  rom_addr                                = addr;
    assign                                  playing                                 = (state == PLAYING);

endmodule