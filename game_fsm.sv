/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Last Action Reesie FSM Module
// Filename:                        game_fsm.sv
// Version:                         9
// Author:                          Daniel J. Lomis 
// Date:                            4/17/2025  
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
//                                  4/17/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module game_fsm
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   frame_tick,
    input                                   logic                                   start_press,
    input                                   logic                                   sw0,
    input                                   logic               [2:0]               p1_lives,
    input                                   logic               [2:0]               p2_lives,
    input                                   logic               [47:0]              enemy_alive,
    output                                  logic               [1:0]               game_state,
    output                                  logic                                   game_active,
    output                                  logic                                   two_player,
    output                                  logic                                   game_over_sfx,
    output                                  logic                                   reset_scores
);
    // Local Parameters
    localparam          int                 GO_HOLD_FRAMES                          = 180;

    // Type Definitions of Enumerations
    typedef             enum                logic               [1:0]               {
        IDLE      = 2'b00,
        PLAYING   = 2'b01,
        GAME_OVER = 2'b10
    }   state_t;

    state_t     state,      next_state;

    // Internal Register-based Connections
                                            logic                                   all_enemies_dead;
                                            logic                                   game_over_cond;
                                            logic               [7:0]               go_timer;
                                            logic                                   go_hold_done;

    // Player 2 Handling of Game Over
    always_comb begin
        if (two_player) begin
            game_over_cond = ((p1_lives == 3'd0) && (p2_lives == 3'd0)) || all_enemies_dead;
        end
        else begin
            game_over_cond = (p1_lives == 3'd0) || all_enemies_dead;
        end
    end

    // Sequential Logic Block
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            state <= IDLE;
            two_player <= 1'b0;
            game_over_sfx <= 1'b0;
            reset_scores <= 1'b0;
            go_timer <= 8'd0;
        end 
        else begin
            game_over_sfx <= 1'b0;
            reset_scores <= 1'b0;
            if (state == GAME_OVER) begin
                if (!go_hold_done && frame_tick) begin
                    go_timer <= go_timer + 8'd1;
                end
            end
            else begin
                go_timer <= 8'd0;
            end
            case (state)
                IDLE: begin
                    if (start_press) begin
                        two_player <= sw0;
                        state <= PLAYING;
                    end
                end
                PLAYING: begin
                    if (game_over_cond) begin
                        state <= GAME_OVER;
                        game_over_sfx <= 1'b1;
                    end
                end
                GAME_OVER: begin
                    if (start_press) begin
                        go_timer <= 8'd0;
                        reset_scores <= 1'b1;
                        state <= IDLE;
                        game_over_sfx <= 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Continous Assignments
    assign                                  game_state                              = state;
    assign                                  game_active                             = (state == PLAYING);
    assign                                  go_hold_done                            = (go_timer >= 8'(GO_HOLD_FRAMES));
    assign                                  all_enemies_dead                        = (enemy_alive == 48'd0);

endmodule