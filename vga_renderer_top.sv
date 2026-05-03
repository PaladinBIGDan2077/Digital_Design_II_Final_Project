/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           VGA Renderer Top Module
// Filename:                        vga_renderer_top.sv
// Version:                         3
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
// Description:                     Casdasd
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/22/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module  vga_renderer_output_top
(
    input                                   logic                                   vga_clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   blanking_active_low,
    input                                   logic               [10:0]              hcount,
    input                                   logic               [9:0]               vcount,
    input                                   logic               [10:0]              p1_x,
    input                                   logic               [10:0]              p2_x,
    input                                   logic               [9:0]               p1_y,
    input                                   logic               [9:0]               p2_y,
    input                                   logic               [10:0]              p1_bx,
    input                                   logic               [10:0]              p2_bx,
    input                                   logic               [9:0]               p1_by,
    input                                   logic               [9:0]               p2_by,
    input                                   logic                                   p1_ba,
    input                                   logic                                   p2_ba,
    input                                   logic               [2:0]               p1_lives,
    input                                   logic               [2:0]               p2_lives,
    input                                   logic                                   two_player,
    input                                   logic               [43:0]              enemy_base_x,
    input                                   logic               [43:0]              enemy_eb_x,
    input                                   logic               [39:0]              enemy_eb_y,
    input                                   logic               [3:0]               enemy_eb_active,
    input                                   logic               [10:0]              burg_x,
    input                                   logic               [9:0]               burg_y,
    input                                   logic                                   burg_active,
    input                                   logic                                   alignment,
    input                                                                           game_active,
    input                                   logic               [47:0]              enemy_alive,
    input                                   logic                                   frame_tick,
    input                                   logic               [1:0]               game_state,
    output                                  logic               [7:0]               red,
    output                                  logic               [7:0]               green,
    output                                  logic               [7:0]               blue
);
    // Internal Register-derived Connections
                                            logic               [7:0]               sq_pix;
                                            logic               [7:0]               pt_pix;
                                            logic               [7:0]               bt_pix;
                                            logic               [7:0]               dk_pix;
                                            logic               [7:0]               ship_pix;
                                            logic               [7:0]               blk_pix;
                                            logic               [7:0]               burg_pix;
                                            logic               [11:0]              sq_addr;
                                            logic               [12:0]              pt_addr;
                                            logic               [11:0]              bt_addr;
                                            logic               [11:0]              dk_addr;
                                            logic               [10:0]              ship_addr;
                                            logic               [12:0]              blk_addr;
                                            logic               [10:0]              burg_addr;
                                            logic               [7:0]               red_display;
                                            logic               [7:0]               green_display;
                                            logic               [7:0]               blue_display;
                                            logic                                   title_active;
                                            logic               [7:0]               title_r;
                                            logic               [7:0]               title_g;
                                            logic               [7:0]               title_b;
                                            logic                                   hud_active;
                                            logic               [7:0]               hud_r;
                                            logic               [7:0]               hud_g;
                                            logic               [7:0]               hud_b;
    // VGA Renderer Module
    vga_renderer                            vga_graphics                            (
                                                                                    // Inputs
                                                                                    .vga_clock(vga_clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .blank_n(blanking_active_low),
                                                                                    .alignment(alignment),
                                                                                    .hcount(hcount),
                                                                                    .vcount(vcount),
                                                                                    .p1_x(p1_x),
                                                                                    .p2_x(p2_x),
                                                                                    .p1_y(p1_y),
                                                                                    .p2_y(p2_y),
                                                                                    .p1_bx(p1_bx),
                                                                                    .p2_bx(p2_bx),
                                                                                    .p1_by(p1_by),
                                                                                    .p2_by(p2_by),
                                                                                    .p1_ba(p1_ba),
                                                                                    .p2_ba(p2_ba),
                                                                                    .p1_lives(p1_lives),
                                                                                    .p2_lives(p2_lives),
                                                                                    .two_player(two_player),
                                                                                    .enemy_base_x(enemy_base_x),
                                                                                    .enemy_eb_x(enemy_eb_x),
                                                                                    .enemy_eb_y(enemy_eb_y),
                                                                                    .enemy_eb_active(enemy_eb_active),
                                                                                    .enemy_alive(enemy_alive),
                                                                                    .burg_x(burg_x),
                                                                                    .burg_y(burg_y),
                                                                                    .burg_active(burg_active),
                                                                                    .sq_pix(sq_pix),
                                                                                    .pt_pix(pt_pix),
                                                                                    .bt_pix(bt_pix),
                                                                                    .dk_pix(dk_pix),
                                                                                    .ship_pix(ship_pix),
                                                                                    .blk_pix(blk_pix),
                                                                                    .burg_pix(burg_pix),
                                                                                    // Outputs
                                                                                    .sq_addr(sq_addr),
                                                                                    .pt_addr(pt_addr),
                                                                                    .bt_addr(bt_addr),
                                                                                    .dk_addr(dk_addr),
                                                                                    .ship_addr(ship_addr),
                                                                                    .blk_addr(blk_addr),
                                                                                    .burg_addr(burg_addr),
                                                                                    .red(red_display),
                                                                                    .green(green_display),
                                                                                    .blue(blue_display)
                                                                                    );

    // ROMs
    gfx_squirrel_rom                        sq_rom                                  (
                                                                                    .address(sq_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(sq_pix)
                                                                                    );

    gfx_postal_truck_rom                    pt_rom                                  (
                                                                                    .address(pt_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(pt_pix)
                                                                                    );

    gfx_bath_tub_rom                        bt_rom                                  (
                                                                                    .address(bt_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(bt_pix)
                                                                                    );

    gfx_door_knock_rom                      dk_rom                                  (
                                                                                    .address(dk_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(dk_pix)
                                                                                    );

    gfx_player_rom                          ship_rom                                (
                                                                                    .address(ship_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(ship_pix)
                                                                                    );

    gfx_blockade_rom                        blk_rom                                 (
                                                                                    .address(blk_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(blk_pix)
                                                                                    );

    gfx_burger_rom                          burg_rom                                (
                                                                                    .address(burg_addr),
                                                                                    .clock(vga_clock),
                                                                                    .q(burg_pix)
                                                                                    );


    lives_hud                               lives_sprite_overlay                    (
                                                                                    .vga_clock(vga_clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .hcount(hcount),
                                                                                    .vcount(vcount),
                                                                                    .p1_lives(p1_lives),
                                                                                    .p2_lives(p2_lives),
                                                                                    .two_player(two_player),
                                                                                    .game_active(game_active),
                                                                                    .active(hud_active),
                                                                                    .r(hud_r),
                                                                                    .g(hud_g),
                                                                                    .b(hud_b)
                                                                                    );

    title_screen                            title_screen_overlay                    (
                                                                                    .vga_clock(vga_clock),
                                                                                    .reset_active_low(reset_active_low),
                                                                                    .blank_n(blanking_active_low),
                                                                                    .hcount(hcount),
                                                                                    .vcount(vcount),
                                                                                    .game_state(game_state),
                                                                                    .frame_tick(frame_tick),
                                                                                    .alignment(alignment),
                                                                                    .active(title_active),
                                                                                    .r(title_r),
                                                                                    .g(title_g),
                                                                                    .b(title_b)
                                                                                    );

    // Continous Assignments
    assign                                  red                                     = title_active ? title_r : (hud_active ? hud_r : red_display);
    assign                                  green                                   = title_active ? title_g : (hud_active ? hud_g : green_display);
    assign                                  blue                                    = title_active ? title_b : (hud_active ? hud_b : blue_display);

endmodule