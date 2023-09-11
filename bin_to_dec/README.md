# bin_to_dec
Prints the binary or decimal representation of the number 1729 to the display in the [6502 machine from Ben Eater](https://eater.net/6502). Pressing the [button](https://youtu.be/oOYA-jsWTmc?si=c8B5LPQbzB7_M48G) will toggle between the two representations.

To compile the code I used VASM with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir hello.asm
```

To run the code you'll need the 6502 machine with the architecture Ben Eater laid out with the following memory address mappings:
- $0000-$3FFF: RAM
- $6000      : VIA Port B - LCD screen data
- $6001      : VIA Port A - LCD screen flags
- $6002      : VIA Data Direction Register for Port B
- $6003      : VIA Data Direction Register for Port A
- $600c      : VIA peripheral control register
- $600d      : VIA interrupt flag register
- $600e      : VIA interrupt enable register
- $8000-$FFFF: ROM
