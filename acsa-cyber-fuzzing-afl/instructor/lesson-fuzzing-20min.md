# ACSA 2026 Academy — Fuzzing in 20 Minutes

Instructor lesson for the AFL++ software-fuzzing lab.

## Lesson Goal

By the end of this introduction, students should be able to explain:

- What fuzzing is and when it is useful
- The difference between black-box and coverage-guided fuzzing
- Why AFL++ needs an instrumented target
- What seeds, mutations, coverage, crashes, and triage mean
- Why finding a crash is different from understanding or exploiting it

The lesson should end with students ready to build and fuzz the medium track.

## Before Students Arrive

Verify the Linux VM first:

```bash
afl-fuzz -h >/dev/null
afl-clang-fast --version || afl-clang-lto --version
gdb --version
```

Prepare a clean terminal in the medium challenge directory. Do not start AFL++ until the live-demo section.

Avoid running AFL++ from a VirtualBox shared folder such as `/media/sf_*`. AFL++ may fail when it tries to create queue links there. Use the native Linux copy under `~/fuzzing-lab` instead:

```bash
cd ~/fuzzing-lab/challenge_files/medium
bash build.sh
```

## Timing Overview

| Time | Topic | Outcome |
|------|-------|---------|
| 0:00–2:00 | Motivation | Students understand why input bugs are difficult to test manually |
| 2:00–5:00 | What fuzzing is | Students can describe the fuzzing loop |
| 5:00–8:00 | Coverage guidance | Students understand what makes AFL++ different |
| 8:00–11:00 | AFL++ workflow | Students understand instrumentation, seeds, mutations, and findings |
| 11:00–15:00 | Live demo | Students see AFL++ discover paths and save inputs |
| 15:00–18:00 | Crash triage and ASan | Students understand that a crash is evidence, not an explanation |
| 18:00–20:00 | Lab briefing | Students know how to start the medium and hard tracks |

---

## 0:00–2:00 — Why Fuzzing?

### Say

> Most software accepts input: files, packets, messages, configuration, or API calls. The input boundary is where assumptions meet reality. A developer may expect a short filename, a valid packet, or a normal sensor value. An attacker can provide unusual length, structure, ordering, or encoding.

> Manual testing checks examples chosen by people. Fuzzing explores combinations that people would not think to write by hand.

### Ask

- What inputs does an automotive component receive?
- Which of those inputs are controlled by another ECU, a diagnostic tool, a file, or a network?
- What makes an input difficult to test exhaustively?

### Key message

Fuzzing is automated input generation plus observation of the target's behavior.

---

## 2:00–5:00 — What Is Fuzzing?

Draw this loop on a whiteboard:

```text
seed input
    |
    v
mutate input  --->  run target  --->  observe behavior
    ^                                      |
    |                                      |
    +----------- keep interesting <--------+
```

### Explain

A fuzzer repeatedly:

1. Starts with one or more valid or semi-valid inputs called **seeds**.
2. Changes bytes, lengths, structure, or ordering.
3. Runs the target with the generated input.
4. Observes normal exit, new behavior, timeout, crash, or sanitizer report.
5. Keeps inputs that are useful and mutates them again.

### Useful vocabulary

- **Seed corpus:** Initial files used to start exploration.
- **Mutation:** A change made to an input.
- **Target:** The program or harness being tested.
- **Finding:** A crash, timeout, sanitizer report, or other behavior worth investigating.
- **Reproduction:** Running the target again with the saved input.
- **Triage:** Determining the root cause, impact, and reliability of a finding.

### Clarify

A fuzzer is not an oracle that understands the program. It needs a measurable signal that helps it decide which inputs are promising.

---

## 5:00–8:00 — Black-Box vs. Coverage-Guided Fuzzing

### Black-box fuzzing

The fuzzer sees only the outside behavior:

```text
input -> target -> exit code / output / crash
```

It can find obvious failures, but it may spend a lot of time generating inputs that all take the same path.

### Coverage-guided fuzzing

A coverage-guided fuzzer uses an instrumented target:

```text
input -> instrumented target -> behavior + executed code edges
```

AFL++ records which control-flow edges an input reached. If a mutation reaches new code, AFL++ considers it interesting and saves it for future mutations.

### Simple example

Imagine code with four nested checks:

```c
if (byte0 == 'A') {
    if (byte1 == 'B') {
        if (byte2 == 'C') {
            if (byte3 == 'D') {
                unlock_feature();
            }
        }
    }
}
```

A blind fuzzer has to guess a sequence. A coverage-guided fuzzer gets feedback after matching each stage and can keep inputs that reach deeper checks.

### Ask

> If an input reaches one more `if` statement than every previous input, why should the fuzzer keep it?

Expected answer: it has demonstrated new coverage and may be closer to a hidden behavior or bug.

---

## 8:00–11:00 — How AFL++ Fits Together

Show the students this workflow:

```text
C source
   |
   | afl-clang-fast
   v
instrumented executable
   |
   | afl-fuzz -i seeds -o out -- ./target @@
   v
queue / crashes / hangs
```

### Explain the important command pieces

```bash
afl-fuzz -i seeds -o out -- ./target @@
```

- `-i seeds`: directory containing initial inputs.
- `-o out`: directory where AFL++ stores the queue, crashes, hangs, and metadata.
- `--`: separates AFL++ options from target options.
- `./target`: program being tested.
- `@@`: placeholder replaced by the path to the current generated input.

