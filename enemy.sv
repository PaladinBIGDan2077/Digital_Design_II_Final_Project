/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Enemy Row Spawner Module
// Filename:                        enemy.sv
// Version:                         11
// Author:                          Daniel J. Lomis
// Date:                            4/25/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Manages one horizontal row of up to NUM_SPRITES enemies on a
//                                  1280x720 display. Handles row translation, per-sprite alive
//                                  tracking, LFSR-driven random bullet firing, and bullet movement.
//                                  Fully parameterized so that enemies_top.sv can instantiate
//                                  multiple rows with independent Y positions, speeds, and
//                                  directions.
//
//                                  Row movement:
//                                    base_x advances by MOVE_SPEED pixels every frame_tick.
//                                    MOVE_RIGHT selects left-to-right or right-to-left wrapping.
//                                    Each sprite's screen X = base_x + col * SPACING.
//                                    On reset or reset_game, base_x returns to its spawn edge.
//
//                                  Alive mask:
//                                    alive[NUM_SPRITES-1:0] is a hot bitmask, initialised to all
//                                    ones. kill_en + kill_col clears the corresponding bit when
//                                    collision_detector confirms a bullet hit. any_alive prevents
//                                    firing and movement once the row is fully eliminated.
//
//                                  Enemy bullet (one per row):
//                                    A 12-bit Galois LFSR (taps 11,10,9,3) advances one step per
//                                    frame_tick. fire_trigger asserts when the top FIRE_BITS of
//                                    the LFSR match FIRE_PATTERN, no bullet is already in flight,
//                                    and at least one sprite is alive. The firing column is chosen
//                                    by pick_alive_col(), a combinatorial function that walks
//                                    LFSR[2:0] mod NUM_SPRITES to find the nearest living sprite,
//                                    ensuring dead columns are skipped. The bullet spawns at
//                                    spawn_x = base_x + fire_col * SPACING + SPRITE_W/2 and
//                                    travels downward at BULLET_SPEED px/frame. eb_kill
//                                    deactivates it on collision or game reset.
//
//                                  Parameters:
//                                    SCREEN_W     - display width
//                                    SCREEN_H     - display height
//                                    ROW_Y        - fixed Y coordinate of this row
//                                    MOVE_RIGHT   - 1 = left -> right wrap, 0 = right -> left wrap
//                                    MOVE_SPEED   - px/frame translation rate
//                                    SPRITE_W/H   - sprite bounding box in pixels
//                                    NUM_SPRITES  - enemies per row
//                                    SPACING      - pixel pitch between sprite centres
//                                    BULLET_SPEED - enemy bullet descent rate px/frame
//                                    FIRE_PATTERN - LFSR match value that triggers a shot
//                                    FIRE_BITS    - how many MSBs of LFSR to compare
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/25/2025  DJL  1        Original Code; fixed-position sprites, no movement or bullet logic
//                                  4/25/2025  DJL  2        Added base_x register and per-frame MOVE_SPEED translation with screen wrap for both directions
//                                  4/26/2025  DJL  3        Added alive bitmask and kill_en / kill_col inputs to clear individual sprites on collision
//                                  4/26/2025  DJL  4        Added 12-bit Galois LFSR (taps 11,10,9,3) for pseudorandom timing; LFSR advances once per frame_tick
//                                  4/27/2025  DJL  5        Added fire_trigger logic comparing top FIRE_BITS of LFSR to FIRE_PATTERN; parameterized FIRE_PATTERN/FIRE_BITS
//                                  4/28/2025  DJL  6        Added enemy bullet registers (eb_x, eb_y, eb_active) and downward movement at BULLET_SPEED px/frame
//                                  4/28/2025  DJL  7        Added pick_alive_col()to skip dead columns when selecting firing sprite
//                                  4/30/2025  DJL  8        Added eb_kill input to deactivate bullet from collision_detector; bullet also deactivates at SCREEN_H
//                                  5/1/2025   DJL  9        Added reset_game input to restore alive mask, bullet state, and base_x without a full system reset
//                                  5/2/2025   DJL  10       Promoted movement, bullet, and fire constants to module parameters so enemies_top.sv can vary rows independently at instantiation
//                                  5/2/2025   DJL  11       Gated LFSR advance and movement on game_active to freeze enemies during IDLE and GAME_OVER FSM states
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module enemy_row
#(  // Parameters
    parameter           int                                     SCREEN_W            = 1280,
    parameter           int                                     SCREEN_H            = 720,
    parameter           int                                     ROW_Y               = 120,
    parameter           bit                                     MOVE_RIGHT          = 1'b1,
    parameter           int                                     MOVE_SPEED          = 2,
    parameter           int                                     SPRITE_W            = 64,
    parameter           int                                     SPRITE_H            = 48,
    parameter           int                                     NUM_SPRITES         = 7,
    parameter           int                                     SPACING             = 140,
    parameter           int                                     BULLET_SPEED        = 5,
    parameter           logic               [11:0]              FIRE_PATTERN        = 12'hA3C,
    parameter           int                                     FIRE_BITS           = 5
)
(   // I/O
    input               logic                                                       clock,
    input               logic                                                       reset_active_low,
    input               logic                                                       game_active,
    input               logic                                                       frame_tick,
    input               logic                                                       reset_game,
    input               logic                                                       eb_kill,
    input               logic                                                       kill_en,
    input               logic               [2:0]                                   kill_col,
    output              logic               [10:0]                                  base_x,
    output              logic               [10:0]                                  eb_x,
    output              logic               [9:0]                                   eb_y,
    output              logic                                                       eb_active,
    output              logic               [11:0]                                  alive
);
    // Internal Register-based Connections
                        logic               [10:0]                                  spawn_x;
                        logic                                                       fire_trigger;
                        logic               [11:0]                                  base_x_int;
                        logic               [3:0]                                   fire_col;
                        logic                                                       any_alive;
                        logic               [11:0]                                  lfsr;
                        logic                                                       fb;


    // Internal Functions
    // Galois-derived Linear-feedback Shift Register
    always_comb begin
        fb = lfsr[11] ^ lfsr[10] ^ lfsr[9] ^ lfsr[3];
    end

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            lfsr <= 12'hFFF;
        end 
        else if (frame_tick && game_active) begin
            lfsr <= {lfsr[10:0], fb};
        end
    end

    // Dead Masker Function - Generated During Synthesis
    function            automatic           logic               [3:0]                       pick_alive_col
    (
        input               logic               [11:0]                                  rnd,
        input               logic               [11:0]                                  alive_mask
    );
        automatic           logic               [2:0]                                   base_idx;
        automatic           logic               [3:0]                                   found;
        base_idx = (lfsr[2:0] >= 3'(NUM_SPRITES)) ? 3'(NUM_SPRITES - 1) : lfsr[2:0];
        found = 4'(NUM_SPRITES);
        // Begin
        for (int k = 0; k < NUM_SPRITES; k++) begin
            automatic logic [3:0] candidate;
            candidate = 4'((int'(base_idx) + k) % NUM_SPRITES);
            if (alive_mask[candidate] && found == 4'(NUM_SPRITES)) begin
                found = candidate;
            end
        end
        return found;
    endfunction

    // Sprite Rotator
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            base_x_int <= MOVE_RIGHT ? 12'd0 : 12'(SCREEN_W - NUM_SPRITES * SPACING);
        end 
        else if (reset_game) begin
            base_x_int <= MOVE_RIGHT ? 12'd0 : 12'(SCREEN_W - NUM_SPRITES * SPACING);
        end 
        else if (game_active && frame_tick) begin
            if (MOVE_RIGHT) begin
                if (base_x_int + MOVE_SPEED >= SCREEN_W) begin
                    base_x_int <= base_x_int + 12'(MOVE_SPEED) - 12'(SCREEN_W);
                end
                else begin
                    base_x_int <= base_x_int + 12'(MOVE_SPEED);
                end
            end 
            else begin
                if (base_x_int < 12'(MOVE_SPEED)) begin
                    base_x_int <= 12'(SCREEN_W) - 12'(MOVE_SPEED) + base_x_int;
                end
                else begin
                    base_x_int <= base_x_int - 12'(MOVE_SPEED);
                end
            end
        end
    end

    // Bullet Spawner
    always_comb begin
        spawn_x = base_x + 11'(int'(fire_col)) * 11'(SPACING) + 11'(SPRITE_W / 2);
    end

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            eb_active <= 1'b0;
            eb_x <= '0;
            eb_y <= '0;
            alive <= 12'((1 << NUM_SPRITES) - 1);
        end 
        else if (reset_game) begin
            eb_active <= 1'b0;
            eb_x <= '0;
            eb_y <= '0;
            alive <= 12'((1 << NUM_SPRITES) - 1);
        end 
        else begin
            if (kill_en) begin
                alive[kill_col] <= 1'b0;
            end
            if (eb_kill) begin
                eb_active <= 1'b0;
            end 
            else if (game_active && frame_tick) begin
                if (fire_trigger) begin
                    eb_active <= 1'b1;
                    eb_x <= spawn_x;
                    eb_y <= 10'(ROW_Y + SPRITE_H);
                end else if (eb_active) begin
                    if (eb_y + 10'(BULLET_SPEED) >= 10'(SCREEN_H)) begin
                        eb_active <= 1'b0;
                    end
                    else begin
                        eb_y <= eb_y + 10'(BULLET_SPEED);
                    end
                end
            end
        end
    end

    // Continous Assignments
    assign                                  base_x                                  = base_x_int[10:0];
    assign                                  any_alive                               = (alive != '0);
    assign                                  fire_col                                = pick_alive_col(lfsr, alive);
    assign                                  fire_trigger                            = (lfsr[11 -: FIRE_BITS] == FIRE_PATTERN[11 -: FIRE_BITS]) && !eb_active && any_alive && game_active;

endmodule