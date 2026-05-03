/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Player Lives Renderer Module
// Filename:                        player_lives.sv
// Version:                         5
// Author:                          Daniel J. Lomis
// Date:                            4/30/2025
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
//                                  4/30/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module lives_hud
(
    input                                   logic                                   vga_clock,
    input                                   logic                                   reset_active_low,
    input                                   logic               [10:0]              hcount,
    input                                   logic               [9:0]               vcount,
    input                                   logic               [2:0]               p1_lives,
    input                                   logic               [2:0]               p2_lives,
    input                                   logic                                   two_player,
    input                                   logic                                   game_active,
    output                                  logic                                   active,
    output                                  logic               [7:0]               r,
    output                                  logic               [7:0]               g,
    output                                  logic               [7:0]               b
);
    // Local Parameters
    localparam          int                 SPRITE_W                                = 56;
    localparam          int                 SPRITE_H                                = 56;
    localparam          int                 ICON_GAP                                = 8;
    localparam          int                 MARGIN_X                                = 12;
    localparam          int                 ICON_Y                                  = 12;
    localparam          int                 SCREEN_W                                = 1280;
    localparam          int                 P1_X                [3]                 = '{MARGIN_X, MARGIN_X + (SPRITE_W + ICON_GAP), MARGIN_X + 2*(SPRITE_W + ICON_GAP)};
    localparam          int                 P2_X                [3]                 = '{SCREEN_W - MARGIN_X - SPRITE_W, SCREEN_W - MARGIN_X - SPRITE_W - (SPRITE_W + ICON_GAP), SCREEN_W - MARGIN_X - SPRITE_W - 2*(SPRITE_W + ICON_GAP)};
    // Internal Register-based Connections
                                            logic               [11:0]              p1_addr             [3];
                                            logic               [11:0]              p2_addr             [3];
                                            logic                                   p1_in               [3];
                                            logic                                   p2_in               [3];
                                            logic               [7:0]               p1_q                [3];
                                            logic               [7:0]               p2_q                [3];
                                            logic                                   p1_in_d             [3];
                                            logic                                   p2_in_d             [3];
                                            logic               [2:0]               p1_lives_d;
                                            logic               [2:0]               p2_lives_d;
                                            logic                                   two_player_d;
                                            logic                                   game_active_d;
                                            logic               [7:0]               p1_r                [3];
                                            logic               [7:0]               p1_g                [3];
                                            logic               [7:0]               p1_b                [3];
                                            logic               [7:0]               p2_r                [3];
                                            logic               [7:0]               p2_g                [3];
                                            logic               [7:0]               p2_b                [3];
    // Submodule Declarations
    // Player 1
    gfx_lives_rom                           u_p1_life0                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p1_addr[0]),
                                                                                    .q(p1_q[0])
                                                                                    );
    gfx_lives_rom                           u_p1_life1                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p1_addr[1]),
                                                                                    .q(p1_q[1])
                                                                                    );
    gfx_lives_rom                           u_p1_life2                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p1_addr[2]),
                                                                                    .q(p1_q[2])
                                                                                    );
    // Player 2
    gfx_lives_rom                           u_p2_life0                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p2_addr[0]),
                                                                                    .q(p2_q[0])
                                                                                    );
    gfx_lives_rom                           u_p2_life1                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p2_addr[1]),
                                                                                    .q(p2_q[1])
                                                                                    );
    gfx_lives_rom                           u_p2_life2                              (
                                                                                    .clock(vga_clock),
                                                                                    .address(p2_addr[2]),
                                                                                    .q(p2_q[2])
                                                                                    );
    // Player 1 256 Color LUT
    color_lut_8b                            u_lut_p1_0                              (
                                                                                    .color_idx(p1_q[0]),
                                                                                    .r(p1_r[0]),
                                                                                    .g(p1_g[0]),
                                                                                    .b(p1_b[0])
                                                                                    );
    color_lut_8b                            u_lut_p1_1                              (
                                                                                    .color_idx(p1_q[1]),
                                                                                    .r(p1_r[1]),
                                                                                    .g(p1_g[1]),
                                                                                    .b(p1_b[1])
                                                                                    );
    color_lut_8b                            u_lut_p1_2                              (
                                                                                    .color_idx(p1_q[2]),
                                                                                    .r(p1_r[2]),
                                                                                    .g(p1_g[2]),
                                                                                    .b(p1_b[2])
                                                                                    );
    // Player 2 256 Color LUT
    color_lut_8b                            u_lut_p2_0                              (
                                                                                    .color_idx(p2_q[0]),
                                                                                    .r(p2_r[0]),
                                                                                    .g(p2_g[0]),
                                                                                    .b(p2_b[0])
                                                                                    );
    color_lut_8b                            u_lut_p2_1                              (
                                                                                    .color_idx(p2_q[1]),
                                                                                    .r(p2_r[1]),
                                                                                    .g(p2_g[1]),
                                                                                    .b(p2_b[1])
                                                                                    );
    color_lut_8b                            u_lut_p2_2                              (
                                                                                    .color_idx(p2_q[2]),
                                                                                    .r(p2_r[2]),
                                                                                    .g(p2_g[2]),
                                                                                    .b(p2_b[2])
                                                                                    );

    // Sequential Logic Block
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            for (int i = 0; i < 3; i++) begin
                p1_in_d[i] <= 1'b0;
                p2_in_d[i] <= 1'b0;
            end
            p1_lives_d <= '0;
            p2_lives_d <= '0;
            two_player_d <= 1'b0;
            game_active_d <= 1'b0;
        end 
        else begin
            for (int i = 0; i < 3; i++) begin
                p1_in_d[i] <= p1_in[i];
                p2_in_d[i] <= p2_in[i];
            end
            p1_lives_d <= p1_lives;
            p2_lives_d <= p2_lives;
            two_player_d <= two_player;
            game_active_d <= game_active;
        end
    end

    // Sprite Drawing
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            // Player 1 
            if (hcount >= 11'(P1_X[i]) && hcount < 11'(P1_X[i] + SPRITE_W) && vcount >= 10'(ICON_Y) && vcount < 10'(ICON_Y  + SPRITE_H)) begin
                p1_in  [i] = 1'b1;
                p1_addr[i] = 12'((int'(vcount) - ICON_Y) * SPRITE_W + int'(hcount) - P1_X[i]);
            end else begin
                p1_in  [i] = 1'b0;
                p1_addr[i] = 12'd0;
            end
            // Player 2
            if (hcount >= 11'(P2_X[i]) && hcount < 11'(P2_X[i] + SPRITE_W) && vcount >= 10'(ICON_Y) && vcount < 10'(ICON_Y  + SPRITE_H)) begin
                p2_in  [i] = 1'b1;
                p2_addr[i] = 12'((int'(vcount) - ICON_Y) * SPRITE_W + int'(hcount) - P2_X[i]);
            end else begin
                p2_in  [i] = 1'b0;
                p2_addr[i] = 12'd0;
            end
        end
    end

    // Color Decoding
    always_comb begin
        active = 1'b0;
        r = 8'h00;
        g = 8'h00;
        b = 8'h00;
        if (game_active_d) begin
            // Player 1 Lives
            for (int i = 0; i < 3; i++) begin
                if (p1_in_d[i] && (i < int'(p1_lives_d)) && (p1_q[i] != 8'h00)) begin
                    active = 1'b1;
                    r = p1_r[i];
                    g = p1_g[i];
                    b = p1_b[i];
                end
            end
            // Player 2 Lives
            if (two_player_d) begin
                for (int i = 0; i < 3; i++) begin
                    if (p2_in_d[i] && (i < int'(p2_lives_d)) && (p2_q[i] != 8'h00)) begin
                        active = 1'b1;
                        r = p2_r[i];
                        g = p2_g[i];
                        b = p2_b[i];
                    end
                end
            end
        end
    end

endmodule