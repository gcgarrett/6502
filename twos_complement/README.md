# twos_complement
Prints the decimal representation of a 16-bit signed integer to the display in the [6502 machine from Ben Eater](https://eater.net/6502). Pressing the [button](https://youtu.be/oOYA-jsWTmc?si=c8B5LPQbzB7_M48G) will select the next number in the list or wrap around back to the first number. Negative numbers are represented using the two's complement method, giving a range of -32768 to 32767.

The 16 numbers are:
- -32768
- -32767
- -32766
- -21845
- -16384
- -1000
- -5
- -1
- 0
- 1
- 5
- 1000
- 16384
- 21845
- 32766
- 32767

To compile the code I used VASM with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir twos_complement.s
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
