# toggler
Got this challenge from the NES Hacker Bitwise logic crash course video (see: https://www.youtube.com/watch?v=6tNSxabHqRI). I wrote it in C first, to refamilarize myself with bitwise logic, then tried my hand at writing it in 6502 assembly. The set bits, which would be, for instance, the power ups the user has, are stored in memory location 0x00. The mask that we use to toggle features on/off are stored in memory location 0x01.

I tested this code using the Easy 6502 emulator found here: https://skilldrick.github.io/easy6502/.
