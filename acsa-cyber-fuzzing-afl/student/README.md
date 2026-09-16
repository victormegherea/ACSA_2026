# Automotive Cybersecurity — Software Fuzzing Student Guide
## Software (Coverage-Guided) Fuzzing with AFL++

Welcome to the Software Fuzzing Lab! You'll use [AFL++](https://aflplus.plus/), a coverage-guided fuzzer, to automatically discover crashing inputs in small C programs, then analyze those crashes to extract a flag.

**⚠️ Ethics First:** Only fuzz the provided challenge binaries (or, for the bonus track, the public COVESA dlt-daemon repo). Never fuzz software you don't have permission to test.

---

## 🚀 Getting Started

### Step 1: Verify your tools
```bash
bash setup/lab-start.sh
```

If the hard-track build reports that `libclang_rt.asan_static` or `libclang_rt.asan` is missing, install the Clang sanitizer runtime and rerun the build:

```bash
sudo bash setup/vm-setup.sh
```

If this folder is on a VirtualBox shared path such as `/media/sf_*`, copy it
to a native Linux directory before fuzzing. AFL++ needs to create many queue
files and links, which shared folders may reject:

```bash
mkdir -p ~/fuzzing-lab
cp -a /media/sf_share/acsa-cyber-fuzzing-afl/student/. ~/fuzzing-lab/
cd ~/fuzzing-lab
```

### Step 2: Read the challenge brief
Open `task.md` for the full brief, the two tracks, and learning objectives.

### Step 3: Pick a track
- **Medium** — start here. A single vulnerable program findable by fuzzing alone.
- **Hard (expert)** — a heap-overflow that AFL++ will crash, but you'll need to manually reverse-engineer and hand-craft the final input to reach the flag.

### Step 4: Build and fuzz
```bash
cd challenge_files/medium/
bash build.sh
afl-fuzz -i seeds -o out -- ./vuln_medium @@
```

For the hard track, use its ASan binary for fuzzing and the separate replay
binary only for the hand-crafted exploit:

```bash
cd challenge_files/hard/
bash build.sh
AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@
```

The hard build keeps the `win()` symbol available for `nm` and uses an
unoptimized replay binary so the intentionally unsafe copy remains
observable.

### Step 5: Triage the crash
Once AFL++ finds a crash, replay it directly with the same target you fuzzed:
```bash
# Medium track
./vuln_medium out/default/crashes/<crash_file>

# Hard track (inspect the ASan report first)
./vuln_hard_asan out/default/crashes/<crash_file>
```

If you get stuck, check `cheatsheet/hints.md`. Still stuck after working through all the hints? Ask your instructor.

---

## 📁 What's in This Folder

```
student/
├── README.md                           ← You are here
├── task.md                             ← Challenge brief & learning objectives
├── setup/
│   ├── lab-start.sh                    ← Tool check & quick reference
│   └── vm-setup.sh                     ← Install AFL++, Clang, ASan, and tools
├── challenge_files/
│   ├── medium/
│   │   ├── vuln_medium.c               ← Medium-track vulnerable source
│   │   ├── build.sh                    ← Build script (AFL++ instrumented)
│   │   └── seeds/                       ← Starter corpus (created if missing)
│   └── hard/
│       ├── vuln_hard.c                 ← Hard-track vulnerable source
│       ├── build.sh                    ← Builds ASan fuzzing and replay targets
│       └── seeds/                       ← Starter corpus (created if missing)
├── cheatsheet/
│   └── hints.md                        ← Tiered hints (try these first!)
└── workspace/                          ← Save your team's work here
```

---

## ⏱️ Timeline

| Time | Activity |
|------|----------|
| 0–15 min | Intro: fuzzing concepts, AFL++ workflow |
| 15–55 min | Medium track: build, fuzz, find the crash, extract the flag |
| 55–90 min | Hard track: fuzz, triage with ASan/gdb, hand-craft the exploit |
| 90+ min | (Expert bonus) Try AFL++ against the public COVESA dlt-daemon |

---

## 🧰 Tool Reference

| Tool | Purpose | Example |
|------|---------|---------|
| **afl-fuzz** | Coverage-guided fuzzer | `afl-fuzz -i seeds -o out -- ./target @@` |
| **afl-clang-fast/lto** | Instrumenting compiler wrapper | `afl-clang-fast -g -O1 -o target target.c` |
| **afl-tmin** | Minimize a crashing input | `afl-tmin -i crash -o crash.min -- ./target @@` |
| **gdb** | Debug a crash manually | `gdb --args ./target crash_file` |
| **objdump / nm** | Find function addresses in a binary | `nm ./vuln_hard \| grep win` |

---

## ❓ Troubleshooting

| Problem | Try this |
|---------|----------|
| Don't know where to start | Read `task.md` first, then check `cheatsheet/hints.md`, then ask your instructor |
| `afl-fuzz` refuses to start (core_pattern error) | `echo core \| sudo tee /proc/sys/kernel/core_pattern` |
| Fuzzer runs but finds nothing after a long time | Double-check you built with an AFL++ compiler wrapper (`afl-clang-fast` or `afl-clang-lto`), not plain `gcc` |
| Hard track: fuzzer finds a crash but no flag | That's expected — read `cheatsheet/hints.md` for the hard track, the crash is only step one |
