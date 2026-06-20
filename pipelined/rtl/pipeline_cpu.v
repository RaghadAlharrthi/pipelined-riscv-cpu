// pipeline_cpu.v — 5-stage RV32I: forwarding + loads/stores + load-use stall
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
    wire [31:0] pc_next = pc + 32'd4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      pc <= 32'd0;
        else if (stall)  pc <= pc;           // STALL: freeze PC
        else             pc <= pc_next;
    end
    assign pc_out = pc;

    reg [31:0] imem [0:15];
    initial begin
        // test program WITH a load-use hazard:
        imem[0] = 32'b000000000000_00000_010_00001_0000011; // lw  x1, 0(x0)   x1=mem[0]=100
        imem[1] = 32'b0000000_00001_00001_000_00010_0110011; // add x2, x1, x1  uses x1 RIGHT AFTER load!
        imem[2] = 32'b000000000101_00000_000_00011_0010011; // addi x3,x0,5
        imem[3] = 32'b0000000_00011_00010_000_00100_0110011; // add x4,x2,x3
        imem[4] = 32'd0;
    end
    wire [31:0] if_instr = imem[pc[31:2]];

    // ---- IF/ID register (can stall) ----
    reg [31:0] ID_pc, ID_instr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      begin ID_pc <= 0; ID_instr <= 32'h00000013; end
        else if (stall)  begin ID_pc <= ID_pc; ID_instr <= ID_instr; end // STALL: hold
        else             begin ID_pc <= pc; ID_instr <= if_instr; end
    end

    // ============ STAGE 2: ID ============
    wire [6:0] id_opcode = ID_instr[6:0];
    wire [4:0] id_rs1 = ID_instr[19:15];
    wire [4:0] id_rs2 = ID_instr[24:20];
    wire [4:0] id_rd  = ID_instr[11:7];
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
    wire [3:0] id_alu_op = (id_opcode == 7'b0110011 && id_funct7_5) ? 4'd1 : 4'd0;

    // ---- hazard detection (load-use) ----
    hazard u_hz (.ex_mem_read(EX_mem_read), .ex_rd(EX_rd),
        .id_rs1(id_rs1), .id_rs2(id_rs2), .stall(stall));

    // when stalling, insert a bubble: zero out the control signals into EX
    wire bubble = stall;

    // ---- ID/EX register ----
    reg [31:0] EX_rs1_data, EX_rs2_data, EX_imm;
    reg [4:0]  EX_rd, EX_rs1, EX_rs2;
    reg [3:0]  EX_alu_op;
    reg        EX_reg_write, EX_alu_src, EX_mem_read, EX_mem_write;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            EX_reg_write<=0; EX_rd<=0; EX_alu_op<=0; EX_alu_src<=0;
            EX_rs1_data<=0; EX_rs2_data<=0; EX_imm<=0; EX_rs1<=0; EX_rs2<=0;
            EX_mem_read<=0; EX_mem_write<=0;
        end else begin
            EX_rs1_data  <= id_rs1_data;
            EX_rs2_data  <= id_rs2_data;
            EX_imm       <= id_imm;
            EX_rd        <= id_rd;
            EX_rs1       <= id_rs1;
            EX_rs2       <= id_rs2;
            EX_alu_op    <= id_alu_op;
            EX_alu_src   <= id_alu_src;
            // control signals: zeroed when bubble (stall) inserted
            EX_reg_write <= bubble ? 1'b0 : id_reg_write;
            EX_mem_read  <= bubble ? 1'b0 : id_mem_read;
            EX_mem_write <= bubble ? 1'b0 : id_mem_write;
        end
    end

    // ============ STAGE 3: EX (forwarding) ============
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
    // load -> use memory data; otherwise -> use ALU result
    assign wb_data_out = WB_mem_read ? WB_mem_data : WB_alu_result;
    assign wb_rd_out   = WB_rd;
    assign wb_we_out   = WB_reg_write;
endmodule
