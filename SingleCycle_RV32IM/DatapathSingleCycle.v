`timescale 1ns / 1ns

`include "defines.vh"
module DatapathSingleCycle (
    input                    clk,
    input                    rst,
    output reg               halt,
    output     [`REG_SIZE:0] pc_to_imem,
    input      [`REG_SIZE:0] inst_from_imem,
    // addr_to_dmem is a read-write port
    output reg [`REG_SIZE:0] addr_to_dmem,
    input      [`REG_SIZE:0] load_data_from_dmem,
    output reg [`REG_SIZE:0] store_data_to_dmem,
    output reg [        3:0] store_we_to_dmem
);

  // components of the instruction
  wire [           6:0] inst_funct7;
  wire [           4:0] inst_rs2;
  wire [           4:0] inst_rs1;
  wire [           2:0] inst_funct3;
  wire [           4:0] inst_rd;
  wire [`OPCODE_SIZE:0] inst_opcode;

  // split R-type instruction - see section 2.2 of RiscV spec
  assign {inst_funct7, inst_rs2, inst_rs1, inst_funct3, inst_rd, inst_opcode} = inst_from_imem;

  // setup for I, S, B & J type instructions
  // I - short immediates and loads
  wire [11:0] imm_i;
  assign imm_i = inst_from_imem[31:20];
  wire [ 4:0] imm_shamt = inst_from_imem[24:20];

  // S - stores
  wire [11:0] imm_s;
  assign imm_s = {inst_funct7, inst_rd};

  // B - conditionals
  wire [12:0] imm_b;
  assign {imm_b[12], imm_b[10:1], imm_b[11], imm_b[0]} = {inst_funct7, inst_rd, 1'b0};

  // J - unconditional jumps
  wire [20:0] imm_j;
  assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {inst_from_imem[31:12], 1'b0};
  
  
  wire [`REG_SIZE:0] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
  wire [`REG_SIZE:0] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
  wire [`REG_SIZE:0] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
  wire [`REG_SIZE:0] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};   
  wire [`REG_SIZE:0] imm_u_sext = {inst_from_imem[31:12], 12'b0};

  // opcodes - see section 19 of RiscV spec
  localparam [`OPCODE_SIZE:0] OpLoad    = 7'b00_000_11;
  localparam [`OPCODE_SIZE:0] OpStore   = 7'b01_000_11;
  localparam [`OPCODE_SIZE:0] OpBranch  = 7'b11_000_11;
  localparam [`OPCODE_SIZE:0] OpJalr    = 7'b11_001_11;
  localparam [`OPCODE_SIZE:0] OpMiscMem = 7'b00_011_11;
  localparam [`OPCODE_SIZE:0] OpJal     = 7'b11_011_11;

  localparam [`OPCODE_SIZE:0] OpRegImm  = 7'b00_100_11;
  localparam [`OPCODE_SIZE:0] OpRegReg  = 7'b01_100_11;
  localparam [`OPCODE_SIZE:0] OpEnviron = 7'b11_100_11;

  localparam [`OPCODE_SIZE:0] OpAuipc   = 7'b00_101_11;
  localparam [`OPCODE_SIZE:0] OpLui     = 7'b01_101_11;

  wire inst_lui    = (inst_opcode == OpLui    );
  wire inst_auipc  = (inst_opcode == OpAuipc  );
  wire inst_jal    = (inst_opcode == OpJal    );
  wire inst_jalr   = (inst_opcode == OpJalr   );

  wire inst_beq    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_bne    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_blt    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_bge    = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b101);
  wire inst_bltu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_bgeu   = (inst_opcode == OpBranch ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_lb     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_lh     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_lw     = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_lbu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_lhu    = (inst_opcode == OpLoad   ) & (inst_from_imem[14:12] == 3'b101);

  wire inst_sb     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_sh     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b001);
  wire inst_sw     = (inst_opcode == OpStore  ) & (inst_from_imem[14:12] == 3'b010);

  wire inst_addi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b000);
  wire inst_slti   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b010);
  wire inst_sltiu  = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b011);
  wire inst_xori   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b100);
  wire inst_ori    = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b110);
  wire inst_andi   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b111);

  wire inst_slli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srli   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srai   = (inst_opcode == OpRegImm ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);

  wire inst_add    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sub    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b000) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_sll    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b001) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_slt    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b010) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sltu   = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b011) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_xor    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b100) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_srl    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_sra    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b101) & (inst_from_imem[31:25] == 7'b0100000);
  wire inst_or     = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b110) & (inst_from_imem[31:25] == 7'd0      );
  wire inst_and    = (inst_opcode == OpRegReg ) & (inst_from_imem[14:12] == 3'b111) & (inst_from_imem[31:25] == 7'd0      );

  wire inst_mul    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b000    );
  wire inst_mulh   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b001    );
  wire inst_mulhsu = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b010    );
  wire inst_mulhu  = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b011    );
  wire inst_div    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b100    );
  wire inst_divu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b101    );
  wire inst_rem    = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b110    );
  wire inst_remu   = (inst_opcode == OpRegReg ) & (inst_from_imem[31:25] == 7'd1  ) & (inst_from_imem[14:12] == 3'b111    );

  wire inst_ecall  = (inst_opcode == OpEnviron) & (inst_from_imem[31:7] == 25'd0  );
  wire inst_fence  = (inst_opcode == OpMiscMem);

  // program counter
  reg [`REG_SIZE:0] pcNext, pcCurrent;
  always @(posedge clk) begin
    if (rst) begin
      pcCurrent <= 32'd0;
    end else begin
      pcCurrent <= pcNext;
    end
  end
  assign pc_to_imem = pcCurrent;

  // cycle/inst._from_imem counters
  reg [`REG_SIZE:0] cycles_current, num_inst_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
      num_inst_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
      if (!rst) begin
        num_inst_current <= num_inst_current + 1;
      end
    end
  end

  // NOTE: don't rename your RegFile instance as the tests expect it to be `rf`
  // TODO: you will need to edit the port connections, however.
  wire [`REG_SIZE:0] rs1_data, rs2_data;
  wire [`REG_SIZE:0] ALUResult;
  wire ZeroFlag, LessThan, LessThanU;
  reg [`REG_SIZE:0] ALUOp1, ALUOp2;
  reg [`REG_SIZE:0] rd_data;
  reg MemToReg, MemWrite, RegWrite;
  reg [5:0] ALUCtrl;
    
  // RegFile
  RegFile rf (
    .clk      (clk),
    .rst      (rst),
    .we       (RegWrite),
    .rd       (inst_rd),
    .rd_data  (rd_data),
    .rs1      (inst_rs1),
    .rs2      (inst_rs2),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
  );
  
  // ALU
  ALU alu (
    .A(ALUOp1),
    .B(ALUOp2),
    .ALUCtrl(ALUCtrl),
    .ALUResult(ALUResult),
    .Zero(ZeroFlag),
    .LessThan(LessThan),
    .LessThanU(LessThanU)
  );
  
  reg [7:0]  load_byte;
  reg [15:0] load_half;
  // Data Memory Interface (replace previous block)
  always @(*) begin
    rd_data              <= ALUResult;                
    addr_to_dmem         <= ALUResult;
    store_we_to_dmem     <= 4'b0000;
    store_data_to_dmem   <= rs2_data;

    if (MemWrite) begin
      if (inst_sb) store_we_to_dmem <= 4'b0001;      // SB - least-significant byte
      else if (inst_sh) store_we_to_dmem <= 4'b0011; // SH - two low bytes
      else if (inst_sw) store_we_to_dmem <= 4'b1111; // SW - full word
      else store_we_to_dmem <= 4'b0000;
    end

    if (MemToReg) begin
      load_byte = load_data_from_dmem[7:0];
      load_half = load_data_from_dmem[15:0];

      if      (inst_lb)  rd_data <= {{24{load_byte[7]}},  load_byte};  
      else if (inst_lbu) rd_data <= {24'd0,               load_byte};  
      else if (inst_lh)  rd_data <= {{16{load_half[15]}}, load_half};  
      else if (inst_lhu) rd_data <= {16'd0,               load_half};  
      else if (inst_lw)  rd_data <= load_data_from_dmem;              
      else               rd_data <= ALUResult;                       
    end
  end

 
  reg illegal_inst;
  
  // Control Unit
  always @(*) begin
  illegal_inst  <= 1'b0;
  halt          <= 1'b0;
  pcNext        <= pcCurrent + 32'd4;
  ALUOp1        <= 32'd0;
  ALUOp2        <= 32'd0;
  ALUCtrl       <= `ALU_ADD;
  MemWrite      <= 1'b0;
  RegWrite      <= 1'b0;
  MemToReg      <= 1'b0;

  case (inst_opcode)
    // R-type (OpRegReg)
    OpRegReg: begin
      ALUOp1   <= rs1_data;
      ALUOp2   <= rs2_data;
      RegWrite <= 1'b1;
      if      (inst_add)    ALUCtrl <= `ALU_ADD;
      else if (inst_sub)    ALUCtrl <= `ALU_SUB;
      else if (inst_sll)    ALUCtrl <= `ALU_LSHIFT_LEFT;
      else if (inst_slt)    ALUCtrl <= `ALU_SLT;    
      else if (inst_sltu)   ALUCtrl <= `ALU_SLTU;   
      else if (inst_xor)    ALUCtrl <= `ALU_XOR;
      else if (inst_srl)    ALUCtrl <= `ALU_LSHIFT_RIGHT;
      else if (inst_sra)    ALUCtrl <= `ALU_ASHIFT_RIGHT;
      else if (inst_or)     ALUCtrl <= `ALU_OR;
      else if (inst_and)    ALUCtrl <= `ALU_AND;
      else if (inst_mul)    ALUCtrl <= `ALU_MUL;
      else if (inst_mulh)   ALUCtrl <= `ALU_MULH;
      else if (inst_mulhsu) ALUCtrl <= `ALU_MULSU;
      else if (inst_mulhu)  ALUCtrl <= `ALU_MULU;
      else if (inst_div)    ALUCtrl <= `ALU_DIV;
      else if (inst_divu)   ALUCtrl <= `ALU_DIVU;
      else if (inst_rem)    ALUCtrl <= `ALU_REM;
      else if (inst_remu)   ALUCtrl <= `ALU_REMU;
      
      else illegal_inst <= 1'b1;
    end

    // I-type arithmetic
    OpRegImm: begin
      ALUOp1   <= rs1_data;
      ALUOp2   <= imm_i_sext;
      RegWrite <= 1'b1;
      if      (inst_addi)  ALUCtrl <= `ALU_ADD  ;
      else if (inst_slti)  ALUCtrl <= `ALU_SLT  ;
      else if (inst_sltiu) ALUCtrl <= `ALU_SLTU ;
      else if (inst_xori)  ALUCtrl <= `ALU_XOR  ;
      else if (inst_ori)   ALUCtrl <= `ALU_OR   ;
      else if (inst_andi)  ALUCtrl <= `ALU_AND  ;
      else if (inst_slli)  ALUCtrl <= `ALU_LSHIFT_LEFT  ;
      else if (inst_srli)  ALUCtrl <= `ALU_LSHIFT_RIGHT ;
      else if (inst_srai)  ALUCtrl <= `ALU_ASHIFT_RIGHT ;
      else illegal_inst <= 1'b1;
    end

    // Load
    OpLoad: begin
      ALUOp1   <= rs1_data;
      ALUOp2   <= imm_i_sext;
      ALUCtrl  <= `ALU_ADD;
      MemWrite <= 1'b0;
      RegWrite <= 1'b1;
      MemToReg <= 1'b1;
    end

    // Store
    OpStore: begin
      ALUOp1   <= rs1_data;
      ALUOp2   <= imm_s_sext;
      ALUCtrl  <= `ALU_ADD;
      MemWrite <= 1'b1;
      RegWrite <= 1'b0;
    end

    // Branch
    OpBranch: begin
      ALUOp1   <= rs1_data;
      ALUOp2   <= rs2_data;
      ALUCtrl  <= `ALU_SUB;    
      RegWrite <= 1'b0;
      MemWrite <= 1'b0;
  
      illegal_inst <= 1'b0;
  
      if (inst_beq) begin
          if (ZeroFlag) pcNext <= pcCurrent + imm_b_sext;
      end 
      else if (inst_bne) begin
          if (!ZeroFlag) pcNext <= pcCurrent + imm_b_sext;
      end
      else if (inst_blt) begin
          if (LessThan) pcNext <= pcCurrent + imm_b_sext;
      end
      else if (inst_bge) begin
          if (!LessThan) pcNext <= pcCurrent + imm_b_sext;
      end
      else if (inst_bltu) begin
          if (LessThanU) pcNext <= pcCurrent + imm_b_sext;
      end
      else if (inst_bgeu) begin
          if (!LessThanU) pcNext <= pcCurrent + imm_b_sext;
      end
      else begin
          illegal_inst <= 1'b1;
      end
    end

    // JAL
    OpJal: begin
      RegWrite <= 1'b1;
      ALUOp1   <= pcCurrent;
      ALUOp2   <= 32'd4;
      ALUCtrl  <= `ALU_ADD;             // rd = PC + 4
      pcNext   <= pcCurrent + imm_j_sext;
    end

    // JALR
    OpJalr: begin
      RegWrite <= 1'b1;
      ALUOp1   <= pcCurrent;
      ALUOp2   <= 32'd4;
      ALUCtrl  <= `ALU_ADD;             // rd = PC + 4
      pcNext   <= (rs1_data + imm_i_sext);
    end

    // LUI
    OpLui: begin
      RegWrite <= 1'b1;
      ALUOp1   <= 32'd0;
      ALUOp2   <= imm_u_sext;
      ALUCtrl  <= `ALU_ADD;             // rd = immU
    end        

    // AUIPC
    OpAuipc: begin
      RegWrite <= 1'b1;
      ALUOp1   <= pcCurrent;
      ALUOp2   <= imm_u_sext;
      ALUCtrl  <= `ALU_ADD;             // rd = PC + immU
    end        

    // ECALL
    OpEnviron: begin
      halt <= 1'b1;
    end

    default: begin
      illegal_inst <= 1'b1;
    end
  endcase
end


endmodule





