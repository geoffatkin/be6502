; This file divides page zero into "registers" of different lengths,
; and defines macros that load/move the appropriate number of bytes
; based on register length.

; 0 - 15	scratch area
; b0-b7	    8-bit bytes
; w0-w7	    16-bit words (unsigned short ints)
; p0-p7	    16-bit addresses (pointers)
; i0-i7	    32-bit ints (signed)
; f0-f7	    32-bit floats
; q0-q7	    64-bit quad words (signed long ints)
; d0-d7	    64-bit double-precision floats
; r0-r1     reserved for firmware
; hp	    heap pointer
; sp	    stack pointer

b0 = 16
b1 = 17
b2 = 18
b3 = 19
b4 = 20
b5 = 21
b6 = 22
b7 = 23

w0 = 24
w1 = 26
w2 = 28
w3 = 30
w4 = 32
w5 = 34
w6 = 36
w7 = 38

p0 = 40
p1 = 42
p2 = 44
p3 = 46
p4 = 48
p5 = 50
p6 = 52
p7 = 54

i0 = 56
i1 = 60
i2 = 64
i3 = 68
i4 = 72
i5 = 76
i6 = 80
i7 = 84

f0 = 88
f1 = 92
f2 = 96
f3 = 100
f4 = 104
f5 = 108
f6 = 112
f7 = 116

q0 = 120
q1 = 128
q2 = 136
q3 = 144
q4 = 152
q5 = 160
q6 = 168
q7 = 176

d0 = 184
d1 = 192
d2 = 200
d3 = 208
d4 = 216
d5 = 224
d6 = 232
d7 = 240

r0 = 248
r1 = 250
hp = 252
sp = 254

; Compares two registers. But if the second operand is 0..15, 
; compares register to immediate value.
comp .macro register, reg_or_value
    .if (\2 < b0) | (\2 > 255)
    comp_imm \1,\2
    .else
    comp_reg \1,\2
    .endif
.endm

; Sets the Z flag if register = value; sets the C flag if register >= value.
; Value is always positive, so if the register is signed and negative, 
; it's automaticallly < value.
comp_imm .macro register, value
    .if (\1 >= b0) & (\1 <= b7)
    lda \1
    cmp #\2
    .endif
    .if (\1 >= w0) & (\1 <= w7 )
    lda \1+1
    cmp #>\2
    bne done\@$
    lda \1
    cmp #<\2
done\@$
    .endif
    .if (\1 >= i0) & (\1 <= i7 )
    lda \1+3
    bmi neg\@$
    cmp #0
    bne done\@$
    lda \1+2
    cmp #0
    bne done\@$
    lda \1+1
    cmp #>\2
    bne done\@$
    lda \1
    cmp #<\2
    bra done\@$
neg\@$
    lda #0
    cmp #1
done\@$
    .endif
.endm

; Sets the Z flag if reg1 = reg2; sets the C flag if reg1 >= reg2.
comp_reg .macro reg1, reg2
    .if (\1 >= b0) & (\1 <= b7) & (\2 >= b0) & (\2 <= b7)
    lda \1
    cmp \2
    .endif
    .if (\1 >= w0) & (\1 <= w7) & (\2 >= w0) & (\2 <= w7)
    lda \1+1
    cmp \2+1
    bne done\@$
    lda \1
    cmp \2
done\@$
    .endif
    .if (((\1 >= p0) & (\1 <= p7)) | ((\1 >= r0) & (\1 <= r1))) & (((\2 >= p0) & (\2 <= p7)) | ((\2 >= r0) & (\2 <= r1)))
    lda \1+1
    cmp \2+1
    bne done\@$
    lda \1
    cmp \2
done\@$
    .endif
.endm

; Increment reg by immediate value. Value must be < 256
incr .macro reg, value
    clc
    .if (\1 >= b0) & (\1 <= b7)
    lda \1
    adc #\2
    sta \1
    .endif
    .if ((\1 >= w0) & (\1 <= p7)) | ((\1 >= r0) & (\1 <= r1 ))
    lda \1
    adc #\2
    sta \1
    lda \1+1
    adc #0
    sta \1+1
    .endif
    .if (\1 >= i0) & (\1 <= i7)
    lda \1
    adc #\2
    sta \1
    lda \1+1
    adc #0
    sta \1+1
    lda \1+2
    adc #0
    sta \1+2
    lda \1+3
    adc #0
    sta \1+3
    .endif
.endm

; Jumps to the address contained in r0 or r1
jump .macro reg
    .if \1 = w0
    jmp ($0018)
    .endif
    .if \1 = w1
    jmp ($001a)
    .endif
    .if \1 = r0
    jmp ($00f8)
    .endif
    .if \1 = r1
    jmp ($00fa)
    .endif
.endm

; Stores the immediate value (0..ffff) in the destination register.
; Zero-extend the value if register is larger than 2 bytes.
load .macro destination, value
    .if (\1 >= b0) & (\1 <= b7)
    lda #\2
    sta \1
    .endif
    .if (\1 >= w0) & (\1 <= p7 )
    lda #<\2
    sta \1
    lda #>\2
    sta \1+1
    .endif
    .if (\1 >= r0) & (\1 <= r1 )
    lda #<\2
    sta \1
    lda #>\2
    sta \1+1
    .endif
    .if (\1 >= i0) & (\1 <= i7 )
    lda #<\2
    sta \1
    lda #>\2
    sta \1+1
    lda #0
    sta \1+2
    sta \2+3
    .endif
.endm

move .macro destination, source
    .if (\1 >= b0) & (\1 <= b7)
    move1 \1,\2
    .endif
    .if (\1 >= w0) & (\1 <= w7 )
    move2 \1,\2
    .endif
.endm

move1 .macro destination, source
    .if ((\2 >= r0) & (\2 <= r1)) | ((\2 >= p0) & (\2 <= p7))
    lda (\2)
    sta \1
    .else
    lda \2
    sta \1
    .endif
.endm

move2 .macro destination, source
    .if ((\2 >= r0) & (\2 <= r1)) | ((\2 >= p0) & (\2 <= p7))
    phy
    lda (\2)
    sta \1
    ldy #1
    lda (\2),y
    sta \1+1
    ply
    .else
    lda \2
    sta \1
    lda \2+1
    sta \1+1
    .endif
.endm