### Explain the compiler step

```bash
afl-clang-fast -g -O1 -o target target.c
```

`afl-clang-fast` adds instrumentation while compiling. A normal `gcc` build may run correctly but gives AFL++ no coverage feedback.

### Explain the AFL++ screen

Point out:

- `execs_done`: how many test cases have run.
- `paths_total`: inputs that reached distinct coverage behavior.
- `unique_crashes`: distinct crash behavior, not necessarily distinct bugs.
- `last new find`: how recently AFL++ discovered new coverage.

Do not promise that every crash is a unique vulnerability. Multiple inputs can trigger the same bug.

---

## 11:00–15:00 — Live Demo

Use the medium track from a native Linux filesystem.

### 1. Build

```bash
cd ~/fuzzing-lab/challenge_files/medium
bash build.sh
```

Explain that the build script creates a small seed corpus if one does not already exist.

### 2. Run AFL++

```bash
rm -rf demo-out  # only needed when repeating the demonstration
afl-fuzz -i seeds -o demo-out -- ./vuln_medium @@
```

Let it run for roughly 60–90 seconds. The objective is to show the workflow and screen, not to wait for a perfect result.

### 3. Stop safely

Press `Ctrl+C`. AFL++ saves its state and findings in `demo-out`.

### 4. Inspect the output

```bash
find demo-out/default -maxdepth 2 -type f | sort | head -20
```

Explain:

- `queue/` contains inputs AFL++ considered interesting.
- `crashes/` contains inputs that caused a crash.
- `hangs/` contains inputs that exceeded the timeout.

If a crash exists, replay it:

```bash
./vuln_medium demo-out/default/crashes/<crash_file>
```

If the demo does not produce a crash during the short window, that is fine. Show the queue and explain that the student exercise gives AFL++ more time. Do not hand students a crash file during the introduction.

### Shared-folder warning

If AFL++ reports an error such as:

```text
Unable to create out/default/queue/id:...
```

move the lab to the VM's native filesystem:

```bash
rm -rf ~/fuzzing-lab/challenge_files/medium/demo-out
```

Then rerun from `~/fuzzing-lab`, not `/media/sf_*`.

---

## 15:00–18:00 — Crash Triage and ASan

### Say

> A crash is a symptom. The important engineering work is understanding what caused it, whether it is reproducible, what memory was affected, and what an attacker could control.

The triage loop is:

```text
reproduce -> minimize -> inspect -> explain -> assess impact -> fix
```

### Reproduce

Run the exact saved input against the target. A finding that cannot be reproduced is not ready to report.

### Minimize

AFL++ can reduce a crashing input:

```bash
afl-tmin -i crash_file -o crash.min -- ./target @@
```

A smaller input makes debugging and root-cause analysis easier.

### ASan

AddressSanitizer detects many memory-safety errors and reports details such as:

- Type of error
- Source location
- Allocation location
- Access size
- Stack trace

For the hard track, students fuzz `vuln_hard_asan` and use the separate non-ASan `vuln_hard` only for the controlled replay. ASan stops at the invalid write; it is not the binary used to demonstrate the final function-pointer redirect.

### Ask

- Is every crash exploitable?
- Can one bug produce many different crash files?
- Why is a sanitizer report more useful than only seeing `Segmentation fault`?

Expected answers: no; yes; it explains the memory error and points to the root cause.

---

## 18:00–20:00 — Bridge Into the Lab

### Medium track

Tell students:

1. Build with `bash build.sh`.
2. Run AFL++ with the provided seeds.
3. Watch for new paths and crashes.
4. Replay the saved input.
5. Minimize it and explain the bug.

### Hard track

Tell students:

1. Build both the ASan fuzzing binary and the non-ASan replay binary.
2. Fuzz only the ASan binary with `AFL_USE_ASAN=1`; it stops at the invalid write and is for diagnosis.
3. Read the sanitizer report.
4. Use `nm` and GDB to understand the function-pointer layout.
5. Craft the final input manually and replay it with the non-ASan binary.

### Close with this message

> Fuzzing is excellent at searching a huge input space and finding suspicious behavior. It does not replace analysis. The strongest workflow is fuzzing to discover, sanitizers to explain, debugging to confirm, and engineering judgment to assess impact.

Then direct students to:

```text
student/task.md
student/cheatsheet/hints.md
```

Keep `instructor/step-by-step.md` and `instructor/solution.md` instructor-only.

## Optional Discussion Prompts

Use these if the class finishes early:

- What makes a good seed corpus?
- What would change if the target accepted network packets instead of files?
- How can a harness make a library easier to fuzz?
- What inputs should be prioritized in an automotive ECU?
- How would you integrate fuzzing into CI without making builds unreasonably slow?
- Which mitigations reduce impact even when fuzzing finds a bug: bounds checks, ASan in testing, fuzzing in CI, sandboxing, privilege reduction, or control-flow integrity?

## Instructor Notes

- Keep the first 20 minutes conceptual and visual; students learn the commands during the hands-on portion.
- Do not reveal the challenge flags or the hard-track payload during this presentation.
- A short live run is enough. The goal is to make AFL++'s feedback loop concrete, not to complete the challenge in front of the class.
- The COVESA material is a structural inspiration only. Present this lab as original ACSA 2026 Academy content.
