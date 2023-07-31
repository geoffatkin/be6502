    .ifdef led_base

LED_A = $01
LED_B = $02
LED_C = $04
LED_D = $08
LED_E = $10
LED_F = $20
LED_G = $40
LED_H = $80

LED_HIGH_MINUS = LED_A
LED_MINUS = LED_G
LED_UNDERLINE = LED_D
LED_DP = LED_H

LED_1 = LED_B | LED_C
LED_2 = LED_A | LED_B | LED_G | LED_E | LED_D
LED_3 = LED_A | LED_B | LED_G | LED_C | LED_D
LED_4 = LED_F | LED_G | LED_B | LED_C
LED_5 = LED_A | LED_F | LED_G | LED_C | LED_D
LED_6 = LED_A | LED_F | LED_E | LED_D | LED_C | LED_G
LED_7 = LED_F | LED_A | LED_B | LED_C
LED_8 = LED_A | LED_B | LED_C | LED_D | LED_E | LED_F | LED_G
LED_9 = LED_A | LED_B | LED_C | LED_D | LED_F | LED_G
LED_0 = LED_A | LED_B | LED_C | LED_D | LED_E | LED_F

    .endif