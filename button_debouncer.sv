/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Monostable Multivibrator Input Decoder
// Filename:                        button_debouncer.sv
// Version:                         2
// Author:                          Daniel J. Lomis 
// Date:                            4/14/2025  
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
//                                  4/14/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module input_decode
(
    input                                   logic                                   clock,
    input                                   logic                                   reset_active_low,
    input                                   logic                                   JOY_1,
    input                                   logic                                   JOY_2,
    output                                  logic                                   fire1,
    output                                  logic                                   fire2,
    output                                  logic                                   start_press
);
    // Internal Register-based Connections
                                            logic                                   JOY_1_r;
                                            logic                                   JOY_2_r;
                                            logic                                   start_r;
    // Sequential Block
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            JOY_1_r <= 1'b0;
            JOY_2_r <= 1'b0;
            start_r <= 1'b0;
            fire1 <= 1'b0;
            fire2 <= 1'b0;
            start_press <= 1'b0;
        end 
        else begin
            JOY_1_r <= JOY_1;
            JOY_2_r <= JOY_2;
            start_r <= JOY_1;
            fire1 <= ~JOY_1 &  JOY_1_r;
            fire2 <= ~JOY_2 &  JOY_2_r;
            start_press <= ~JOY_1 &  start_r;
        end
    end

endmodule