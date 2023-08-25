PORTB = $6000      ; Map VIA data port B to $6000
PORTA = $6001      ; Map VIA data port A to $6001
DDRB  = $6002      ; Map VIA data direction register B to $6002
DDRA  = $6003      ; Map VIA data direction register A to $6003

E  = %10000000     ; LCD enable (E) flag bit
RW = %01000000     ; LCD read/write (RW) flag bit
RS = %00100000     ; LCD register select (RS) flag bit

    .org $8000

reset:
    ; Initialize the stack pointer to 0x01FF
    ldx #$ff
    txs

    ; Initialize the VIA data direction registers
    ; Port B is where the computer reads and writes data to the display
    ; Port A is where the computer sets the flags for the display
    lda #%11111111  ; Set all bits of port B as output
    sta DDRB        ; Store in data direction register B
    lda #%11100000  ; Set 3 highest bits of port A as output
    sta DDRA        ; Store in data direction register A

    ; Initialize the display
    lda #%00111000  ; Init screen to 8-bit mode, 2 lines, 5x8 font
    jsr send_lcd_instruction
    lda #%00001110  ; Turn on display, turn on cursor
    jsr send_lcd_instruction
    lda #%00000110  ; Set to shift cursor on write
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    ; Print Hello 6502!
    ldx #0          ; Start at index 0
loop_hello:
    lda message,x   ; Load next character in message
    beq loop        ; If the character is the null terminator, we're done
    jsr send_lcd_character
    inx             ; Increment index
    jmp loop_hello

    ; Do nothing (this is not a complicated program)
loop:
    jmp loop

    ; Set aside a block of memory for the message, adding a null terminator
message: .asciiz "Hello 6502!"

    ; Subroutine to check if the display is ready to accept new commands
check_lcd_busy:
    pha             ; Store value in accumulator on the stack
    lda #%00000000  ; Set all bits of port B as input
    sta DDRB        ; Store in data direction register B
check_busy_flag:
    lda #RW         ; Set R/W flag to read
    sta PORTA       ; Store in port A
    lda #(RW | E)   ; Set R/W and E flags
    sta PORTA       ; Store in port A
    lda PORTB       ; Read value from port B
    and #%10000000  ; Logical AND with busy flag bit
    bne check_busy_flag  ; If still busy loop
    lda #RW         ; Clear E flag
    sta PORTA       ; Store in port A
    lda #%11111111  ; Restore all bits of port B as output
    sta DDRB        ; Store in data direction register B
    pla             ; Restore value to accumulator from the stack
    rts

send_lcd_instruction:
    jsr check_lcd_busy
    sta PORTB       ; Send instruction data to display
    lda #%00000000  ; Clear RS, R/W, and E flags
    sta PORTA
    lda #E          ; Set E flag
    sta PORTA
    lda #%00000000  ; Clear RS, R/W, and E flags
    sta PORTA
    rts

send_lcd_character:
    jsr check_lcd_busy
    sta PORTB       ; Send character data to display
    lda #RS         ; Set RS flag
    sta PORTA
    lda #(RS | E)   ; Set RS and E flags
    sta PORTA
    lda #RS         ; Set RS flag
    sta PORTA
    rts

    .org $fffc
    .word reset
    .word $0000