; lcs.s - 65c22 VIA interface to HD44780U LCD module.
;
; I would like to express my deepest appreciation to Ben Eater. Without his 
; wonderful series of educational/instructional YouTube videos, I would not 
; have attempted this project. The code below assume the use of the hardware 
; interface he describes (D7-D0 are connected to PB7-PB0, and E, RS, and RW 
; are connected to PA7-PA5). As a result some constants will be the same;
; for example E is 10000000 binary because it is pin 7 of port A.
;
; However, the code in this file is an original implementation based on his
; explanations.

    .if lcd_interface==8

; Rising edge on pin E tells the module to perform the action indicated by 
; the other pins, and must trail changes to them by tAS=60ns.

LCD_E  = $80

; Constants for port A

LCD_WRITE_INST  = $00   ; RS=0, RW=0
LCD_READ_STATUS = $40   ; RS=0, RW=1
LCD_WRITE_DATA  = $20   ; RS=1, RW=0
LCD_READ_DATA   = $60   ; RS=1, RW=1

LCD_PA_OUTPUT   = LCD_E | LCD_READ_STATUS | LCD_WRITE_DATA

; Constants for port B

LCD_CLEAR       = $01
LCD_HOME        = $02
LCD_ENTRY_MODE  = $04
LCD_DISPLAY_MODE= $08
LCD_SHIFT_MODE  = $10
LCD_FUNCTION    = $20
LCD_SET_CGRAM   = $40
LCD_SET_DDRAM   = $80

LCD_INCREMENT   = $02
LCD_AUTO_SHIFT  = $01
LCD_DISPLAY_ON  = $04
LCD_CURSOR_ON   = $02
LCD_BLINK_ON    = $01
LCD_DISP_SHIFT  = $08
LCD_SHIFT_RIGHT = $04
LCD_EIGHT_BITS  = $10
LCD_FOUR_BITS   = $00
LCD_TWO_LINES   = $08
LCD_ONE_LINE    = $00
LCD_FONT_5x10   = $04
LCD_FONT_5x8    = $00
LCD_BUSY_FLAG   = $80
LCD_LINE_TWO    = $40   ; DDRAM address for start of second line

LCD_PB_OUTPUT   = $ff
LCD_PB_INPUT    = $00

; Initialize the LCD interface
lcd_init:
    lda #LCD_PA_OUTPUT
    sta via_ddra

    jsr lcd_wait
    lda #(LCD_FUNCTION | LCD_EIGHT_BITS | LCD_TWO_LINES | LCD_FONT_5x8)
    jsr lcd_write_instruction

    jsr lcd_wait
    lda #(LCD_DISPLAY_MODE | LCD_DISPLAY_ON | LCD_BLINK_ON)
    jsr lcd_write_instruction

    jsr lcd_wait
    lda #(LCD_ENTRY_MODE | LCD_INCREMENT)
    jsr lcd_write_instruction

    jsr lcd_wait
    lda #LCD_CLEAR
    jsr lcd_write_instruction
    rts

; Reads the LCD status into the accumulator, including the busy flag in
; bit 7. The caller can branch on busy with BMI or not-busy with BPL.
lcd_isbusy:
    lda #LCD_PB_INPUT
    sta via_ddrb
    lda #LCD_READ_STATUS
    sta via_porta
    ora #LCD_E              ; set E
    sta via_porta
    lda via_portb
    pha
    lda #LCD_READ_STATUS    ; clear E
    sta via_porta
    pla
    rts

; Loops until LCD not busy.
lcd_wait:
    jsr lcd_isbusy
    bmi lcd_wait
    rts

; Loads the address counter into the accumulator. This information is
; actually returned by lcd_isbusy, but the LCD module doesn't update the
; address counter until tADD=7.9 ms after the busy flag clears. So this
; subroutine waits for the not-busy condition, then runs a delay loop,
; then calls lcd_isbusy to get the updated address counter. As a result,
; this subroutine is very slow. The X and Y registers are used for the
; delay loop.
lcd_cursor_position:
    jsr lcd_isbusy
    bmi lcd_cursor_position     ; repeat until not busy
delayloop$
    ldy #251            ; delayloop takes 31632 cycles with x=24,y=251
loop1$
    ldx #24             ; 31.6 ms at 1MHz = 7.9 ms at 4 MHz
loop2$
    dex
    bne loop2$
    dey
    bne loop1$          ; end of delay loop
    jsr lcd_isbusy
    rts

; Takes an instruction such as LCD_CLEAR from the accumulator,
; and writes it to the LCD module. The caller must check 
; lcd_isbusy before calling this routine.
lcd_write_instruction:
    pha
    lda #LCD_PB_OUTPUT
    sta via_ddrb
    pla
    sta via_portb
    lda #LCD_WRITE_INST
    sta via_porta
    ora #LCD_E              ; set E
    sta via_porta
    lda #LCD_WRITE_INST     ; clear E
    sta via_porta
    rts

; Writes data from accumlator to the LCD module. The caller must
; check lcd_isbusy before calling this routine.
lcd_write_data:
    pha
    lda #LCD_PB_OUTPUT
    sta via_ddrb
    pla
    sta via_portb
    lda #LCD_WRITE_DATA
    sta via_porta
    ora #LCD_E              ; set E
    sta via_porta
    lda #LCD_WRITE_DATA     ; clear E
    sta via_porta
    rts

; Writes the ASCII character in the accumulator to the LCD module.
; The caller must check lcd_isbusy before calling this routine.
; If the character to be printed is a formfeed or newline control
; character, this routine issues a clear-display or cursor-move
; instruction instead.
lcd_putc:
    pha
    lda #LCD_PB_OUTPUT
    sta via_ddrb
    pla
    ; if character is formfeed then clear display
    cmp #$0c
    bne elseif$
    lda #LCD_CLEAR
    jmp lcd_write_instruction
elseif$
    ; else if character is newline then move to second line
    cmp #$0a
    bne else$
    lda #(LCD_SET_DDRAM | LCD_LINE_TWO)
    jmp lcd_write_instruction
else$
    jmp lcd_write_data

    .endif
