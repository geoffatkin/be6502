; Macro for initializing a region of memory to a byte value. 

; Intended for use in code being assembled with
; vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt
; Currently only works if the region starts on a page boundary.
; However, does support a partial page at the end.

; Author: Geoffrey Atkin

MEMSET .macro addr, value, size
MS_START .set <\1
    .ifeq MS_START
MS_FULL_PAGES .set \3 / 256
MS_REMAINDER .set \3 % 256
MS_DIFF .set 256 - MS_REMAINDER
MS_OFFSET .set 3 * MS_DIFF
MS_PARTIAL .set pagefill + MS_OFFSET
    lda #0
    sta $00
    lda #>\1
    sta $01
    lda \2
    ldy #0
    ldx #MS_FULL_PAGES
    beq partial\@$
loop\@$
    jsr pagefill
    inc $01
    dex
    bne loop\@$
partial\@$
    jsr MS_PARTIAL
    .else
    .fail "code not yet written"
    .endif
.endm

; pagefill sets 256 bytes in a memory page to a given value
; on entry:
;   A = byte value to fill
;   Y = low byte of address to start, normally 0
;   $00 = 0 (to avoid page-crossing penalty)
;   $01 = page number (high byte of address to start)
pagefill:
    .repeat 256
    sta ($00),y
    iny
    .endr
    rts
