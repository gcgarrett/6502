toggler:
  LDA #$0a     ; load set bits (hex 0x0a) into accumulator
  STA $00      ; store accumulator value to zero-page memory location 0x00
  LDA #$05     ; load toggle bits mask (hex 0x05) into accumulator
  STA $01      ; store accumulator value to zero-page memory location 0x01
  LDA $00      ; load set bits into accumulator
  AND $01      ; and set bits with toggle bits mask
  BEQ toggle   ; if result is 0, then bits are not set
untoggle:
  LDA #$ff     ; load 0xff into accumulator
  EOR $01      ; exclusive or (XOR) with toggle bits, setting them to zero
  AND $00      ; and the result with the set bits to toggle off
  JMP end      ; jump to the end
toggle:
  LDA $00      ; load the set bits into the accumulator
  ORA $01      ; or (OR) them with the toggle bits mask to toggle on
end:
  STA $00      ; store the updated set bits into zero-page memory location 0x00
  RTS          ; return
