; Macros for 16-bit math. Intended for use in code being assembled with
; vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt

ADDW .macro label1,label2
    clc
    lda \1
    adc \2
    sta \1
    lda \1+1
    adc \2+1
    sta \1+1
.endm

ADDW_IMM .macro label,value
    clc
    lda \1
    adc #<\2
    sta \1
    lda \1+1
    adc #>\2
    sta \1+1
.endm

ARRAY_INDEX .macro addr,label
    clc
    lda #<\1
    adc \2
    sta $00
    lda #>\1
    adc \2+1
    sta $01
    lda ($00)
.endm

SET_ARRAY_INDEX .macro addr,label,value
    clc
    lda #<\1
    adc \2
    sta $00
    lda #>\1
    adc \2+1
    sta $01
    lda #\3
    sta ($00)
.endm

CMPW .macro label1,label2
    lda \1+1
    cmp \2+2
    bne done\@$
    lda \1
    cmp \2
done\@$    
.endm

CMPW_IMM .macro label,value
    lda \1+1
    cmp #>\2
    bne done\@$
    lda \1
    cmp #<\2
done\@$    
.endm

INCW .macro label
    inc \1
    bne done\@$
    inc \1+1
done\@$
.endm

LSHW .macro label
    clc
    rol \1
    rol \1+1
.endm

SETW .macro label1,label2
    lda \2
    sta \1
    lda \2+1
    sta \1+1
.endm

SETW_IMM .macro label,value
    lda #<\2
    sta \1
    lda #>\2
    sta \1+1
.endm

ZEROW .macro label
    stz \1
    stz \1+1
.endm