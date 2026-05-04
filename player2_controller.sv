/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Player 2 Controller Module
// Filename:                        player2_controller.sv
// Version:                         2
// Author:                          Daniel J. Lomis
// Date:                            4/28/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Controls Player 2's ship position, bullet, lives, invincibility
//                                  window, and sound trigger pulses in two-player mode. Identical
//                                  to player1_controller.sv in logic and structure, but constrained
//                                  to the right half of the screen (X = 640..1232) and gated by
//                                  the two_player input.
//
//                                  Ship position (two_player mode only):
//                                    player_x is mapped continuously from the 12-bit LTC2308 ADC
//                                    paddle value (CH1) to the right-half playing field:
//                                      x = 640 + (adc_val * 592) >> 12  (right half: 640..1232)
//                                    In 1P mode, player_x = 0 (off-screen left).
//                                    player_y is fixed at SHIP_Y_POS = 650.
//
//                                  Bullet:
//                                    Fires from the ship center (player_x + SHIP_W/2) on
//                                    fire_press or a latched prior press, but only when
//                                    two_player = 1 and game_active = 1. Travels upward at
//                                    BULLET_SPEED = 5 px/frame. Deactivated when it reaches
//                                    y < 5, on bull_kill, or on enemy_hit.
//                                    Only one bullet may be in flight at a time.
//
//                                  Lives and invincibility:
//                                    Starts at START_LIVES = 3, only in two_player mode.
//                                    A hit pulse decrements lives and starts a 90-frame (~1.5 s)
//                                    invincibility window. Hits received during the window are
//                                    discarded. Lives floor at 0; die_sfx pulses on each valid
//                                    hit. In 1P mode, lives is held at START_LIVES.
//
//                                  Input latching:
//                                    fire_press and hit are latched (fire_latch, hit_latch) to
//                                    capture pulses arriving between frame_tick boundaries.
//                                    Both latches are cleared on reset_game.
//
//                                  Two-player gating:
//                                    All game logic (bullet, lives, invincibility, sound output)
//                                    is wrapped in 'if (two_player)' so the module safely disables
//                                    when 1P mode is active. bullet_active, lives, inv_cnt, and
//                                    fire_latch are explicitly reset when two_player = 0.
//
//                                  Sound outputs (single clock-cycle pulses):
//                                    fire_sfx - asserted when a bullet is successfully spawned
//                                    die_sfx  - asserted when a valid hit is processed
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/28/2025   DJL  1        Original Code; copy of player1_ctrl for Player 2, updated for two_player support
//                                  5/2/2025    DJL  2        Minor Bug Fixes
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module player2_ctrl
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   game_active,
    input                                   logic                                   frame_tick,
    input                                   logic                                   two_player,
    input                                   logic               [11:0]              adc_val,
    input                                   logic                                   fire_press,
    input                                   logic                                   hit,
    input                                   logic                                   bull_kill,
    input                                   logic                                   enemy_hit,
    input                                   logic                                   reset_game,
    output                                  logic               [10:0]              player_x,
    output                                  logic               [9:0]               player_y,
    output                                  logic               [10:0]              bullet_x,
    output                                  logic               [9:0]               bullet_y,
    output                                  logic                                   bullet_active,
    output                                  logic               [2:0]               lives,
    output                                  logic                                   fire_sfx,
    output                                  logic                                   die_sfx
);
    // Local Parameters
    localparam          int                 SCREEN_W                                = 1280;
    localparam          int                 HALF_W                                  = 640;
    localparam          int                 SHIP_W                                  = 48;
    localparam          int                 SHIP_Y_POS                              = 650;
    localparam          int                 BULLET_SPEED                            = 5;
    localparam          int                 START_LIVES                             = 3;
    localparam          int                 INVINCIBLE_FR                           = 90;
    localparam          int                 P2_X_MIN                                = 640;
    localparam          int                 P2_X_MAX                                = SCREEN_W - SHIP_W;
    localparam          int                 P2_X_RNG                                = P2_X_MAX - P2_X_MIN;
    // Internal Register-based Connections
                                            logic               [6:0]               inv_cnt;
                                            logic                                   invincible;
                                            logic                                   fire_latch;
                                            logic                                   hit_latch;

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            bullet_active <= 1'b0;
            bullet_x <= '0;
            bullet_y <= '0;
            lives <= 3'(START_LIVES);
            inv_cnt <= '0;
            fire_sfx <= 1'b0;
            die_sfx <= 1'b0;
            fire_latch <= 1'b0;
            hit_latch <= 1'b0;
        end 
        else begin
            fire_sfx <= 1'b0;
            die_sfx <= 1'b0;
            if (fire_press) begin
                fire_latch <= 1'b1;
            end
            if (hit) begin
                hit_latch <= 1'b1;
            end
            if (reset_game) begin
                lives <= 3'(START_LIVES);
                bullet_active <= 1'b0;
                inv_cnt <= '0;
                hit_latch <= 1'b0;
                fire_latch <= 1'b0;
            end
            // Two Player-specific Subsystem
            if (two_player) begin
                if (frame_tick && invincible) begin
                    inv_cnt <= inv_cnt - 7'd1;
                end
                if (bull_kill || enemy_hit) begin
                    bullet_active <= 1'b0;
                end
                else if (game_active && frame_tick) begin
                    if ((fire_press || fire_latch) && lives > 3'd0) begin
                        fire_latch <= 1'b0;
                        if (!bullet_active) begin
                            bullet_active <= 1'b1;
                            bullet_x <= player_x + 11'(SHIP_W / 2);
                            bullet_y <= 10'(SHIP_Y_POS);
                            fire_sfx <= 1'b1;
                        end
                    end 
                    else if (fire_latch && lives == 3'd0) begin
                        fire_latch <= 1'b0;
                    end
                    if (bullet_active) begin
                        if (bullet_y < 10'(BULLET_SPEED)) begin
                            bullet_active <= 1'b0;
                        end
                        else begin
                            bullet_y <= bullet_y - 10'(BULLET_SPEED);
                        end
                    end
                    if (hit_latch && !invincible) begin
                        hit_latch <= 1'b0;
                        die_sfx <= 1'b1;
                        if (lives > 3'd0) begin
                            lives <= lives - 3'd1;
                            inv_cnt <= 7'(INVINCIBLE_FR);
                        end
                    end 
                    else if (hit_latch && invincible) begin
                        hit_latch <= 1'b0;
                    end
                end
            end 
            else begin
                // Player 1 Mode
                bullet_active <= 1'b0;
                lives         <= 3'(START_LIVES);
                inv_cnt       <= '0;
                fire_latch    <= 1'b0;
            end
        end
    end

    // Continous Assignments
    assign                                  player_x                                = two_player ? (11'(P2_X_MIN) + 11'((24'(adc_val) * 24'(P2_X_RNG)) >> 12)) : 11'd0;
    assign                                  player_y                                = 10'(SHIP_Y_POS);
    assign                                  invincible                              = (inv_cnt != '0);

endmodule