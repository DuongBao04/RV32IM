`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 05:30:53 PM
// Design Name: 
// Module Name: ID_Stage
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

module ID_Stage(
    input clk, rst,
    input [`REG_SIZE:0] f_inst,
    input [`REG_SIZE:0] f_pc_current,
    input ID_Flush,
    
    // From WB
    input [4:0] rd_W,
    input RegWrite_W,
    input [`REG_SIZE:0] rd_data_W,
    
    output div_overlap,
    output reg is_div_op_E,
    output reg [`REG_SIZE:0] rs1_data_E, rs2_data_E, immediate_E,
    output reg [`REG_SIZE:0] pc_current_E, inst_E,
    output reg [4:0] ALUCtrl_E,
    output reg [4:0] rd_E, rs1_E, rs2_E,
    output reg RegWrite_E, ALUSrc_E, MemWrite_E, MemToReg_E, MemRead_E, Branch_E, halt_E,
    output reg Jal_E, Jalr_E,
    output reg [2:0] BranchType_E, StoreType_E, LoadType_E
);

wire is_div_op;
wire [`REG_SIZE:0] rs1_data, rs2_data, immediate;
wire [4:0] ALUCtrl;
wire RegWrite, ALUSrc, MemWrite, MemToReg, MemRead, Branch, halt;
wire Jal, Jalr, Auipc, Lui;
wire [2:0] BranchType, StoreType, LoadType;

wire [4:0] rs1 = f_inst[19:15];
wire [4:0] rs2 = f_inst[24:20];
wire [4:0] rd  = f_inst[11:7];
wire illegal_inst;

assign div_overlap = (is_div_op_E == is_div_op) && (is_div_op_E == 1) && (is_div_op == 1) &&
                    (rd_E != rs1) && (rd_E != rs2);
reg [3:0] stall_counter;

// ========================= RegFile =========================
RegFile rf (
    .clk(clk), .rst(rst),
    .rd(rd_W),
    .rd_data(rd_data_W),
    .rs1(rs1),
    .rs1_data(rs1_data),
    .rs2(rs2),
    .rs2_data(rs2_data),
    .we(RegWrite_W)
);

// ========================= Control =========================
ControlUnit cu (
    .inst_opcode(f_inst[6:0]),
    .inst_funct3(f_inst[14:12]),
    .inst_funct7(f_inst[31:25]),
    
    .is_div_op(is_div_op),
    .RegWrite(RegWrite),
    .ALUCtrl(ALUCtrl),
    .ALUSrc(ALUSrc),
    .MemWrite(MemWrite),
    .MemToReg(MemToReg),
    .MemRead(MemRead),
    .Branch(Branch),
    .halt(halt),
    .BranchType(BranchType),
    .StoreType(StoreType),
    .LoadType(LoadType),
    .Jal(Jal),
    .Jalr(Jalr),
    .Auipc(Auipc),
    .Lui(Lui),
    .illegal_inst(illegal_inst)
);

// ========================= Immediate =========================
ImmGen ig (
    .inst_from_imem(f_inst),
    .imm_out(immediate)
);

// ============================================================
//     Pipeline Registers + WD Bypass
// ============================================================
always @(posedge clk or posedge rst) begin
    if (rst || ID_Flush || illegal_inst) begin
        pc_current_E    <= 0;
        inst_E          <= 0;
        rd_E            <= 0;
        rs1_E           <= 0;
        rs2_E           <= 0;
        
        is_div_op_E     <= 0;

        RegWrite_E      <= 0;
        ALUSrc_E        <= 0;
        MemWrite_E      <= 0;
        MemToReg_E      <= 0;
        MemRead_E       <= 0;
        Branch_E        <= 0;
        halt_E          <= 0;
        BranchType_E    <= 0;
        StoreType_E     <= 0;
        LoadType_E      <= 0;

        rs1_data_E      <= 0;
        rs2_data_E      <= 0;
        ALUCtrl_E       <= 0;
        immediate_E     <= 0;
        Jal_E           <= 0;
        Jalr_E          <= 0;
    end else begin
        pc_current_E <= f_pc_current;
        inst_E       <= f_inst;

        rd_E  <= rd;
        rs1_E <= rs1;
        rs2_E <= rs2;
        
        is_div_op_E  <= is_div_op;

        RegWrite_E   <= RegWrite;
        ALUSrc_E     <= ALUSrc;
        MemWrite_E   <= MemWrite;
        MemToReg_E   <= MemToReg;
        MemRead_E    <= MemRead;
        Branch_E     <= Branch;
        halt_E       <= halt;
        BranchType_E <= BranchType;
        StoreType_E  <= StoreType;
        LoadType_E   <= LoadType;
        ALUCtrl_E    <= ALUCtrl;
        immediate_E  <= immediate;
        Jal_E        <= Jal;
        Jalr_E       <= Jalr;
        // =====================================================
        //               Bypass 
        // =====================================================
        rs1_data_E <= rs1_data;
        rs2_data_E <= rs2_data;
        
        // WB Bypass for rs1
        if (RegWrite_W && rd_W != 0 && rd_W == rs1)
            rs1_data_E <= rd_data_W;

        // WB Bypass for rs2
        if (RegWrite_W && rd_W != 0 && rd_W == rs2)
            rs2_data_E <= rd_data_W;
        
        if (Jalr) begin
            rs1_data_E <= rs1_data;
        end

        // Special cases (override)
        if (Lui)
            rs1_data_E <= 32'b0;

        if (Auipc)
            rs1_data_E <= f_pc_current;
    end
end

endmodule

