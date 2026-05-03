/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           256 Color Look Up Table Module
// Filename:                        color_lut.sv
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
// Description:                     Casdasd
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/19/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module color_lut_8b
(
    input                                   logic               [7:0]               color_idx,
    output                                  logic               [7:0]               r,
    output                                  logic               [7:0]               g,
    output                                  logic               [7:0]               b
);
    // Internal Register-based Connections
                                            logic               [23:0]              rgb24;

    always_comb begin
        case (color_idx)
            8'h00 : rgb24 = 24'h000000;
            8'h01 : rgb24 = 24'h800000;
            8'h02 : rgb24 = 24'h008000;
            8'h03 : rgb24 = 24'h808000;
            8'h04 : rgb24 = 24'h000080;
            8'h05 : rgb24 = 24'h800080;
            8'h06 : rgb24 = 24'h008080;
            8'h07 : rgb24 = 24'hC0C0C0;
            8'h08 : rgb24 = 24'hC0DCC0;
            8'h09 : rgb24 = 24'hA6CAF0;
            8'h0A : rgb24 = 24'h000000;
            8'h0B : rgb24 = 24'h000033;
            8'h0C : rgb24 = 24'h000066;
            8'h0D : rgb24 = 24'h000099;
            8'h0E : rgb24 = 24'h0000CC;
            8'h0F : rgb24 = 24'h0000FF;
            8'h10 : rgb24 = 24'h003300;
            8'h11 : rgb24 = 24'h003333;
            8'h12 : rgb24 = 24'h003366;
            8'h13 : rgb24 = 24'h003399;
            8'h14 : rgb24 = 24'h0033CC;
            8'h15 : rgb24 = 24'h0033FF;
            8'h16 : rgb24 = 24'h006600;
            8'h17 : rgb24 = 24'h006633;
            8'h18 : rgb24 = 24'h006666;
            8'h19 : rgb24 = 24'h006699;
            8'h1A : rgb24 = 24'h0066CC;
            8'h1B : rgb24 = 24'h0066FF;
            8'h1C : rgb24 = 24'h009900;
            8'h1D : rgb24 = 24'h009933;
            8'h1E : rgb24 = 24'h009966;
            8'h1F : rgb24 = 24'h009999;
            8'h20 : rgb24 = 24'h0099CC;
            8'h21 : rgb24 = 24'h0099FF;
            8'h22 : rgb24 = 24'h00CC00;
            8'h23 : rgb24 = 24'h00CC33;
            8'h24 : rgb24 = 24'h00CC66;
            8'h25 : rgb24 = 24'h00CC99;
            8'h26 : rgb24 = 24'h00CCCC;
            8'h27 : rgb24 = 24'h00CCFF;
            8'h28 : rgb24 = 24'h00FF00;
            8'h29 : rgb24 = 24'h00FF33;
            8'h2A : rgb24 = 24'h00FF66;
            8'h2B : rgb24 = 24'h00FF99;
            8'h2C : rgb24 = 24'h00FFCC;
            8'h2D : rgb24 = 24'h00FFFF;
            8'h2E : rgb24 = 24'h330000;
            8'h2F : rgb24 = 24'h330033;
            8'h30 : rgb24 = 24'h330066;
            8'h31 : rgb24 = 24'h330099;
            8'h32 : rgb24 = 24'h3300CC;
            8'h33 : rgb24 = 24'h3300FF;
            8'h34 : rgb24 = 24'h333300;
            8'h35 : rgb24 = 24'h333333;
            8'h36 : rgb24 = 24'h333366;
            8'h37 : rgb24 = 24'h333399;
            8'h38 : rgb24 = 24'h3333CC;
            8'h39 : rgb24 = 24'h3333FF;
            8'h3A : rgb24 = 24'h336600;
            8'h3B : rgb24 = 24'h336633;
            8'h3C : rgb24 = 24'h336666;
            8'h3D : rgb24 = 24'h336699;
            8'h3E : rgb24 = 24'h3366CC;
            8'h3F : rgb24 = 24'h3366FF;
            8'h40 : rgb24 = 24'h339900;
            8'h41 : rgb24 = 24'h339933;
            8'h42 : rgb24 = 24'h339966;
            8'h43 : rgb24 = 24'h339999;
            8'h44 : rgb24 = 24'h3399CC;
            8'h45 : rgb24 = 24'h3399FF;
            8'h46 : rgb24 = 24'h33CC00;
            8'h47 : rgb24 = 24'h33CC33;
            8'h48 : rgb24 = 24'h33CC66;
            8'h49 : rgb24 = 24'h33CC99;
            8'h4A : rgb24 = 24'h33CCCC;
            8'h4B : rgb24 = 24'h33CCFF;
            8'h4C : rgb24 = 24'h33FF00;
            8'h4D : rgb24 = 24'h33FF33;
            8'h4E : rgb24 = 24'h33FF66;
            8'h4F : rgb24 = 24'h33FF99;
            8'h50 : rgb24 = 24'h33FFCC;
            8'h51 : rgb24 = 24'h33FFFF;
            8'h52 : rgb24 = 24'h660000;
            8'h53 : rgb24 = 24'h660033;
            8'h54 : rgb24 = 24'h660066;
            8'h55 : rgb24 = 24'h660099;
            8'h56 : rgb24 = 24'h6600CC;
            8'h57 : rgb24 = 24'h6600FF;
            8'h58 : rgb24 = 24'h663300;
            8'h59 : rgb24 = 24'h663333;
            8'h5A : rgb24 = 24'h663366;
            8'h5B : rgb24 = 24'h663399;
            8'h5C : rgb24 = 24'h6633CC;
            8'h5D : rgb24 = 24'h6633FF;
            8'h5E : rgb24 = 24'h666600;
            8'h5F : rgb24 = 24'h666633;
            8'h60 : rgb24 = 24'h666666;
            8'h61 : rgb24 = 24'h666699;
            8'h62 : rgb24 = 24'h6666CC;
            8'h63 : rgb24 = 24'h6666FF;
            8'h64 : rgb24 = 24'h669900;
            8'h65 : rgb24 = 24'h669933;
            8'h66 : rgb24 = 24'h669966;
            8'h67 : rgb24 = 24'h669999;
            8'h68 : rgb24 = 24'h6699CC;
            8'h69 : rgb24 = 24'h6699FF;
            8'h6A : rgb24 = 24'h66CC00;
            8'h6B : rgb24 = 24'h66CC33;
            8'h6C : rgb24 = 24'h66CC66;
            8'h6D : rgb24 = 24'h66CC99;
            8'h6E : rgb24 = 24'h66CCCC;
            8'h6F : rgb24 = 24'h66CCFF;
            8'h70 : rgb24 = 24'h66FF00;
            8'h71 : rgb24 = 24'h66FF33;
            8'h72 : rgb24 = 24'h66FF66;
            8'h73 : rgb24 = 24'h66FF99;
            8'h74 : rgb24 = 24'h66FFCC;
            8'h75 : rgb24 = 24'h66FFFF;
            8'h76 : rgb24 = 24'h990000;
            8'h77 : rgb24 = 24'h990033;
            8'h78 : rgb24 = 24'h990066;
            8'h79 : rgb24 = 24'h990099;
            8'h7A : rgb24 = 24'h9900CC;
            8'h7B : rgb24 = 24'h9900FF;
            8'h7C : rgb24 = 24'h993300;
            8'h7D : rgb24 = 24'h993333;
            8'h7E : rgb24 = 24'h993366;
            8'h7F : rgb24 = 24'h993399;
            8'h80 : rgb24 = 24'h9933CC;
            8'h81 : rgb24 = 24'h9933FF;
            8'h82 : rgb24 = 24'h996600;
            8'h83 : rgb24 = 24'h996633;
            8'h84 : rgb24 = 24'h996666;
            8'h85 : rgb24 = 24'h996699;
            8'h86 : rgb24 = 24'h9966CC;
            8'h87 : rgb24 = 24'h9966FF;
            8'h88 : rgb24 = 24'h999900;
            8'h89 : rgb24 = 24'h999933;
            8'h8A : rgb24 = 24'h999966;
            8'h8B : rgb24 = 24'h999999;
            8'h8C : rgb24 = 24'h9999CC;
            8'h8D : rgb24 = 24'h9999FF;
            8'h8E : rgb24 = 24'h99CC00;
            8'h8F : rgb24 = 24'h99CC33;
            8'h90 : rgb24 = 24'h99CC66;
            8'h91 : rgb24 = 24'h99CC99;
            8'h92 : rgb24 = 24'h99CCCC;
            8'h93 : rgb24 = 24'h99CCFF;
            8'h94 : rgb24 = 24'h99FF00;
            8'h95 : rgb24 = 24'h99FF33;
            8'h96 : rgb24 = 24'h99FF66;
            8'h97 : rgb24 = 24'h99FF99;
            8'h98 : rgb24 = 24'h99FFCC;
            8'h99 : rgb24 = 24'h99FFFF;
            8'h9A : rgb24 = 24'hCC0000;
            8'h9B : rgb24 = 24'hCC0033;
            8'h9C : rgb24 = 24'hCC0066;
            8'h9D : rgb24 = 24'hCC0099;
            8'h9E : rgb24 = 24'hCC00CC;
            8'h9F : rgb24 = 24'hCC00FF;
            8'hA0 : rgb24 = 24'hCC3300;
            8'hA1 : rgb24 = 24'hCC3333;
            8'hA2 : rgb24 = 24'hCC3366;
            8'hA3 : rgb24 = 24'hCC3399;
            8'hA4 : rgb24 = 24'hCC33CC;
            8'hA5 : rgb24 = 24'hCC33FF;
            8'hA6 : rgb24 = 24'hCC6600;
            8'hA7 : rgb24 = 24'hCC6633;
            8'hA8 : rgb24 = 24'hCC6666;
            8'hA9 : rgb24 = 24'hCC6699;
            8'hAA : rgb24 = 24'hCC66CC;
            8'hAB : rgb24 = 24'hCC66FF;
            8'hAC : rgb24 = 24'hCC9900;
            8'hAD : rgb24 = 24'hCC9933;
            8'hAE : rgb24 = 24'hCC9966;
            8'hAF : rgb24 = 24'hCC9999;
            8'hB0 : rgb24 = 24'hCC99CC;
            8'hB1 : rgb24 = 24'hCC99FF;
            8'hB2 : rgb24 = 24'hCCCC00;
            8'hB3 : rgb24 = 24'hCCCC33;
            8'hB4 : rgb24 = 24'hCCCC66;
            8'hB5 : rgb24 = 24'hCCCC99;
            8'hB6 : rgb24 = 24'hCCCCCC;
            8'hB7 : rgb24 = 24'hCCCCFF;
            8'hB8 : rgb24 = 24'hCCFF00;
            8'hB9 : rgb24 = 24'hCCFF33;
            8'hBA : rgb24 = 24'hCCFF66;
            8'hBB : rgb24 = 24'hCCFF99;
            8'hBC : rgb24 = 24'hCCFFCC;
            8'hBD : rgb24 = 24'hCCFFFF;
            8'hBE : rgb24 = 24'hFF0000;
            8'hBF : rgb24 = 24'hFF0033;
            8'hC0 : rgb24 = 24'hFF0066;
            8'hC1 : rgb24 = 24'hFF0099;
            8'hC2 : rgb24 = 24'hFF00CC;
            8'hC3 : rgb24 = 24'hFF00FF;
            8'hC4 : rgb24 = 24'hFF3300;
            8'hC5 : rgb24 = 24'hFF3333;
            8'hC6 : rgb24 = 24'hFF3366;
            8'hC7 : rgb24 = 24'hFF3399;
            8'hC8 : rgb24 = 24'hFF33CC;
            8'hC9 : rgb24 = 24'hFF33FF;
            8'hCA : rgb24 = 24'hFF6600;
            8'hCB : rgb24 = 24'hFF6633;
            8'hCC : rgb24 = 24'hFF6666;
            8'hCD : rgb24 = 24'hFF6699;
            8'hCE : rgb24 = 24'hFF66CC;
            8'hCF : rgb24 = 24'hFF66FF;
            8'hD0 : rgb24 = 24'hFF9900;
            8'hD1 : rgb24 = 24'hFF9933;
            8'hD2 : rgb24 = 24'hFF9966;
            8'hD3 : rgb24 = 24'hFF9999;
            8'hD4 : rgb24 = 24'hFF99CC;
            8'hD5 : rgb24 = 24'hFF99FF;
            8'hD6 : rgb24 = 24'hFFCC00;
            8'hD7 : rgb24 = 24'hFFCC33;
            8'hD8 : rgb24 = 24'hFFCC66;
            8'hD9 : rgb24 = 24'hFFCC99;
            8'hDA : rgb24 = 24'hFFCCCC;
            8'hDB : rgb24 = 24'hFFCCFF;
            8'hDC : rgb24 = 24'hFFFF00;
            8'hDD : rgb24 = 24'hFFFF33;
            8'hDE : rgb24 = 24'hFFFF66;
            8'hDF : rgb24 = 24'hFFFF99;
            8'hE0 : rgb24 = 24'hFFFFCC;
            8'hE1 : rgb24 = 24'hFFFFFF;
            8'hE2 : rgb24 = 24'h080808;
            8'hE3 : rgb24 = 24'h101010;
            8'hE4 : rgb24 = 24'h181818;
            8'hE5 : rgb24 = 24'h202020;
            8'hE6 : rgb24 = 24'h282828;
            8'hE7 : rgb24 = 24'h303030;
            8'hE8 : rgb24 = 24'h383838;
            8'hE9 : rgb24 = 24'h404040;
            8'hEA : rgb24 = 24'h484848;
            8'hEB : rgb24 = 24'h505050;
            8'hEC : rgb24 = 24'h585858;
            8'hED : rgb24 = 24'h606060;
            8'hEE : rgb24 = 24'h686868;
            8'hEF : rgb24 = 24'h707070;
            8'hF0 : rgb24 = 24'h787878;
            8'hF1 : rgb24 = 24'h828282;
            8'hF2 : rgb24 = 24'h8A8A8A;
            8'hF3 : rgb24 = 24'h929292;
            8'hF4 : rgb24 = 24'h9A9A9A;
            8'hF5 : rgb24 = 24'hA2A2A2;
            8'hF6 : rgb24 = 24'hFFFBF0;
            8'hF7 : rgb24 = 24'hA0A0A4;
            8'hF8 : rgb24 = 24'h808080;
            8'hF9 : rgb24 = 24'hFF0000;
            8'hFA : rgb24 = 24'h00FF00;
            8'hFB : rgb24 = 24'hFFFF00;
            8'hFC : rgb24 = 24'h0000FF;
            8'hFD : rgb24 = 24'hFF00FF;
            8'hFE : rgb24 = 24'h00FFFF;
            8'hFF : rgb24 = 24'hFFFFFF;
            default : rgb24 = 24'h000000;
        endcase
    end

    // Continous Assignments
    assign                                  r                                       = rgb24[23:16];
    assign                                  g                                       = rgb24[15:8];
    assign                                  b                                       = rgb24[7:0];

endmodule