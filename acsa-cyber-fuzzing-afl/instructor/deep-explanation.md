# ACSA 2026 Academy — Deep Instructor Explanation
## AFL++ Software Fuzzing Lab

This document explains the lab's technical design, intended learning progression, expected behavior, and troubleshooting model. It is instructor-only. Use it to teach the lab accurately and to distinguish a student mistake from a platform problem.

---

## 1. What This Lab Teaches

The lab is not primarily about discovering a secret string. It teaches a vulnerability-research workflow:

```text
model the input boundary
        |
        v
instrument the target
        |
        v
fuzz for new behavior
        |
        v
save and reproduce a finding
        |
        v
minimize and triage it
        |
        v
explain root cause and impact
```

The two tracks intentionally teach different limits of automation:

- **Medium:** coverage guidance is enough to reach the hidden behavior. Students see AFL++ make progress through staged checks and save the resulting crash.
- **Hard:** AFL++ finds the memory-safety failure, but manual analysis is required to turn the crash into controlled execution. Students must understand allocator layout, symbols, function pointers, address encoding, and the difference between an ASan diagnostic binary and an exploit-replay binary.

The central lesson is:

> Fuzzing is excellent at searching and discovering. It does not replace debugging, reverse engineering, or impact analysis.

---

## 2. The Fuzzing Model

A fuzzer repeatedly supplies inputs to a target and observes the result. In this lab, the target takes a filename:

```text
input file -> target process -> exit/output/coverage/crash
```

AFL++ adds a feedback loop:

```text
seed corpus
    |
    v
mutate a seed
    |
    v
run instrumented target
    |
    +--> new coverage? save input in queue
    +--> crash? save input in crashes/
    +--> timeout? save input in hangs/
    +--> nothing new? discard or continue mutation
```

### Important terms

- **Seed:** An initial input file. It does not need to be a complete solution; it gives the fuzzer a starting point.
- **Mutation:** A generated variation of an existing input. AFL++ changes bytes, sizes, arithmetic values, and structure patterns.
- **Instrumentation:** Compiler-added code that records control-flow behavior while the target runs.
- **Edge coverage:** A compact signal representing transitions between program locations. AFL++ uses this to distinguish inputs that execute different paths.
- **Queue:** Inputs that reached new or otherwise interesting coverage.
- **Crash:** An input that terminates abnormally, such as through `SIGABRT`, `SIGSEGV`, or a sanitizer abort.
- **Triage:** Reproducing a finding, minimizing it, identifying the root cause, and assessing impact.

AFL++ does not understand the meaning of a byte. It only knows that changing a byte caused the target to execute code it had not seen before.

---

## 3. Why Instrumentation Matters

A plain build may run correctly but provide no useful feedback:

```bash
gcc -g -O0 -o target target.c
```

The AFL++ build adds instrumentation:

```bash
afl-clang-fast -g -O1 -o target target.c
```

The instrumented executable reports coverage to AFL++ through shared memory. This is much faster than starting a separate analysis tool after every test case.

The student command is:

```bash
afl-fuzz -i seeds -o out -- ./target @@
```

The pieces mean:

- `-i seeds`: read initial inputs from `seeds/`.
- `-o out`: write queue entries, crashes, hangs, and session data to `out/`.
- `--`: end AFL++ options.
- `./target`: executable under test.
- `@@`: AFL++ replaces this token with the current generated input filename.

### What students should watch

- **Paths found / paths total:** whether the fuzzer is reaching new behavior.
- **Exec speed:** how many test cases are run per second.
- **Saved crashes:** whether reproducible abnormal exits have been found.
- **Stability:** whether the same input produces consistent coverage. Low stability can indicate nondeterminism, timing dependence, uninitialized data, or environmental noise.

A high execution speed is useful, but it is not the goal by itself. The goal is meaningful coverage and reproducible findings.

---

## 4. Medium Track: Coverage-Guided Discovery

### Input layout

The program defines a global object with two adjacent fields:

```c
static struct {
    char buf[64];
    unsigned char magic[4];
} g;
```

The vulnerable read is:

```c
fread(g.buf, 1, sizeof(g), f);
```

`sizeof(g)` is 68 bytes, but the destination expression begins at `g.buf`, whose declared size is 64 bytes. The first 64 bytes fill `buf`; the next four bytes fill `magic` because the fields are adjacent in the structure.

The intended fix in real software would be to read only the capacity of the
destination field and validate the result, for example:

```c
if (fread(g.buf, 1, sizeof(g.buf), f) != sizeof(g.buf)) {
    /* reject a truncated input */
}
```

The challenge deliberately leaves the four trailing bytes attacker-controlled because they drive the staged path.

### Coverage-friendly gates

The program checks the four bytes one at a time:

