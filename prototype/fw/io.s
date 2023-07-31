; Drains the console buffer to the LCD screen as quickly as possible but
; prevents anything else from running while this routine waits for the LCD.
console_flush:
    sei                 ; disable interrupts
    ldx console_rd      ; because this routine alters the rd pointer
                        ; and interacts directly with lcd
loop$
    cpx console_wr
    beq done$           ; buffer empty
loop2$
    jsr lcd_isbusy
    bmi loop2$
    lda console_buf,x
    jsr lcd_putc
    inx
    stx console_rd
    bra loop$
done$
    cli                 ; enable interrupts
    rts

; Displays the null-terminated string referenced by r0
; (excludes the terminating null).
console_print:
    ldy #0
loop$
    lda (r0),y
    beq done$
    jsr console_putc
    iny
    bra loop$
done$
    rts

; Displays the null-terminated string referenced by r0, and moves to the
; second line if on the first one (excludes the terminating null).
console_println:
    jsr console_print
    lda #ASCII_LF
    jsr console_putc
    rts

; Displays the single character stored in A.
console_putc:
    ldx console_wr
    sta console_buf,x
    inx
    cpy console_rd
    bne done$
done$
    stx console_wr
    rts

; Gets a character from the input buffer.
; Blocks (goes into infinite loop) until there is one.
input_getc:
loop$
    ldx input_rd
    cpx input_wr
    beq loop$
    lda input_buf,x
    inx
    stx input_rd
    ; if the buffer was full before, it isn't now, so...
    tax
    lda ace_ier
    ora #ACE_ERBI
    sta ace_ier   ; ...enable received data available interrupt
    txa
    rts

; Transmits the null-terminated string referenced by r0
; (excludes the terminating null, does not add CR or LF).
output_print:
    ldy #0
loop1$
    lda (r0),y
    beq done$
    ldx output_wr
    inx
    cpx output_rd
    bne buffer_not_full$
buffer_full$
    ; make sure the interrupt is on to drain the buffer
    ; (it is possible the string is longer than the buffer and the
    ; buffer was empty when this subroutine started)
    lda ace_ier
    ora #ACE_ETBEI
    sta ace_ier     ; enable transmit buffer empty interrupt
loop2$
    cpx output_rd
    beq loop2$
buffer_not_full$
    dex
    sta output_buf,x
    inx
    stx output_wr
    iny
    bra loop1$
done$
    lda ace_ier
    ora #ACE_ETBEI
    sta ace_ier     ; enable transmit buffer empty interrupt
    rts

; less-efficient reference implementation:
;output_print:
;    ldy #0
;loop$
;    lda (r0),y
;    beq done$
;    jsr output_putc
;    iny
;    bra loop$
;done$
;    rts

; Transmits the null-terminated string referenced by r0, plus CR and LF
; (excludes the terminating null).
output_println:
    jsr output_print
    jsr output_crlf
    rts

; Transmit the byte stored in A. Alters X.
output_putc:
    pha
    ldx output_wr
    inx
loop$
    cpx output_rd
    beq loop$           ; block until space available in output buffer
    dex
    sta output_buf,x
    inx
    stx output_wr
    ; there's data ready to be transmitted now, so...
    lda ace_ier
    ora #ACE_ETBEI
    sta ace_ier     ; ...enable transmit buffer empty interrupt
    pla
    rts

; Prints ASCII carriage return and linefeed. Slightly more efficient than
;    lda #ASCII_CR
;    jsr output_putc
;    lda #ASCII_LF
;    jsr output_putc
; and doesn't trash registers like
;    load r0,ascii_crlf
;    jsr output_print
output_crlf:
    pha
    phx
    lda #ASCII_CR
    ldx output_wr
    inx
loop$
    cpx output_rd
    beq loop$
    dex
    sta output_buf,x
    inx
    stx output_wr
    lda #ASCII_LF
    ldx output_wr
    inx
loop2$
    cpx output_rd
    beq loop2$
    dex
    sta output_buf,x
    inx
    stx output_wr
    ; there's data ready to be transmitted now
    lda ace_ier
    ora #ACE_ETBEI
    sta ace_ier
    plx
    pla
    rts