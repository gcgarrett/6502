# all_characters

Prints all of the possible characters for the `HD44780U` display of the [6502 machine from Ben Eater](https://eater.net/6502). The characters are displayed one at a time, and each character will automatically transition to the next one after a fixed amount of time. Through this exercise I discovered that I had ROM code A00 of the LCD, so it displays a modified set of ASCII characters ($20-$7F) and Japanese katakana characters ($A0-$FF).

## compilation
To compile the code use [VASM](http://sun.hasenbraten.de/vasm/) with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir all_characters.asm
```

## memory address mapping
To run the code you'll need the 6502 machine architecture Ben Eater laid out with the following memory address mappings:
- $0000-$3FFF: RAM
- $6000      : VIA Port B - LCD screen data
- $6001      : VIA Port A - LCD screen flags
- $6002      : VIA Data Direction Register for Port B
- $6003      : VIA Data Direction Register for Port A
- $600c      : VIA peripheral control register
- $600d      : VIA interrupt flag register
- $600e      : VIA interrupt enable register
- $8000-$FFFF: ROM