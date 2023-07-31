
; Copies null terminated string from r1 to r0
; Uses Y register as index, so max string length is 256 including the null
; On exit, Y is number of characters copied before the null

strcpy:
    ldy #$ff
loop$
    iny
    lda (r1),y
    sta (r0),y
    bne loop$
    rts

strcpy .macro destination, source
    lda #<\1
    sta r0
    lda #>\1
    sta r0+1
    lda #<\2
    sta r1
    lda #>\2
    sta r1+1
    jsr strcpy
.endm
