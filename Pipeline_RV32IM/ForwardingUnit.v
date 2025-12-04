`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 11:00:15 AM
// Design Name: 
// Module Name: ForwardingUnit
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


module ForwardingUnit(
    input rst, RegWrite_M, RegWrite_W,
    input [4:0] Rd_M, Rd_W, Rs1_E, Rs2_E,
    output [1:0] ForwardA, ForwardB
);

    // ?u tiên EX tr??c MEM:
    // 10 = l?y t? EX/MEM
    // 01 = l?y t? MEM/WB

    assign ForwardA = (rst) ? 2'b00 :
                      ((RegWrite_M) & (Rd_M != 0) &(Rd_M == Rs1_E)) ? 2'b10 :
                      ((RegWrite_W) & (Rd_W != 0) &(Rd_W == Rs1_E)) ? 2'b01 :
                      2'b00;

    assign ForwardB = (rst) ? 2'b00 :
                      ((RegWrite_M) & (Rd_M != 0) &(Rd_M == Rs2_E)) ? 2'b10 :
                      ((RegWrite_W) & (Rd_W != 0) &(Rd_W == Rs2_E)) ? 2'b01 :
                      2'b00;

endmodule

