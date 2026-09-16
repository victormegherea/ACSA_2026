# Software Fuzzing with AFL++

## Background

Fuzzing feeds a program huge numbers of automatically generated/mutated inputs, watching for crashes. **Coverage-guided** fuzzers like AFL++ go further: they instrument the target at compile time so the fuzzer can see which code paths ("edges") each input exercises, and reward inputs that reach *new* code — turning a blind random search into a guided one.

You're given two vulnerable C programs. Each reads a file and does something unsafe with its contents. Your job: fuzz them, find a crashing input, and figure out what it takes to get the flag.

**Provided files** (see `challenge_files/`):
- `medium/vuln_medium.c` + `build.sh`
- `hard/vuln_hard.c` + `build.sh`

## Track 1 — Medium

A single vulnerable program with a classic overflow bug. AFL++'s coverage feedback is enough to find the crashing input on its own — no manual exploitation required. Your job is to:
1. Build it with AFL++ instrumentation
2. Fuzz it until you get a crash
3. Replay the crash and read what it prints

## Track 2 — Hard (Expert)

A heap-based overflow that corrupts a function pointer. AFL++ (with ASan) will find a *crash* — but the crash alone won't give you the flag. You'll need to:
1. Fuzz it and get AFL++ to report a crash
2. Understand *why* it crashed (ASan report / gdb)
3. Figure out what the corrupted function pointer could be redirected to
4. Hand-craft an input that redirects execution there

## Bonus Track — Real-World Fuzzing (Expert, open-ended)

If you finish both tracks with time to spare, try AFL++ against the public [COVESA dlt-daemon](https://github.com/COVESA/dlt-daemon) project (the same kind of automotive logging daemon that's been fuzzed in real CTF sessions before). No flag here — the goal is the experience of pointing AFL++ at a real, unfamiliar codebase and seeing what it finds. Ask your instructor for pointers if you want a specific starting function.

## Learning Objectives

- Coverage-guided fuzzing concepts and the AFL++ workflow
- Building instrumented binaries (`afl-clang-fast`)
- Seed corpus design and why "fuzzer-friendly" checks matter
- Crash triage: reading ASan reports, using gdb on a crashing input
- The difference between finding a crash and building a working exploit
- Applying fuzzing to a real open-source project

---
*Need a hint? Check `../cheatsheet/hints.md`. Still stuck? Ask your instructor.*
