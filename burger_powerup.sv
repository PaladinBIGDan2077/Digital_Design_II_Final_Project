/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Burger Power Up Module
// Filename:                        burger_powerup.sv
// Version:                         4
// Author:                          Daniel J. Lomis 
// Date:                            4/27/2025  
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
//                                  4/27/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module burger_ctrl (
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   game_active,
    input                                   logic                                   frame_tick,
    input                                   logic                                   burger_hit_p1,
    input                                   logic                                   burger_hit_p2,
    output                                  logic               [10:0]              burg_x,
    output                                  logic               [9:0]               burg_y,
    output                                  logic                                   burg_active,
    output                                  logic                                   collect_sfx
);
    // Local Parameters
    localparam          int                 SCREEN_W                                = 1280;
    localparam          int                 BURGER_Y                                = 80;
    localparam          int                 BURGER_W                                = 48;
    localparam          int                 BURGER_SPEED                            = 4;
    localparam          logic   [10:0]      SPAWN_PATTERN                           = 11'h2EF;
    // Internal Register-based Connections
                                            logic               [6:0]               inv_cnt;
                                            logic                                   spawn_trigger;
                                            logic                                   burger_hit;
                                            logic               [15:0]              lfsr;
                                            logic                                   fb;

    // Galois-derived Linear-feedback Shift Register
    always_comb begin
        fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    end

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            lfsr <= 16'hACE1;
        end 
        else if (frame_tick && game_active) begin
            lfsr <= {lfsr[14:0], fb};
        end
    end

    // Main Seqeuential Block
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            burg_x <= '0;
            burg_active <= 1'b0;
            collect_sfx <= 1'b0;
        end else begin
            collect_sfx <= 1'b0;
            if (game_active && frame_tick) begin
                // Spawner
                if (spawn_trigger) begin
                    burg_x <= 11'(SCREEN_W);
                    burg_active <= 1'b1;
                end
                else if (burg_active) begin
                    // Bullet Hit
                    if (burger_hit) begin
                        burg_active <= 1'b0;
                        collect_sfx <= 1'b1;
                    end
                    // Movement
                    else if (burg_x < 11'(BURGER_SPEED)) begin
                        burg_active <= 1'b0;
                    end 
                    else begin
                        burg_x <= burg_x - 11'(BURGER_SPEED);
                    end
                end
            end
        end
    end

    // Continous Assignments
    assign                                  burger_hit                              = burger_hit_p1 || burger_hit_p2;
    assign                                  spawn_trigger                           = (lfsr[10:0] == SPAWN_PATTERN) && !burg_active  && game_active;
    assign                                  burg_y                                  = 10'(BURGER_Y);


endmodule