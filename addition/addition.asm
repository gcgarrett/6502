PORTB = $6000      ; Map VIA data port B to $6000
PORTA = $6001      ; Map VIA data port A to $6001
DDRB  = $6002      ; Map VIA data direction register B to $6002
DDRA  = $6003      ; Map VIA data direction register A to $6003
PCR   = $600c      ; Map VIA peripheral control register to $600c
IFR   = $600d      ; Map VIA interrupt flag register to $600d
IER   = $600e      ; Map VIA interrupt enable register to $600e

current = $00      ; 1 byte - Stores current number pointer
value   = $01      ; 2 bytes - Stores value to display
mod10   = $03      ; 2 bytes - Used in converting binary to decimal
minus   = $05      ; 1 byte  - Negative flag
message = $06      ; 8 bytes - Message buffer, null terminated

E  = %10000000     ; LCD enable (E) flag bit
RW = %01000000     ; LCD read/write (RW) flag bit
RS = %00100000     ; LCD register select (RS) flag bit

    .org $8000

reset:
    ; Initialize the stack pointer to 0x01FF
    ldx #$ff
    txs
    ; Clear interrupt disabled bit
    cli

    ; Initialize the VIA to interrupt processor when CA1 goes low
    lda #%10000010 ; Enable CA1
    sta IER
    lda #%00000000 ; Interrupt on negative edge (transition from high to low)
    sta PCR

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
    lda #%00001100  ; Turn on display, turn off cursor
    jsr send_lcd_instruction
    lda #%00000110  ; Set to shift cursor on write
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    ; Initialize current number pointer
    lda #0
    sta current

redraw:
    lda #%00000010  ; Return cursor to home on display (overwrites display)
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    ; Zero out message buffer and minus flag
    lda #0
    sta message
    sta minus

    sei          ; Disable interrupts while we load number pointer value
    ldx current  ; Load current number pointer into the x register
    cli          ; Re-enable interrupts

    ; Initialize value with sum of number A and number B
    clc             ; Clear carry bit
    lda numbers_a,x ; Load low byte of number A
    adc numbers_b,x ; Add low byte of number B
    sta value       ; Store low byte of sum in value
    inx             ; Increment x for high byte of number
    clv             ; Clear overflow bit
    lda numbers_a,x ; Load high byte of number A
    adc numbers_b,x ; Add high byte of number B
    sta value + 1   ; Store high byte of number to display

    bvs print_error ; Print error message on overflow

    bit value + 1 ; Test if negative bit set in high byte
    bpl to_dec    ; If not, skip twos complement

    ; Set minus flag
    lda #1
    sta minus

    ; In two's complement, to get the negative value of a number you first flip
    ; the bits of the binary representation and then add one. Here we do the
    ; reverse to get the positive number value to display after the minus sign.

    ; Subtract 1 from value
    sec           ; Set the carry flag
    lda value     ; Load low byte of value
    sbc #1        ; Subtract 1 with borrow
    sta value     ; Store low byte
    lda value + 1 ; Load high byte of value
    sbc #0        ; Subtract 0 with borrow
    sta value + 1 ; Store high byte

    ; Flip bits from value
    lda value     ; Load low byte of value
    eor #$ff      ; XOR with 0xff to flip the bits
    sta value     ; Store low byte
    lda value + 1 ; Load high byte of value
    eor #$ff      ; XOR with 0xff to flip the bits
    sta value + 1 ; Store high byte

to_dec:
    ; Initialize remainder with 0 for both bytes
    lda #0
    sta mod10
    sta mod10 + 1
    clc            ; Clear the carry bit

    ldx #16        ; Loop through 16 bits
dec_loop:
    ; Rotate quotient and remainder
    rol value      ; Rotate low byte of value left
    rol value + 1  ; Rotate high byte of value left
    rol mod10      ; Rotate low byte of mod10 left
    rol mod10 + 1  ; Rotate high byte of mod10 left

    ; A and Y = dividend - divisor
    sec            ; Set carry bit
    lda mod10
    sbc #10
    tay            ; Save low byte in Y
    lda mod10 + 1
    sbc #0
    bcc ignore_result ; branch if dividend < divisor
    sty mod10
    sta mod10 + 1

ignore_result:
    dex
    bne dec_loop
    rol value      ; Shift in the last bit of the quotient
    rol value + 1

    lda mod10
    adc #"0"
    jsr push_character

    ; If value is not zero, continue conversion to decimal
    lda value
    ora value + 1
    bne to_dec

    ; Add negative sign if minus flag is set
    lda minus
    and #1
    beq print_number

    lda #"-"
    jsr push_character

print_number:
    ; Print sum
    ldx #0          ; Start at index 0
loop_message:
    lda message,x   ; Load next character in message
    beq end         ; If null character we are done
    jsr send_lcd_character
    inx             ; Increment index
    jmp loop_message

print_error:
    ; Print error "Out of bounds"
    ldx #0              ; Start at index 0
loop_error:
    lda error_message,x ; Load next character of error message
    beq end             ; If null character we are done
    jsr send_lcd_character
    inx                 ; Increment index
    jmp loop_error

    ; Delay and then redraw
end:
    ldy #$ff        ; Add redraw delay of 131.072ms @ 1MHz to reduce flickering
end_outer_delay:
    ldx #$ff
end_inner_delay:
    dex
    bne end_inner_delay
    dey
    bne end_outer_delay
    jmp redraw

    ; Error message
error_message: .asciiz "Out of bounds"

    ; Table A of numbers to add
numbers_a:
    .word 32768    ; -32768
    .word 32769    ; -32767
    .word 49152    ; -16384
    .word 65531    ;     -5
    .word 65535    ;     -1
    .word 5        ;      5
    .word 16384    ;  16384
    .word 32767    ;  32767

    ; Table B of numbers to add
numbers_b:
    .word 65535    ;     -1
    .word 65531    ;     -5
    .word 49152    ; -16384
    .word 5        ;      5
    .word 6        ;      6
    .word 10       ;     10
    .word 16384    ;  16384
    .word 1        ;      1

push_character:
    pha            ; Store digit to add on stack
    ldy #0         ; Start at index 0
digit_loop:
    lda message,y  ; Get digit at index
    tax            ; Store in x register as temp value
    pla            ; Get digit off stack
    sta message,y  ; Store digit on stack at index
    iny            ; Increment index
    txa            ; Store temp value digit on stack
    pha
    bne digit_loop ; If not null character, continue loop
    pla            ; Pull null character from stack
    sta message,y  ; Put null character on end of string
    rts

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

irq:
    pha            ; Store value in accumulator on stack
    txa            ; Store value in x register on stack
    pha
    tya            ; Store value in y register on stack
    pha

    lda current    ; Load current number pointer value
    clc            ; Clear carry bit
    adc #2         ; Increment pointer by 2, as numbers are 2 bytes each
    and #%00001111 ; Wrap around after 15 (e.g. 16 becomes 0)
    sta current    ; Update current number pointer value

    ldy #$ff       ; Add debounce delay of 131.072ms @ 1MHz
irq_outer_delay:
    ldx #$ff
irq_inner_delay:
    dex
    bne irq_inner_delay
    dey
    bne irq_outer_delay
    bit PORTA      ; Read port A to clear interrupt; use 'bit' to avoid
                   ; updating accumulator value
    pla            ; Restore y register value
    tay
    pla            ; Restore x register value
    tax
    pla            ; Restore accumulator value
    rti

    .org $fffc
    .word reset
    .word irq