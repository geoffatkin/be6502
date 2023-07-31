    ; Intended to be assembled with: vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt
    ; Only 16 KB addressable on 32 KB EEPROM, so have to skip half of the 32 KB image.
    .org $8000
    .asciiz "spinner.s"
    .org $c000

DELAY .macro count
    lda #\1
loop0\@
    ldy #137
loop1\@
    ldx #242
loop2\@
    dex
    bne loop2\@
    dey
    bne loop1\@
    dec a
    bne loop0\@
.endm

nmi:
irq:
    rti

reset:
    lda #$01    ; segment a
    sta $ff00
    DELAY 1
    lda #$02
    sta $ff00
    DELAY 1
    lda #$04
    sta $ff00
    DELAY 1
    lda #$08
    sta $ff00
    DELAY 1
    lda #$10
    sta $ff00
    DELAY 1
    lda #$20    ; segment f
    sta $ff00
    DELAY 1
    jmp reset


; Delay loop implemented as nested count loops. 
; Delays for A divided by 6 seconds, at clock=1MHz. 
; Expects A; alters A, X, Y.
; Useful upper values for X and Y (assuming clock=1MHz)
;       x=155, y=64 yields 49990 ns (1/20 sec)
;       x=242, y=137 yields 166598 ns (1/6 sec)
;       x=238, y=209 yields 249970 ns (1/4 sec)
;       (not counting lda,jsr,rts)
delayloop:
                    ; cycle count:
    ldy #137        ; 2
loop1$
    ldx #242        ; y * 2
loop2$
    dex             ; y * x * 2
    bne loop2$      ; y*(x-1)*3 + y*2 
    dey             ; y * 2
    bne loop1$      ; (y-1)*3 + 2
    dec a           ; 2
    bne delayloop   ; 3
    rts


    .org $fffa
    .word nmi
    .word reset
    .word irq