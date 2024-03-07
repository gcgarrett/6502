# addition
Prints the decimal representation of the sum of two 16-bit signed integers to the display in the [6502 machine from Ben Eater](https://eater.net/6502). Pressing the [button](https://youtu.be/oOYA-jsWTmc?si=c8B5LPQbzB7_M48G) will select the next numbers in the two lists or wrap around back to the beginning of the lists. Negative numbers are represented using the two's complement method, giving a range of -32768 to 32767. Sums that result in a value outside the range will print an error message, "Out of bounds".

## numbers
The two lists consist of 8 numbers each.

List A:
- -32768
- -32767
- -16384
- -5
- -1
- 5
- 16384
- 32767

List B:
- -1
- -5
- -16384
- 5
- 6
- 10
- 16384
- 1

The expected results are:
- Out of bounds
- Out of bounds
- -32768
- 0
- 5
- 15
- Out of bounds
- Out of bounds

## compilation
To compile the code I used VASM with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir addition.asm
```

## memory address mapping
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
