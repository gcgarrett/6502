# hello
Prints "Hello 6502!" to the display in the [6502 machine from Ben Eater](https://eater.net/6502). The Japanese version prints "ハロー・ワールド!"

To compile the code I used VASM with the following flags:
```
vasm6502_oldstyle -Fbin -dotdir hello.asm
```
or
```
vasm6502_oldstyle -Fbin -dotdir hello_japanese.asm
```


To run the code you'll need the 6502 machine with the architecture Ben Eater laid out with the following memory address mappings:
- $0000-$3FFF: RAM
- $6000      : VIA Port B - LCD screen data
- $6001      : VIA Port A - LCD screen flags
- $6002      : VIA Data Direction Register for Port B
- $6003      : VIA Data Direction Register for Port A
- $8000-$FFFF: ROM
