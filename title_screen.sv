/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Title Screen Module
// Filename:                        title_screen.sv
// Version:                         4
// Author:                          Daniel J. Lomis 
// Date:                            5/1/2025  
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
//                                  5/2/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module title_screen
(
    input               logic                                                       vga_clock,
    input               logic                                                       reset_active_low,
    input               logic                                                       blank_n,
    input               logic               [10:0]                                  hcount,
    input               logic               [9:0]                                   vcount,
    input               logic               [1:0]                                   game_state,
    input               logic                                                       frame_tick,
    input               logic                                                       alignment,
    output              logic                                                       active,
    output              logic               [7:0]                                   r,
    output              logic               [7:0]                                   g,
    output              logic               [7:0]                                   b
);
    // Local Parameters
    localparam          logic   [1:0]       IDLE                                    = 2'b00;
    localparam          logic   [3:0]       S_LG                                    = 4'd8;
    localparam          logic   [3:0]       S_MD                                    = 4'd5;
    localparam          logic   [3:0]       S_SM                                    = 4'd3;
    localparam          int                 CW_LG                                   = 48;
    localparam          int                 CW_MD                                   = 30;
    localparam          int                 CW_SM                                   = 18;
    localparam          int                 Y_TITLE                                 = 90;
    localparam          int                 Y_SUB                                   = 175;
    localparam          int                 Y_PRESS                                 = 310;
    localparam          int                 Y_INS1                                  = 420;
    localparam          int                 Y_INS2                                  = 450;
    localparam          int                 Y_INS3                                  = 480;
    localparam          int                 Y_INS4                                  = 510;
    localparam          int                 Y_CRED1                                 = 560;
    localparam          int                 Y_CRED2                                 = 588;
    localparam          int                 X_TITLE                                 = 376;
    localparam          int                 X_SUB                                   = 496;
    localparam          int                 X_PRESS                                 = 475;
    localparam          int                 X_INS1                                  = 361;
    localparam          int                 X_INS2                                  = 478;
    localparam          int                 X_INS3                                  = 541;
    localparam          int                 X_INS4                                  = 406;
    localparam          int                 X_CRED1                                 = 388;
    localparam          int                 X_CRED2                                 = 280;
    // Internal Register-based Connections
                        logic                                   [5:0]               blink_cnt;
                        logic                                                       blink_on;
                        logic                                                       t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10; // LAST ACTION
                        logic                                                       s0, s1, s2, s3, s4, s5; // REESIE
                        logic                                                       ps0, ps1, ps2, ps3, ps4, ps5, ps6, ps7, ps8, ps9, ps10; // PRESS START
                        logic                                                       k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10, k11, k12, k13, k14, k15, k16, k17, k18, k19, k20, k21, k22, k23, k24, k25, k26, k27, k28, k29, k30; // RED BUTTON ON PADDLE 1 TO START
                        logic                                                       w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16, w17; // SW0: 1P / 2P MODE
                        logic                                                       r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10; // RESET: KEY0
                        logic                                                       c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25; // SW1: WHITE FOR CALIBRATION
                        logic                                                       d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27; // DEVELOPED BY DANIEL J. LOMIS
                        logic                                                       p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39;// THE LOMIS COMPANY OF VIRGINIA © MAY 2026
                        logic                                                       title_on;
    // Functions
    // Character Bitmap Look Up Table
    function            automatic           logic               [34:0]                      char_bm
    (
        input               logic               [6:0]                                   ascii
    );
        case (ascii)
            7'h01: char_bm = 35'b01110_10001_10110_10000_10110_10001_01110; // Copyright Symbol
            7'h41: char_bm = 35'b01110_10001_10001_11111_10001_10001_10001; // A
            7'h42: char_bm = 35'b11110_10001_10001_11110_10001_10001_11110; // B
            7'h43: char_bm = 35'b01110_10001_10000_10000_10000_10001_01110; // C
            7'h44: char_bm = 35'b11110_10001_10001_10001_10001_10001_11110; // D
            7'h45: char_bm = 35'b11111_10000_10000_11110_10000_10000_11111; // E
            7'h46: char_bm = 35'b11111_10000_10000_11110_10000_10000_10000; // F
            7'h47: char_bm = 35'b01110_10001_10000_10111_10001_10001_01111; // G
            7'h48: char_bm = 35'b10001_10001_10001_11111_10001_10001_10001; // H
            7'h49: char_bm = 35'b01110_00100_00100_00100_00100_00100_01110; // I
            7'h4A: char_bm = 35'b00111_00010_00010_00010_00010_10010_01100; // J
            7'h4B: char_bm = 35'b10001_10010_10100_11000_10100_10010_10001; // K
            7'h4C: char_bm = 35'b10000_10000_10000_10000_10000_10000_11111; // L
            7'h4D: char_bm = 35'b10001_11011_10101_10001_10001_10001_10001; // M
            7'h4E: char_bm = 35'b10001_11001_10101_10011_10001_10001_10001; // N
            7'h4F: char_bm = 35'b01110_10001_10001_10001_10001_10001_01110; // O
            7'h50: char_bm = 35'b11110_10001_10001_11110_10000_10000_10000; // P
            7'h52: char_bm = 35'b11110_10001_10001_11110_10100_10010_10001; // R
            7'h53: char_bm = 35'b01110_10000_10000_01110_00001_00001_01110; // S
            7'h54: char_bm = 35'b11111_00100_00100_00100_00100_00100_00100; // T
            7'h55: char_bm = 35'b10001_10001_10001_10001_10001_10001_01110; // U
            7'h56: char_bm = 35'b10001_10001_10001_10001_10001_01010_00100; // V
            7'h57: char_bm = 35'b10001_10001_10001_10101_10101_11011_10001; // W
            7'h59: char_bm = 35'b10001_10001_01010_00100_00100_00100_00100; // Y
            7'h30: char_bm = 35'b01110_10001_10011_10101_11001_10001_01110; // 0
            7'h31: char_bm = 35'b00100_01100_00100_00100_00100_00100_01110; // 1
            7'h32: char_bm = 35'b01110_10001_00001_00110_01000_10000_11111; // 2
            7'h36: char_bm = 35'b01110_10000_10000_11110_10001_10001_01110; // 6
            7'h39: char_bm = 35'b01110_10001_10001_01111_00001_00001_01110; // 9
            7'h20: char_bm = 35'b00000_00000_00000_00000_00000_00000_00000; // (space)
            7'h2F: char_bm = 35'b00001_00001_00010_00100_01000_10000_10000; // /
            7'h2E: char_bm = 35'b00000_00000_00000_00000_00000_00000_00100; // .
            7'h3A: char_bm = 35'b00000_00100_00100_00000_00100_00100_00000; // :
            default: char_bm = 35'b0;
        endcase
    endfunction
    // Pixel Generator
    function            automatic           logic                                           pix_char
    (
        input               logic               [10:0]                                  hx,
        input               logic               [9:0]                                   vy,
        input               logic               [10:0]                                  cx,
        input               logic               [9:0]                                   cy,
        input               logic               [3:0]                                   sc,
        input               logic               [6:0]                                   ascii
    );
        logic       [10:0]      dx;
        logic       [9:0]       dy;
        logic       [2:0]       col;
        logic       [2:0]       row;
        logic       [34:0]      bm;
        if (hx >= cx && hx < (cx + 11'(5) * {7'b0, sc}) && vy >= cy && vy < (cy + 10'(7) * {6'b0, sc})) begin
            dx = hx - cx;
            dy = vy - cy;
            case (sc)
                4'd8: begin
                    col = dx[5:3];
                    row = dy[5:3];
                end
                4'd5: begin
                    case (dx[5:0])
                        6'd0,  6'd1,  6'd2,  6'd3,  6'd4 : col = 3'd0;
                        6'd5,  6'd6,  6'd7,  6'd8,  6'd9 : col = 3'd1;
                        6'd10, 6'd11, 6'd12, 6'd13, 6'd14: col = 3'd2;
                        6'd15, 6'd16, 6'd17, 6'd18, 6'd19: col = 3'd3;
                        6'd20, 6'd21, 6'd22, 6'd23, 6'd24: col = 3'd4;
                        default:                           col = 3'd4;
                    endcase
                    case (dy[5:0])
                        6'd0,6'd1,6'd2,6'd3,6'd4:      row = 3'd0;
                        6'd5,6'd6,6'd7,6'd8,6'd9:      row = 3'd1;
                        6'd10,6'd11,6'd12,6'd13,6'd14: row = 3'd2;
                        6'd15,6'd16,6'd17,6'd18,6'd19: row = 3'd3;
                        6'd20,6'd21,6'd22,6'd23,6'd24: row = 3'd4;
                        6'd25,6'd26,6'd27,6'd28,6'd29: row = 3'd5;
                        6'd30,6'd31,6'd32,6'd33,6'd34: row = 3'd6;
                        default:                       row = 3'd6;
                    endcase
                end
                4'd3: begin
                    case (dx[3:0])
                        4'd0, 4'd1,  4'd2 : col = 3'd0;
                        4'd3, 4'd4,  4'd5 : col = 3'd1;
                        4'd6, 4'd7,  4'd8 : col = 3'd2;
                        4'd9, 4'd10, 4'd11: col = 3'd3;
                        default:            col = 3'd4;
                    endcase
                    case (dy[4:0])
                        5'd0, 5'd1, 5'd2 : row = 3'd0;
                        5'd3, 5'd4, 5'd5 : row = 3'd1;
                        5'd6, 5'd7, 5'd8 : row = 3'd2;
                        5'd9, 5'd10,5'd11: row = 3'd3;
                        5'd12,5'd13,5'd14: row = 3'd4;
                        5'd15,5'd16,5'd17: row = 3'd5;
                        default:           row = 3'd6;
                    endcase
                end
                default: begin
                    col = 3'd0;
                    row = 3'd0;
                end
            endcase
            // Bitmap LUT
            bm = char_bm(ascii);
            case ({row, col})
                6'b000_000: pix_char = bm[34];
                6'b000_001: pix_char = bm[33];
                6'b000_010: pix_char = bm[32];
                6'b000_011: pix_char = bm[31];
                6'b000_100: pix_char = bm[30];
                6'b001_000: pix_char = bm[29];
                6'b001_001: pix_char = bm[28];
                6'b001_010: pix_char = bm[27];
                6'b001_011: pix_char = bm[26];
                6'b001_100: pix_char = bm[25];
                6'b010_000: pix_char = bm[24];
                6'b010_001: pix_char = bm[23];
                6'b010_010: pix_char = bm[22];
                6'b010_011: pix_char = bm[21];
                6'b010_100: pix_char = bm[20];
                6'b011_000: pix_char = bm[19];
                6'b011_001: pix_char = bm[18];
                6'b011_010: pix_char = bm[17];
                6'b011_011: pix_char = bm[16];
                6'b011_100: pix_char = bm[15];
                6'b100_000: pix_char = bm[14];
                6'b100_001: pix_char = bm[13];
                6'b100_010: pix_char = bm[12];
                6'b100_011: pix_char = bm[11];
                6'b100_100: pix_char = bm[10];
                6'b101_000: pix_char = bm[9];
                6'b101_001: pix_char = bm[8];
                6'b101_010: pix_char = bm[7];
                6'b101_011: pix_char = bm[6];
                6'b101_100: pix_char = bm[5];
                6'b110_000: pix_char = bm[4];
                6'b110_001: pix_char = bm[3];
                6'b110_010: pix_char = bm[2];
                6'b110_011: pix_char = bm[1];
                6'b110_100: pix_char = bm[0];
                default: pix_char = 1'b0;
            endcase
        end 
        else begin
            pix_char = 1'b0;
        end
    endfunction

    // Blinking Characters 
    always_ff @(posedge vga_clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            blink_cnt <= 6'd0;
            blink_on <= 1'b1;
        end 
        else if (frame_tick) begin
            if (blink_cnt == 6'd29) begin
                blink_cnt <= 6'd0;
                blink_on <= ~blink_on;
            end 
            else begin
                blink_cnt <= blink_cnt + 6'd1;
            end
        end
    end
    
    // Character Assignment
    always_comb begin
        // Horizontal Centers
        //  "LAST ACTION"                        11×48=528   X=376
        //  "REESIE"                              6×48=288   X=496
        //  "PRESS START"                        11×30=330   X=475
        //  "RED BUTTON ON PADDLE 1 TO START"    31×18=558   X=361
        //  "SW0: 1P / 2P MODE"                  18×18=324   X=478
        //  "RESET: KEY0"                        11×18=198   X=541
        //  "SW1: WHITE FOR CALIBRATION"         26×18=468   X=406
        //  "DEVELOPED BY DANIEL J. LOMIS"       28×18=504   X=388
        //  "THE LOMIS COMPANY OF VIRGINIA C MAY 2026"
        //       29 + 1(sp) + 1(C) + 1(sp) + 8 = 40×18=720  X=280
        // "LAST ACTION"
        t0  = pix_char(hcount,vcount,11'(X_TITLE+ 0*CW_LG),10'(Y_TITLE),S_LG,7'h4C); // L
        t1  = pix_char(hcount,vcount,11'(X_TITLE+ 1*CW_LG),10'(Y_TITLE),S_LG,7'h41); // A
        t2  = pix_char(hcount,vcount,11'(X_TITLE+ 2*CW_LG),10'(Y_TITLE),S_LG,7'h53); // S
        t3  = pix_char(hcount,vcount,11'(X_TITLE+ 3*CW_LG),10'(Y_TITLE),S_LG,7'h54); // T
        t4  = pix_char(hcount,vcount,11'(X_TITLE+ 4*CW_LG),10'(Y_TITLE),S_LG,7'h20); // sp
        t5  = pix_char(hcount,vcount,11'(X_TITLE+ 5*CW_LG),10'(Y_TITLE),S_LG,7'h41); // A
        t6  = pix_char(hcount,vcount,11'(X_TITLE+ 6*CW_LG),10'(Y_TITLE),S_LG,7'h43); // C
        t7  = pix_char(hcount,vcount,11'(X_TITLE+ 7*CW_LG),10'(Y_TITLE),S_LG,7'h54); // T
        t8  = pix_char(hcount,vcount,11'(X_TITLE+ 8*CW_LG),10'(Y_TITLE),S_LG,7'h49); // I
        t9  = pix_char(hcount,vcount,11'(X_TITLE+ 9*CW_LG),10'(Y_TITLE),S_LG,7'h4F); // O
        t10 = pix_char(hcount,vcount,11'(X_TITLE+10*CW_LG),10'(Y_TITLE),S_LG,7'h4E); // N
        // "REESIE"
        s0 = pix_char(hcount,vcount,11'(X_SUB+0*CW_LG),10'(Y_SUB),S_LG,7'h52); // R
        s1 = pix_char(hcount,vcount,11'(X_SUB+1*CW_LG),10'(Y_SUB),S_LG,7'h45); // E
        s2 = pix_char(hcount,vcount,11'(X_SUB+2*CW_LG),10'(Y_SUB),S_LG,7'h45); // E
        s3 = pix_char(hcount,vcount,11'(X_SUB+3*CW_LG),10'(Y_SUB),S_LG,7'h53); // S
        s4 = pix_char(hcount,vcount,11'(X_SUB+4*CW_LG),10'(Y_SUB),S_LG,7'h49); // I
        s5 = pix_char(hcount,vcount,11'(X_SUB+5*CW_LG),10'(Y_SUB),S_LG,7'h45); // E
        // "PRESS START"
        ps0  = pix_char(hcount,vcount,11'(X_PRESS+ 0*CW_MD),10'(Y_PRESS),S_MD,7'h50); // P
        ps1  = pix_char(hcount,vcount,11'(X_PRESS+ 1*CW_MD),10'(Y_PRESS),S_MD,7'h52); // R
        ps2  = pix_char(hcount,vcount,11'(X_PRESS+ 2*CW_MD),10'(Y_PRESS),S_MD,7'h45); // E
        ps3  = pix_char(hcount,vcount,11'(X_PRESS+ 3*CW_MD),10'(Y_PRESS),S_MD,7'h53); // S
        ps4  = pix_char(hcount,vcount,11'(X_PRESS+ 4*CW_MD),10'(Y_PRESS),S_MD,7'h53); // S
        ps5  = pix_char(hcount,vcount,11'(X_PRESS+ 5*CW_MD),10'(Y_PRESS),S_MD,7'h20); // sp
        ps6  = pix_char(hcount,vcount,11'(X_PRESS+ 6*CW_MD),10'(Y_PRESS),S_MD,7'h53); // S
        ps7  = pix_char(hcount,vcount,11'(X_PRESS+ 7*CW_MD),10'(Y_PRESS),S_MD,7'h54); // T
        ps8  = pix_char(hcount,vcount,11'(X_PRESS+ 8*CW_MD),10'(Y_PRESS),S_MD,7'h41); // A
        ps9  = pix_char(hcount,vcount,11'(X_PRESS+ 9*CW_MD),10'(Y_PRESS),S_MD,7'h52); // R
        ps10 = pix_char(hcount,vcount,11'(X_PRESS+10*CW_MD),10'(Y_PRESS),S_MD,7'h54); // T
        // "RED BUTTON ON PADDLE 1 TO START"
        k0  = pix_char(hcount,vcount,11'(X_INS1+ 0*CW_SM),10'(Y_INS1),S_SM,7'h52); // R
        k1  = pix_char(hcount,vcount,11'(X_INS1+ 1*CW_SM),10'(Y_INS1),S_SM,7'h45); // E
        k2  = pix_char(hcount,vcount,11'(X_INS1+ 2*CW_SM),10'(Y_INS1),S_SM,7'h44); // D
        k3  = pix_char(hcount,vcount,11'(X_INS1+ 3*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k4  = pix_char(hcount,vcount,11'(X_INS1+ 4*CW_SM),10'(Y_INS1),S_SM,7'h42); // B
        k5  = pix_char(hcount,vcount,11'(X_INS1+ 5*CW_SM),10'(Y_INS1),S_SM,7'h55); // U
        k6  = pix_char(hcount,vcount,11'(X_INS1+ 6*CW_SM),10'(Y_INS1),S_SM,7'h54); // T
        k7  = pix_char(hcount,vcount,11'(X_INS1+ 7*CW_SM),10'(Y_INS1),S_SM,7'h54); // T
        k8  = pix_char(hcount,vcount,11'(X_INS1+ 8*CW_SM),10'(Y_INS1),S_SM,7'h4F); // O
        k9  = pix_char(hcount,vcount,11'(X_INS1+ 9*CW_SM),10'(Y_INS1),S_SM,7'h4E); // N
        k10 = pix_char(hcount,vcount,11'(X_INS1+10*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k11 = pix_char(hcount,vcount,11'(X_INS1+11*CW_SM),10'(Y_INS1),S_SM,7'h4F); // O
        k12 = pix_char(hcount,vcount,11'(X_INS1+12*CW_SM),10'(Y_INS1),S_SM,7'h4E); // N
        k13 = pix_char(hcount,vcount,11'(X_INS1+13*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k14 = pix_char(hcount,vcount,11'(X_INS1+14*CW_SM),10'(Y_INS1),S_SM,7'h50); // P
        k15 = pix_char(hcount,vcount,11'(X_INS1+15*CW_SM),10'(Y_INS1),S_SM,7'h41); // A
        k16 = pix_char(hcount,vcount,11'(X_INS1+16*CW_SM),10'(Y_INS1),S_SM,7'h44); // D
        k17 = pix_char(hcount,vcount,11'(X_INS1+17*CW_SM),10'(Y_INS1),S_SM,7'h44); // D
        k18 = pix_char(hcount,vcount,11'(X_INS1+18*CW_SM),10'(Y_INS1),S_SM,7'h4C); // L
        k19 = pix_char(hcount,vcount,11'(X_INS1+19*CW_SM),10'(Y_INS1),S_SM,7'h45); // E
        k20 = pix_char(hcount,vcount,11'(X_INS1+20*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k21 = pix_char(hcount,vcount,11'(X_INS1+21*CW_SM),10'(Y_INS1),S_SM,7'h31); // 1
        k22 = pix_char(hcount,vcount,11'(X_INS1+22*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k23 = pix_char(hcount,vcount,11'(X_INS1+23*CW_SM),10'(Y_INS1),S_SM,7'h54); // T
        k24 = pix_char(hcount,vcount,11'(X_INS1+24*CW_SM),10'(Y_INS1),S_SM,7'h4F); // O
        k25 = pix_char(hcount,vcount,11'(X_INS1+25*CW_SM),10'(Y_INS1),S_SM,7'h20); // sp
        k26 = pix_char(hcount,vcount,11'(X_INS1+26*CW_SM),10'(Y_INS1),S_SM,7'h53); // S
        k27 = pix_char(hcount,vcount,11'(X_INS1+27*CW_SM),10'(Y_INS1),S_SM,7'h54); // T
        k28 = pix_char(hcount,vcount,11'(X_INS1+28*CW_SM),10'(Y_INS1),S_SM,7'h41); // A
        k29 = pix_char(hcount,vcount,11'(X_INS1+29*CW_SM),10'(Y_INS1),S_SM,7'h52); // R
        k30 = pix_char(hcount,vcount,11'(X_INS1+30*CW_SM),10'(Y_INS1),S_SM,7'h54); // T
        // "SW0: 1P / 2P MODE"
        w0  = pix_char(hcount,vcount,11'(X_INS2+ 0*CW_SM),10'(Y_INS2),S_SM,7'h53); // S
        w1  = pix_char(hcount,vcount,11'(X_INS2+ 1*CW_SM),10'(Y_INS2),S_SM,7'h57); // W
        w2  = pix_char(hcount,vcount,11'(X_INS2+ 2*CW_SM),10'(Y_INS2),S_SM,7'h30); // 0
        w3  = pix_char(hcount,vcount,11'(X_INS2+ 3*CW_SM),10'(Y_INS2),S_SM,7'h3A); // :
        w4  = pix_char(hcount,vcount,11'(X_INS2+ 4*CW_SM),10'(Y_INS2),S_SM,7'h20); // sp
        w5  = pix_char(hcount,vcount,11'(X_INS2+ 5*CW_SM),10'(Y_INS2),S_SM,7'h31); // 1
        w6  = pix_char(hcount,vcount,11'(X_INS2+ 6*CW_SM),10'(Y_INS2),S_SM,7'h50); // P
        w7  = pix_char(hcount,vcount,11'(X_INS2+ 7*CW_SM),10'(Y_INS2),S_SM,7'h20); // sp
        w8  = pix_char(hcount,vcount,11'(X_INS2+ 8*CW_SM),10'(Y_INS2),S_SM,7'h2F); // /
        w9  = pix_char(hcount,vcount,11'(X_INS2+ 9*CW_SM),10'(Y_INS2),S_SM,7'h20); // sp
        w10 = pix_char(hcount,vcount,11'(X_INS2+10*CW_SM),10'(Y_INS2),S_SM,7'h32); // 2
        w11 = pix_char(hcount,vcount,11'(X_INS2+11*CW_SM),10'(Y_INS2),S_SM,7'h50); // P
        w12 = pix_char(hcount,vcount,11'(X_INS2+12*CW_SM),10'(Y_INS2),S_SM,7'h20); // sp
        w13 = pix_char(hcount,vcount,11'(X_INS2+13*CW_SM),10'(Y_INS2),S_SM,7'h4D); // M
        w14 = pix_char(hcount,vcount,11'(X_INS2+14*CW_SM),10'(Y_INS2),S_SM,7'h4F); // O
        w15 = pix_char(hcount,vcount,11'(X_INS2+15*CW_SM),10'(Y_INS2),S_SM,7'h44); // D
        w16 = pix_char(hcount,vcount,11'(X_INS2+16*CW_SM),10'(Y_INS2),S_SM,7'h45); // E
        w17 = pix_char(hcount,vcount,11'(X_INS2+17*CW_SM),10'(Y_INS2),S_SM,7'h20); // sp
        // "RESET: KEY0"
        r0  = pix_char(hcount,vcount,11'(X_INS3+ 0*CW_SM),10'(Y_INS3),S_SM,7'h52); // R
        r1  = pix_char(hcount,vcount,11'(X_INS3+ 1*CW_SM),10'(Y_INS3),S_SM,7'h45); // E
        r2  = pix_char(hcount,vcount,11'(X_INS3+ 2*CW_SM),10'(Y_INS3),S_SM,7'h53); // S
        r3  = pix_char(hcount,vcount,11'(X_INS3+ 3*CW_SM),10'(Y_INS3),S_SM,7'h45); // E
        r4  = pix_char(hcount,vcount,11'(X_INS3+ 4*CW_SM),10'(Y_INS3),S_SM,7'h54); // T
        r5  = pix_char(hcount,vcount,11'(X_INS3+ 5*CW_SM),10'(Y_INS3),S_SM,7'h3A); // :
        r6  = pix_char(hcount,vcount,11'(X_INS3+ 6*CW_SM),10'(Y_INS3),S_SM,7'h20); // sp
        r7  = pix_char(hcount,vcount,11'(X_INS3+ 7*CW_SM),10'(Y_INS3),S_SM,7'h4B); // K
        r8  = pix_char(hcount,vcount,11'(X_INS3+ 8*CW_SM),10'(Y_INS3),S_SM,7'h45); // E
        r9  = pix_char(hcount,vcount,11'(X_INS3+ 9*CW_SM),10'(Y_INS3),S_SM,7'h59); // Y
        r10 = pix_char(hcount,vcount,11'(X_INS3+10*CW_SM),10'(Y_INS3),S_SM,7'h30); // 0
        // "SW9: WHITE FOR CALIBRATION"
        c0  = pix_char(hcount,vcount,11'(X_INS4+ 0*CW_SM),10'(Y_INS4),S_SM,7'h53); // S
        c1  = pix_char(hcount,vcount,11'(X_INS4+ 1*CW_SM),10'(Y_INS4),S_SM,7'h57); // W
        c2  = pix_char(hcount,vcount,11'(X_INS4+ 2*CW_SM),10'(Y_INS4),S_SM,7'h39); // 9
        c3  = pix_char(hcount,vcount,11'(X_INS4+ 3*CW_SM),10'(Y_INS4),S_SM,7'h3A); // :
        c4  = pix_char(hcount,vcount,11'(X_INS4+ 4*CW_SM),10'(Y_INS4),S_SM,7'h20); // sp
        c5  = pix_char(hcount,vcount,11'(X_INS4+ 5*CW_SM),10'(Y_INS4),S_SM,7'h57); // W
        c6  = pix_char(hcount,vcount,11'(X_INS4+ 6*CW_SM),10'(Y_INS4),S_SM,7'h48); // H
        c7  = pix_char(hcount,vcount,11'(X_INS4+ 7*CW_SM),10'(Y_INS4),S_SM,7'h49); // I
        c8  = pix_char(hcount,vcount,11'(X_INS4+ 8*CW_SM),10'(Y_INS4),S_SM,7'h54); // T
        c9  = pix_char(hcount,vcount,11'(X_INS4+ 9*CW_SM),10'(Y_INS4),S_SM,7'h45); // E
        c10 = pix_char(hcount,vcount,11'(X_INS4+10*CW_SM),10'(Y_INS4),S_SM,7'h20); // sp
        c11 = pix_char(hcount,vcount,11'(X_INS4+11*CW_SM),10'(Y_INS4),S_SM,7'h46); // F
        c12 = pix_char(hcount,vcount,11'(X_INS4+12*CW_SM),10'(Y_INS4),S_SM,7'h4F); // O
        c13 = pix_char(hcount,vcount,11'(X_INS4+13*CW_SM),10'(Y_INS4),S_SM,7'h52); // R
        c14 = pix_char(hcount,vcount,11'(X_INS4+14*CW_SM),10'(Y_INS4),S_SM,7'h20); // sp
        c15 = pix_char(hcount,vcount,11'(X_INS4+15*CW_SM),10'(Y_INS4),S_SM,7'h43); // C
        c16 = pix_char(hcount,vcount,11'(X_INS4+16*CW_SM),10'(Y_INS4),S_SM,7'h41); // A
        c17 = pix_char(hcount,vcount,11'(X_INS4+17*CW_SM),10'(Y_INS4),S_SM,7'h4C); // L
        c18 = pix_char(hcount,vcount,11'(X_INS4+18*CW_SM),10'(Y_INS4),S_SM,7'h49); // I
        c19 = pix_char(hcount,vcount,11'(X_INS4+19*CW_SM),10'(Y_INS4),S_SM,7'h42); // B
        c20 = pix_char(hcount,vcount,11'(X_INS4+20*CW_SM),10'(Y_INS4),S_SM,7'h52); // R
        c21 = pix_char(hcount,vcount,11'(X_INS4+21*CW_SM),10'(Y_INS4),S_SM,7'h41); // A
        c22 = pix_char(hcount,vcount,11'(X_INS4+22*CW_SM),10'(Y_INS4),S_SM,7'h54); // T
        c23 = pix_char(hcount,vcount,11'(X_INS4+23*CW_SM),10'(Y_INS4),S_SM,7'h49); // I
        c24 = pix_char(hcount,vcount,11'(X_INS4+24*CW_SM),10'(Y_INS4),S_SM,7'h4F); // O
        c25 = pix_char(hcount,vcount,11'(X_INS4+25*CW_SM),10'(Y_INS4),S_SM,7'h4E); // N
        // "DEVELOPED BY DANIEL J LOMIS"
        d0  = pix_char(hcount,vcount,11'(X_CRED1+ 0*CW_SM),10'(Y_CRED1),S_SM,7'h44); // D
        d1  = pix_char(hcount,vcount,11'(X_CRED1+ 1*CW_SM),10'(Y_CRED1),S_SM,7'h45); // E
        d2  = pix_char(hcount,vcount,11'(X_CRED1+ 2*CW_SM),10'(Y_CRED1),S_SM,7'h56); // V
        d3  = pix_char(hcount,vcount,11'(X_CRED1+ 3*CW_SM),10'(Y_CRED1),S_SM,7'h45); // E
        d4  = pix_char(hcount,vcount,11'(X_CRED1+ 4*CW_SM),10'(Y_CRED1),S_SM,7'h4C); // L
        d5  = pix_char(hcount,vcount,11'(X_CRED1+ 5*CW_SM),10'(Y_CRED1),S_SM,7'h4F); // O
        d6  = pix_char(hcount,vcount,11'(X_CRED1+ 6*CW_SM),10'(Y_CRED1),S_SM,7'h50); // P
        d7  = pix_char(hcount,vcount,11'(X_CRED1+ 7*CW_SM),10'(Y_CRED1),S_SM,7'h45); // E
        d8  = pix_char(hcount,vcount,11'(X_CRED1+ 8*CW_SM),10'(Y_CRED1),S_SM,7'h44); // D
        d9  = pix_char(hcount,vcount,11'(X_CRED1+ 9*CW_SM),10'(Y_CRED1),S_SM,7'h20); // sp
        d10 = pix_char(hcount,vcount,11'(X_CRED1+10*CW_SM),10'(Y_CRED1),S_SM,7'h42); // B
        d11 = pix_char(hcount,vcount,11'(X_CRED1+11*CW_SM),10'(Y_CRED1),S_SM,7'h59); // Y
        d12 = pix_char(hcount,vcount,11'(X_CRED1+12*CW_SM),10'(Y_CRED1),S_SM,7'h20); // sp
        d13 = pix_char(hcount,vcount,11'(X_CRED1+13*CW_SM),10'(Y_CRED1),S_SM,7'h44); // D
        d14 = pix_char(hcount,vcount,11'(X_CRED1+14*CW_SM),10'(Y_CRED1),S_SM,7'h41); // A
        d15 = pix_char(hcount,vcount,11'(X_CRED1+15*CW_SM),10'(Y_CRED1),S_SM,7'h4E); // N
        d16 = pix_char(hcount,vcount,11'(X_CRED1+16*CW_SM),10'(Y_CRED1),S_SM,7'h49); // I
        d17 = pix_char(hcount,vcount,11'(X_CRED1+17*CW_SM),10'(Y_CRED1),S_SM,7'h45); // E
        d18 = pix_char(hcount,vcount,11'(X_CRED1+18*CW_SM),10'(Y_CRED1),S_SM,7'h4C); // L
        d19 = pix_char(hcount,vcount,11'(X_CRED1+19*CW_SM),10'(Y_CRED1),S_SM,7'h20); // sp
        d20 = pix_char(hcount,vcount,11'(X_CRED1+20*CW_SM),10'(Y_CRED1),S_SM,7'h4A); // J
        d21 = pix_char(hcount,vcount,11'(X_CRED1+21*CW_SM),10'(Y_CRED1),S_SM,7'h2E); // .
        d22 = pix_char(hcount,vcount,11'(X_CRED1+22*CW_SM),10'(Y_CRED1),S_SM,7'h20); // sp
        d23 = pix_char(hcount,vcount,11'(X_CRED1+23*CW_SM),10'(Y_CRED1),S_SM,7'h4C); // L
        d24 = pix_char(hcount,vcount,11'(X_CRED1+24*CW_SM),10'(Y_CRED1),S_SM,7'h4F); // O
        d25 = pix_char(hcount,vcount,11'(X_CRED1+25*CW_SM),10'(Y_CRED1),S_SM,7'h4D); // M
        d26 = pix_char(hcount,vcount,11'(X_CRED1+26*CW_SM),10'(Y_CRED1),S_SM,7'h49); // I
        d27 = pix_char(hcount,vcount,11'(X_CRED1+27*CW_SM),10'(Y_CRED1),S_SM,7'h53); // S
        // "THE LOMIS COMPANY OF VIRGINIA C MAY 2026"
        p0  = pix_char(hcount,vcount,11'(X_CRED2+ 0*CW_SM),10'(Y_CRED2),S_SM,7'h54); // T
        p1  = pix_char(hcount,vcount,11'(X_CRED2+ 1*CW_SM),10'(Y_CRED2),S_SM,7'h48); // H
        p2  = pix_char(hcount,vcount,11'(X_CRED2+ 2*CW_SM),10'(Y_CRED2),S_SM,7'h45); // E
        p3  = pix_char(hcount,vcount,11'(X_CRED2+ 3*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p4  = pix_char(hcount,vcount,11'(X_CRED2+ 4*CW_SM),10'(Y_CRED2),S_SM,7'h4C); // L
        p5  = pix_char(hcount,vcount,11'(X_CRED2+ 5*CW_SM),10'(Y_CRED2),S_SM,7'h4F); // O
        p6  = pix_char(hcount,vcount,11'(X_CRED2+ 6*CW_SM),10'(Y_CRED2),S_SM,7'h4D); // M
        p7  = pix_char(hcount,vcount,11'(X_CRED2+ 7*CW_SM),10'(Y_CRED2),S_SM,7'h49); // I
        p8  = pix_char(hcount,vcount,11'(X_CRED2+ 8*CW_SM),10'(Y_CRED2),S_SM,7'h53); // S
        p9  = pix_char(hcount,vcount,11'(X_CRED2+ 9*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p10 = pix_char(hcount,vcount,11'(X_CRED2+10*CW_SM),10'(Y_CRED2),S_SM,7'h43); // C
        p11 = pix_char(hcount,vcount,11'(X_CRED2+11*CW_SM),10'(Y_CRED2),S_SM,7'h4F); // O
        p12 = pix_char(hcount,vcount,11'(X_CRED2+12*CW_SM),10'(Y_CRED2),S_SM,7'h4D); // M
        p13 = pix_char(hcount,vcount,11'(X_CRED2+13*CW_SM),10'(Y_CRED2),S_SM,7'h50); // P
        p14 = pix_char(hcount,vcount,11'(X_CRED2+14*CW_SM),10'(Y_CRED2),S_SM,7'h41); // A
        p15 = pix_char(hcount,vcount,11'(X_CRED2+15*CW_SM),10'(Y_CRED2),S_SM,7'h4E); // N
        p16 = pix_char(hcount,vcount,11'(X_CRED2+16*CW_SM),10'(Y_CRED2),S_SM,7'h59); // Y
        p17 = pix_char(hcount,vcount,11'(X_CRED2+17*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p18 = pix_char(hcount,vcount,11'(X_CRED2+18*CW_SM),10'(Y_CRED2),S_SM,7'h4F); // O
        p19 = pix_char(hcount,vcount,11'(X_CRED2+19*CW_SM),10'(Y_CRED2),S_SM,7'h46); // F
        p20 = pix_char(hcount,vcount,11'(X_CRED2+20*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p21 = pix_char(hcount,vcount,11'(X_CRED2+21*CW_SM),10'(Y_CRED2),S_SM,7'h56); // V
        p22 = pix_char(hcount,vcount,11'(X_CRED2+22*CW_SM),10'(Y_CRED2),S_SM,7'h49); // I
        p23 = pix_char(hcount,vcount,11'(X_CRED2+23*CW_SM),10'(Y_CRED2),S_SM,7'h52); // R
        p24 = pix_char(hcount,vcount,11'(X_CRED2+24*CW_SM),10'(Y_CRED2),S_SM,7'h47); // G
        p25 = pix_char(hcount,vcount,11'(X_CRED2+25*CW_SM),10'(Y_CRED2),S_SM,7'h49); // I
        p26 = pix_char(hcount,vcount,11'(X_CRED2+26*CW_SM),10'(Y_CRED2),S_SM,7'h4E); // N
        p27 = pix_char(hcount,vcount,11'(X_CRED2+27*CW_SM),10'(Y_CRED2),S_SM,7'h49); // I
        p28 = pix_char(hcount,vcount,11'(X_CRED2+28*CW_SM),10'(Y_CRED2),S_SM,7'h41); // A
        p29 = pix_char(hcount,vcount,11'(X_CRED2+29*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p30 = pix_char(hcount,vcount,11'(X_CRED2+30*CW_SM),10'(Y_CRED2),S_SM,7'h01); // C
        p31 = pix_char(hcount,vcount,11'(X_CRED2+31*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p32 = pix_char(hcount,vcount,11'(X_CRED2+32*CW_SM),10'(Y_CRED2),S_SM,7'h4D); // M
        p33 = pix_char(hcount,vcount,11'(X_CRED2+33*CW_SM),10'(Y_CRED2),S_SM,7'h41); // A
        p34 = pix_char(hcount,vcount,11'(X_CRED2+34*CW_SM),10'(Y_CRED2),S_SM,7'h59); // Y
        p35 = pix_char(hcount,vcount,11'(X_CRED2+35*CW_SM),10'(Y_CRED2),S_SM,7'h20); // sp
        p36 = pix_char(hcount,vcount,11'(X_CRED2+36*CW_SM),10'(Y_CRED2),S_SM,7'h32); // 2
        p37 = pix_char(hcount,vcount,11'(X_CRED2+37*CW_SM),10'(Y_CRED2),S_SM,7'h30); // 0
        p38 = pix_char(hcount,vcount,11'(X_CRED2+38*CW_SM),10'(Y_CRED2),S_SM,7'h32); // 2
        p39 = pix_char(hcount,vcount,11'(X_CRED2+39*CW_SM),10'(Y_CRED2),S_SM,7'h36); // 6
    end
    // Color Encoder
    always_comb begin
        active = 1'b0;
        r      = 8'h00;
        g      = 8'h00;
        b      = 8'h00;
        if (title_on) begin
            active = 1'b1;
            // Background: white in alignment mode, black otherwise
            if (alignment) begin
                r = 8'hFF;
                g = 8'hFF;
                b = 8'hFF;
            end
            else begin
                r = 8'h00;
                g = 8'h00;
                b = 8'h00;
            end
            // Cyan separator
            if (vcount >= 10'd80 && vcount <= 10'd82) begin
                r = 8'h00;
                g = 8'hFF;
                b = 8'hFF;
            end
            // Cyan separator
            if (vcount >= 10'd238 && vcount <= 10'd240) begin
                r = 8'h00;
                g = 8'hFF;
                b = 8'hFF;
            end
            // Grey separator
            if (vcount >= 10'd548 && vcount <= 10'd549) begin
                r = 8'h44;
                g = 8'h44;
                b = 8'h44;
            end
            // BEGIN TEXT
            // "LAST ACTION": white
            if (t0 | t1 | t2 | t3 | t4 | t5 | t6 | t7 | t8 | t9 | t10) begin
                r = 8'hFF;
                g = 8'hFF;
                b = 8'hFF;
            end
            // "REESIE": green
            if (s0 | s1 | s2 | s3 | s4 | s5) begin
                r = 8'h00;
                g = 8'hFF;
                b = 8'h00;
            end
            // "PRESS START": red
            if (blink_on && (ps0 | ps1 | ps2 | ps3 | ps4 | ps5 | ps6 | ps7 | ps8 | ps9 | ps10)) begin
                r = 8'hFF;
                g = 8'h00;
                b = 8'h00;
            end
            // Instructions: grey
            // "RED BUTTON ON PADDLE 1 TO START"
            if (k0 | k1 | k2 | k3 | k4 | k5 | k6 | k7 | k8 | k9 | k10 | k11 | k12 | k13 | k14 | k15 | k16 | k17 | k18 | k19 | k20 | k21 | k22 | k23 | k24 | k25 | k26 | k27 | k28 | k29 | k30) begin
                r = 8'hAA;
                g = 8'hAA;
                b = 8'hAA;
            end
            // "SW0: 1P / 2P MODE"
            if (w0 | w1 | w2 | w3 | w4 | w5 | w6 | w7 | w8 | w9 | w10 | w11 | w12 | w13 | w14 | w15 | w16 | w17) begin
                r = 8'hAA;
                g = 8'hAA;
                b = 8'hAA;
            end
            // "RESET: KEY0"
            if (r0 | r1 | r2 | r3 | r4 | r5 | r6 | r7 | r8 | r9 | r10) begin
                r = 8'hAA;
                g = 8'hAA;
                b = 8'hAA;
            end
            // "SW9: WHITE FOR CALIBRATION"
            if (c0 | c1 | c2 | c3 | c4 | c5 | c6 | c7 | c8 | c9 | c10 | c11 | c12 | c13 | c14 | c15 | c16 | c17 | c18 | c19 | c20 | c21 | c22 | c23 | c24 | c25) begin
                r = 8'hAA;
                g = 8'hAA;
                b = 8'hAA;
            end
            // Credits: dimmer white
            // "DEVELOPED BY DANIEL J. LOMIS"
            if (d0 | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 | d9 | d10 | d11 | d12 | d13 | d14 | d15 | d16 | d17 | d18 | d19 | d20 | d21 | d22 | d23 | d24 | d25 | d26 | d27) begin
                r = 8'hCC;
                g = 8'hCC;
                b = 8'hCC;
            end
            // "THE LOMIS COMPANY OF VIRGINIA C MAY 2026"
            if (p0 | p1 | p2 | p3 | p4 | p5 | p6 | p7 | p8 | p9 | p10 | p11 | p12 | p13 | p14 | p15 | p16 | p17 | p18 | p19 | p20 | p21 | p22 | p23 | p24 | p25 | p26 | p27 | p28 | p29 | p30 | p31 | p32 | p33 | p34 | p35 | p36 | p37 | p38 | p39) begin
                r = 8'hCC;
                g = 8'hCC;
                b = 8'hCC;
            end
        end
    end

    // Continous Assignment
    assign                                  title_on                                = (game_state == IDLE) && blank_n;

endmodule