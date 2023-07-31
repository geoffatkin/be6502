    ; Intended to be assembled with: vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt
    
    ; Power-on self test. LED displays decimal point if all tests pass. Other values are:
    ; 0     ROM test started. Stuck here indicates ROM test incomplete.
    ; 1     ROM test failed.
    ; 2     RAM test failed.
    ; 3     VIA IER unexpected value, indicates addr bus, data bus, or IO selection problem
    ; -     (minus sign) Waiting for VIA timer 2 timeout.
    ; -     (high minus) Waiting for VIA timer 2 IRQ. Stuck here indicates VIA IRQ problem
    ; 4     LCD test started. Stuck here with nothing displayed indicates LCD interface problem.
    ; 5     LCD test failed. Cursor position not reported as 1 after printing ">"
    ; 6     ACE test started. Stuck here indicates ACE test setup problem.
    ; 7     ACE scratch register test failed, indicates addr bus, data bus, or IO selection problem
    ; -     (triple dash) ACE interrupts enabled
    ; 9     Waiting for ACE receive buffer. Stuck indicates IRQ problem.
    ; o     (lowercase c, n, or o with segment missing) ACE IRQ handler called unexpectedly.
    ; .     (decimal point) all tests pass
    

    .org $8000
    .asciiz "post.s"

ram_available   = $7f00     ; addresses from 0 inclusive to here exclusive are general purpose memory
via_base        = $7f10     ; address of a WDC 65c22
ace_base        = $7f20     ; address of a TL 16c550
led_base        = $7f80     ; address of 7-segment LED display circuit
lcd_interface   = 8         ; 8=byte mode, 0=no HD44780 present

    .include via.s
    .include led.s
    .include lcd.s
    .include ace.s

buffer = $0200

reset:
    ldx #$ff            
    txs                 ; initialize stack pointer
    jmp post            

printmsg:
    ldx #0
loop$
    cpx $05             ; number of characters in buffer
    beq done$
    lda buffer,x
    inx
    jsr putchar
    bra loop$
done$
    jmp spin

putchar:
    pha
    jsr lcd_wait
    pla
    jsr lcd_putc
    rts

spin:
    lda #(LED_A | LED_DP)
    sta led_base
    jsr delayloop
    lda #(LED_B | LED_DP)
    sta led_base
    jsr delayloop
    lda #(LED_C | LED_DP)
    sta led_base
    jsr delayloop
    lda #(LED_D | LED_DP)
    sta led_base
    jsr delayloop
    lda #(LED_E | LED_DP)
    sta led_base
    jsr delayloop
    lda #(LED_F | LED_DP)
    sta led_base
    jsr delayloop
    jmp spin

post:
    ; LED segment test (only visible when single-stepping)
    lda #LED_A
    sta led_base
    lda #LED_B
    sta led_base
    lda #LED_C
    sta led_base
    lda #LED_D
    sta led_base
    lda #LED_E
    sta led_base
    lda #LED_F
    sta led_base

    lda #LED_0
    sta led_base   ; show zero during first test

    ; perfunctory ROM test
    lda #0
    sec
    rol
    cmp testdata
    bne fail1$
    asl
    cmp testdata + 1
    bne fail1$
    asl
    cmp testdata + 2
    bne fail1$
    asl
    cmp testdata + 3
    bne fail1$
    asl
    cmp testdata + 4
    bne fail1$
    asl
    cmp testdata + 5
    bne fail1$
    asl
    cmp testdata + 6
    bne fail1$
    asl
    cmp testdata + 7
    beq ramtest$
fail1$
    lda #LED_1
    sta led_base
    jmp fail1$
ramtest$
    lda #0
    sta $00
    sta ram_available - 1
    lda #$ff
    sta $00
    sta ram_available - 1
    lda $00
    cmp #$ff
    bne fail2$
    lda ram_available - 1
    cmp #$ff
    bne fail2$
    lda #$01
    sta $0101
    lda $0101
    cmp #$01
    bne fail2$
    lda #$02
    sta $0202
    lda $0202
    cmp #$02
    bne fail2$
    lda #$04
    sta $0404
    lda $0404
    cmp #$04
    bne fail2$
    lda #$08
    sta $0808
    lda $0808
    cmp #$08
    bne fail2$
    lda #$0c
    sta $0c0c
    lda $0c0c
    cmp #$0c
    bne fail2$
    lda #$10
    sta $1010
    lda $1010
    cmp #$10
    bne fail2$
    lda #$20
    sta $2020
    lda $2020
    cmp #$20
    bne fail2$
    lda #$40
    sta $4040
    lda $4040
    cmp #$40
    bne fail2$
    bra viatest$
fail2$
    lda #LED_2
    sta led_base
    jmp fail2$
fail3$
    lda #LED_3
    sta led_base
    jmp fail3$
viatest$
    lda #$7f        ; bit 7 clear, bit 0-6 set -> disable all interrupts
    sta via_ier     ; disable interrupts
    lda #%10100000  ; IER5 with high bit set-> enable timer 2 interrupt
    sta via_ier     ; enable interrupt
    lda #%01011111  ; disable all other interrupts
    sta via_ier
    lda via_ier     ; on read, IER indicates which interrupts are enabled
    cmp #%10100000  ; should indicate timer 2 interrupt is enabled
    bne fail3$
    lda #$7f        ; disable all interrupts
    sta via_ier
    lda #0
    sta via_acr     ; one-shot timer
    sta via_t2l     ; load timer 2 low order latch
    lda #1
    sta via_t2h     ; load timer 2 high order counter
    lda #LED_MINUS
    sta led_base    ; display minus sign while waiting for timer
    lda #$20        ; IFR5 indicates timer 2 time out
