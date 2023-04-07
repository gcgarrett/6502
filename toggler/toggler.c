#include <stdio.h>
#include <stdint.h>

uint8_t toggle(uint8_t value, uint8_t mask) {
    if ((value & mask) == 0x00) {
        /* bits are not set, toggle them on */
        return value | mask;
    }
    else {
        /* bits are set, toggle them off */
        return value & ~mask;
    }
}

int main(void)
{
    uint8_t value = 0x0a;
    uint8_t mask = 0x05;
    uint8_t toggled = value;
    
    toggled = toggle(value, mask);
    
    printf("First toggle: 0x%02x\n", toggled);
    
    toggled = toggle(toggled, mask);
    
    printf("Second toggle: 0x%02x", toggled);
    return 0;
}
