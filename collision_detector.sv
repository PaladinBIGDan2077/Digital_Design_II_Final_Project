/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Collision Detector Module
// Filename:                        collision_detector.sv
// Version:                         12
// Author:                          Daniel J. Lomis
// Date:                            4/26/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Fully combinatorial axis-aligned bounding box (AABB) collision
//                                  detector for all game objects: player ships, bullets, enemies,
//                                  enemy bullets, burger power-up, and optional blockade shields.
//                                  Runs entirely on game_active; all outputs are zero when the game
//                                  is not active. Outputs are registered one cycle later via
//                                  always_ff for clean timing.
//
//                                  Collision types detected:
//                                    Player vs. Enemy Bullet       - outputs c_p1_hit, c_p2_hit (also sets c_eb_kill to deactivate)
//                                    Player 1 Bullet vs. Blockade  - outputs c_p1_bull_kill
//                                    Player 1 Bullet vs. Enemies   - outputs c_enemy_kill[row], c_enemy_kill_col (3-bit sprite index), c_p1_score_inc (row-encoded)
//                                    Player 1 Bullet vs. Burger    - outputs c_burg_p1
//                                    (same trio for Player 2, gated by two_player input)
//                                    Enemy Bullet vs. Blockade     - outputs c_eb_kill[row]
//
//                                  Core helper functions:
//                                    aabb()                 - generic 4-parameter AABB test
//                                    bullet_hits_blockade() - checks left and right blockade zones
//                                    sprite_x()             - wraps enemy sprite X across screen edge
//
//                                  Sprite/blockade parameters:
//                                    Each enemy row has its own {SPR_W, SPR_H, Y, SPACING, N_SPR}
//                                    Blockade zones (left & right): static rects at Y between [505, 569]
//                                    Bullet dimensions: 4x14; Enemy bullet: 4x14; Burger: 48x32
//
//                                  Score encoding (per-row when bullet kills enemy):
//                                    Row 0 (squirrel)  -> 0x8
//                                    Row 1 (truck)     -> 0x4
//                                    Row 2 (bathtub)   -> 0x2
//                                    Row 3 (door)      -> 0x1
//                                    OR'd together if multiple rows killed in one cycle.
//
//                                  Two-player support:
//                                    Player 2 collisions are checked only when two_player = 1.
//                                    In 1P mode, c_p2_hit, c_p2_bull_kill, etc. remain low.
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/26/2025  DJL  1        Original Code; single AABB test for player vs. enemy bullet only
//                                  4/26/2025  DJL  2        Added player bullet vs. enemy collision detection with nested loop over 4 rows x 8 sprites per row
//                                  4/26/2025  DJL  3        Added sprite_x() function to wrap enemy X coordinate across screen boundary (< 0 or >= 1280)
//                                  4/27/2025  DJL  4        Added enemy_kill_col output (3-bit column index) to identify which sprite in a row was hit
//                                  4/27/2025  DJL  5        Added score encoding (SCORE_ENC[4]) per-row lookup; c_p1_score_inc OR'd with row-specific bits on hit
//                                  4/27/2025  DJL  6        Added blockade shield zones; bullet hit blockade > auto-kill bullet; enemy bullet hit blockade > auto-kill
//                                  4/28/2025  DJL  7        Added bullet_hits_blockade() helper to check both left and right zones with separate rect definitions
//                                  4/29/2025  DJL  8        Added burger collision; c_burg_p1 asserts when P1 bullet hits active burger sprite (48x32 rect)
//                                  4/30/2025  DJL  9        Added Player 2 bullet vs. enemy and burger logic gated on (p2_ba && two_player); separate c_p2_score_inc and c_p2_bull_hit_enemy outputs
//                                  4/30/2025  DJL  10       Added p1_bull_hit_enemy and p2_bull_hit_enemy outputs to gate bullet deactivation separately from burger collision
//                                  5/2/2025   DJL  11       Separated combinatorial logic (always_comb) from registered outputs (always_ff @posedge clock) for timing closure and proper edge-triggered collision reporting
//                                  5/3/2025   DJL  12       Gated entire collision logic tree on game_active; all combinatorial outputs zero when game is inactive; prevents spurious hits during IDLE or GAME_OVER FSM states
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module collision_detect
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   game_active,
    input                                   logic               [10:0]              p1_x,
    input                                   logic               [9:0]               p1_y,
    input                                   logic               [10:0]              p1_bx,
    input                                   logic               [9:0]               p1_by,
    input                                   logic                                   p1_ba,
    input                                   logic               [10:0]              p2_x,
    input                                   logic               [9:0]               p2_y,
    input                                   logic               [10:0]              p2_bx,
    input                                   logic               [9:0]               p2_by,
    input                                   logic                                   p2_ba,
    input                                   logic                                   two_player,
    input                                   logic               [43:0]              enemy_base_x,
    input                                   logic               [43:0]              enemy_eb_x,
    input                                   logic               [39:0]              enemy_eb_y,
    input                                   logic               [3:0]               enemy_eb_active,
    input                                   logic               [47:0]              enemy_alive,
    input                                   logic               [10:0]              burg_x,
    input                                   logic               [9:0]               burg_y,
    input                                   logic                                   burg_active,
    output                                  logic                                   p1_hit,
    output                                  logic                                   p2_hit,
    output                                  logic               [3:0]               enemy_kill,
    output                                  logic               [3:0]               eb_kill,
    output                                  logic                                   p1_bull_kill,
    output                                  logic                                   p2_bull_kill,
    output                                  logic                                   burger_hit_p1,
    output                                  logic                                   burger_hit_p2,
    output                                  logic               [3:0]               p1_score_inc,
    output                                  logic               [3:0]               p2_score_inc,
    output                                  logic                                   p1_bull_hit_enemy,
    output                                  logic                                   p2_bull_hit_enemy,
    output                                  logic               [11:0]              enemy_kill_col
);
    // Local Parameters
    localparam          int                 SCREEN_W                                = 1280;
    localparam          int                 SHIP_W                                  = 48;
    localparam          int                 SHIP_H                                  = 24;
    localparam          int                 BULLET_W                                = 4;
    localparam          int                 BULLET_H                                = 14;
    localparam          int                 EB_W                                    = 4;
    localparam          int                 EB_H                                    = 14;
    localparam          int                 BURG_W                                  = 48;
    localparam          int                 BURG_H                                  = 32;

    localparam          int                 ROW_SPR_W           [4]                 = '{64, 80, 72, 56};
    localparam          int                 ROW_SPR_H           [4]                 = '{48, 56, 48, 64};
    localparam          int                 ROW_Y               [4]                 = '{120, 220, 330, 440};
    localparam          int                 ROW_SPACING         [4]                 = '{140, 155, 140, 130};
    localparam          int                 ROW_NSPR            [4]                 = '{7, 6, 7, 8};

    localparam          logic   [3:0]       SCORE_ENC           [4]                 = '{4'b1000, 4'b0100, 4'b0010, 4'b0001};

    localparam          int                 BLK_L_X0                                = 160;
    localparam          int                 BLK_L_X1                                = 288;
    localparam          int                 BLK_R_X0                                = 992;
    localparam          int                 BLK_R_X1                                = 1120;
    localparam          int                 BLK_Y0                                  = 505;
    localparam          int                 BLK_Y1                                  = 569;
    // Internal Register-based Connections
                        logic                                                       c_p1_hit;
                        logic                                                       c_p2_hit;
                        logic               [3:0]                                   c_enemy_kill;
                        logic               [11:0]                                  c_enemy_kill_col;
                        logic               [3:0]                                   c_eb_kill;
                        logic                                                       c_p1_bull_kill;
                        logic                                                       c_p2_bull_kill;
                        logic                                                       c_p1_bull_hit_enemy;
                        logic                                                       c_p2_bull_hit_enemy;
                        logic                                                       c_burg_p1;
                        logic                                                       c_burg_p2;
                        logic               [3:0]                                   c_p1_score_inc;
                        logic               [3:0]                                   c_p2_score_inc;
    // Functions
    // Collision Checker Function
    function            automatic           logic                                           aabb
    (
        input               logic               [10:0]                                  ax,
        input               int                                                         aw,
        input               logic               [9:0]                                   ay,
        input               int                                                         ah,
        input               logic               [10:0]                                  bx,
        input               int                                                         bw,
        input               logic               [9:0]                                   by,
        input               int                                                         bh
    );
        return (ax < bx + 11'(bw)) && (ax + 11'(aw) > bx ) && (ay < by + 10'(bh)) && (ay + 10'(ah) > by);
    endfunction

    // Bullet in Blockade Checker
    function            automatic           logic                                           bullet_hits_blockade
    (
        input               logic               [10:0]                                  bx,
        input               logic               [9:0]                                   by
    );
        return aabb(bx - 11'(BULLET_W/2), BULLET_W, by, BULLET_H, 11'(BLK_L_X0), BLK_L_X1 - BLK_L_X0, 10'(BLK_Y0), BLK_Y1 - BLK_Y0) || aabb(bx - 11'(BULLET_W/2), BULLET_W, by, BULLET_H, 11'(BLK_R_X0), BLK_R_X1 - BLK_R_X0, 10'(BLK_Y0), BLK_Y1 - BLK_Y0);
    endfunction

    // Collision Detector for Sprites
    function            automatic           logic               [10:0]                      sprite_x
    (
        input               logic               [10:0]                                  base,
        input               int                                                         j,
        input               int                                                         spacing
    );
        automatic logic [11:0] raw;
        raw = 12'(base) + 12'(j) * 12'(spacing);
        return (raw >= 12'(SCREEN_W)) ? raw[10:0] - 11'(SCREEN_W) : raw[10:0];
    endfunction

    always_comb begin
        c_p1_hit = 1'b0;
        c_p2_hit = 1'b0;
        c_enemy_kill = 4'b0;
        c_eb_kill = 4'b0;
        c_p1_bull_kill = 1'b0;
        c_p2_bull_kill = 1'b0;
        c_p1_bull_hit_enemy = 1'b0;
        c_p2_bull_hit_enemy = 1'b0;
        c_burg_p1 = 1'b0;
        c_burg_p2 = 1'b0;
        c_p1_score_inc = 4'b0;
        c_p2_score_inc = 4'b0;
        c_enemy_kill_col = 12'b0;
        if (game_active) begin
            // Player Against Enemy
            for (int i = 0; i < 4; i++) begin
                if (enemy_eb_active[i]) begin
                    if (aabb(enemy_eb_x[i*11 +: 11] - 11'(EB_W/2), EB_W, enemy_eb_y[i*10 +: 10], EB_H, p1_x, SHIP_W, p1_y, SHIP_H)) begin
                        c_p1_hit = 1'b1;
                        c_eb_kill[i] = 1'b1;
                    end
                    if (two_player && aabb(enemy_eb_x[i*11 +: 11] - 11'(EB_W/2), EB_W, enemy_eb_y[i*10 +: 10], EB_H, p2_x, SHIP_W, p2_y, SHIP_H)) begin
                        c_p2_hit     = 1'b1;
                        c_eb_kill[i] = 1'b1;
                    end
                    if (bullet_hits_blockade(enemy_eb_x[i*11 +: 11], enemy_eb_y[i*10 +: 10])) begin
                        c_eb_kill[i] = 1'b1;
                    end
                end
            end
            // Player 1 Bullet Logic
            if (p1_ba) begin
                // Bullet Against Blockade
                if (bullet_hits_blockade(p1_bx, p1_by)) begin
                    c_p1_bull_kill = 1'b1;
                end
                // Bullet Against Enemy
                if (!c_p1_bull_kill) begin
                    for (int i = 0; i < 4; i++) begin
                        for (int j = 0; j < 8; j++) begin
                            if (j < ROW_NSPR[i] && !c_enemy_kill[i] && enemy_alive[i*12 + j]) begin
                                automatic logic [10:0] sx;
                                sx = sprite_x(enemy_base_x[i*11 +: 11], j, ROW_SPACING[i]);
                                if (aabb(p1_bx - 11'(BULLET_W/2), BULLET_W, p1_by, BULLET_H, sx, ROW_SPR_W[i], 10'(ROW_Y[i]), ROW_SPR_H[i])) begin
                                    c_enemy_kill[i]= 1'b1;
                                    c_enemy_kill_col[i*3 +: 3] = 3'(j);
                                    c_p1_score_inc = (c_p1_score_inc | SCORE_ENC[i]);
                                    c_p1_bull_hit_enemy = 1'b1;
                                end
                            end
                        end
                    end
                end
                // Bullet Against Burger
                if (!c_p1_bull_kill && burg_active && aabb(p1_bx - 11'(BULLET_W/2), BULLET_W, p1_by, BULLET_H, burg_x, BURG_W, burg_y, BURG_H)) begin
                    c_burg_p1 = 1'b1;
                end
            end
            // Player 2 Bullet Logic
            if (p2_ba && two_player) begin
                // Bullet Against Blockade
                if (bullet_hits_blockade(p2_bx, p2_by)) begin
                    c_p2_bull_kill = 1'b1;
                end
                // Bullet Against Enemy
                if (!c_p2_bull_kill) begin
                    for (int i = 0; i < 4; i++) begin
                        for (int j = 0; j < 8; j++) begin
                            if (j < ROW_NSPR[i] && !c_enemy_kill[i] && enemy_alive[i*12 + j]) begin
                                automatic logic [10:0] sx;
                                sx = sprite_x(enemy_base_x[i*11 +: 11], j, ROW_SPACING[i]);
                                if (aabb(p2_bx - 11'(BULLET_W/2), BULLET_W, p2_by, BULLET_H, sx, ROW_SPR_W[i], 10'(ROW_Y[i]), ROW_SPR_H[i])) begin
                                    c_enemy_kill[i] = 1'b1;
                                    c_enemy_kill_col[i*3 +: 3] = 3'(j);
                                    c_p2_score_inc = (c_p2_score_inc | SCORE_ENC[i]);
                                    c_p2_bull_hit_enemy = 1'b1;
                                end
                            end
                        end
                    end
                end
                // Bullet Against Burger
                if (!c_p2_bull_kill && burg_active && aabb(p2_bx - 11'(BULLET_W/2), BULLET_W, p2_by, BULLET_H, burg_x, BURG_W, burg_y, BURG_H)) begin
                    c_burg_p2 = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            p1_hit <= 1'b0;
            p2_hit <= 1'b0;
            enemy_kill <= 4'b0;
            eb_kill <= 4'b0;
            p1_bull_kill <= 1'b0;
            p2_bull_kill <= 1'b0;
            p1_bull_hit_enemy <= 1'b0;
            p2_bull_hit_enemy <= 1'b0;
            burger_hit_p1 <= 1'b0;
            burger_hit_p2 <= 1'b0;
            p1_score_inc <= 4'b0;
            p2_score_inc <= 4'b0;
            enemy_kill_col <= 12'b0;
        end
        else begin
            p1_hit <= c_p1_hit;
            p2_hit <= c_p2_hit;
            enemy_kill <= c_enemy_kill;
            eb_kill <= c_eb_kill;
            p1_bull_kill <= c_p1_bull_kill;
            p2_bull_kill <= c_p2_bull_kill;
            p1_bull_hit_enemy <= c_p1_bull_hit_enemy;
            p2_bull_hit_enemy <= c_p2_bull_hit_enemy;
            burger_hit_p1 <= c_burg_p1;
            burger_hit_p2 <= c_burg_p2;
            p1_score_inc <= c_p1_score_inc;
            p2_score_inc <= c_p2_score_inc;
            enemy_kill_col <= c_enemy_kill_col;
        end
    end

endmodule