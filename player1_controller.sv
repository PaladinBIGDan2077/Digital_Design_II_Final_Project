/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Player 1 Controller Module
// Filename:                        player1_controller.sv
// Version:                         9
// Author:                          Daniel J. Lomis
// Date:                            4/24/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Controls Player 1's ship position, bullet, lives, invincibility
//                                  window, and sound trigger pulses for a 1280x720 space-shooter
//                                  game running at 60 Hz on the DE1-SoC.
//
//                                  Ship position:
//                                    player_x is mapped continuously from the 12-bit LTC2308 ADC
//                                    paddle value (CH0) using a fixed-point scale:
//                                      1P mode: x = (adc_val * 1232) >> 12  (full 1280 px width)
//                                      2P mode: x = (adc_val *  592) >> 12  (left half only)
//                                    player_y is fixed at SHIP_Y_POS = 650.
//
//                                  Bullet:
//                                    Fires from the ship centre (player_x + SHIP_W/2) on
//                                    fire_press or a latched prior press. Travels upward at
//                                    BULLET_SPEED = 5 px/frame. Deactivated when it reaches
//                                    y < 5, on bull_kill, or on enemy_hit.
//                                    Only one bullet may be in flight at a time.
//
//                                  Lives and invincibility:
//                                    Starts at START_LIVES = 3. A hit pulse decrements lives
//                                    and starts a 90-frame (~1.5 s) invincibility window
//                                    (INVINCIBLE_FR). Hits received during the window are
//                                    discarded. Lives floor at 0; die_sfx pulses on each
//                                    valid hit regardless of remaining lives.
//
//                                  Input latching:
//                                    fire_press and hit are latched (fire_latch, hit_latch) so
//                                    that pulses arriving between frame_ticks are not dropped.
//                                    Both latches are cleared on reset_game.
//
//                                  Sound outputs (single clock-cycle pulses):
//                                    fire_sfx - asserted when a bullet is successfully spawned
//                                    die_sfx  - asserted when a valid hit is processed
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/24/2025   DJL  1        Original Code; fixed ship position, no bullet or lives logic
//                                  4/25/2025   DJL  2        Added ADC-driven player_x mapping with fixed-point scale via >> 12
//                                  4/25/2025   DJL  3        Added bullet spawning and upward movement; bullet deactivates attop of screen
//                                  4/25/2025   DJL  4        Added lives counter and hit detection; die_sfx pulse on hit
//                                  4/27/2025   DJL  5        Added 90-frame invincibility window (inv_cnt) to prevent multi-hit on single collision event
//                                  4/27/2025   DJL  6        Added fire_latch and hit_latch to capture pulses arriving between frame_tick boundaries
//                                  4/28/2025   DJL  7        Added two_player input; split ADC scale between 1P (full width) and 2P (left half) modes
//                                  4/29/2025   DJL  8        Added bull_kill and enemy_hit inputs to deactivate bullet on collision events from collision_detector
//                                  4/30/2025   DJL  9        Added reset_game input to restore lives, clear bullet, and flush both latches on game restart
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module player_ctrl
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
    localparam          int                 P1_X_RNG_2P                             = HALF_W  - SHIP_W;
    localparam          int                 P1_X_RNG_1P                             = SCREEN_W - SHIP_W;
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
            if (bull_kill || enemy_hit) begin
                bullet_active <= 1'b0;
            end
            fire_sfx <= 1'b0;
            die_sfx <= 1'b0;
            if (fire_press) begin
                fire_latch <= 1'b1;
            end
            if (hit) begin
                hit_latch <= 1'b1;
            end
            if (frame_tick && invincible) begin
                inv_cnt <= inv_cnt - 7'd1;
            end
            if (reset_game) begin
                lives <= 3'(START_LIVES);
                bullet_active <= 1'b0;
                inv_cnt <= '0;
                hit_latch <= 1'b0;
                fire_latch <= 1'b0;
            end
            if (game_active && frame_tick) begin
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
    end

    // Continous Assignments
    assign                                  player_x                                = two_player ? 11'((24'(adc_val) * 24'(P1_X_RNG_2P)) >> 12) : 11'((24'(adc_val) * 24'(P1_X_RNG_1P)) >> 12);
    assign                                  player_y                                = 10'(SHIP_Y_POS);
    assign                                  invincible                              = (inv_cnt != '0);

endmodule