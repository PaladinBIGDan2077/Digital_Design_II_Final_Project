/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Audio Sequencer Module for SoundFx
// Filename:                        sound_sequencer.sv
// Version:                         6
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
// Description:                     Streams ROM addresses for one of eight selectable sound effects
//                                  stored back-to-back in a single concatenated 17-bit PCM ROM
//                                  (sfx_all.hex). On each 8 kHz sample_pulse strobe, the module
//                                  advances rom_addr by one until the selected effect's sample
//                                  count is exhausted, then returns to IDLE.
//
//                                  A play_trigger pulse (asserted for exactly one clock cycle by
//                                  sound_effects_generator_top) loads the start address and
//                                  computed end address from SFX_TABLE for the effect indexed by
//                                  sfx_select[2:0].
//
//                                  Implementation:
//                                    SFX_TABLE - packed struct array (sfx_entry_t) of 8 entries,
//                                                each holding a 17-bit start address and 17-bit
//                                                sample count. end_addr is computed combinatorially
//                                                as start + length - 1 at load time.
//                                    FSM       - three-state (IDLE / PLAYING / DONE), implemented
//                                                as a separated always_comb / always_ff pair.
//                                                DONE transitions back to IDLE in one cycle.
//                                    playing   - combinatorial decode of (state == PLAYING);
//                                                used by sound_effects_generator_top to gate
//                                                sfx_data to 16'h0000 when silent.
//
//                                  SFX table (all durations at 8 kHz):
//                                    Index  Name           Start addr  Samples   Duration
//                                    0      fire           0x00000      2,402    ~0.300 s
//                                    1      burger         0x0112E      4,303    ~0.538 s
//                                    2      kill_squirrel  0x02818      5,566    ~0.696 s
//                                    3      kill_truck     0x04833      4,783    ~0.598 s
//                                    4      kill_bathtub   0x0629E     14,997    ~1.875 s
//                                    5      kill_door      0x0A502      6,193    ~0.774 s
//                                    6      die            0x0CC33      7,586    ~0.948 s
//                                    7      game_over      0x0F316     18,397    ~2.299 s
//
//                                  Total ROM depth = 63,227 samples, 17-bit address space
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/22/2025  DJL  1        Original Code; single hardcoded SFX, flat counter with no FSM
//                                  4/24/2025  DJL  2        Parameterized start/length for one selectable SFX via sfx_select input
//                                  4/27/2025  DJL  3        Expanded to 8 SFX entries
//                                  4/28/2025  DJL  4        Introduced three-state FSM (IDLE / PLAYING / DONE) to cleanly handle play_trigger edge and end-of-sample detection
//                                  4/29/2025  DJL  5        Separated FSM
//                                  4/30/2025  DJL  6        Added end_addr register computed at load time (start + length - 1) to avoid recomputing every sample cycle
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