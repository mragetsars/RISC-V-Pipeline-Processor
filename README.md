# RISC-V Pipeline Processor Implementation

> **Computer Architecture - University of Tehran - Department of Electrical & Computer Engineering**

![Verilog](https://img.shields.io/badge/Language-Verilog-blue) ![Tool](https://img.shields.io/badge/Sim-ModelSim-green) ![Status](https://img.shields.io/badge/Status-Completed-success)

## 📌 Overview

This repository contains the Register Transfer Level (RTL) implementation of a  **5-Stage Pipelined RISC-V Processor** . This project was developed as the fourth assignment for the *Computer Architecture* course at the University of Tehran.

The processor is designed based on the RISC-V ISA, featuring a classic five-stage pipeline ( **Fetch, Decode, Execute, Memory, Write-back** ). It includes a dedicated **Hazard Unit** to handle data and control hazards, ensuring correct execution through forwarding and stalling mechanisms.

## 🏗️ Architecture

The design follows a modular approach, separating the concerns of data processing, control signaling, and hazard management.

### Datapath Design

The datapath manages the flow of data through the five pipeline stages. it includes the ALU, Register File, Program Counter (PC), and various pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB).
![Datapath Architecture](./Design/DataPath.png)

### Control Unit

The control unit consists of a **Main Decoder** and an  **ALU Decoder** . It generates the necessary control signals for each stage of the pipeline based on the instruction opcodes.

* **Main Decoder:** Manages overall control signals like `RegWrite`, `MemWrite`, etc.

  | Command Type | Command         | Opcode (7-bit) | RegWrite | ALUSrc | MemWrite | ResultSrc | ImmSrc | ALUOp | Jump | Branch |
  | ------------ | --------------- | -------------- | -------- | ------ | -------- | --------- | ------ | ----- | ---- | ------ |
  | R-Type       | add, sub, ...   | 110011         | 1        | 0      | 0        | 00 (ALU)  | xxx    | 10    | 0    | 0      |
  | I-Type       | addi, xori, ... | 10011          | 1        | 1      | 0        | 00 (ALU)  | 0      | 10    | 0    | 0      |
  | Load         | lw              | 11             | 1        | 1      | 0        | 01 (Mem)  | 0      | 0     | 0    | 0      |
  | Store        | sw              | 100011         | 0        | 1      | 1        | xx        | 1      | 0     | 0    | 0      |
  | Branch       | beq, bne        | 1100011        | 0        | 0      | 0        | xx        | 10     | 1     | 0    | 1      |
  | J-Type       | jal             | 1101111        | 1        | x      | 0        | 10 (PC+4) | 11     | 0     | 1    | 0      |
  | I-Type       | jalr            | 1100111        | 1        | 1      | 0        | 10 (PC+4) | 0      | 0     | 1    | 0      |
  | U-Type       | lui             | 110111         | 1        | 1      | 0        | 00 (ALU)  | 100    | 11    | 0    | 0      |

* **ALU Decoder:** Determines the specific ALU operation based on `funct3` and `funct7` bits.

  | ALUOp | Funct3 | Funct7 (bit 30) | Command     | ALUControl | ALU                 |
  | ----- | ------ | --------------- | ----------- | ---------- | ------------------- |
  | 0     | x      | x               | lw, sw, jal | 0          | Add (A + B)         |
  | 1     | x      | x               | beq, bne    | 1          | Sub (A - B)         |
  | 11    | x      | x               | lui         | 110        | Pass B (Imm)        |
  | 10    | 0      | 0               | add, addi   | 0          | Add                 |
  | 10    | 0      | 1               | sub         | 1          | Sub                 |
  | 10    | 10     | x               | slt, slti   | 101        | SLT (Set Less Than) |
  | 10    | 100    | x               | xor, xori   | 100        | XOR                 |
  | 10    | 110    | x               | or, ori     | 11         | OR                  |
  | 10    | 111    | x               | and, andi   | 10         | AND                 |

### Hazard Unit

To maintain pipeline efficiency and correctness, the Hazard Unit handles:

* **Forwarding:** Resolves data hazards by bypassing data to the Execute stage.

  |   | Condition                               | ForwardAE | Source              |
  | - | --------------------------------------- | --------- | ------------------- |
  | 1 | (Rs1E == RdM) & RegWriteM & (Rs1E != 0) | 10        | ALUResultM (Memory) |
  | 2 | (Rs1E == RdW) & RegWriteW & (Rs1E != 0) | 1         | ResultW (Writeback) |
  | 3 | Else                                    | 0         | Rd1E (RegFile)      |

  |   | Condition                               | ForwardBE | Source              |
  | - | --------------------------------------- | --------- | ------------------- |
  | 1 | (Rs2E == RdM) & RegWriteM & (Rs2E != 0) | 10        | ALUResultM (Memory) |
  | 2 | (Rs2E == RdW) & RegWriteW & (Rs2E != 0) | 1         | ResultW (Writeback) |
  | 3 | Else                                    | 0         | Rd2E (RegFile)      |

* **Stalling:** Handles Load-Use hazards by pausing the pipeline.
* **Flushing:** Manages control hazards (branches/jumps) by clearing incorrect instructions from the pipeline.

| Condition                                               | Stall/Flush                        |
| ------------------------------------------------------- | ---------------------------------- |
| ResultSrcE0 (Is Load) AND  (RdE == Rs1D OR RdE == Rs2D) | StallF = 1  StallD = 1  FlushE = 1 |

| Condition                     | Flush                  |
| ----------------------------- | ---------------------- |
| PCSrcE (Branch Taken OR Jump) | FlushD = 1  FlushE = 1 |

## 📂 Repository Structure

The project is organized as follows:

```text
RISC-V-Pipeline-Processor-Implementation/
├── Description/           # Project requirements and documents
│   └── CA#04.pdf          # Problem statement (Assignment 4)
├── Design/                # Architecture diagrams and design docs
│   ├── DataPath.png       # Full datapath schematic
│   ├── Control Unit - ... # Decoders' architecture
│   ├── Hazard Unit - ...  # Forwarding and Stall logic diagrams
│   └── Design.pdf         # Detailed project report
├── Project/               # ModelSim project files and memory initialization
│   ├── CA_CA4.mpf         # ModelSim project file
│   ├── data.mem           # Data memory initialization
│   └── program.mem        # Machine code for the program
├── Source/                # Verilog HDL source files
│   ├── RISCV_Top.v        # Top-level module
│   ├── Datapath.v         # Pipeline stages and registers logic
│   ├── ControlUnit.v      # Main and ALU decoders
│   ├── HazardUnit.v       # Forwarding and Hazard detection logic
│   ├── Memory.v           # Instruction and Data memory modules
│   ├── Moduls.v           # Building blocks (Mux, Adders, RegFile, etc.)
│   ├── Testbench.v        # Testbench for verification
│   └── program.asm        # Assembly source code
└── README.md              # Project documentation
