PORTB = $6000       ; Map VIA data port B to address $6000
PORTA = $6001       ; Map VIA data port A to address $6001
DDRB  = $6002       ; Map VIA data direction register B to address $6002
DDRA  = $6003       ; Map VIA data direction register A to address $6003

E  = %10000000      ; E  - LCD enable flag bit, 1 is enabled, 0 is disabled
RW = %01000000      ; RW - LCD read/write flag bit, 1 is read, 0 is write
RS = %00100000      ; RS - LCD register select flag bit, 1 selects data register, 0 selects instruction register

    .org $8000      ; ROM starts at address $8000

reset:
    ; Initialize the stack pointer to 0x01FF
    ldx #$ff
    txs

    ; Initialize the VIA data direction registers
    ; Port B is where the computer reads/writes data from/to the display
    ; Port A is where the computer sets the E/RW/RS flags for the display
    lda #%11111111  ; Set all bits of port B as output (e.g. writes 8 bits to display)
    sta DDRB        ; Store in data direction register B
    lda #%11100000  ; Set 3 highest bits of port A as output (e.g. write 3 bits of flag data)
    sta DDRA        ; Store in data direction register A

    ; Initialize the display
    lda #%00111000  ; Initialize screen to 8-bit mode, 2 lines, 5x8 font size
    jsr send_lcd_instruction
    lda #%00001110  ; Turn on display, turn on cursor
    jsr send_lcd_instruction
    lda #%00000110  ; Set to shift cursor on write
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    ; Initialize and store current character in X register
    ldx #$20  ; Characters that can be displayed start at $20

redraw:
    lda #%00000010  ; Return cursor to home on display (overwrites display)
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    cpx #%00000000  ; Check X register value to determine if we have rolled over
    bne display_char ; If not 0, we have not rolled over
    ldx #$20        ; Start over at the beginning of displayable characters

display_char:
    txa             ; Transfer X register value to accumulator
    jsr send_lcd_character ; Display character to screen
    inx             ; Increment X register to display next character

end:
    txa             ; Transfer X register value to accumulator
    pha             ; Push current character value to the stack
    sec
    lda #2          ; Add redraw delay of 658.978ms @ 1MHz
end_outer_delay:
    ldy #$ff
end_middle_delay:
    ldx #$ff
end_inner_delay:
    dex
    bne end_inner_delay
    dey
    bne end_middle_delay
    sbc #1
    bne end_outer_delay
    pla             ; Pull current character from the stack
    tax             ; Transfer character back to the X register
    clc
    jmp redraw


check_lcd_busy:
    pha             ; Store value of accumulator on the stack
    lda #%00000000  ; Set all bits of port B as input (e.g. reads 8 bits from display)
    sta DDRB        ; Store in data direction register B
check_busy_flag:
    lda #RW         ; Tell display we want to read from it
    sta PORTA       ; Store flag in port A
    lda #(RW | E)   ; Set read and enable flags
    sta PORTA       ; Store flags in port A
    bit PORTB       ; Read busy value form port B
    bmi check_busy_flag  ; If 7th bit set the display is still busy
    lda #RW         ; Clear the enable flag
    sta PORTA       ; Store read flag in port A
    lda #%11111111  ; Set all bits of port B as output (e.g. writes 8 bits to display)
    sta DDRB        ; Store in data direction register B
    pla             ; Restore value of accumulator from the stack
    rts

send_lcd_instruction:
    jsr check_lcd_busy
    sta PORTB       ; Send instruction data to display
    lda #%00000000  ; Clear the flags, indicating we are writing instruction to the display
    sta PORTA       ; Store cleared flags in port A
    lda #E          ; Set the enable flag
    sta PORTA       ; Store flag in port A
    lda #%00000000  ; Clear all flags
    sta PORTA       ; Store cleared flags in port A
    rts

send_lcd_character:
    jsr check_lcd_busy
    sta PORTB       ; Send character data to display
    lda #RS         ; Set register select flag, selecting data register
    sta PORTA       ; Store flag in port A
    lda #(RS | E)   ; Set register select and enable flags
    sta PORTA       ; Store flags in port A
    lda #RS         ; Clear enable flag
    sta PORTA       ; Store flag in port A
    rts

    .org $fffc
    .word reset
    .word $0000