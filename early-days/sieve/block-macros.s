; A few block structure macros for use with code being compiled with
; vasm6502_oldstyle -c02 -dotdir -Fbin -L listing.txt
; These are inspired by Garth Wilson's structure macros, but I 
; wanted something simpler.

FOR .macro label,from,to
FOR_LIMIT_\1 .set \3
FOR_LOOP_\1 .set for\@$
    SETW_IMM \1,\2
for\@$
.endm

NEXT .macro label
    INCW \1
    CMPW_IMM \1,FOR_LIMIT_\1
    beq repeat\@$
    bcs norepeat\@$
repeat\@$
    jmp FOR_LOOP_\1
norepeat\@$
.endm

IF_NON_ZERO .macro
    beq einz$
.endm

END_IF_NON_ZERO .macro
einz$
.endm

WHILE_LESS_THAN .macro
    bcs ewlt$
wlt$
.endm

END_WHILE_LESS_THAN .macro
    bcc wlt$
ewlt$
.endm

WHILE_NONZERO .macro
    beq ewnz$
wnz$
.endm

END_WHILE_NONZERO .macro
    bne wnz$
ewnz$
.endm
