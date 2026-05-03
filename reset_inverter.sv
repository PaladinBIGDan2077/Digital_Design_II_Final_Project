/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Reset Inverter for PLLs / PLL Reset Line Modules
// Filename:                        reset_inverter.sv
// Version:                         3
// Author:                          Daniel J. Lomis 
// Date:                            4/15/2025
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4514 - Digital Design II 
// Instructor:                      Professor Jason Thweatt 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
// 
// Description:                     This module represents the colmination of several modules.
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/15/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module reset_inverter
(
    input                                                                           a,
    output                                  logic                                   b
);

    assign                                  b                                       = !a;

endmodule

module pll_reset
(
    input                                                                           pll_locked,
    input                                                                           reset_active_low,
    output                                  logic                                   clock_signal_ready
);

    assign                                  clock_signal_ready                      = reset_active_low & pll_locked;

endmodule