/* SPDX-License-Identifier: BSD-2-Clause */

/* Change random bytes
   Usage: ./fuzzing INPUT_FILE OUTPUT_FILE SEED_VALUE CHANGE_PROB_X CHANGE_PROB_Y IGNORE_SYNC_BYTE
       SEED_VALUE is used for reproducibility
       IGNORE_SYNC_BYTE might be 0 or 1. If set to 1 then every 188 byte is ignored
       Probability of changing packet is CHANGE_PROB_X/CHANGE_PROB_Y, by default 1/1000
*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// xorisho256++ code from https://prng.di.unimi.it/xoshiro256plusplus.c
static uint64_t s[4];
static inline uint64_t rotl(const uint64_t x, int k)
{
    return (x << k) | (x >> (64 - k));
}
uint64_t rand_next(void)
{
    const uint64_t result = rotl(s[0] + s[3], 23) + s[0];
    const uint64_t t = s[1] << 17;
    s[2] ^= s[0];
    s[3] ^= s[1];
    s[1] ^= s[2];
    s[0] ^= s[3];
    s[2] ^= t;
    s[3] = rotl(s[3], 45);
    return result;
}
// end of xorisho256++

#define BUF_SIZE 65536
#define MPEGTS_SIZE 188
int main(int argc, char *argv[])
{
    // get args or assign default values
    char *in_fname = "in.ts", *out_fname = "out.ts";
    char *seed_s = "1", *change_prob_x_s = "1", *change_prob_y_s = "1000";
    char *ignore_sync_byte_s = "1";
    if (argc > 1)
        in_fname = argv[1];
    if (argc > 2)
        out_fname = argv[2];
    if (argc > 3)
        seed_s = argv[3];
    if (argc > 4)
        change_prob_x_s = argv[4];
    if (argc > 5)
        change_prob_y_s = argv[5];
    if (argc > 6)
        ignore_sync_byte_s = argv[5];

    // opens source and destination files
    FILE *src, *dst;
    src = fopen(in_fname, "r");
    if (src == NULL)
        return 2;
    dst = fopen(out_fname, "w");
    if (dst < 0)
        return 3;

    // seed random generator
    s[0] = (uint64_t)atoi(seed_s);
    s[3] = 1; //if seed_s is 0, then xorish256++ doesn't work so we need to seed something

    // parse probability of change. probability is change_prob/CHANGE_DENOM
    uint64_t change_prob_x = (uint64_t)atoi(change_prob_x_s);
    uint64_t change_prob_y = (uint64_t)atoi(change_prob_y_s);
    // parse sync byte ignoring
    int ignore_sync_byte = atoi(ignore_sync_byte_s);

    // main loop: read from input, change random bytes and write
    uint8_t buf[BUF_SIZE];
    size_t global_counter = 0; // input ts packet number
    while (1)
    {
        size_t in_size = fread(buf, 1, BUF_SIZE, src);
        if (in_size == 0) // assume no errors on read so 0 means EOF
            break;

        for (size_t i = 0; i < in_size; i++)
        {
            if (ignore_sync_byte && ((global_counter++ % MPEGTS_SIZE) == 0))
                continue;

            uint64_t rnd = rand_next();
            if ((rnd % change_prob_y) < change_prob_x) // main condition: check if random value is less than probability
            {
                buf[i] = rnd % 256; // assign some random value from 0 to 255
            }
        }

        // write modified data
        if (fwrite(buf, 1, in_size, dst) < in_size)
            return 4; // return error if data is not writted or writted partially
    }

    return 0;
}