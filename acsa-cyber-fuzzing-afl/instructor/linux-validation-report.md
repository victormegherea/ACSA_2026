# Linux Validation Report — ACSA 2026 AFL++ Lab

Use this checklist on the Ubuntu lab PC before distributing the lab. It records the current design, the checks already performed on Windows, and the Linux-only checks that require AFL++, Clang, ASan, and GDB.

## Current Status

| Area | Status | Notes |
|------|--------|-------|
| Lab structure | Pass | Instructor and student materials are separated; the full walkthrough is instructor-only. |
| Medium C source | Pass on Windows GCC | Compiled successfully with GCC 15.2.0. |
| Hard C source | Pass on Windows GCC without ASan | Compiled successfully without the sanitizer runtime. |
| Hard ASan build | Linux validation required | Windows MSYS2 GCC did not provide `libasan`; the intended Ubuntu/AFL++ build must be tested. |
| AFL++ instrumentation | Linux validation required | AFL++ is not available in the Windows workspace. |
| Student flag disclosure | Pass | Flag strings are not present as plaintext in the student C sources. |
| Script portability | Pass after setup | `vm-setup.sh` restores executable bits after copying from a Windows checkout. `bash build.sh` also works without executable bits. |
| Medium crash portability | Pass | The medium target raises `SIGABRT` after the flag path, so AFL++ receives a deterministic crash on every supported toolchain. |

## 1. Provisioning Check

From the lab VM or Linux checkout:

```bash
cd acsa-cyber-fuzzing-afl
sudo bash instructor/setup/vm-setup.sh
bash ~/fuzzing-lab/setup/lab-start.sh
```

Expected tool checks:

```text
afl-fuzz          found
afl-clang-fast (or afl-clang-lto)    found
afl-tmin         found
afl-cmin         found
gdb               found
objdump           found
nm               found
gcc               found
```

The VM setup should also report AFL++ versions and copy the student directory to:

```text
~/fuzzing-lab
```

If the shell scripts came from a Windows checkout, verify permissions:

```bash
find ~/fuzzing-lab -type f -name '*.sh' -not -perm -u+x -print
```

Expected result: no output.

## 2. Medium Track Build and Smoke Test

```bash
cd ~/fuzzing-lab/challenge_files/medium
bash build.sh
file vuln_medium
```

Expected result: an instrumented Linux executable named `vuln_medium`.

Run the known valid path directly to verify the flag mechanism:

```bash
printf '%064s' '' | tr ' ' 'A' > /tmp/medium-valid
printf '\x41\x42\x43\x44' >> /tmp/medium-valid
./vuln_medium /tmp/medium-valid
```

Expected output includes:

```text
[FLAG] ACSA2026{c0v3r4g3_gu1d3d_fuzz1ng_w0rks}
```

Then run AFL++:

```bash
afl-fuzz -i seeds -o out -- ./vuln_medium @@
```

Validation points:

- AFL++ recognizes the target as instrumented.
- The path/edge counters increase.
- The nested stages become reachable.
- A crash is found after the flag path. The target deliberately raises `SIGABRT` after the out-of-bounds write so this result is independent of the compiler and memory layout.

## 3. Hard Track Build and ASan Smoke Test

```bash
cd ~/fuzzing-lab/challenge_files/hard
bash build.sh
file vuln_hard_asan vuln_hard
```

Expected result: two Linux executables:

- `vuln_hard_asan`: AFL++-instrumented AddressSanitizer target for fuzzing.
- `vuln_hard`: non-ASan, non-PIE replay target for the controlled function-pointer overwrite. The hard build uses `-O0` so the intentionally invalid copy is not optimized away, and keeps `win()` available to `nm`.

Start fuzzing:

```bash
AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@
```

Replay a crash with the ASan target:

```bash
./vuln_hard_asan out/default/crashes/<crash_file>
```

Expected result: an AddressSanitizer heap-buffer-overflow report showing that the attacker-controlled length can write past the 16-byte `rec->name` allocation.

Important: do not use `vuln_hard_asan` for the final function-pointer exploit. ASan aborts at the invalid write before the overwritten pointer is called. Use `vuln_hard` for the controlled replay after measuring the heap layout and finding `win()` with `nm`.

## 4. Hard Track Manual Replay

Find the target function:

```bash
nm ./vuln_hard | grep -E ' win$| normal_handler$'
```

Measure the actual allocation gap with GDB. Do not assume the example gap in the walkthrough is universal; allocator and libc versions can change it.

After crafting the payload with the measured gap and `win()` address:

```bash
./vuln_hard exploit.bin
```

Expected output includes:

```text
[FLAG] ACSA2026{h34p_0v3rfl0w_pwn5_funct10n_p01nt3rs}
```

## 5. Student Disclosure Check

Run from the repository root:

```bash
grep -RInE 'ACSA2026\{[^}]+\}' \
    acsa-cyber-fuzzing-afl/student
```

Expected result: no output. Instructor materials may contain the answers;
the student package must not.

## 6. Cleanup Before Distribution

Do not distribute generated binaries, AFL++ output, crash files, or local seed mutations:

```bash
find acsa-cyber-fuzzing-afl/student -type f \( \
    -name 'vuln_medium' -o \
    -name 'vuln_hard' -o \
    -name 'vuln_hard_asan' -o \
    -name '*.exe' \
\) -delete
rm -rf acsa-cyber-fuzzing-afl/student/challenge_files/medium/out
rm -rf acsa-cyber-fuzzing-afl/student/challenge_files/hard/out
```

Keep only the source, build scripts, starter seeds, setup script, task, README, and hints in the student package.

## Linux Sign-Off Criteria

The lab is ready for delivery when all of these are true:

- `vm-setup.sh` completes without a required-tool failure.
- `lab-start.sh` reports all required tools.
- Both `bash build.sh` commands succeed.
- Medium's valid path prints its flag.
- AFL++ recognizes both instrumented targets.
- Hard ASan produces a heap-buffer-overflow report from a discovered crash.
- Hard non-ASan replay prints its flag with a measured, locally crafted payload.
- No expected flag appears in student-facing source or documentation.
- Generated binaries and fuzzing output are removed before distribution.
