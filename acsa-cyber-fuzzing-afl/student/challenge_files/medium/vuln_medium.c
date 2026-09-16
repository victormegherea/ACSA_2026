/*
 * ACSA 2026 Academy — Software Fuzzing Lab (Medium Track)
 * ---------------------------------------------------------
 * Usage:   ./vuln_medium <input_file>
 *
 * Build for fuzzing (AFL++ instrumentation):
 *   afl-clang-fast -g -O1 -o vuln_medium vuln_medium.c
 *
 * Build a plain debug copy for manual testing:
 *   gcc -g -O0 -o vuln_medium_debug vuln_medium.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

/* buf and magic are guaranteed adjacent in memory (struct field order). */
static struct {
    char buf[64];
    unsigned char magic[4];
} g;

/* Small lookup table placed right after g in the binary's data/bss. */
static volatile int lut[4] = {10, 20, 30, 40};

static void print_flag(void) {
    static const unsigned char encoded[] = {
        0x1B, 0x19, 0x09, 0x1B, 0x68, 0x6A, 0x68, 0x6C, 0x21, 0x39,
        0x6A, 0x2C, 0x69, 0x28, 0x6E, 0x3D, 0x69, 0x05, 0x3D, 0x2F,
        0x6B, 0x3E, 0x69, 0x3E, 0x05, 0x3C, 0x2F, 0x20, 0x20, 0x6B,
        0x34, 0x3D, 0x05, 0x2D, 0x6A, 0x28, 0x31, 0x29, 0x27
    };
    fputs("\n[FLAG] ", stdout);
    for (size_t i = 0; i < sizeof(encoded); i++) {
        putchar(encoded[i] ^ 0x5A);
    }
    fputs("\n\n", stdout);
    fflush(stdout);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror("fopen"); return 1; }

    memset(&g, 0, sizeof(g));

    /* VULNERABILITY: reads sizeof(g) bytes (buf + magic) straight from the
     * file with no validation of what ends up in g.magic. A real program
     * should only ever read sizeof(g.buf) bytes here. */
    fread(g.buf, 1, sizeof(g), f);
    fclose(f);

    if (g.magic[0] == 0x41) {
        puts("[*] stage 1 unlocked");
        if (g.magic[1] == 0x42) {
            puts("[*] stage 2 unlocked");
            if (g.magic[2] == 0x43) {
                puts("[*] stage 3 unlocked");
                if (g.magic[3] == 0x44) {
                    puts("[*] stage 4 unlocked");
                    print_flag();

                    /* VULNERABILITY: g.magic[0] (0x41 = 65) is used directly
                     * as an index into a 4-element array with no bounds
                     * check, corrupting memory well past the end of lut[]. */
                    lut[g.magic[0]] = 0x1337;

                    /* Keep the lab's crash-after-flag behavior consistent
                     * across compilers and memory layouts.  The out-of-bounds
                     * write above is still the bug students should explain;
                     * this explicit abort only makes AFL++'s crash signal
                     * deterministic once the full magic value is reached. */
                    raise(SIGABRT);
                }
            }
        }
    }

    return 0;
}
