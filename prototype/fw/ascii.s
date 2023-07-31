ASCII_BS = $08      ; backspace
ASCII_HT = $09      ; tab
ASCII_LF = $0a      ; line feed
ASCII_FF = $0c      ; form feed
ASCII_CR = $0d      ; carriage return (enter key)
ASCII_ESC = $1b     ; escape
ASCII_DEL = $7f     ; delete
ASCII_SPACE = $20   ; space (spacebar key)

; Terminals send CR for the Enter key, but expect the combination of CR 
; followed by LF to mark the end of a line of text to be displayed. 
; Operating systems vary in how they represent end-of-line in text files.
; For maximum interoperability, be flexible.

ascii_crlf:
    .asciiz ASCII_CR, ASCII_LF

; ANSI terminals support hundreds of escape sequences as instructions.
; Here are some useful ones.

ansi_home:
    .asciiz ASCII_ESC, "[H"

ansi_clear:
    .asciiz ASCII_ESC, "[H", ASCII_ESC, "[J"

ansi_erase_line:
    .asciiz ASCII_ESC, "[K"

ansi_up:
    .asciiz ASCII_ESC, "[A"

ansi_down:
    .asciiz ASCII_ESC, "[B"

ansi_right:
    .asciiz ASCII_ESC, "[C"

ansi_left:
    .asciiz ASCII_ESC, "[D"

ansi_reset:
    .asciiz ASCII_ESC, "[!p"
