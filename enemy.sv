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
// Description:                     Casdasd
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/25/2025   DJL  1        Original Code
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