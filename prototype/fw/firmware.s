    ; Intended to be assembled with: vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt

    .org $8000
    .asciiz "firmware.s"

ram_available   = $7f00     ; addresses from 0 inclusive to here exclusive are general purpose memory
via_base        = $7f10     ; address of a WDC 65c22
ace_base        = $7f20     ; address of a TL 16c550
led_base        = $7f80     ; address of a 7-segment LED display (driven by octal flip flop)
lcd_interface   = 8         ; 8=byte mode, 4=nibble mode, 0=no HD44780 present
serial_clock    = 18432     ; serial port crystal is 1.8432 MHz

; circular buffers for I/O
input_buf   = $7b00
output_buf  = $7c00
console_buf = $7d00

; command line buffer
cmd_buf     = $7e00
cmd_cursor  = $7e40
cmd_end     = $7e41

; read and write pointers into I/O buffers
input_rd    = $7ec0
input_wr    = $7ec2
output_rd   = $7ed0
output_wr   = $7ed2
console_rd  = $7ee0
console_wr  = $7ee2

    .include via.s
    .include led.s
    .include lcd.s
    .include ace.s
    .include registers.s
    .include strings.s
    .include ascii.s
    .include cmd.s
    .include io.s
    .include builtins.s

version_msg:
    .asciiz "Firmware 0.0.4"

prompt_msg:
    .asciiz "6502>"

running_msg:
    .asciiz ASCII_FF, "Running "

ace_config: ace_config_block ACE_38400_BAUD, ACE_8N1, ACE_ENABLE_ALL_INTERRUPTS

reset:
    lda #LED_0
    sta led_base
    ldx #$ff            ; initialize stack pointer
    txs                 
    stz input_rd        ; buffer empty when rd = wr
    stz input_wr
    stz output_rd
    stz output_wr
    stz console_rd
    stz console_wr

    jsr lcd_init        ; initialize LCD
    jsr timer_init      ; initialize 65c22 timer
    jsr ace_init        ; initialize serial port (using ace_config)

    cli                 ; enable interrupts

    load r0,version_msg
    jsr console_println

    load r0,ansi_reset
    jsr output_print

    load r0,ansi_clear
    jsr output_print

cmd_loop$
    lda #LED_DP
    sta led_base

    load r0,prompt_msg  ; print command prompt
    jsr output_print

    jsr cmd_readln      ; blocks until user presses enter
    load r0,ascii_crlf  ; move cursor to next line
    jsr output_print

    load r0,running_msg ; display running message on LCD
    jsr console_print
    load r0,cmd_buf
    jsr console_println
    jsr do_command

    jmp cmd_loop$

; Configures VIA timer 1 to fire an irq every 10 milliseconds.
timer_init:
    ; set counter 1 to 4e20 hex = 20,000 decimal = 1/100 sec at 2MHz
    lda #$7f        ; disable all interrupts
    sta via_ier
    lda #%01000000  ; continuous interrupts on timer 1
    sta via_acr
    lda #$20
    sta via_t1l
    lda #$4e
    sta via_t1h     ; loading high order counter starts countdown
    lda #%11000000  ; enable timer 1 interrupt
    sta via_ier
    rts

; Triggered by 65c22 VIA when timer reaches 0; and by 16c550 ACE when
; it wants attention.
irq:
    pha
    phx
    bit via_ifr     ; check bit 7 of interrupt flag register
    bmi via_irq$    ; IFR7=1 indicates interrupt
    lda ace_iir
    bit #ACE_NOT_PENDING
    beq ace_irq$    ; IIR0=0 indicates interrupt
    plx
    pla
    rti
via_irq$
    lda via_t1l         ; clear timer 1 interrupt by reading low counter
    ldx console_rd
    cpx console_wr
    beq via_irq_done$   ; rd=wr indicates buffer empty
    jsr lcd_isbusy      ; bit 7 set indicates busy
    bmi via_irq_done$   ; try again on next timer 1 interrupt
    lda console_buf,x   
    inx
    stx console_rd
    jsr lcd_putc
via_irq_done$
    plx
    pla
    rti
ace_irq$
    and #%00000110      ; use IIR2 and IIR1 ...
    tax                 ; as index into vector table...
    jmp (irq_vec,x)     ; to jump to one of the next four cases
ace_modem_status:
    lda #LED_7
    sta led_base
    lda ace_msr         ; clear interrupt by reading modem status reg
    jsr show_modem_status
    plx
    pla
    rti
ace_line_status:
    lda #LED_8
    sta led_base
    lda ace_lsr     ; clear interrupt by reading line status reg
    plx
    pla
    rti
ace_empty:
    ; write up to 16 bytes to the transmit holding register
    lda output_wr
    sec
    sbc output_rd
    cmp #17
    bcc lessthan17$
morethan16$
    ldx output_rd
    .repeat 16
    lda output_buf,x
    sta ace_thr
    inx
    .endrepeat
    stx output_rd
    bra done$
lessthan17$
    ldx output_rd
loop$
    cpx output_wr
    beq output_buffer_drained$
    lda output_buf,x
    sta ace_thr
    inx
    stx output_rd
    bra loop$
output_buffer_drained$
    lda ace_ier
    and #~ACE_ETBEI     ; disable the transmit buffer empty interrupt
    sta ace_ier
done$
    plx
    pla
    rti
ace_data_available:
    phy
    ldy #16         ; read up to 16 bytes, the size of the recv FIFO
loop$
    ldx input_wr
    inx
    cpx input_rd
    beq input_buffer_full$
    dex
    lda ace_lsr     ; check line status reg
    bit #ACE_DR     ; data ready
    beq done$       ; LSR0=0 means no data to be read
    lda ace_rbr
    sta input_buf,x
    inx
    stx input_wr
    dey
    beq done$
    bra loop$
input_buffer_full$
    lda ace_ier
    and #~ACE_ERBI  ; disable the received data available interrupt
    sta ace_ier
done$
    ply
    plx
    pla
    rti

nop:
    nop
    rti

; Update LED display to reflect modem status reported by ACE_EDSSI.
; $01 = offline, $11 = online
show_modem_status:
    cmp $11
    beq online$
    cmp $01
    beq offline$
    rts
online$
    lda LED_DP
    bra done$
offline$
    lda LED_C | LED_D | LED_E | LED_G   ; small "o"
done$
    sta led_base
    rts

    .org $fff0
irq_vec:
    .word ace_modem_status    
    .word ace_empty
    .word ace_data_available
    .word ace_line_status

    .org $fffa
    .word nop
    .word reset
    .word irq