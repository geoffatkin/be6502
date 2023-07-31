; 65c22 Versatile Interface Adapter

    .ifdef via_base
via_portb   = via_base + $00  ; input/output register B
via_porta   = via_base + $01  ; input/output register A
via_ddrb    = via_base + $02  ; data direction register B
via_ddra    = via_base + $03  ; data direction register A
via_t1cl    = via_base + $04  ; T1 low order latches/counter
via_t1ch    = via_base + $05  ; T1 high order counter
via_t1ll    = via_base + $06  ; T1 low order latches
via_t1lh    = via_base + $07  ; T1 high order latches
via_t2l     = via_base + $08  ; T2 low order latches/counter
via_t2h     = via_base + $09  ; T2 high order counter
via_sr      = via_base + $0a  ; shift register
via_acr     = via_base + $0b  ; auxilary control register
via_pcr     = via_base + $0c  ; peripheral control register
via_ifr     = via_base + $0d  ; interrupt flag register
via_ier     = via_base + $0e  ; interrupt enable register
via_oraira  = via_base + $0f  ; same as reg 1 except no handshake

    .endif
