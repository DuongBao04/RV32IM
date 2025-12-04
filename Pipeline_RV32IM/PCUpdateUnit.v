`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2025 11:55:15 PM
// Design Name: 
// Module Name: PCUpdateUnit
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

`include "defines.vh"

module PCUpdateUnit(
    input  [`REG_SIZE:0] rs1_data_E,
    input  [`REG_SIZE:0] pc_current_E,
    input  [`REG_SIZE:0] immediate_E,

    input                Branch_E,
    input                Jal_E,
    input                Jalr_E,
    input  [2:0]         BranchType_E,

    input                Zero,
    input                LessThan,
    input                LessThanU,

    output reg [`REG_SIZE:0] PCTarget,
    output reg               PCSrc
);

    // ------------------------------
    // 1. Compute branch condition
    // ------------------------------
    reg BranchCond;
    always @(*) begin
        case (BranchType_E)
            `BEQ  : BranchCond =  Zero;
            `BNE  : BranchCond = ~Zero;
            `BLT  : BranchCond =  LessThan;
            `BGE  : BranchCond = ~LessThan;
            `BLTU : BranchCond =  LessThanU;
            `BGEU : BranchCond = ~LessThanU;
            default: BranchCond = 1'b0;
        endcase
    end

    always @(*) begin
        PCSrc <= 1'b0;
        if (Jal_E || Jalr_E)
            PCSrc <= 1'b1;
        else if (Branch_E && BranchCond)
            PCSrc <= 1'b1;
        else
            PCSrc <= 1'b0;
    end


    always @(*) begin
        if (Jal_E) begin
            // JAL: PC + imm
            PCTarget <= pc_current_E + immediate_E;
        end else if (Jalr_E) begin
            // JALR: (rs1 + imm) & ~1
            PCTarget <= (rs1_data_E + immediate_E);
        end else if (Branch_E && BranchCond) begin
            // Branch: PC + imm
            PCTarget <= pc_current_E + immediate_E;
        end else begin
            // No branch: don't care, safe default
            PCTarget <= pc_current_E + 4;
        end
    end

endmodule
