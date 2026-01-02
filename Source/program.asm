# x10 = Base Address (Initially 0)
# x11 = Counter (9 iterations)
# x12 = Current Min
# x13 = Loaded Value
# x14 = Comparison Result

addi x10, x0, 0       # 00000513: x10 = 0 (Start of Array)
lw   x12, 0(x10)      # 00052603: x12 = RAM[0] (Load 1st element as min)
addi x10, x10, 4      # 00450513: x10 = 4 (Point to 2nd element)
addi x11, x0, 9       # 00900593: x11 = 9 (Loop counter)

loop:
lw   x13, 0(x10)      # 00052683: Load next number
slt  x14, x13, x12    # 00c6a733: if (x13 < x12) x14=1 else 0
beq  x14, x0, skip    # 00070463: if (x13 >= x12) goto skip
addi x12, x13, 0      # 00068613: x12 = x13 (New Min Found)

skip:
addi x10, x10, 4      # 00450513: Pointer++
addi x11, x11, -1     # fff58593: Counter--
bne  x11, x0, loop    # fe0594e3: if counter != 0 goto loop

sw   x12, 80(x0)      # 04c02823: Store Result at address 80 (0x50)
end:
beq  x0, x0, end      # 00000063: Infinite Loop