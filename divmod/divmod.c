#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

// global carry flag
bool CARRY = false;
// 16 bit high bit mask
static const uint16_t HIGH_BIT_MASK = 0x8000;

// struct with divmod result, the quotient and remainder
struct qr {
    uint16_t quotient;
    uint16_t remainder;
};

/**
 * Method to clear the global carry flag
 */
void clc() {
    CARRY = false;
}

/**
 * Method to set the global carry flag
 */
void sec() {
    CARRY = true;
}

/**
 * Method to rotate the value left by 1 bit, adding 1 if the carry flag is set,
 * and setting the carry flag if the high bit (the bit being rotated out) is a
 * 1 or clearing it if the high bit is 0.
 *
 * parameters
 *   value (uint16_t *): pointer to the unsigned 16 bit integer to rotate left
 */
void rol(uint16_t *value) {
    // if carry is set, add 1 to the value, else add 0
    uint16_t shiftIn = CARRY ? 1 : 0;

    // set the carry flag if the high bit is 1, otherwise clear it
    (((*value) & HIGH_BIT_MASK) == HIGH_BIT_MASK) ? sec() : clc();

    // update value, shifting it left by 1 and adding the shift in value
    (*value) = ((*value) << 1) + shiftIn;
}

/**
 * Implementation of Python's `divmod` function, which calculates the quotient
 * and remainder of the given dividend and divisors. Uses the algorithm I hope
 * to implement in 6502 assembly, hence why only shifts and subtractions are
 * used to calculate the answer.
 *
 * parameters
 *   dividend (uint16_t): The unsigned 16 bit integer dividend value
 *   divisor  (uint16_t): The unsigned 16 bit integer divisor value
 *
 * returns
 *   (struct qr):         The struct containing the calculated quotient and
 *                        remainder values, both unsigned 16 bit integers
 */
struct qr divmod(uint16_t dividend, uint16_t divisor) {
    // initialize remainder to 0
    uint16_t remainder = 0;
    // initialize quotient to dividend
    uint16_t quotient = dividend;

    // clear the carry flag
    clc();

    // iterate over all 16 bits of the unsigned integers
    for (uint8_t i = 0; i < 16; i++) {
        // rotate quotient left
        rol(&quotient);
        // rotate remainder left, rotating the high bit of the quotient in
        rol(&remainder);

        // if remainder is greater than the divisor, we want to set remainder
        // to remainder - divisor and set the carry flag; else clear the carry
        // flag. this mimics the 6502 algorithm, which subtracts the divisor
        // from the remainder; if a borrow occurred (e.g. divisor > remainder)
        // then the carry flag is cleared and we want to skip setting the
        // remainder to the result of the subtraction; if a borrow did not
        // occur (e.g. divisor <= remainder) then the carry flag is set.
        if (remainder >= divisor) {
            remainder = remainder - divisor;
            sec();
        }
        else {
            clc();
        }
    }

    // rotate the carry value into the quotient
    rol(&quotient);

    // set values in the result
    struct qr result = {.quotient = quotient, .remainder = remainder};

    return result;
}

int main() {
    uint16_t dividend = 95;
    uint16_t divisor = 7;

    struct qr result = divmod(dividend, divisor);

    printf("Quotient is: %" PRIu16 "\n", result.quotient);
    printf("Remainder is: %" PRIu16 "\n", result.remainder);

    return 0;
}