```c
if (magic[0] == 0x41) {
    if (magic[1] == 0x42) {
        if (magic[2] == 0x43) {
            if (magic[3] == 0x44) {
                print_flag();
                ...
            }
        }
    }
}
```

Each successful check reaches a new `puts` call and therefore produces new coverage. AFL++ is rewarded for keeping an input that reaches stage 1, then another that reaches stage 2, and so on.

This is why the medium challenge is suitable for teaching coverage guidance: students can see that AFL++ is not simply generating random files. It is preserving mutations that move deeper into the program.

### Why the crash occurs after the flag

After the four checks, the program performs:

```c
lut[magic[0]] = 0x1337;
```

`magic[0]` is `0x41`, or decimal 65, while `lut` has only four elements. This is an out-of-bounds write. The source then raises `SIGABRT` deliberately after printing the flag. The explicit abort makes the challenge's crash signal reproducible across compiler and allocator layouts; the out-of-bounds write remains the memory-safety bug students should explain.

The teaching point is that a crash and a flag can be part of the same finding, but the flag is not the vulnerability explanation. Students should be able to describe both:

1. The unchecked read makes the staged bytes controllable.
2. The unchecked array index causes an out-of-bounds write.
3. The explicit abort makes AFL++ save the fully unlocked input reliably.

### Expected medium workflow

```bash
cd ~/fuzzing-lab/challenge_files/medium
bash build.sh
afl-fuzz -i seeds -o out -- ./vuln_medium @@
```

After a crash appears:

```bash
ls -l out/default/crashes
./vuln_medium out/default/crashes/<crash_file>
afl-tmin -i out/default/crashes/<crash_file> \
    -o crash.min -- ./vuln_medium @@
```

The minimized input is valuable because it lets students inspect which bytes matter instead of staring at a large mutated file.

---

## 5. Hard Track: Discover First, Exploit Second

The hard track is intentionally split into two binaries:

| Binary | Purpose | Sanitizer |
|--------|---------|-----------|
| `vuln_hard_asan` | Fuzzing and memory-error discovery | AddressSanitizer enabled |
| `vuln_hard` | Manual controlled replay | ASan disabled, non-PIE |

This split is essential. ASan is excellent for detecting the invalid write, but it normally aborts at the write before the corrupted function pointer can be called. The non-ASan binary is reserved for demonstrating the later control-flow effect.

### Vulnerable data flow

The input format begins with one attacker-controlled length byte:

```text
byte 0: length L
bytes 1..L: name data
```

The program allocates:

```c
record_t *rec = malloc(sizeof(record_t));
handler_fn *handlers = malloc(sizeof(handler_fn) * 2);
```

`rec->name` is 16 bytes. The copy uses the untrusted length directly:

```c
fread(rec->name, 1, len, f);
```

There is no check that `len <= sizeof(rec->name)`. A length greater than 16 writes beyond `rec->name`.

The next allocation contains two function pointers:

```c
handlers[0] = normal_handler;
handlers[1] = normal_handler;
```

A sufficiently long input can overwrite bytes in that allocation. The later call:

```c
handlers[0]();
```

uses the overwritten pointer as a code address.

### Why ASan is used

Without a sanitizer, heap corruption may:

- appear to do nothing immediately,
- crash later in a different function,
- trigger allocator diagnostics during `free`, or
- behave differently across libc versions.

ASan turns the invalid write into a precise finding at the moment it occurs. Students should learn to read the report as evidence about the bug, not as the final exploit.

### Why ASan cannot be used for the final redirect

A successful overwrite requires the program to continue after the invalid write and call `handlers[0]`. ASan detects the invalid write and terminates the process first. Therefore:

```text
vuln_hard_asan -> discover and explain the heap overflow
vuln_hard      -> replay a deliberately crafted control-flow overwrite
```

### Why `-no-pie` is used

Position-independent executables randomize code addresses under ASLR. For an introductory exploit-development exercise, that adds a separate problem unrelated to fuzzing. The hard build uses `-no-pie` so students can inspect a stable `win()` address with:

```bash
nm ./vuln_hard | grep -E ' win$| normal_handler$'
```

This is a teaching simplification, not a recommended production compiler setting.

### Why the heap gap must be measured

The distance from the start of `rec` to `handlers` depends on allocator behavior, alignment, metadata, libc version, and build conditions. Students should measure it with GDB instead of blindly copying an example value:

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

Break on the vulnerable `fread` line, after both allocations have occurred. Inspecting the pointers at the beginning of `main` produces uninitialized values and an invalid gap. The pointer cast in `print/x (void *)win` makes GDB display the function address reliably. The exact source line may differ if the file changes, so use `list` and set the breakpoint on the local vulnerable `fread` line. One tested VM reported a 32-byte gap and `win()` at `0x402450`; those are local observations, not universal constants.

### Expected hard workflow

