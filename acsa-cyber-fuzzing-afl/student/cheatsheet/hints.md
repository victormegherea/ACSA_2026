# Hints — Software Fuzzing with AFL++

Use these hints progressively — try each level yourself before revealing the next one. If you're still stuck after working through both tracks' hints, ask your instructor for further guidance.

---

## 🔧 Tool Reference

| Tool | What it does | Install if missing | Example usage |
|------|---------------|---------------------|---------------|
| **afl-fuzz** | Coverage-guided fuzzer | `sudo apt install afl++` | `afl-fuzz -i seeds -o out -- ./target @@` |
| **afl-clang-fast** | Compiler wrapper that instruments the target for AFL++ | Bundled with AFL++ | `afl-clang-fast -g -O1 -o target target.c` |
| **afl-tmin** | Shrinks a crashing input to its minimal form | Bundled with AFL++ | `afl-tmin -i crash -o crash.min -- ./target @@` |
| **gdb** | Interactive debugger for crash triage | `sudo apt install gdb` | `gdb --args ./target crash_file` |
| **nm / objdump** | List symbols / disassemble a binary | `sudo apt install binutils` | `nm ./vuln_hard \| grep FUNCTION_NAME` |

---

## Medium Track

<details>
<summary>Level 1 — Getting started</summary>

- Build the target with an AFL++ compiler wrapper (`afl-clang-fast` or `afl-clang-lto`), not plain `gcc` — AFL++ needs the instrumentation to see code coverage.
- Look at `build.sh` — it already sets up a small starter seed corpus in `seeds/`. A good seed corpus helps the fuzzer get moving faster.
- `afl-fuzz -i <seeds_dir> -o <out_dir> -- <target> @@` — the `@@` is replaced by AFL++ with the path to each generated input file.

</details>

<details>
<summary>Level 2 — What is the fuzzer actually looking for?</summary>

- Read the source. There's a nested chain of checks against specific byte values. Each correct byte "unlocks" a new `puts(...)` call.
- That's not an accident — nested checks against fixed values are exactly the kind of structure coverage-guided fuzzing is good at: each partial match is *new coverage*, which AFL++ rewards and keeps in its queue.
- Watch the `afl-fuzz` UI — the "paths found" / "edges found" counters going up as your fuzzer runs is a sign it's making progress through those stages.

</details>

<details>
<summary>Level 3 — Found a crash, now what?</summary>

- Crashing inputs land in `out/default/crashes/`. Just run the target directly against one of those files — no special tooling needed.
- Read the full program output, not just the crash message — something gets printed *before* the crash.

</details>

---

## Hard Track (Expert)

<details>
<summary>Level 1 — Building and fuzzing</summary>

- This target needs AddressSanitizer to reliably catch its bug — fuzz the `vuln_hard_asan` binary with `AFL_USE_ASAN=1` set. The separate `vuln_hard` binary is reserved for replaying the final controlled exploit because ASan aborts before the overwritten function pointer can run.
- Without ASan, this same bug might silently corrupt memory without crashing at all, or crash somewhere confusing far from the actual bug.

</details>

<details>
<summary>Level 2 — Understanding the crash</summary>

- Read the ASan crash report carefully — it tells you the allocation size, the access size, and roughly where the corruption happened relative to a heap chunk. What kind of chunk is it corrupting?
- The source reads a length byte from the file, then uses it directly as a copy length into a fixed-size buffer with no bounds check. What's the maximum value a single byte can hold, versus the buffer's actual size?

</details>

<details>
<summary>Level 3 — From crash to exploit</summary>

- The program allocates two things on the heap, back to back, before the vulnerable copy happens. What's stored in the second allocation, and could overflowing into it change what the program does next?
- The second allocation holds function pointers that get called later. If you could control the bytes that land there, what would you put there instead?
- `nm` or `objdump -t` can list every function in the binary, including ones never called directly by any visible code path. Is there a function that looks like it prints something interesting?
- The build uses `-no-pie` specifically so this function's address is fixed and doesn't change between runs — that's a big hint about what your final payload needs to contain.

</details>

<details>
<summary>Level 4 — Crafting the final input (last resort!)</summary>

- Your input needs: a length byte large enough to reach past the intended 16-byte field and into the function pointer table, followed by filler bytes, followed by the target function's address encoded as raw bytes in the right byte order for your CPU.
- Getting the exact overflow distance right requires knowing (or measuring, e.g. with gdb watchpoints) the gap between the two allocations — this is *not* something AFL++'s random mutations will reliably stumble into on their own.
- Python is the easiest way to build a precise binary file: pack a length byte, filler bytes, then a little-endian 8-byte address.

</details>

---

## 📚 Reference

- [AFL++ documentation](https://aflplus.plus/)
- [AFL++ GitHub](https://github.com/AFLplusplus/AFLplusplus)
- [COVESA dlt-daemon](https://github.com/COVESA/dlt-daemon) — real-world bonus fuzzing target

---

*Still stuck? Ask your instructor for a targeted hint — they're here to help!*
