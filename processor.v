// File: processor.v
// This is a simple 8-bit processor implementation with a built-in testbench
// 4 basic operations: LOAD, STORE, ADD, and SUB

// Main processor module definition
module processor(
    input wire clk,          // Clock input
    input wire rst,          // Reset input
    output reg [7:0] result  // 8-bit output to show operation results
);

    // ========== Internal Storage Declarations ==========
    // Register file: 8 registers of 8 bits each (R0-R7)
    reg [7:0] registers [0:7];  
    
    // Memory: 8 locations of 8 bits each (addresses 0-7)
    reg [7:0] memory [0:7];     
    
    // Current instruction register
    reg [7:0] instruction;
    
    // Program counter: Points to current instruction (3 bits for 8 locations)
    reg [2:0] pc;               

    // ========== Instruction Decoding ==========
    // Breaking down the 8-bit instruction into fields:
    // [7:6] - opcode (2 bits)
    // [5:3] - register address (3 bits)
    // [2:0] - memory address (3 bits)
    wire [1:0] opcode;
    wire [2:0] reg_addr;
    wire [2:0] mem_addr;

    // Instruction field assignments
    assign opcode = instruction[7:6];    // Upper 2 bits are opcode
    assign reg_addr = instruction[5:3];  // Next 3 bits are register address
    assign mem_addr = instruction[2:0];  // Lower 3 bits are memory address

    // ========== Main Processor Operation ==========
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset operation: Clear all registers and memory
            pc <= 0;
            result <= 0;
            // Initialize all registers and memory locations to 0
            for (integer i = 0; i < 8; i = i + 1) begin
                registers[i] <= 0;
                memory[i] <= 0;
            end
        end else begin
            // Instruction execution based on opcode
            case (opcode)
                2'b00: begin // LOAD operation
                    // Load value from memory into register
                    // Format: LOAD reg_addr, [mem_addr]
                    registers[reg_addr] <= memory[mem_addr];
                    result <= memory[mem_addr];
                end
                
                2'b01: begin // STORE operation
                    // Store value from register into memory
                    // Format: STORE reg_addr, [mem_addr]
                    memory[mem_addr] <= registers[reg_addr];
                    result <= registers[reg_addr];
                end
                
                2'b10: begin // ADD operation
                    // Add value from specified register to destination register
                    // Format: ADD reg_addr, [mem_addr]
                    registers[reg_addr] <= registers[reg_addr] + registers[mem_addr];
                    result <= registers[reg_addr] + registers[mem_addr];
                end
                
                2'b11: begin // SUB operation
                    // Subtract value in specified register from destination register
                    // Format: SUB reg_addr, [mem_addr]
                    registers[reg_addr] <= registers[reg_addr] - registers[mem_addr];
                    result <= registers[reg_addr] - registers[mem_addr];
                end
            endcase
            // Increment program counter after each instruction
            pc <= pc + 1;
        end
    end

    // ========== Debug Output ==========
    // Only compiled when DEBUG is defined
    `ifdef DEBUG
    always @(posedge clk) begin
        $display("Time=%0t instruction=%b op=%b reg=%b mem=%b result=%h", 
                 $time, instruction, opcode, reg_addr, mem_addr, result);
    end
    `endif

endmodule

// ========== Testbench Module ==========
module processor_tb;
    // Testbench signals
    reg clk;                  // Clock signal
    reg rst;                  // Reset signal
    wire [7:0] result;       // Processor result output

    // Instantiate the processor unit under test
    processor uut (
        .clk(clk),
        .rst(rst),
        .result(result)
    );

    // Clock generation - 10ns period (5ns high, 5ns low)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Setup monitoring for key signals
    initial begin
        $monitor("Time=%0t rst=%b result=%h", $time, rst, result);
    end

    // Test sequence
    initial begin
        // Create waveform dump file for visualization
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);

        // Initial reset
        rst = 1;             // Assert reset
        #10 rst = 0;         // Deassert reset after 10 time units

        // ===== Test Sequence =====
        // Test 1: Load value 5A into R0
        uut.instruction = 8'b00_000_001;  // LOAD R0, mem[1]
        uut.memory[1] = 8'h5A;            // Set memory value
        #10;

        // Test 2: Load value 3C into R1
        uut.instruction = 8'b00_001_010;  // LOAD R1, mem[2]
        uut.memory[2] = 8'h3C;            // Set memory value
        #10;

        // Test 3: Add R0 to R2, then add R1 to R2
        uut.instruction = 8'b10_010_000;  // ADD R2, R0
        #10;
        uut.instruction = 8'b10_010_001;  // ADD R2, R1
        #10;

        // Test 4: Store R2's value to memory
        uut.instruction = 8'b01_010_011;  // STORE R2, mem[3]
        #10;

        // Test 5: Subtract R1 from R0, store in R3
        uut.instruction = 8'b11_011_001;  // SUB R3, R1
        #10;

        // Display final state
        $display("Final register values:");
        for (integer i = 0; i < 8; i = i + 1)
            $display("R%0d = %h", i, uut.registers[i]);

        $display("\nFinal memory values:");
        for (integer i = 0; i < 8; i = i + 1)
            $display("M%0d = %h", i, uut.memory[i]);

        // End simulation
        #10 $finish;
    end

endmodule