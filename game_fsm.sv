/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Game State Finite State Machine Module
// Filename:                        game_fsm.sv
// Version:                         9
// Author:                          Daniel J. Lomis
// Date:                            4/17/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Top-level game state machine that orchestrates the main
//                                  gameplay loop: IDLE > PLAYING > GAME_OVER > IDLE. Manages
//                                  mode selection (1-player vs. 2-player), game-over fanfare
//                                  timing, and score reset signals. Detects game-over conditions
//                                  in 1P and 2P modes separately (either player out of lives or
//                                  all enemies eliminated). Holds GAME_OVER state for a minimum
//                                  of 180 frames (~3 seconds at 60 Hz) before accepting a
//                                  restart pulse.
//
//                                  FSM states:
//                                    IDLE      - waiting for start_press to begin gameplay.
//                                                SW[0] is sampled here and latched into two_player.
//                                                game_active = 0; all game logic frozen.
//                                    PLAYING   - normal gameplay. game_active = 1. Enemies move,
//                                                bullets fly, collisions detected. Transitions to
//                                                GAME_OVER when the game-over condition is met.
//                                    GAME_OVER - enemies frozen, game_over_sfx pulse sent on
//                                                entry. A timer (go_timer) counts frames up to
//                                                GO_HOLD_FRAMES. If start_press arrives before
//                                                the timer expires, it is ignored. Once the timer
//                                                completes, the next start_press resets go_timer,
//                                                asserts reset_scores, and transitions to IDLE.
//
//                                  Game-over conditions:
//                                    1P mode   - (p1_lives == 0) OR (all_enemies_dead)
//                                    2P mode   - (p1_lives == 0 AND p2_lives == 0) OR (all_enemies_dead)
//                                    where all_enemies_dead = (enemy_alive == 48'h0)
//
//                                  Score management:
//                                    reset_scores is pulsed on the transition from GAME_OVER
//                                    back to IDLE, signaling score_display module to clear
//                                    both player scores. This happens after the player has been
//                                    in GAME_OVER state long enough to read the fanfare.
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/17/2025   DJL  1        Original Code; simple 2-state FSM (IDLE <-> PLAYING) with no game-over
//                                  4/18/2025   DJL  2        Added GAME_OVER state; transition on p1_lives == 0 condition
//                                  4/19/2025   DJL  3        Added game_over_sfx output pulsed on PLAYING -> GAME_OVER transition
//                                  4/21/2025   DJL  4        Added two_player mode support; latched from SW[0] on IDLE -> PLAYING transition
//                                  4/28/2025   DJL  5        Split game-over condition: 1P uses (p1_lives == 0), 2P uses (p1_lives == 0 AND p2_lives == 0)
//                                  4/28/2025   DJL  6        Added all_enemies_dead detection; win condition when enemy_alive == 48'h0
//                                  4/29/2025   DJL  7        Added go_timer (8-bit counter) and GO_HOLD_FRAMES localparam to delay state transition out of GAME_OVER for fanfare audio
//                                  4/30/2025   DJL  8        Added reset_scores output; pulsed on GAME_OVER -> IDLE transition to signal score_display to clear both players' scores
//                                  5/2/2025    DJL  9        Refined go_timer logic: counts only when in GAME_OVER state and frame_tick asserts; resets to 0 on exit from GAME_OVER; go_hold_done gates acceptance of next start_press
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   frame_tick,
    input                                   logic                                   start_press,
    input                                   logic                                   sw0,
    input                                   logic               [2:0]               p1_lives,
    input                                   logic               [2:0]               p2_lives,
    input                                   logic               [47:0]              enemy_alive,
    output                                  logic               [1:0]               game_state,
    output                                  logic                                   game_active,
    output                                  logic                                   two_player,
    output                                  logic                                   game_over_sfx,
    output                                  logic                                   reset_scores
);
    // Local Parameters
    localparam          int                 GO_HOLD_FRAMES                          = 180;

    // Type Definitions of Enumerations
    typedef             enum                logic               [1:0]               {
        IDLE      = 2'b00,
        PLAYING   = 2'b01,
        GAME_OVER = 2'b10
    }   state_t;

    state_t     state,      next_state;

    // Internal Register-based Connections
                                            logic                                   all_enemies_dead;
                                            logic                                   game_over_cond;
                                            logic               [7:0]               go_timer;
                                            logic                                   go_hold_done;

    // Player 2 Handling of Game Over
    always_comb begin
        if (two_player) begin
            game_over_cond = ((p1_lives == 3'd0) && (p2_lives == 3'd0)) || all_enemies_dead;
        end
        else begin
            game_over_cond = (p1_lives == 3'd0) || all_enemies_dead;
        end
    end

    // Sequential Logic Block
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            state <= IDLE;
            two_player <= 1'b0;
            game_over_sfx <= 1'b0;
            reset_scores <= 1'b0;
            go_timer <= 8'd0;
        end 
        else begin
            game_over_sfx <= 1'b0;
            reset_scores <= 1'b0;
            if (state == GAME_OVER) begin
                if (!go_hold_done && frame_tick) begin
                    go_timer <= go_timer + 8'd1;
                end
            end
            else begin
                go_timer <= 8'd0;
            end
            case (state)
                IDLE: begin
                    if (start_press) begin
                        two_player <= sw0;
                        state <= PLAYING;
                    end
                end
                PLAYING: begin
                    if (game_over_cond) begin
                        state <= GAME_OVER;
                        game_over_sfx <= 1'b1;
                    end
                end
                GAME_OVER: begin
                    if (start_press) begin
                        go_timer <= 8'd0;
                        reset_scores <= 1'b1;
                        state <= IDLE;
                        game_over_sfx <= 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Continous Assignments
    assign                                  game_state                              = state;
    assign                                  game_active                             = (state == PLAYING);
    assign                                  go_hold_done                            = (go_timer >= 8'(GO_HOLD_FRAMES));
    assign                                  all_enemies_dead                        = (enemy_alive == 48'd0);

endmodule