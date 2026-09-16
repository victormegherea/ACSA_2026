# Automotive Cybersecurity — Instructor Guide
## Software (Coverage-Guided) Fuzzing with AFL++

## Overview

This lab teaches **coverage-guided fuzzing** with [AFL++](https://aflplus.plus/). Students compile a small vulnerable C program with AFL++'s instrumenting compiler, fuzz it to find a crashing input, then analyze the crash to recover a flag.

This lab is inspired by the COVESA Software Fuzzing CTF session (Nov 2025), which fuzzed both artificial challenges and real bugs in the [COVESA dlt-daemon](https://github.com/COVESA/dlt-daemon) project. It is **not** a copy of that session's materials — this is original content built for the ACSA 2026 Academy, using the same general workflow (intro → AFL++ basics → hands-on fuzzing → crash triage) as a reference structure.

**Two tracks, so students can pick their level:**
- **Medium** — a single self-contained C program with a classic stack-adjacent overflow. AFL++'s coverage feedback alone can find the crashing input in a normal lab session.
- **Hard (expert)** — a heap-based overflow that corrupts a function pointer. AFL++ (`vuln_hard_asan`) finds the *crash*, but reaching the flag requires manually reverse-engineering the crash and hand-crafting the final payload for the separate non-ASan replay binary (`vuln_hard`).
- **Bonus (open-ended, expert only)** — point strong teams at the real, public [COVESA dlt-daemon](https://github.com/COVESA/dlt-daemon) repo and have them try to (re)discover a known historical bug class using AFL++. No proprietary materials are used or required — everything needed is public upstream.

---

## Folder Contents

```
instructor/
├── README.md          ← This file
├── lesson-fuzzing-20min.md ← 20-minute instructor lesson
├── deep-explanation.md ← Deep technical design and teaching notes
├── solution.md         ← Full solution for both tracks + bonus
├── linux-validation-report.md ← Linux smoke-test checklist
├── step-by-step.md     ← Instructor-only walkthrough
└── setup/
    └── vm-setup.sh      ← Installs AFL++, clang, gdb, build tools
```

---

## VM Build Instructions

Run `sudo bash ./setup/vm-setup.sh` on the lab VM (same Ubuntu 26.04 LTS base as the other labs), then verify with `fuzzing-start`.

---

## Required Tools (installed by vm-setup.sh)

| Tool | Purpose | Install |
|------|---------|---------|
| **AFL++** (`afl-fuzz`, `afl-clang-fast`/`afl-clang-lto`, `afl-cmin`, `afl-tmin`) | Coverage-guided fuzzer + instrumenting compiler | `apt install afl++` (falls back to building from source) |
| **clang / llvm** | Required by AFL++'s LLVM-mode instrumentation | `apt install clang llvm` |
| **gdb** | Crash triage / manual exploitation (hard track) | `apt install gdb` |
| **gcc / build-essential** | Fallback compiler, general builds | `apt install build-essential` |
| **binutils** (`objdump`, `nm`, `readelf`) | Inspect binaries, find function addresses | `apt install binutils` |
| **ASan** (`libclang_rt.asan`) | Detects heap corruption precisely (hard track) | `apt install libclang-rt-dev` |

---

## Lab Day — Facilitation Guide

### Before the Lab
- [ ] Deliver the 20-minute introduction from `lesson-fuzzing-20min.md`
- [ ] Read `deep-explanation.md` for the medium/hard mechanics and troubleshooting model
- [ ] Run `vm-setup.sh` and confirm `afl-fuzz --help` and an AFL++ compiler wrapper (`afl-clang-fast` or `afl-clang-lto`) both work
- [ ] Pre-build both challenge binaries once yourself to confirm they compile cleanly on the lab VM
- [ ] Decide whether teams pick medium or hard, or all start medium and graduate to hard
- [ ] Prepare intro slides: what is coverage-guided fuzzing, AFL++ workflow (instrument → seed corpus → `afl-fuzz` → triage crashes)

### During the Lab

| Time | Activity | Facilitator role |
|------|----------|-------------------|
| 0–15 | Intro: fuzzing concepts, AFL++ workflow, edge coverage | Present, demo `afl-fuzz` running for 60 seconds on the medium binary |
| 15–20 | Teams build the medium challenge with `afl-clang-fast` | Help with build errors |
| 20–55 | Teams fuzz the medium challenge, find the crash, extract the flag | Circulate, ask guiding questions |
| 55–90 | Teams that finish early move to the hard challenge | Push them toward ASan + manual analysis, not more fuzzing |
| 90+ | (Optional, expert-only) Point strong teams at dlt-daemon for open-ended bonus fuzzing | Only for teams that finish both tracks |

### Guiding Questions (don't give answers — ask these instead)
- "How does AFL++ know an input is 'interesting' — what is it measuring?"
- "Your fuzzer found a crash — how do you turn that file into something you can debug?"
- "Why does the medium bug get found by fuzzing alone, but the hard one doesn't?"
- "If you didn't have ASan, how would this crash look different?"

### If a Team is Stuck
1. Point them to `cheatsheet/hints.md` first
2. Suggest re-checking their AFL++ instrumentation (build with `afl-clang-fast` or `afl-clang-lto`, not plain `gcc`)
3. For the hard track: suggest attaching `gdb` to the crash input directly instead of re-fuzzing
4. Last resort: `step-by-step.md` (in this instructor folder) has the full walkthrough — walk them through it verbally rather than handing it over

### If a Team Finishes Early
- Have them minimize their crashing input with `afl-tmin`
- Ask them to write a one-paragraph root-cause explanation of the bug (as if filing a real vulnerability report)
- Point them at the dlt-daemon bonus track

---

## Key Talking Points for Debrief

1. **Coverage-guided fuzzing finds inputs by rewarding new code paths**, not just crashes — that's why nested checks (like the medium challenge's staged magic bytes) are "fuzzer-friendly": each correct byte unlocks new coverage, guiding the search.
2. **Not all bugs are equally fuzzable.** The hard challenge's heap overflow crashes easily under ASan, but weaponizing it (function pointer hijack) requires the same manual RE skills used in the other labs — fuzzing finds the crash, humans find the exploit.
3. **Sanitizers change what "crash" means.** Without ASan, many heap bugs silently corrupt memory without an immediate crash — always fuzz with ASan when looking for memory-safety bugs.
4. **This mirrors real vulnerability research**: fuzzing narrows an enormous input space down to a handful of interesting test cases; the expensive human time is spent triaging those, not searching blindly.

---

## Answer Key Location

See `solution.md` in this folder for the full flags, exact commands, and root-cause explanation for both tracks.
