commands:
    .byte "hi"
    .word cmd_hello
    .byte "hd"
    .word cmd_hexdump
    .word 0

match:
    .asciiz "match"

nomatch:
    .asciiz "nomatch"

zero:
    .asciiz "zero"

; Searches the above list of commands for one matching contents of r0.
; If found, runs the corresponding subroutine.
do_command:
    move w0,r0
    load r1,commands
loop$
    move w1,r1
    comp w1,0
    beq  notfound$
    comp w0,w1
    beq  found$
    incr r1,4
    bra  loop$
found$
    incr r1,2
    move w1,r1
    jump w1
notfound$
    ; r0 is still the entered command
    jsr  output_print
    load r0,not_found_msg
    jsr  output_println
    rts

not_found_msg:
    .asciiz": command not found"

hello_msg:
    .asciiz "Hello, world!"

five_spaces:
    .asciiz "     "

cmd_hello:
    load r0,hello_msg
    jsr output_println
    rts

cmd_hexdump:
    load r1, $8000
    load r0,five_spaces
    jsr output_print
    ldy #0
loop$
    tya
    jsr fmt_hex
    lda #ASCII_SPACE
    jsr output_putc
    iny
    cpy #$10
    bcc loop$
    ldy #0
row_loop$
    jsr output_crlf
    lda r1+1
    jsr fmt_hex
    tya
    jsr fmt_hex
    lda #ASCII_SPACE
    jsr output_putc
col_loop$
    lda (r1),y
    jsr fmt_hex
    lda #ASCII_SPACE
    jsr output_putc
    iny
    tya
    and #$0f
    bne col_loop$
    tya
    sec
    sbc #16
    tay
char_loop$
    lda (r1),y
    jsr fmt_printable
    jsr output_putc
    iny
    beq done$
    tya
    and #$0f
    bne char_loop$
    bra row_loop$
done$
    jsr output_crlf
    rts

fmt_hex:
    pha                 ; save a copy
    lsr                 ; shift top 4 bits to bottom 4
    lsr
    lsr
    lsr
    clc
    adc #"0"            ; convert value to ascii hex digit
    cmp #("9" + 1)
    bcc print1$
    clc
    adc #("a" - "9" - 1)
print1$
    jsr output_putc     ; print it
    pla                 ; restore copy for second hex digit
    and #$0f            ; bottom 4 bits
    clc
    adc #"0"            ; convert value to ascii hex digit
    cmp #("9" + 1)
    bcc print2$
    clc
    adc #("a" - "9" - 1)
print2$
    jsr output_putc
    rts

; If A is non-ascii character then replace A with dot (".")
fmt_printable:
    cmp #" "
    bcc dot$
    cmp #$7f
    bcc done$
dot$
    lda #"."
done$
    rts