```bash
cd ~/fuzzing-lab/challenge_files/hard
bash build.sh
AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@
```

Replay an ASan finding with the ASan binary:

```bash
./vuln_hard_asan out/default/crashes/<crash_file>
```

Then inspect the non-ASan binary:

```bash
nm ./vuln_hard | grep -E ' win$| normal_handler$'
gdb ./vuln_hard
```

Students then craft an input containing:

1. A length byte large enough to reach the handler table.
2. Filler bytes up to `handlers[0]`.
3. The address of `win()` encoded in the platform's byte order.

The instructor should emphasize that randomly guessing a full pointer value is not a realistic fuzzing strategy. Fuzzing discovers the weakness; manual analysis supplies precision.

---

## 6. Why the Flags Are Runtime-Encoded

The student source contains encoded bytes rather than the literal flag strings. At runtime, the challenge decodes the bytes and prints the result only after the intended condition is reached.

This prevents a trivial solution such as:

```bash
grep -R ACSA2026 student/challenge_files
```

It does not provide cryptographic protection. Students can still reverse-engineer the decode operation if they choose. That is intentional: the goal is to make the fuzzing and control-flow behavior the first discovery path, not to claim that a toy XOR encoding is secure.

The instructor solution contains the expected flags and should remain outside the student distribution.

---

## 7. AFL++ Findings Are Not Vulnerability Reports

A saved file in `out/default/crashes/` answers only one question:

> Can this input make the target terminate abnormally under this build and environment?

A useful vulnerability report answers more:

- What input condition triggers the bug?
- Which source operation is unsafe?
- What memory or control data is affected?
- Is the behavior reproducible?
- Does the issue cause denial of service, information disclosure, or control-flow influence?
- Which mitigations detect or prevent it?
- What is the minimal reproducer?

Ask students to produce a short root-cause paragraph after each track. This prevents the lab from becoming a button-clicking exercise.

---

## 8. Linux Environment Requirements

The intended environment is Ubuntu/Linux with:

```bash
sudo apt install build-essential clang llvm libclang-rt-dev afl++ gdb binutils file tree
```

The `libclang-rt-dev` package matters for the hard build. Without it, Clang may instrument the source successfully but fail at link time with errors such as:

```text
cannot find libclang_rt.asan_static-x86_64.a
cannot find libclang_rt.asan-x86_64.a
```

The hard `build.sh` performs a small ASan link preflight and reports this dependency clearly.

### Shared-folder limitation

Do not run AFL++ directly from a VirtualBox shared folder such as `/media/sf_*`. AFL++ may fail to create queue files or hard links there:

```text
Unable to create out/default/queue/id:...
```

Copy the lab to a native Linux filesystem first:

```bash
mkdir -p ~/fuzzing-lab
cp -a /media/sf_share/acsa-cyber-fuzzing-afl/student/. ~/fuzzing-lab/
cd ~/fuzzing-lab/challenge_files/medium
```

If an old output directory is root-owned or partially created:

```bash
sudo rm -rf out
```

Then run AFL++ as the normal student user, not with `sudo`.

---

## 9. Common Instructor Diagnoses

### AFL++ refuses to start

Check:

```bash
command -v afl-fuzz
command -v afl-clang-fast || command -v afl-clang-lto
```

If the target is not instrumented, rebuild with `bash build.sh` and inspect the compiler output.

### The hard build fails at the linker

Install the runtime:

```bash
sudo apt install libclang-rt-dev
```

Then remove stale binaries and rebuild:

```bash
rm -f vuln_hard vuln_hard_asan
bash build.sh
```

### AFL++ cannot create queue files

Move off `/media/sf_*`, remove a root-owned `out/`, and rerun without `sudo`.

### No crashes appear

For medium, check that the target is instrumented and that the fuzzer is using the intended `@@` file placeholder. For hard, ensure the ASan binary is the target and `AFL_USE_ASAN=1` is set.

### The hard exploit works on one VM but not another

Do not assume the heap gap. Rebuild with the documented flags, measure the allocation addresses in GDB, and craft the payload for that VM.

### Students find the flag by reading the source

Check that they received the current student package and that the encoded flag bytes were not replaced by an older plaintext source copy.

---

## 10. Debrief: Security Engineering Lessons

Close the lab with these points:

1. Input validation must be based on destination capacity, not attacker-controlled length.
2. Coverage guidance makes deep conditional behavior discoverable without understanding every semantic rule.
3. Sanitizers are development and testing tools that make memory errors diagnosable.
4. A crash is a starting point for analysis, not proof of exploitability.
5. Reproducibility depends on build flags, allocator behavior, filesystem behavior, and runtime configuration.
6. Real automotive software needs harnesses, protocol-aware seeds, deterministic execution, and CI integration; a toy file parser is only the first step.
7. Fuzzing should be performed only against software and environments where the tester has authorization.
