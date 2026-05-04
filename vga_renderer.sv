/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           VGA Renderer Module
// Filename:                        vga_renderer.sv
// Version:                         14
// Author:                          Daniel J. Lomis
// Date:                            4/19/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     Composites all game sprites (enemies, players, bullets, burger,
//                                  blockades, background) into a single RGB(8,8,8) pixel stream for
//                                  1280×720 @ 60 Hz VGA output. Uses a two-stage pipeline on the
//                                  VGA pixel clock: stage 0 determines which sprite(s) to draw at
//                                  the current scan position via combinatorial overlap tests; stage 1
//                                  (one cycle later) multiplexes sprite ROM data or solid colors and
//                                  outputs the final RGB result. Supports configurable background
//                                  color (black or white) via alignment input.
//
//                                  Sprite priority (drawn back-to-front, last write wins):
//                                    DRAW_BG           - background (black or white)
//                                    DRAW_BLK          - left and right blockade shields (128×64 each)
//                                    DRAW_ROW0/1/2/3   - enemy rows (squirrel, postal, bathtub, door)
//                                    DRAW_SHIP_P2      - Player 2 ship (only if two_player = 1)
//                                    DRAW_SHIP_P1      - Player 1 ship
//                                    DRAW_BURGER       - burger power-up (48×32)
//                                    DRAW_EBULL        - enemy bullets (red, 4×14 hardcoded)
//                                    DRAW_PBULL        - player bullets (green, 4×14 hardcoded)
//
//                                  Pipeline stages:
//                                    Stage 0 (combinatorial):
//                                      - Compares (h_la, v_la) against all sprite bounding boxes
//                                      - Selects the topmost sprite via last-write priority
//                                      - Computes the address offset into that sprite's ROM
//                                      - Outputs selection (sel_s0) and ROM addresses
//                                    Stage 1 (registered):
//                                      - Latches sel_s0 -> sel_s1
//                                      - Muxes sprite ROM data or uses hardcoded colors
//                                      - Applies blank_n (outputs black during blanking intervals)
//                                      - Drives RGB output
//
//                                  Helper functions:
//                                    in_spr() - AABB test: returns true if (hx, vy) falls inside
//                                               sprite at (sx, sy) with dimensions (w, h)
//                                    sprite_x() - wraps enemy sprite X across screen boundary
//
//                                  Sprite ROMs (externally provided):
//                                    sq_pix (squirrel)     12-bit addr
//                                    pt_pix (postal truck) 13-bit addr
//                                    bt_pix (bathtub)      12-bit addr
//                                    dk_pix (door)         12-bit addr
//                                    ship_pix (ship)       11-bit addr (shared by P1/P2)
//                                    blk_pix (blockade)    13-bit addr
//                                    burg_pix (burger)     11-bit addr
//
//                                  Hard-coded colors:
//                                    Player bullets         - green (0x00FF00)
//                                    Enemy bullets          - red   (0xFF0000)
//                                    Sprite ROM color == 0  - background (black or white per alignment)
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/19/2025   DJL  1        Original Code; simple background fill
//                                  4/19/2025   DJL  2        Added single sprite ROM support; introduced in_spr() AABB test
//                                  4/20/2025   DJL  3        Added enemy row rendering; nested loop over 4 rows × 8 sprites
//                                  4/21/2025   DJL  4        Added player ship rendering; separate ship ROM address for P1/P2
//                                  4/21/2025   DJL  5        Added player bullet rendering with hard-coded green color; introduced pipeline stage split
//                                  4/23/2025   DJL  6        Added enemy bullet rendering with red color; looped over 4 enemy rows
//                                  4/25/2025   DJL  7        Introduced two-stage pipeline: stage 0 (comb) priority sel, stage 1 (reg) color mux and RGB output
//                                  4/27/2025   DJL  8        Added burger power-up sprite rendering with active gating
//                                  4/27/2025   DJL  9        Added blockade shield rendering (left and right rects)
//                                  4/28/2025   DJL  10       Added two_player gating for Player 2 ship rendering in sprite priority
//                                  4/30/2025   DJL  11       Added sprite alive-mask gating to skip dead enemies; added active-flag gating for burger and enemy bullets
//                                  5/2/2025    DJL  12       Added alignment input for dual background color (white/black); used when ROM pixel == 0x00
//                                  5/2/2025    DJL  13       Refactored sprite selection into sprite_sel_t enum; introduced sel_s0 and sel_s1 registers for cleaner priority encoding
//                                  5/3/2025    DJL  14       Added blank_n blanking during sync intervals; added rom_color to separate sprite pixel data from RGB multiplexing
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module vga_renderer
(
    input                                   logic                                   vga_clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   blank_n,
    input                                   logic                                   alignment,
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
    input                                   logic               [47:0]              enemy_alive,
    input                                   logic               [10:0]              burg_x,
    input                                   logic               [9:0]               burg_y,
    input                                   logic                                   burg_active,
    input                                   logic               [7:0]               sq_pix,
    input                                   logic               [7:0]               pt_pix,
    input                                   logic               [7:0]               bt_pix,
    input                                   logic               [7:0]               dk_pix,
    input                                   logic               [7:0]               ship_pix,
    input                                   logic               [7:0]               blk_pix,
    input                                   logic               [7:0]               burg_pix,
    output                                  logic               [11:0]              sq_addr,
    output                                  logic               [12:0]              pt_addr,
    output                                  logic               [11:0]              bt_addr,
    output                                  logic               [11:0]              dk_addr,
    output                                  logic               [10:0]              ship_addr,
    output                                  logic               [12:0]              blk_addr,
    output                                  logic               [10:0]              burg_addr,
    output                                  logic               [7:0]               red,
    output                                  logic               [7:0]               green,
    output                                  logic               [7:0]               blue
);
    // Local Parameters
    localparam          int                 SQ_W                                    = 64;
    localparam          int                 SQ_H                                    = 48;
    localparam          int                 PT_W                                    = 80;
    localparam          int                 PT_H                                    = 56;
    localparam          int                 BT_W                                    = 72;
    localparam          int                 BT_H                                    = 48;
    localparam          int                 DK_W                                    = 56;
    localparam          int                 DK_H                                    = 64;
    localparam          int                 SHIP_W                                  = 48;
    localparam          int                 SHIP_H                                  = 24;
    localparam          int                 BLK_W                                   = 128;
    localparam          int                 BLK_H                                   = 64;
    localparam          int                 BURG_W                                  = 48;
    localparam          int                 BURG_H                                  = 32;
    localparam          int                 BULL_W                                  = 4;
    localparam          int                 BULL_H                                  = 14;
    localparam          int                 ROW_Y               [4]                 = '{120, 220, 330, 440};
    localparam          int                 ROW_W               [4]                 = '{SQ_W, PT_W, BT_W, DK_W};
    localparam          int                 ROW_H               [4]                 = '{SQ_H, PT_H, BT_H, DK_H};
    localparam          int                 ROW_SPC             [4]                 = '{140, 155, 140, 130};
    localparam          int                 ROW_NSPR            [4]                 = '{7, 6, 7, 8};
    localparam          int                 BLK_LX                                  = 160;
    localparam          int                 BLK_RX                                  = 992;
    localparam          int                 BLK_Y0                                  = 505;
    localparam          int                 BLK_Y1                                  = 569;
    localparam          int                 GROUND_Y                                = 680;
    localparam          int                 ICON_W                                  = 24;
    localparam          int                 ICON_H                                  = 12;
    localparam          int                 ICON_SEP                                = 30;

    // Type Definitions of Structures/Enumerators
    typedef             enum                logic               [3:0]               {
        DRAW_BG      = 4'd0,
        DRAW_BLK     = 4'd1,
        DRAW_ROW0    = 4'd2,
        DRAW_ROW1    = 4'd3,
        DRAW_ROW2    = 4'd4,
        DRAW_ROW3    = 4'd5,
        DRAW_SHIP_P1 = 4'd6,
        DRAW_SHIP_P2 = 4'd7,
        DRAW_BURGER  = 4'd8,
        DRAW_EBULL   = 4'd9,
        DRAW_PBULL   = 4'd10
    }   sprite_sel_t;

    sprite_sel_t    sel_s0,    sel_s1;

    // Internal Register-based Connections
                                            logic               [3:0]               s0_ebull_row;
                                            logic                                   s0_p1bull;
                                            logic                                   s0_p2bull;
                                            logic               [10:0]              h_la;
                                            logic               [9:0]               v_la;
                                            logic               [7:0]               rom_color;
                                            logic               [7:0]               r_s2;
                                            logic               [7:0]               g_s2;
                                            logic               [7:0]               b_s2;

    // Functions
    // Address Selector
    function            automatic           logic                                           in_spr
    (
        input               logic               [10:0]                                  hx,
        input               logic               [10:0]                                  sx,
        input               int                                                         w,
        input               logic               [9:0]                                   vy,
        input               logic               [9:0]                                   sy,
        input               int                                                         h
    );
        return ((hx >= sx) && (hx < sx + 11'(w)) && (vy >= sy) && (vy < sy + 10'(h)));
    endfunction
    // Submodule Look Up Table
    color_lut_8b                            look_up_table_256_color                 (
                                                                                    .color_idx(rom_color),
                                                                                    .r(r_s2),
                                                                                    .g(g_s2),
                                                                                    .b(b_s2)
                                                                                    );
    // Color Drawer
    always_comb begin
        case (sel_s1)
            DRAW_ROW0:    rom_color = sq_pix;
            DRAW_ROW1:    rom_color = pt_pix;
            DRAW_ROW2:    rom_color = bt_pix;
            DRAW_ROW3:    rom_color = dk_pix;
            DRAW_SHIP_P1: rom_color = ship_pix;
            DRAW_SHIP_P2: rom_color = ship_pix;
            DRAW_BLK:     rom_color = blk_pix;
            DRAW_BURGER:  rom_color = burg_pix;
            default:      rom_color = 8'h00;
        endcase
    end

    // Address Look Ahead
    always_comb begin
        if (hcount + 11'd2 >= 11'd1280) begin
            h_la = hcount + 11'd2 - 11'd1280;
            v_la = (vcount == 10'd719) ? 10'd0 : vcount + 10'd1;
        end else begin
            h_la = hcount + 11'd2;
            v_la = vcount;
        end
    end

    // Rom Selector Register Block
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            sel_s1 <= DRAW_BG;
        end
        else begin
            sel_s1 <= sel_s0;
        end
    end

    // Main Combinational Block
    always_comb begin
        // Background Draw
        sel_s0 = DRAW_BG;
        sq_addr = '0;
        pt_addr = '0;
        bt_addr = '0;
        dk_addr = '0;
        ship_addr = '0;
        blk_addr = '0;
        burg_addr = '0;
        // Blockade Draw, Left and Right
        if (h_la >= 11'(BLK_LX) && h_la < 11'(BLK_LX + BLK_W) && v_la >= 10'(BLK_Y0) && v_la < 10'(BLK_Y1)) begin
            sel_s0 = DRAW_BLK;
            blk_addr = 13'((v_la - BLK_Y0) * BLK_W + (h_la - BLK_LX));
        end
        if (h_la >= 11'(BLK_RX) && h_la < 11'(BLK_RX + BLK_W) && v_la >= 10'(BLK_Y0) && v_la < 10'(BLK_Y1)) begin
            sel_s0 = DRAW_BLK;
            blk_addr = 13'((v_la - BLK_Y0) * BLK_W + (h_la - BLK_RX));
        end
        // Enemy Draw
        // Squirrel
        for (int j = 0; j < ROW_NSPR[0]; j++) begin
            logic [10:0] sx;
            sx = (enemy_base_x[0*11 +: 11] + 11'(j) * 11'(ROW_SPC[0])) % 11'd1280;
            if (enemy_alive[0*12 + j] && in_spr(h_la, sx, ROW_W[0], v_la, 10'(ROW_Y[0]), ROW_H[0])) begin
                sel_s0 = DRAW_ROW0;
                sq_addr = 12'((v_la - ROW_Y[0]) * ROW_W[0] + (h_la - sx));
            end
        end
        // Postal Van
        for (int j = 0; j < ROW_NSPR[1]; j++) begin
            logic [10:0] sx;
            sx = (enemy_base_x[1*11 +: 11] + 11'(j) * 11'(ROW_SPC[1])) % 11'd1280;
            if (enemy_alive[1*12 + j] && in_spr(h_la, sx, ROW_W[1], v_la, 10'(ROW_Y[1]), ROW_H[1])) begin
                sel_s0 = DRAW_ROW1;
                pt_addr = 13'((v_la - ROW_Y[1]) * ROW_W[1] + (h_la - sx));
            end
        end
        // Dog Bath
        for (int j = 0; j < ROW_NSPR[2]; j++) begin
            logic [10:0] sx;
            sx = (enemy_base_x[2*11 +: 11] + 11'(j) * 11'(ROW_SPC[2])) % 11'd1280;
            if (enemy_alive[2*12 + j] && in_spr(h_la, sx, ROW_W[2], v_la, 10'(ROW_Y[2]), ROW_H[2])) begin
                sel_s0 = DRAW_ROW2;
                bt_addr = 12'((v_la - ROW_Y[2]) * ROW_W[2] + (h_la - sx));
            end
        end
        // Door Knock
        for (int j = 0; j < ROW_NSPR[3]; j++) begin
            logic [10:0] sx;
            sx = (enemy_base_x[3*11 +: 11] + 11'(j) * 11'(ROW_SPC[3])) % 11'd1280;
            if (enemy_alive[3*12 + j] && in_spr(h_la, sx, ROW_W[3], v_la, 10'(ROW_Y[3]), ROW_H[3])) begin
                sel_s0 = DRAW_ROW3;
                dk_addr = 12'((v_la - ROW_Y[3]) * ROW_W[3] + (h_la - sx));
            end
        end
        // Players, One and Two
        if (two_player && in_spr(h_la, p2_x, SHIP_W, v_la, p2_y, SHIP_H)) begin
            sel_s0 = DRAW_SHIP_P2;
            ship_addr = 11'((v_la - p2_y) * SHIP_W + (h_la - p2_x));
        end
        if (in_spr(h_la, p1_x, SHIP_W, v_la, p1_y, SHIP_H)) begin
            sel_s0 = DRAW_SHIP_P1;
            ship_addr = 11'((v_la - p1_y) * SHIP_W + (h_la - p1_x));
        end
        // Burger Power Up
        if (burg_active && in_spr(h_la, burg_x, BURG_W, v_la, burg_y, BURG_H)) begin
            sel_s0 = DRAW_BURGER;
            burg_addr = 11'((v_la - burg_y) * BURG_W + (h_la - burg_x));
        end
        // Enemy Bullets
        for (int i = 0; i < 4; i++) begin
            if (enemy_eb_active[i] && in_spr(h_la, enemy_eb_x[i*11 +: 11] - 11'(BULL_W/2), BULL_W, v_la, enemy_eb_y[i*10 +: 10], BULL_H)) begin
                sel_s0 = DRAW_EBULL;
            end
        end
        // Player Bullets, One and Two
        if (p1_ba && in_spr(h_la, p1_bx - 11'(BULL_W/2), BULL_W, v_la, p1_by, BULL_H)) begin
            sel_s0 = DRAW_PBULL;
        end
        if (p2_ba && two_player && in_spr(h_la, p2_bx - 11'(BULL_W/2), BULL_W, v_la, p2_by, BULL_H)) begin
            sel_s0 = DRAW_PBULL;
        end
    end

    // Main Proceedural Block
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            red   <= 8'h00;
            green <= 8'h00;
            blue  <= 8'h00;
        end 
        else begin
            if (!blank_n) begin
                // Blanking Interval
                red   <= 8'h00;
                green <= 8'h00;
                blue  <= 8'h00;
            end 
            else begin
                case (sel_s1)
                    // Bullets
                    DRAW_PBULL: begin
                        red   <= 8'h00;
                        green <= 8'hFF;
                        blue  <= 8'h00;
                    end
                    DRAW_EBULL: begin
                        red   <= 8'hFF;
                        green <= 8'h00;
                        blue  <= 8'h00;
                    end
                    default: begin
                        // Background Generation
                        if (rom_color == 8'h00) begin
                            // White BKG
                            if (alignment) begin
                                red   <= 8'hFF;
                                green <= 8'hFF;
                                blue  <= 8'hFF;
                            end
                            // Black BKG
                            else begin
                                red   <= 8'h00;
                                green <= 8'h00;
                                blue  <= 8'h00;
                            end
                        end 
                        else begin
                            red   <= r_s2;
                            green <= g_s2;
                            blue  <= b_s2;
                        end
                    end
                endcase
            end
        end
    end

endmodule