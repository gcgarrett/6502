# rand
Implements a pseudo-random number generator for the [6502 machine from Ben Eater](https://eater.net/6502). Pushing the [button](https://youtu.be/oOYA-jsWTmc?si=c8B5LPQbzB7_M48G) will generate a new 16-bit integer value. The generator is a [linear-feedback shift register](https://en.wikipedia.org/wiki/Linear-feedback_shift_register) implemented using shifts and XOR operations. The seed value is 1729. The random value is displayed in decimal format on the display.

To compile the code I used VASM with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir rand.asm
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
