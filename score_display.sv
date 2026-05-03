/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Seven Segment Display Module
// Filename:                        score_display.sv
// Version:                         8
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
// Description:                     Casdasd
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/28/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module score_lives
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   game_active,
    input                                   logic                                   frame_tick,
    input                                   logic                                   two_player,
    input                                   logic                                   reset_scores,
    input                                   logic               [3:0]               p1_score_inc,
    input                                   logic               [3:0]               p2_score_inc,
    input                                   logic                                   burger_hit_p1,
    input                                   logic                                   burger_hit_p2,
    input                                   logic               [2:0]               p1_lives,
    input                                   logic               [2:0]               p2_lives,
    input                                   logic               [1:0]               game_state,
    output                                  logic               [6:0]               HEX0,
    output                                  logic               [6:0]               HEX1,
    output                                  logic               [6:0]               HEX2,
    output                                  logic               [6:0]               HEX3,
    output                                  logic               [6:0]               HEX4,
    output                                  logic               [6:0]               HEX5
);
    // Local Parameters
    localparam          logic   [6:0]       SEG_0                                   = 7'b1000000;
    localparam          logic   [6:0]       SEG_1                                   = 7'b1111001;
    localparam          logic   [6:0]       SEG_2                                   = 7'b0100100;
    localparam          logic   [6:0]       SEG_3                                   = 7'b0110000;
    localparam          logic   [6:0]       SEG_4                                   = 7'b0011001;
    localparam          logic   [6:0]       SEG_5                                   = 7'b0010010;
    localparam          logic   [6:0]       SEG_6                                   = 7'b0000010;
    localparam          logic   [6:0]       SEG_7                                   = 7'b1111000;
    localparam          logic   [6:0]       SEG_8                                   = 7'b0000000;
    localparam          logic   [6:0]       SEG_9                                   = 7'b0010000;
    localparam          logic   [6:0]       SEG_DASH                                = 7'b0111111;
    localparam          logic   [6:0]       SEG_BLK                                 = 7'b1111111;
    localparam          logic   [6:0]       SEG_E                                   = 7'b0000110;
    localparam          logic   [6:0]       SEG_N                                   = 7'b0101011;
    localparam          logic   [6:0]       SEG_D                                   = 7'b0100001;
    localparam          logic   [6:0]       SEG_L                                   = 7'b1000111;
    localparam          logic   [6:0]       SEG_A                                   = 7'b0001000;
    localparam          logic   [6:0]       SEG_C                                   = 7'b1000110;
    localparam          logic   [6:0]       SEG_R                                   = 7'b1001110;
    localparam          logic   [1:0]       ST_GAME_OVER                            = 2'b10;
    localparam          logic   [1:0]       ST_IDLE                                 = 2'b00;
    localparam          int                 ALT_FRAMES                              = 120;

    // Internal Register-based Connections
                                            logic               [13:0]              p1_score;
                                            logic               [13:0]              p2_score;
                                            logic               [6:0]               alt_cnt;
                                            logic                                   show_p2;
                                            logic               [3:0]               d_thou;
                                            logic               [3:0]               d_hund;
                                            logic               [3:0]               d_tens;
                                            logic               [3:0]               d_ones;
                                            logic               [15:0]              p1_bcd;
                                            logic               [15:0]              p2_bcd;
                                            logic               [15:0]              cur_bcd;
    // Internal Functions
    // BCD to Seven Segment Decoder
    function            automatic           logic               [6:0]                       bcd_seg
    (
        input               logic               [3:0]                                   d
    );
        case (d)
            4'd0: bcd_seg = SEG_0;
            4'd1: bcd_seg = SEG_1;
            4'd2: bcd_seg = SEG_2;
            4'd3: bcd_seg = SEG_3;
            4'd4: bcd_seg = SEG_4;
            4'd5: bcd_seg = SEG_5;
            4'd6: bcd_seg = SEG_6;
            4'd7: bcd_seg = SEG_7;
            4'd8: bcd_seg = SEG_8;
            4'd9: bcd_seg = SEG_9;
            default: bcd_seg = SEG_BLK;
        endcase
    endfunction

    // Score Incrementer
    function            automatic           logic               [6:0]                       pts
    (
        input               logic               [3:0]                                   s
    );
        case (s)
            4'b1000: pts = 7'd30;
            4'b0100: pts = 7'd20;
            4'b0010: pts = 7'd15;
            4'b0001: pts = 7'd10;
            default: pts = 7'd0;
        endcase
    endfunction

    // BCD Extractor
    function            automatic           logic               [15:0]                      to_bcd
    (
        input               logic               [13:0]                                  bin
    );
        logic [29:0] scratch;
        scratch = 30'(bin);
        for (int i = 0; i < 14; i++) begin
            if (scratch[17:14] >= 4'd5) begin
                scratch[17:14] = scratch[17:14] + 4'd3;
            end
            if (scratch[21:18] >= 4'd5) begin
                scratch[21:18] = scratch[21:18] + 4'd3;
            end
            if (scratch[25:22] >= 4'd5) begin
                scratch[25:22] = scratch[25:22] + 4'd3;
            end
            if (scratch[29:26] >= 4'd5) begin
                scratch[29:26] = scratch[29:26] + 4'd3;
            end
            scratch = scratch << 1;
        end
        return scratch[29:14];
    endfunction

    // Score Accumulator
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            p1_score <= '0;
            p2_score <= '0;
            alt_cnt <= '0;
            show_p2 <= 1'b0;
        end 
        else begin
            if (reset_scores) begin
                p1_score <= '0;
                p2_score <= '0;
                alt_cnt <= '0;
                show_p2 <= 1'b0;
            end 
            else begin
                if (game_active) begin
                    // Player 1 Scores
                    if (p1_score_inc != 4'b0) begin
                        if (p1_score + 14'(pts(p1_score_inc)) <= 14'd9999) begin
                            p1_score <= p1_score + 14'(pts(p1_score_inc));
                        end
                        else begin
                            p1_score <= 14'd9999;
                        end
                    end
                    // Player 2 Scores
                    if (p2_score_inc != 4'b0 && two_player) begin
                        if (p2_score + 14'(pts(p2_score_inc)) <= 14'd9999) begin
                            p2_score <= p2_score + 14'(pts(p2_score_inc));
                        end
                        else begin
                            p2_score <= 14'd9999;
                        end
                    end
                    // Burger Hit
                    if (burger_hit_p1) begin
                        if (p1_score + 14'd100 <= 14'd9999) begin
                            p1_score <= p1_score + 14'd100;
                        end
                        else begin
                            p1_score <= 14'd9999;
                        end
                    end
                    // Burger Hit Player Two
                    if (burger_hit_p2 && two_player) begin
                        if (p2_score + 14'd100 <= 14'd9999) begin
                            p2_score <= p2_score + 14'd100;
                        end
                        else begin
                            p2_score <= 14'd9999;
                        end
                    end
                end
                // Score Switcher
                if (frame_tick && two_player && game_active) begin
                    if (alt_cnt == 7'(ALT_FRAMES - 1)) begin
                        alt_cnt <= '0;
                        show_p2 <= ~show_p2;
                    end 
                    else begin
                        alt_cnt <= alt_cnt + 7'd1;
                    end
                end
            end
        end
    end

    always_comb begin
        p1_bcd = to_bcd(p1_score);
        p2_bcd = to_bcd(p2_score);
        cur_bcd = (show_p2 && two_player) ? p2_bcd : p1_bcd;
    end

    always_comb begin
        d_thou = cur_bcd[15:12];
        d_hund = cur_bcd[11:8];
        d_tens = cur_bcd[7:4];
        d_ones = cur_bcd[3:0];
    end

    always_comb begin
        if (game_state == ST_GAME_OVER) begin
            HEX5 = SEG_E;
            HEX4 = SEG_N;
            HEX3 = SEG_D;
            HEX2 = SEG_E;
            HEX1 = SEG_N;
            HEX0 = SEG_D;
        end 
        else if (game_state == ST_IDLE) begin
            HEX5 = SEG_L;
            HEX4 = SEG_A;
            HEX3 = SEG_A;
            HEX2 = SEG_C;
            HEX1 = SEG_R;
            HEX0 = SEG_E;
        end 
        else begin
            HEX5 = (show_p2 && two_player) ? SEG_2 : SEG_1;
            HEX4 = SEG_DASH;
            HEX3 = bcd_seg(d_thou);
            HEX2 = bcd_seg(d_hund);
            HEX1 = bcd_seg(d_tens);
            HEX0 = bcd_seg(d_ones);
        end
    end

endmodule