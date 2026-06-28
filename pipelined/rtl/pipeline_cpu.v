// pipeline_cpu.v — 5-stage RV32I (subset): forwarding + load-use stall + branches
//   Now supports: R-type (add/sub/and/or/xor/slt/sll/srl), I-ALU (addi etc.),
//   lw, sw, and beq/bne (branch resolved in EX with a 2-instruction flush).
module pipeline_cpu (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] pc_out,
    output wire [31:0] wb_data_out,
    output wire [4:0]  wb_rd_out,
    output wire        wb_we_out
);
    // ============ STAGE 1: IF ============
    reg [31:0] pc;
    wire stall;                              // from hazard unit
    wire branch_taken;                       // from EX (resolved branch)
    wire [31:0] branch_target;               // from EX
    wire [31:0] pc_plus4 = pc + 32'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            pc <= 32'd0;
        else if (branch_taken) pc <= branch_target; // redirect wins over stall
        else if (stall)        pc <= pc;            // STALL: freeze PC
        else                   pc <= pc_plus4;
    end
    assign pc_out = pc;

    reg [31:0] imem [0:31];
    integer k;
    initial begin
        for (k = 0; k < 32; k = k + 1) imem[k] = 32'h00000013; // NOP fill
        // demo program: ALU ops + a TAKEN beq that skips one instruction
        imem[0] = 32'h00500093; // addi x1, x0, 5
        imem[1] = 32'h00300113; // addi x2, x0, 3
        imem[2] = 32'h00700393; // addi x7, x0, 7    (x7 = 7, a KNOWN value)
        imem[3] = 32'h0020F1B3; // and  x3, x1, x2   = 1
        imem[4] = 32'h0020E233; // or   x4, x1, x2   = 7
        imem[5] = 32'h0020C2B3; // xor  x5, x1, x2   = 6
        imem[6] = 32'h0020A333; // slt  x6, x1, x2   = 0
        imem[7] = 32'h00000463; // beq  x0, x0, +8   -> skip imem[8]
        imem[8] = 32'h06300393; // addi x7, x0, 99   (FLUSHED: x7 must stay 7)
        imem[9] = 32'h02A00413; // addi x8, x0, 42
    end
    wire [31:0] if_instr = imem[pc[31:2]];

    // ---- IF/ID register (can stall / flush) ----
    reg [31:0] ID_pc, ID_instr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            begin ID_pc <= 0; ID_instr <= 32'h00000013; end
        else if (branch_taken) begin ID_pc <= 0; ID_instr <= 32'h00000013; end // FLUSH
        else if (stall)        begin ID_pc <= ID_pc; ID_instr <= ID_instr; end // HOLD
        else                   begin ID_pc <= pc; ID_instr <= if_instr; end
    end

    // ============ STAGE 2: ID ============
    wire [6:0] id_opcode = ID_instr[6:0];
    wire [4:0] id_rs1 = ID_instr[19:15];
    wire [4:0] id_rs2 = ID_instr[24:20];
    wire [4:0] id_rd  = ID_instr[11:7];
    wire [2:0] id_funct3   = ID_instr[14:12];
    wire       id_funct7_5 = ID_instr[30];

    wire id_reg_write, id_alu_src, id_mem_read, id_mem_write, id_branch;
    wire [1:0] id_imm_type;
    control u_ctrl (.opcode(id_opcode), .reg_write(id_reg_write),
        .alu_src(id_alu_src), .mem_read(id_mem_read),
        .mem_write(id_mem_write), .branch(id_branch), .imm_type(id_imm_type));

    wire [31:0] id_rs1_data, id_rs2_data;
    regfile u_rf (.clk(clk), .we(wb_we_out),
        .ra1(id_rs1), .ra2(id_rs2), .wa(wb_rd_out), .wd(wb_data_out),
        .rd1(id_rs1_data), .rd2(id_rs2_data));

    wire [31:0] id_imm;
    immgen u_imm (.instr(ID_instr), .imm_type({1'b0, id_imm_type}), .imm(id_imm));

    // full ALU-op decode (replaces the old add/sub-only line)
    wire [3:0] id_alu_op;
    alu_control u_aluctrl (.opcode(id_opcode), .funct3(id_funct3),
        .funct7_5(id_funct7_5), .alu_op(id_alu_op));

    // ---- hazard detection (load-use) ----
    hazard u_hz (.ex_mem_read(EX_mem_read), .ex_rd(EX_rd),
        .id_rs1(id_rs1), .id_rs2(id_rs2), .stall(stall));

    // bubble on stall OR on a taken-branch flush (kills the instr entering EX)
    wire bubble = stall | branch_taken;

    // ---- ID/EX register ----
    reg [31:0] EX_rs1_data, EX_rs2_data, EX_imm, EX_pc;
    reg [4:0]  EX_rd, EX_rs1, EX_rs2;
    reg [3:0]  EX_alu_op;
    reg [2:0]  EX_funct3;
    reg        EX_reg_write, EX_alu_src, EX_mem_read, EX_mem_write, EX_branch;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            EX_reg_write<=0; EX_rd<=0; EX_alu_op<=0; EX_alu_src<=0;
            EX_rs1_data<=0; EX_rs2_data<=0; EX_imm<=0; EX_rs1<=0; EX_rs2<=0;
            EX_mem_read<=0; EX_mem_write<=0; EX_branch<=0; EX_pc<=0; EX_funct3<=0;
        end else begin
            EX_rs1_data  <= id_rs1_data;
            EX_rs2_data  <= id_rs2_data;
            EX_imm       <= id_imm;
            EX_pc        <= ID_pc;
            EX_rd        <= id_rd;
            EX_rs1       <= id_rs1;
            EX_rs2       <= id_rs2;
            EX_alu_op    <= id_alu_op;
            EX_alu_src   <= id_alu_src;
            EX_funct3    <= id_funct3;
            // control signals: zeroed when bubble (stall or flush) inserted
            EX_reg_write <= bubble ? 1'b0 : id_reg_write;
            EX_mem_read  <= bubble ? 1'b0 : id_mem_read;
            EX_mem_write <= bubble ? 1'b0 : id_mem_write;
            EX_branch    <= bubble ? 1'b0 : id_branch;
        end
    end

    // ============ STAGE 3: EX (forwarding + branch resolve) ============
    wire [1:0] forward_a, forward_b;
    forwarding u_fwd (.ex_rs1(EX_rs1), .ex_rs2(EX_rs2),
        .mem_rd(MEM_rd), .mem_reg_write(MEM_reg_write),
        .wb_rd(WB_rd), .wb_reg_write(WB_reg_write),
        .forward_a(forward_a), .forward_b(forward_b));

    wire [31:0] ex_a = (forward_a==2'b10) ? MEM_alu_result :
                       (forward_a==2'b01) ? wb_data_out    : EX_rs1_data;
    wire [31:0] ex_b_pre = (forward_b==2'b10) ? MEM_alu_result :
                           (forward_b==2'b01) ? wb_data_out    : EX_rs2_data;
    wire [31:0] ex_alu_b = EX_alu_src ? EX_imm : ex_b_pre;

    wire [31:0] ex_alu_result;
    wire        ex_zero;
    alu u_alu (.a(ex_a), .b(ex_alu_b), .alu_op(EX_alu_op),
        .result(ex_alu_result), .zero(ex_zero));

    // branch resolved here: beq (funct3=000) taken if equal; bne (001) if not equal
    wire ex_equal = (ex_a == ex_b_pre);
    assign branch_taken  = EX_branch &
        ((EX_funct3==3'b000 &  ex_equal) |
         (EX_funct3==3'b001 & ~ex_equal));
    assign branch_target = EX_pc + EX_imm;

    // ---- EX/MEM register ----
    reg [31:0] MEM_alu_result, MEM_write_data;
    reg [4:0]  MEM_rd;
    reg        MEM_reg_write, MEM_mem_read, MEM_mem_write;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            MEM_reg_write<=0; MEM_rd<=0; MEM_alu_result<=0;
            MEM_mem_read<=0; MEM_mem_write<=0; MEM_write_data<=0;
        end else begin
            MEM_alu_result <= ex_alu_result;
            MEM_write_data <= ex_b_pre;        // store data (forwarded)
            MEM_rd         <= EX_rd;
            MEM_reg_write  <= EX_reg_write;
            MEM_mem_read   <= EX_mem_read;
            MEM_mem_write  <= EX_mem_write;
        end
    end

    // ============ STAGE 4: MEM (data memory) ============
    wire [31:0] mem_read_data;
    dmem u_dmem (.clk(clk), .mem_read(MEM_mem_read), .mem_write(MEM_mem_write),
        .addr(MEM_alu_result), .write_data(MEM_write_data),
        .read_data(mem_read_data));

    // ---- MEM/WB register ----
    reg [31:0] WB_alu_result, WB_mem_data;
    reg [4:0]  WB_rd;
    reg        WB_reg_write, WB_mem_read;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            WB_reg_write<=0; WB_rd<=0; WB_alu_result<=0;
            WB_mem_data<=0; WB_mem_read<=0;
        end else begin
            WB_alu_result <= MEM_alu_result;
            WB_mem_data   <= mem_read_data;
            WB_rd         <= MEM_rd;
            WB_reg_write  <= MEM_reg_write;
            WB_mem_read   <= MEM_mem_read;
        end
    end

    // ============ STAGE 5: WB ============
    assign wb_data_out = WB_mem_read ? WB_mem_data : WB_alu_result;
    assign wb_rd_out   = WB_rd;
    assign wb_we_out   = WB_reg_write;
endmodule
