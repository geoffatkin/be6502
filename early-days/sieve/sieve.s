; Intended to be assembled with: vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt

    .org $8000

    .include word-macros.s
    .include block-macros.s
    .include memset.s

PRINT .macro label
    lda #<\1
    sta output
    lda #>\1
    sta output+1
    jsr lcd_print
.endm

SIZE = 8190
SIZEP1 = 8191

flags = $0200   ; primality of odd numbers > 2
count = $80     ; number of primes found (2 bytes)
i_index = $82   ; index into flags array (2 bytes)
k_index = $84   ; index for marking non primes (2 bytes)
prime = $86     ; holds prime number found (2 bytes)
iter = $88      ; counts number of passes (2 byte)

output = $40    ; used by lcd_print and lcd_print_uw
quotient = $42  ; used by lcd_print_uw and divide_by_10
remainder = $44 ; used by lcd_print_uw and divide_by_10

reset:
    ldx #$ff            ; initialize stack pointer
    txs
    jsr lcd_init        ; initialize the LCD display
    jsr eratosthenes    ; run the benchmark
halt$
  jmp halt$

iterations_msg:
    .asciiz "10 iterations                           "

found_msg:
    .asciiz " primes"

; MEMSET replaces these three lines:
;        FOR i_index,0,SIZE
;            SET_ARRAY_INDEX flags,i_index,1
;        NEXT i_index

eratosthenes:
    PRINT iterations_msg
    FOR iter,1,10
        ZEROW count
        MEMSET flags,1,SIZE
        FOR i_index,0,SIZE
            ARRAY_INDEX flags,i_index
            IF_NON_ZERO                 ; if flags[i]=1
                SETW prime,i_index          ; prime = i
                LSHW prime                  ; times 2
                ADDW_IMM prime,3            ; plus 3
                SETW k_index,i_index        ; k = i
                ADDW k_index,prime          ; plus prime
                CMPW_IMM k_index,SIZEP1
                WHILE_LESS_THAN                         ; while k <= SIZE
                    SET_ARRAY_INDEX flags,k_index,0     ; flags[k] = 0
                    ADDW k_index,prime                  ; k = k + prime
                    CMPW_IMM k_index,SIZEP1
                END_WHILE_LESS_THAN
                INCW count                  ; count = count + 1
                ;jsr print_prime
            END_IF_NON_ZERO
        NEXT i_index
    NEXT iter

    SETW output,count
    jsr lcd_print_uw
    PRINT found_msg
    rts

print_prime:
    lda #$00000001 ; Clear display
    jsr lcd_instruction
    SETW output,prime
    jsr lcd_print_uw            ; print prime
    jsr delay
    rts

delay:
    ldx $ff
1$
    ldy $ff
2$
    dey
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    bne 2$
    dex
    bne 1$
    rts

; The following is Ben Eater's code, or closely follows his.
; I've added comments and changed internal labels to local.

; prints a string
; entry:    output is the address of the string to be printed
lcd_print:
    ldy #0
loop$
    lda (output),y
    beq done$
    jsr lcd_putchar
    iny
    bra loop$
done$
    rts

; prints a 16 bit unsigned value to the LCD (as decimal digits)
; entry:    output is value to be printed
lcd_print_uw:
    lda output
    sta quotient
    lda output+1
    sta quotient+1
    lda #0                  ; push 0 onto stack to mark the end
    pha                     ; of the remainder digits
loop$
        jsr divide_by_10
        clc
        adc #"0"            ; convert remainder value to ascii digit
        pha                 ; push remainder digit onto stack
        lda quotient
        ora quotient+1
        bne loop$
loop2$
        pla                 ; pull digit from the stack
        beq done$           ; until the 0 we pushed first
        jsr lcd_putchar     ; print it
        bra loop2$
done$
    rts


; divides a 16 bit unsigned value by 10
; entry:    quotient is value to be divided
; exit:     quotient is result of integer division
;           remainder is 16 bit unsigned remainder
;           A is low byte of remainder
divide_by_10:               
    stz remainder           ; initialize remainder to zero
    stz remainder+1
    clc
    ldx #16
loop$
        rol quotient
        rol quotient+1
        rol remainder
        rol remainder+1
        sec                 ; subtract 10 from remainder, leaving result in A,Y
        lda remainder
        sbc #10
        tay                 
        lda remainder+1
        sbc #0
        bcc skip$           ; don't store negative remainder, try again next time around
        sty remainder       ; low byte from Y
        sta remainder+1     ; high byte from A [should be zero, since divisor is 10]
skip$
        dex
        bne loop$

    rol quotient            ; shift one extra time (17th) to put last carry into quotient
    rol quotient+1
    lda remainder           ; return low byte of remainder in A
    rts

PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
E  = %10000000
RW = %01000000
RS = %00100000

lcd_init:
    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%11100000 ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001110 ; Display on; cursor on; blink off
    jsr lcd_instruction
    lda #%00000110 ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #$00000001 ; Clear display
    jsr lcd_instruction
    rts

lcd_wait:
    pha
    lda #%00000000  ; Port B is input
    sta DDRB
lcdbusy$
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000
    bne lcdbusy$

    lda #RW
    sta PORTA
    lda #%11111111  ; Port B is output
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    lda #E         ; Set E bit to send instruction
    sta PORTA
    lda #0         ; Clear RS/RW/E bits
    sta PORTA
    rts

lcd_putchar:
    jsr lcd_wait
    sta PORTB
    lda #RS         ; Set RS; Clear RW/E bits
    sta PORTA
    lda #(RS | E)   ; Set E bit to send instruction
    sta PORTA
    lda #RS         ; Clear E bits
    sta PORTA
    rts

  .org $fffc
  .word reset
  .word $0000