loop1$
    bit via_ifr
    beq loop1$      ; poll until IFR5 isn't zero
    lda via_t2l     ; read T2 low order counter to clear interrupt
    lda #0
    sta led_base    ; clear the minus sign display
via_irq_test$
    lda #0
    sta $00         ; testirq will increment this
    sta $01         ; testirq will store IFR here
    sta $02         ; testirq will store T2L here
    lda #LED_HIGH_MINUS
    sta led_base    ; display "high minus" while waiting for IRQ
    lda #$7f        ; bit 7 clear, bit 0-6 set -> disable all interrupts
    sta via_ier     ; disable interrupts    
    lda #%10100000  ; IER5 plus high bit to enable timer 2 IRQ
    sta via_ier     ; enable interrupt
    cli             ; clear interrupt disable bit
    lda #0
    sta via_acr     ; one-shot timers
    sta via_t2l     ; load timer 2 low order latch
    lda #1          ; timer should time out in 256 cycles
    sta via_t2h     ; load timer 2 high order counter (starts timer)
loop2$
    lda $00
    beq loop2$      ; poll scratch variable set by test irq handler
    lda #$7f        ; bit 7 clear, bit 0-6 set -> disable all interrupts
    sta via_ier     ; disable interrupts
lcdtest$
    lda #LED_4
    sta led_base    ; show 4 while initializing the LCD display
    jsr lcd_init 
    lda #">"
    jsr putchar
    jsr lcd_cursor_position
    cmp #1          ; after printing one character, cursor should be at 1
    beq acetest$
fail5$
    lda #LED_5
    sta led_base
    jmp fail5$
fail7$
    lda #LED_7
    sta led_base
    jmp fail7$
acetest$
    lda #LED_6      ; start of ACE test
    sta led_base
    lda #0
    sta $03         ; ace_irq will increment this
    sta $04         ; ace_irq will store IIR here
    sta $05         ; ace_irq will count number of character read
    sta $06         ; ace_irq will count number of character written
    lda #$5a
    sta ace_scr     ; store a value in the scratch register
    lda ace_scr     ; read it back
    cmp #$5a        ; check that it matches
    bne fail7$
    lda #$a5
    sta ace_scr     ; store a value in the scratch register
    lda ace_scr     ; read it back
    cmp #$a5        ; check that it matches
    bne fail7$
    sei             ; disable interrupts during initialization
    jsr ace_init_loop_mode      ; loop xmit to recv for testing
    cli                         ; re-enable interrupts
    lda #LED_HIGH_MINUS | LED_MINUS | LED_UNDERLINE
    sta led_base
    ldx #0
loop4$              ; wait till right number of characters in buffer
    lda #LED_9
    sta led_base
    lda $05
    cmp #13         ; length of testmsg
    bne loop4$
pass$
    lda #LED_DP
    sta led_base
    jmp printmsg

irq:
    pha
    bit via_ifr
    bmi via_irq$    ; IFR7=1 indicates interrupt
    lda ace_iir
    bit #1
    beq ace_irq$    ; IIR0=0 indicates interrupt
    pla
    rti
via_irq$
    inc $00         ; count number of VIA interrupts
    lda via_ifr
    sta $01         ; store current IFR value
    lda via_t2l     ; read T2 low order counter to clear interrupt
    sta $02         ; store this T2L value
    lda #LED_UNDERLINE
    sta led_base    ; display underline to indicate IRQ handled
    pla
    rti
ace_irq$
    phx
    inc $03         ; count number of ACE interrupts
    sta $04         ; store current IIR value
    and #%00000110  ; use bit1 and bit2...
    tax             ; as index into vector table...
    jmp (irq_vec,x) ; to jump to one of the next four cases
ace_modem_status:
    lda ace_msr     ; clear interrupt by reading modem status reg
    lda #LED_C | LED_D | LED_E
    sta led_base
    plx
    pla
    rti
ace_empty:
    lda #LED_D | LED_E | LED_G
    sta led_base
    ldx $06
    lda testmsg,x
    beq write_done$
    sta ace_thr
    inx
    stx $06
    plx
    pla
    rti
write_done$
    lda ace_ier
    and #~ACE_ETBEI
    sta ace_ier    
ace_line_status:
    lda ace_lsr     ; clear interrupt by reading line status reg
    lda #LED_E | LED_G | LED_C
    sta led_base
    plx
    pla
    rti
ace_data_available:
    lda #LED_G | LED_C | LED_D
    sta led_base
    ldx $05
char_loop$
    lda ace_lsr
    and #ACE_DR     ; 1 indicates data ready
    beq loop_done$
    lda ace_rbr
    sta buffer,x
    inx
    ;stx led_base
    bra char_loop$
loop_done$
    stx $05
irq_done$
    plx
    pla
    rti 

; Delays for approx 1/6 second, assuming clock=1MHz.
; A=1, x=242, y=137 yields 166598 ns.
delayloop:
    lda #1
    ldy #137        ; cycle count: 2
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

testmsg:
    .asciiz "Hello, World!"

testdata:
    .byte $01, $02, $04, $08, $10, $20, $40, $80

    .org $fff0
irq_vec:
    .word ace_modem_status    
    .word ace_empty
    .word ace_data_available
    .word ace_line_status

    .org $fffa
    .word $0000
    .word reset
    .word irq