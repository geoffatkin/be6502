; reads a line of input from terminal, stores result in cmd_buf
; recognizes delete, backspace, and escape sequences
; blocks until enter key is pressed
cmd_readln:
    ldy #0
    sty cmd_cursor
    sty cmd_end
    sty cmd_buf
loop$
    jsr input_getc
    cmp #ASCII_CR
    beq enter$
    cmp #ASCII_BS
    beq backspace$
    cmp #ASCII_ESC
    beq escape$
    cmp #ASCII_DEL
    beq delete$
normal$
    jsr cmd_insert
    jsr cmd_update
    bra loop$
escape$
    jsr cmd_esc
    bra loop$
backspace$
    jsr cmd_backspace
    jsr cmd_update
    bra loop$
delete$
    jsr cmd_delete
    jsr cmd_update
    bra loop$
enter$
    rts

; deletes character before the cursor
cmd_backspace:
    ldy cmd_cursor
    bne echo$           ; ignore BS key when at start of command line (first character under cursor)
    rts
echo$
    dey
    sty cmd_cursor
    jsr output_putc     ; echo the BS to move the terminal cursor left
loop$
    iny
    lda cmd_buf,y
    dey
    sta cmd_buf,y
    iny
    cpy cmd_end
    bne loop$
done$
    dey
    sty cmd_end
    lda #0              ; just in case the trailing null got lost
    sta cmd_buf,y
    rts

; deletes character under cursor
cmd_delete:             
    ldy cmd_cursor
    cpy cmd_end         ; ignore DEL key when at end of command line (no character under cursor)
    bne loop$
    rts
loop$                   ; while cursor is not last character, replace with next one
    iny
    lda cmd_buf,y
    dey
    sta cmd_buf,y
    iny
    cpy cmd_end
    bne loop$
done$
    ldy cmd_end
    dey
    sty cmd_end
    rts



; handle escape key from terminal to support inline editing of command line
cmd_esc:
    ldy #0
    jsr input_getc      ; get next char
    cmp #"["            ; control sequence introducer
    beq csi$
    cmp #"O"            ; cursor key in application mode
    beq app$
    bra ignore$
app$
    jsr input_getc
    cmp #"A"
    bcc ignore$
    cmp #"Z"+1
    bcc letter$         ; ends sequences like ESC O A
    bra ignore$
csi$                    
    jsr input_getc
    cmp #"0"
    bcc ignore$
    cmp #"9"+1
    bcc digit$          ; process numeric keycode
    cmp #";"
    beq csi$            ; allow but ignore modifiers
    cmp #"A"
    bcc ignore$
    cmp #"Z"+1
    bcc letter$         ; ends sequences like ESC [ A
    cmp #"~"
    beq tilde$          ; ends sequences like ESC [ 1 ~
ignore$
    rts                 ; ignore anything else
digit$
    cpy #0
    bne csi$            ; ignore digits other than the first
    sec
    sbc #"0"            ; convert ASCII digit to value
    tay                 ; store key code in Y
    bra csi$
letter$
    cmp #"C"
    beq right$
    cmp #"D"
    beq left$
    cmp #"F"
    beq end$
    cmp #"H"
    cmp home$
    rts                 ; ignore anything else
tilde$
    cpy #1
    beq home$
    cpy #3             ; del on 10-key numeric keypad
    beq del$
    cpy #4
    beq end$
    rts                 ; ignore anything else
left$
    ldy cmd_cursor
    beq done$
    dey
    sty cmd_cursor
    load r0,ansi_left
    jsr output_print
    rts
right$
    ldy cmd_cursor
    cpy cmd_end
    bcs done$
    iny
    sty cmd_cursor
    load r0,ansi_right
    jsr output_print
    rts
home$
    load r0,ansi_left
    ldy cmd_cursor
    beq done$
    dey
    sty cmd_cursor
    jsr output_print
    bra home$
    rts
end$
    load r0,ansi_right
    ldy cmd_cursor
    cpy cmd_end
    beq done$
    iny
    sty cmd_cursor
    jsr output_print
    bra end$
    rts
del$
    jsr cmd_delete
    jsr cmd_update
done$
    rts

; inserts a character in front of the character under the cursor
cmd_insert:
    pha                 ; save the character to be inserted
    ldy cmd_end         ; increment the end index
    iny
    sty cmd_end
    lda #0              ; put a trailing null there
    sta cmd_buf,y
loop$                   ; move characters to the right one position
    dey
    lda cmd_buf,y
    iny
    sta cmd_buf,y
    dey
    cpy cmd_cursor      ; just moved the character under the cursor?
    bne loop$
done$
    pla                 ; restore and insert the character
    sta cmd_buf,y
    iny
    sty cmd_cursor
    jsr output_putc
    rts

; reprints portion of command line to the right of the cursor
; to show results of inline inserts and deletes
cmd_update:
    load r0,ansi_erase_line
    jsr output_print
    ldy cmd_cursor
loop1$
    cpy cmd_end
    beq done1$
    lda cmd_buf,y
    beq done1$
    jsr output_putc
    iny
    bra loop1$
done1$
    sty cmd_end     ; make sure cmd_end is index of trailing zero
    lda #0
    sta cmd_buf,y
loop2$
    cpy cmd_cursor
    beq done2$
    lda #ASCII_BS
    jsr output_putc
    dey
    bra loop2$
done2$
    rts
