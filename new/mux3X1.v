`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 05:19:09 PM
// Design Name: 
// Module Name: mux3X1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mux3X1(
    input [31:0] a,b,c,
    input [1:0] sel,
    output [31:0] data_out
);

assign data_out = (sel == 2'b00) ? a : (sel == 2'b01) ? b : (sel == 2'b10) ? c : 32'd0;

endmodule
