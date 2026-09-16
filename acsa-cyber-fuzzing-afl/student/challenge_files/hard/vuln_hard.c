/*
 * ACSA 2026 Academy — Software Fuzzing Lab (Hard / Expert Track)
 * ------------------------------------------------------------------
 * Usage:   ./vuln_hard <input_file>
 *
 * Build for fuzzing (AFL++ instrumentation + ASan to catch heap corruption):
 *   afl-clang-fast -fsanitize=address -g -O0 -fno-stack-protector -no-pie \
 *       -o vuln_hard vuln_hard.c
 *
 * NOTE: the lab build uses -O0 so the intentionally invalid copy cannot be
 * optimized away under the C abstract machine's bounds assumptions.  -no-pie
 * is used so function addresses are static and predictable —
 * this is intentional for the lab (you'll need a real address later), not
 * something you'd ever do in production code.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[16];
} record_t;

typedef void (*handler_fn)(void);

/* Keep the handler symbols materialized in optimized builds so students can
 * inspect them with nm and use their addresses during replay. */
__attribute__((noinline, used)) static void normal_handler(void) {
    puts("[*] normal_handler() called - nothing to see here.");
}

/* Never called directly by any code path above it — only reachable if
 * something overwrites a function pointer to point here instead. */
__attribute__((noinline, used)) static void win(void) {
    static const unsigned char encoded[] = {
        0x1B, 0x19, 0x09, 0x1B, 0x68, 0x6A, 0x68, 0x6C, 0x21, 0x32,
        0x69, 0x6E, 0x2A, 0x05, 0x6A, 0x2C, 0x69, 0x28, 0x3C, 0x36,
        0x6A, 0x2D, 0x05, 0x2A, 0x2D, 0x34, 0x6F, 0x05, 0x3C, 0x2F,
        0x34, 0x39, 0x2E, 0x6B, 0x6A, 0x34, 0x05, 0x2A, 0x6A, 0x6B,
        0x34, 0x2E, 0x69, 0x28, 0x29, 0x27
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

    /* File format: 1 header byte = length of the "name" field that follows. */
    unsigned char len = 0;
    if (fread(&len, 1, 1, f) != 1) { fclose(f); return 0; }

    /* Two sequential heap allocations. With no prior heap activity, a
     * simple allocator commonly places them adjacently, making the
     * overflow below reliably reach the handlers[] chunk. */
    record_t *rec = malloc(sizeof(record_t));
    handler_fn *handlers = malloc(sizeof(handler_fn) * 2);
    if (!rec || !handlers) { fclose(f); return 1; }
    handlers[0] = normal_handler;
    handlers[1] = normal_handler;

    /* VULNERABILITY: len is fully attacker-controlled and used directly as
     * the copy length into rec->name (a 16-byte buffer), with no bounds
     * check against sizeof(rec->name). A large enough len overflows into
     * the adjacent handlers[] heap allocation. */
    if (fread(rec->name, 1, len, f) != (size_t)len) {
        fclose(f);
        free(rec);
        free(handlers);
        return 0;
    }
    fclose(f);

    handlers[0]();  /* Normally calls normal_handler(); can be hijacked. */

    /* A successful lab payload intentionally overwrites allocator metadata on
     * the way to handlers[0].  Returning here avoids turning a demonstrated
     * control-flow hijack into a libc-specific free() diagnostic. */
    if (handlers[0] == win) {
        return 0;
    }

    free(rec);
    free(handlers);
    return 0;
}
