/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Enemy Row Top Module
// Filename:                        enemy_grid.sv
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
// Description:                     Casdasd
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/25/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module enemy_grid
(
    input               logic                                                       clock,
    input               logic                                                       reset_active_low,
    input               logic                                                       game_active,
    input               logic                                                       frame_tick,
    input               logic               [3:0]                                   eb_kill,
    input               logic               [3:0]                                   enemy_kill,
    input               logic               [11:0]                                  enemy_kill_col,
    input               logic                                                       reset_game,
    output              logic               [43:0]                                  base_x,
    output              logic               [43:0]                                  eb_x,
    output              logic               [39:0]                                  eb_y,
    output              logic               [3:0]                                   eb_active,
    output              logic               [47:0]                                  enemy_alive
);
    // Local Parameter
    localparam          int                 BULLET_VELOCITY                         = 10;
    localparam          int                 MOVEMENT_SPEED                          = 5;

    // Squrriel Row
    enemy_row                                                                       #(
                                                                                    .SCREEN_W(1280),
                                                                                    .SCREEN_H(720),
                                                                                    .ROW_Y(120),
                                                                                    .MOVE_RIGHT(1'b1),
                                                                                    .MOVE_SPEED(MOVEMENT_SPEED),
                                                                                    .SPRITE_W(64),
                                                                                    .SPRITE_H(48),
                                                                                    .NUM_SPRITES (7),
                                                                                    .SPACING(140),
                                                                                    .BULLET_SPEED(BULLET_VELOCITY),
                                                                                    .FIRE_PATTERN(12'hA3C)
    )                       u_row0                                                  (
                                                                                    .clock(clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .game_active(game_active),
                                                                                    .frame_tick(frame_tick),
                                                                                    .reset_game(reset_game),
                                                                                    .eb_kill(eb_kill[0]),
                                                                                    .kill_en(enemy_kill[0]),
                                                                                    .kill_col(enemy_kill_col[0*3 +: 3]),
                                                                                    .base_x(base_x[0*11 +: 11]),
                                                                                    .eb_x(eb_x[0*11 +: 11]),
                                                                                    .eb_y(eb_y[0*10 +: 10]),
                                                                                    .eb_active(eb_active[0]),
                                                                                    .alive(enemy_alive[0*12 +: 12])
    );

    // Postal Truck Row
    enemy_row                                                                       #(
                                                                                    .SCREEN_W(1280),
                                                                                    .SCREEN_H(720),
                                                                                    .ROW_Y(220),
                                                                                    .MOVE_RIGHT(1'b0),
                                                                                    .MOVE_SPEED(MOVEMENT_SPEED),
                                                                                    .SPRITE_W(80),
                                                                                    .SPRITE_H(56),
                                                                                    .NUM_SPRITES(6),
                                                                                    .SPACING(155),
                                                                                    .BULLET_SPEED(BULLET_VELOCITY),
                                                                                    .FIRE_PATTERN(12'h5B1)
    )                       u_row1                                                  (
                                                                                    .clock(clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .game_active(game_active),
                                                                                    .frame_tick(frame_tick),
                                                                                    .reset_game(reset_game),
                                                                                    .eb_kill(eb_kill[1]),
                                                                                    .kill_en(enemy_kill [1]),
                                                                                    .kill_col(enemy_kill_col[1*3 +: 3]),
                                                                                    .base_x(base_x[1*11 +: 11]),
                                                                                    .eb_x(eb_x[1*11 +: 11]),
                                                                                    .eb_y(eb_y[1*10 +: 10]),
                                                                                    .eb_active(eb_active[1]),
                                                                                    .alive(enemy_alive[1*12 +: 12])
    );

    // Dog Bath Row
    enemy_row                                                                       #(
                                                                                    .SCREEN_W(1280),
                                                                                    .SCREEN_H(720),
                                                                                    .ROW_Y(330),
                                                                                    .MOVE_RIGHT(1'b1),
                                                                                    .MOVE_SPEED(MOVEMENT_SPEED),
                                                                                    .SPRITE_W(72),
                                                                                    .SPRITE_H(48),
                                                                                    .NUM_SPRITES(7),
                                                                                    .SPACING(140),
                                                                                    .BULLET_SPEED(BULLET_VELOCITY),
                                                                                    .FIRE_PATTERN(12'hD2E)
    )                       u_row2                                                  (
                                                                                    .clock(clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .game_active(game_active),
                                                                                    .frame_tick(frame_tick),
                                                                                    .reset_game(reset_game),
                                                                                    .eb_kill(eb_kill[2]),
                                                                                    .kill_en(enemy_kill[2]),
                                                                                    .kill_col(enemy_kill_col[2*3 +: 3]),
                                                                                    .base_x(base_x[2*11 +: 11]),
                                                                                    .eb_x(eb_x[2*11 +: 11]),
                                                                                    .eb_y(eb_y[2*10 +: 10]),
                                                                                    .eb_active(eb_active[2]),
                                                                                    .alive(enemy_alive[2*12 +: 12])
    );

    // Door Knocking Row
    enemy_row                                                                       #(
                                                                                    .SCREEN_W(1280),
                                                                                    .SCREEN_H(720),
                                                                                    .ROW_Y(440),
                                                                                    .MOVE_RIGHT(1'b0),
                                                                                    .MOVE_SPEED(MOVEMENT_SPEED),
                                                                                    .SPRITE_W(56),
                                                                                    .SPRITE_H(64),
                                                                                    .NUM_SPRITES(8),
                                                                                    .SPACING(130),
                                                                                    .BULLET_SPEED(BULLET_VELOCITY),
                                                                                    .FIRE_PATTERN(12'h3F7)
    )                       u_row3                                                  (
                                                                                    .clock(clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .game_active(game_active),
                                                                                    .frame_tick(frame_tick),
                                                                                    .reset_game(reset_game),
                                                                                    .eb_kill(eb_kill[3]),
                                                                                    .kill_en(enemy_kill[3]),
                                                                                    .kill_col(enemy_kill_col[3*3 +: 3]),
                                                                                    .base_x(base_x[3*11 +: 11]),
                                                                                    .eb_x(eb_x[3*11 +: 11]),
                                                                                    .eb_y(eb_y[3*10 +: 10]),
                                                                                    .eb_active(eb_active[3]),
                                                                                    .alive(enemy_alive[3*12 +: 12])
    );

endmodule