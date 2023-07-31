; Most of this file is based on Ben Eater's code.

    .if lcd_interface==8

LCD_E  = %10000000
LCD_RW = %01000000
LCD_RS = %00100000

; This is Ben's initialization code from part 7 of his video series.
; (Except for the cursor options.)
lcd_init:
    lda #%11111111 ; Set all pins on port B to output
    sta via_ddrb
    lda #%11100000 ; Set top 3 pins on port A to output
    sta via_ddra

    lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001101 ; Display on; cursor off; blink on
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #%00000001 ; Clear display
    jsr lcd_instruction
    rts

; In part 9 of his video series, Ben added wait code to the lcd_instruction
; routine. However, I found it useful to have both the old and new versions
; available. So I've rearranged the code so that lcd_instruction is the longer 
; version with the wait, and lcd_inst is the short version without the wait.

lcd_instruction:
    pha
    jsr lcd_wait
    pla
    jsr lcd_inst
    rts

lcd_putchar:
    pha
    jsr lcd_wait
    pla
    jsr lcd_char
    rts

lcd_wait:
    jsr lcd_isbusy
    bmi lcd_wait    ; repeat until not busy
    lda #0
    sta via_porta
    lda #%11111111  ; set port B to output
    sta via_ddrb
    rts

lcd_cursor_position:
    jsr lcd_isbusy
    bmi lcd_cursor_position     ; repeat until not busy
    ; LCD module increments address AFTER busy flag is cleared
    ; have to wait tADD=7.9 ms then read port B again
delayloop$
    ldy #251    ; delayloop takes 31632 cycles with x=24,y=251
loop1$
    ldx #24     ; 31.6 ms at 1MHz = 7.9 ms at 4 MHz
loop2$
    dex
    bne loop2$
    dey
    bne loop1$          ; end of delay loop
    jsr lcd_isbusy
    rts

; lcd_isbusy is based on Ben Eater's lcd_wait routine. 
; It reads the instruction register and returns the result,
; which includes the busy flag in bit 7.
; However, this routine does not loop until the busy flag is clear.
; The caller can branch with BMI or BPL.

lcd_isbusy:
    lda #%00000000          ; set port B to input
    sta via_ddrb
    lda #LCD_RW             ; clear RS, set RW, clear E
    sta via_porta
    lda #(LCD_RW | LCD_E)   ; then set E
    sta via_porta
    lda via_portb           ; read instruction register
    pha                     ; save result to return below
    lda #LCD_RW             ; clear E (see fig 26 of data sheet)
    sta via_porta
    pla
    rts                     ; bit 7 will be set if busy

; lcd_putc is a variation of Ben Eater's putchar routine.
; The caller must call lcd_isbusy before calling this routine.
; If the character to be printed is a formfeed or newline control
; character, this routine issues a clear-display or cursor-move
; instruction instead.

lcd_putc:
    pha
    lda #%11111111          ; set port B to output
    sta via_ddrb
    pla
    ; replace formfeed with clear display instruction
    cmp #$0c
    bne elseif$
    lda #%00000001          ; clear display
    jmp lcd_inst
elseif$
    ; replace newline character with cursor move instruction
    cmp #$0a
    bne elseif2$
    lda #%11000000          ; move cursor to start of second line
    jmp lcd_inst
elseif2$
    ; suppress all other control characters
    cmp #" "
    bcs else$
    rts
else$
    jmp lcd_char

; Ben Eater's original code, with minor alterations:
; - calls to lcd_wait removed
; - lcd_instruction renamed to lcd_inst
; - print_char renamed to lcd_char
; - E and RS renamed to LCD_E and LCD_RS
; - PORTA and PORTB renamed to via_porta and via_portb

lcd_inst:
    sta via_portb
    lda #0                  ; Clear RS/RW/E bits
    sta via_porta
    lda #LCD_E              ; Set E bit to send instruction
    sta via_porta
    lda #0                  ; Clear RS/RW/E bits
    sta via_porta
    rts

lcd_char:
    sta via_portb
    lda #LCD_RS             ; Set RS; Clear RW/E bits
    sta via_porta
    lda #(LCD_RS | LCD_E)   ; Set E bit to send instruction
    sta via_porta
    lda #LCD_RS             ; Clear E bits
    sta via_porta
    rts

    .endif
