`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 08:44:04 AM
// Design Name: 
// Module Name: HazardDetectionUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// revision:
// revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HazardDetectionUnit(
    input rst, 
    input MemRead_E,
    input PCSrc, div_stall, div_overlap,              
    input [4:0] rd_E,              
    input [4:0] rs1_D, rs2_D,      
    output reg ID_Flush,        
    output reg IF_Write            
);

always @(*) begin
    if (rst) begin
        IF_Write     <= 1'b1;
        ID_Flush    <= 1'b0;
    end 
    
    else if (MemRead_E &&
                ((rd_E == rs1_D) || (rd_E == rs2_D)) &&
                (rd_E != 5'd0)) begin       // Load Harzard
            // Stall 1 cycle
            IF_Write     <= 1'b0;  
            ID_Flush    <= 1'b1;  
        end else if (PCSrc) begin   // Branch instruction
            ID_Flush     <= 1'b1; 
            IF_Write     <= 1'b0;
        end else if (div_stall && !div_overlap) begin   // div stall
            IF_Write    <= 1'b0;
            ID_Flush    <= 1'b1;
        end else begin
            // No hazard
            IF_Write     <= 1'b1;
            ID_Flush    <= 1'b0;
        end
    end
endmodule
