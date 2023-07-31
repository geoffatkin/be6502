; 16c550c Asynchronous Communications Element

    .ifdef ace_base

ace_rbr = ace_base + $00    ; receiver buffer reg (read only)
ace_thr = ace_base + $00    ; transmitter holding reg (write only)
ace_ier = ace_base + $01    ; interrupt enable reg
ace_iir = ace_base + $02    ; interrupt ident reg (read only)
ace_fcr = ace_base + $02    ; fifo control reg (write only)
ace_lcr = ace_base + $03    ; line control reg
ace_mcr = ace_base + $04    ; modem control reg
ace_lsr = ace_base + $05    ; line status reg
ace_msr = ace_base + $06    ; modem status reg
ace_scr = ace_base + $07    ; scratch reg
ace_dll = ace_base + $00    ; divisor latch LSB (when DLAB = 1)
ace_dlm = ace_base + $01    ; divisor latch MSB (when DLAB = 1)

; Baud rate = 3.072 MHz/(16 * divisor); ace_dlm=0, ace_dll as below.
ACE_2400_BAUD   = 80
ACE_3600_BAUD   = 53
ACE_4800_BAUD   = 40
ACE_9600_BAUD   = 20
ACE_19200_BAUD  = 10
ACE_38400_BAUD  = 5

; Baud rate = 1.8432 MHz/(16 * divisor); set ace_dlm=0, ace_dll as below.
;ACE_2400_BAUD   = 48
;ACE_3600_BAUD   = 32
;ACE_4800_BAUD   = 24
;ACE_9600_BAUD   = 12
;ACE_19200_BAUD  = 6
;ACE_38400_BAUD  = 3
;ACE_115200_BAUD = 1

ACE_ERBI                = %00000001 ; enable received data available interrupt = IER0
ACE_ETBEI               = %00000010 ; enable transmit buffer empty interrupt = IER1
ACE_ELSI                = %00000100 ; enable receiver line status interrupt = IER2
ACE_EDSSI               = %00001000 ; enable modem status interrupt = IER3

ACE_ENABLE_RECV_INTERRUPT = ACE_ERBI | ACE_ELSI
ACE_ENABLE_XMIT_INTERRUPT = ACE_ETBEI
ACE_ENABLE_ALL_INTERRUPTS = ACE_ERBI | ACE_ETBEI | ACE_ELSI | ACE_EDSSI

ACE_NOT_PENDING         = %00000001 ; IIR0=0 means interrupt pending; IIR0=1 means not
ACE_MODEM_STATUS        = %00000000 ; IIR1,2=0
ACE_XMIT_EMPTY          = %00000010 ; IIR1=1
ACE_RECV_DATA_AVAIL     = %00000100 ; IIR2=1
ACE_RECV_LINE_STATUS    = %00000110 ; IIR1,2=1
ACE_CHAR_TIMEOUT        = %00001100 ; IIR2,3=1

ACE_FIFO_ENABLE         = %00000001 ; FCR0
ACE_RECV_FIFO_RESET     = %00000010 ; FCR1
ACE_XMIT_FIFO_RESET     = %00000100 ; FCR2
ACE_RECV_TRIGGER_1      = %00000000 ; FCR7=0,FCR6=0
ACE_RECV_TRIGGER_4      = %01000000 ; FCR7=0,FCR6=1
ACE_RECV_TRIGGER_8      = %10000000 ; FCR7=1,FCR6=0
ACE_RECV_TRIGGER_14     = %11000000 ; FCR7=1,FCR6=1

ACE_7_BITS              = %00000010 ; LCR1=1,LCR0=0
ACE_8_BITS              = %00000011 ; LCR1=1,LCR0=1
ACE_1_STOP              = %00000000 ; LCR2=0
ACE_2_STOP              = %00000100 ; LCR2=1
ACE_NO_PARITY           = %00000000 ; LCR3=0
ACE_ODD_PARITY          = %00001000 ; LCR3=1
ACE_EVEN_PARITY         = %00011000 ; LCR3,4=1
ACE_DLAB                = %10000000 ; divisor latch access bit = LCR7

ACE_DTR                 = %00000001 ; data terminal ready = MCR0
ACE_RTS                 = %00000010 ; request to send = MCR1
ACE_OUT1                = %00000100
ACE_OUT2                = %00001000 ; might need to be set for IRQ to work
ACE_LOOP                = %00010000 ; diagnostic loop mode = MCR4
ACE_AFE                 = %00100000 ; autoflow control enable = MCR5
ACE_AUTO_RTS_AND_CTS    = %00100010 ; MCR5=1,MCR1=1
ACE_AUTO_CTS_ONLY       = %00100000 ; AFE only

ACE_DR                  = %00000001 ; data ready = LSR0
ACE_OE                  = %00000010 ; overrun error = LSR1
ACE_PE                  = %00000100 ; parity error = LSR2
ACE_FE                  = %00001000 ; framing error = LSR3
ACE_BI                  = %00010000 ; break interrupt = LSR4
ACE_THRE                = %00100000 ; transmitter holding register empty = LSR5
ACE_TEMT                = %01000000 ; transmitter empty = LSR6
ACE_ERROR               = %10000000 ; error in recv FIFO

ACE_CTS                 = %00010000 ; clear to send = MSR4 (loop mode: equals MCR1)
ACE_DSR                 = %00100000 ; dataset ready = MSR5 (loop mode: equals MCR0)
ACE_RI                  = %01000000 ; ring indicator = MSR6 (loop mode: equals MCR2)
ACE_DCD                 = %10000000 ; data carrier detect = MSR7 (loop mode: equals MCR3)

ace_init:
    lda #ACE_DLAB
    sta ace_lcr
    lda #0
    sta ace_dlm
    lda #ACE_38400_BAUD
    sta ace_dll
    lda #ACE_8_BITS | ACE_1_STOP | ACE_NO_PARITY
    sta ace_lcr
    lda #ACE_FIFO_ENABLE | ACE_RECV_FIFO_RESET | ACE_XMIT_FIFO_RESET | ACE_RECV_TRIGGER_14
    sta ace_fcr
    lda #ACE_ERBI
    sta ace_ier
    lda #ACE_AUTO_RTS_AND_CTS | ACE_OUT2
    sta ace_mcr
    rts

ace_init_loop_mode:
    lda #ACE_DLAB
    sta ace_lcr
    lda #0
    sta ace_dlm
    lda #ACE_38400_BAUD
    sta ace_dll
    lda #ACE_8_BITS | ACE_1_STOP | ACE_NO_PARITY
    sta ace_lcr
    lda #ACE_FIFO_ENABLE 
    sta ace_fcr
    lda #ACE_FIFO_ENABLE | ACE_RECV_FIFO_RESET | ACE_XMIT_FIFO_RESET | ACE_RECV_TRIGGER_8
    sta ace_fcr
    lda #ACE_LOOP | ACE_DTR | ACE_RTS | ACE_OUT2
    sta ace_mcr
    lda #ACE_ENABLE_ALL_INTERRUPTS
    sta ace_ier
    rts

    .endif