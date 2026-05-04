/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Reset Inverter for PLLs / PLL Reset Line Modules
// Filename:                        reset_inverter.sv
// Version:                         2
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
// Description:                     Contains two small combinational utility modules used at the
//                                  top level to condition reset and PLL-lock signals throughout
//                                  the video subsystem.
//
//                                  reset_inverter
//                                    Converts an active-low reset (KEY[0], logic 0 = asserted)
//                                    into an active-high reset required by the Quartus-generated
//                                    wm8731_clockgen PLL IP core. Single assign: b = !a.
//
//                                  pll_reset
//                                    Gates the system ready signal so that downstream logic is
//                                    only released from reset when BOTH the board-level
//                                    active-low reset is de-asserted AND the PLL has achieved
//                                    lock. Prevents metastability during PLL acquisition.
//                                    Single assign: clock_signal_ready = reset_active_low & pll_locked.
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  4/15/2025  DJL  1        Original Code
//                                  4/16/2025  DJL  2        Added PLL Reset Module
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module reset_inverter
(
    input                                                                           a,
    output                                  logic                                   b
);
    // Continous Assignments
    assign                                  b                                       = !a;

endmodule

module pll_reset
(
    input                                                                           pll_locked,
    input                                                                           reset_active_low,
    output                                  logic                                   clock_signal_ready
);
    // Continous Assignments
    assign                                  clock_signal_ready                      = reset_active_low & pll_locked;

endmodule