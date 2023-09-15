PORTB = $6000      ; Map VIA data port B to $6000
PORTA = $6001      ; Map VIA data port A to $6001
DDRB  = $6002      ; Map VIA data direction register B to $6002
DDRA  = $6003      ; Map VIA data direction register A to $6003
PCR   = $600c      ; Map VIA peripheral control register to $600c
IFR   = $600d      ; Map VIA interrupt flag register to $600d
IER   = $600e      ; Map VIA interrupt enable register to $600e

rand    = $0200    ; 2 bytes - Stores the random value
temp    = $0202    ; 2 bytes - Stores temp value used in calculations
value   = $0204    ; 2 bytes - Stores value to display
mod10   = $0206    ; 2 bytes - Used in converting binary to decimal
message = $0208    ; 6 bytes - Message buffer, null terminated

E  = %10000000     ; LCD enable (E) flag bit
RW = %01000000     ; LCD read/write (RW) flag bit
RS = %00100000     ; LCD register select (RS) flag bit

FIRST  = 7         ; Shift right first by 7
SECOND = 9         ; Shift left second by 9
THIRD  = 13        ; Shift right third by 13

    .org $8000     ; Start ROM code at $8000

reset:
    ; Initialize the stack pointer to 0x01FF
    ldx #$ff
    txs
    ; Clear interrupt disabled bit
    cli

    ; Initialize the VIA to interrupt processor when CA1 goes low
    lda #%10000010  ; Enable CA1
    sta IER
    lda #%00000000  ; Interrupt on negative edge (transition from high to low)
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

    ; Initialize value with seed
    lda seed
    sta rand
    lda seed + 1
    sta rand + 1

redraw:
    lda #%00000010  ; Return cursor to home on display (overwrites display)
    jsr send_lcd_instruction
    lda #%00000001  ; Clear the display
    jsr send_lcd_instruction

    lda #0
    sta message

    sei           ; Disable interrupts while we load current random value
    lda rand      ; Store low byte of rand into value for display
    sta value
    lda rand + 1  ; Store high byte of rand into value for display
    sta value + 1
    cli           ; Re-enable interrupts

   ; Program flow to print the value in decimal
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
    jsr push_digit

    ; if value is not zero, continue conversion to decimal
    lda value
    ora value + 1
    bne to_dec

print_number:
    ; Print converted number
    ldx #0          ; Start at index 0
loop_message:
    lda message,x   ; Load next character in message
    beq end        ; If null character we are done
    jsr send_lcd_character
    inx             ; Increment index
    jmp loop_message

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

seed: .word 1729   ; Seed is fixed at 1729

push_digit:
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

shift_right:
    lda rand        ; Load low byte of current rand into low byte of temp
    sta temp
    lda rand + 1    ; Load high byte of current rand into high byte of temp
    sta temp + 1
shift_right_loop:
    clc             ; Clear carry flag, we don't want to rotate in a 1 bit from the low byte
    ror temp + 1    ; Rotate high byte right
    ror temp        ; Rotate low byte right
    dex             ; Decrement x; if not 0, loop again
    bne shift_right_loop
    lda rand        ; XOR low byte of current rand with low byte of temp
    eor temp
    sta rand
    lda rand + 1    ; XOR high byte of current rand with high byte of temp
    eor temp + 1
    sta rand + 1
    rts

shift_left:
    lda rand        ; Load low byte of current rand into low byte of temp
    sta temp
    lda rand + 1    ; Load high byte of current rand into high byte of temp
    sta temp + 1
shift_left_loop:
    clc             ; Clear carry flag, we don't want to rotate in a 1 bit from the low byte
    rol temp        ; Rotate low byte left
    rol temp + 1    ; Rotate high byte left
    dex             ; Decrement x; if not 0, loop again
    bne shift_left_loop
    lda rand        ; XOR low byte of current rand with low byte of temp
    eor temp
    sta rand
    lda rand + 1    ; XOR high byte of current rand with high byte of temp
    eor temp + 1
    sta rand + 1
    rts

irq:
    pha               ; Store value in accumulator on stack
    txa               ; Store value in x register on stack
    pha
    tya               ; Store value in y register on stack
    pha
    ldx #FIRST        ; Perform first shift and XOR
    jsr shift_right
    ldx #SECOND       ; Perform second shift and XOR
    jsr shift_left
    ldx #THIRD        ; Perform third shift and XOR
    jsr shift_right
    ldy #$ff          ; Add debounce delay of 131.072ms @ 1MHz
irq_outer_delay:
    ldx #$ff
irq_inner_delay:
    dex
    bne irq_inner_delay
    dey
    bne irq_outer_delay
    bit PORTA       ; Read port A to clear interrupt; use 'bit' to avoid
                    ; mucking up the accumulator
    pla             ; Restore y value
    tay
    pla             ; Restore x value
    tax
    pla             ; Restore accumulator value
    rti

    .org $fffc
    .word reset
    .word irq