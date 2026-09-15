# Automotive Cybersecurity Lab 4 — Student Guide
## Firmware Reverse Engineering

Welcome to the Firmware Reverse Engineering Lab! In this hands-on session, you'll work together in teams to extract a firmware file system and hunt for sensitive information inside it.

**⚠️ Ethics First:** Only analyze the provided firmware image. Never apply these techniques against real, unauthorized devices.

---

## 🚀 Getting Started

### Step 1: Verify your tools
Run the lab-start script to check that all tools are installed:
```bash
bash setup/lab-start.sh
```

### Step 2: Read the challenge brief
Open `task.md` for the full brief and learning objectives.

### Step 3: Get the firmware binary
The target firmware binary (`Firmware.bin`) is provided in this folder.

### Step 4: Start analyzing
Begin with `cheatsheet/hints.md` and investigate independently. After an honest attempt, use `cheatsheet/stepbystepguide.md` for a detailed workflow.

---

## 📁 What's in This Folder

```
student/
├── README.md           ← You are here
├── Firmware.bin        ← Target firmware binary
├── task.md             ← Challenge brief
├── setup/
│   └── lab-start.sh    ← Tool check & quick reference
├── cheatsheet/
│   ├── hints.md                 ← Progressive discovery hints
│   └── stepbystepguide.md       ← Detailed workflow after an independent attempt
└── workspace/          ← Save your team's work here
```

---

## 🛠️ Tools You'll Need

### Required Tools (pre-installed on the lab VM)

| Tool | What it does | Example |
|------|-------------|---------|
| **binwalk** | Scans firmware for embedded file systems and extracts them | `binwalk -e Firmware.bin` |
| **strings** | Extracts human-readable strings from binary files | `strings Firmware.bin` |
| **file** | Identifies file types by examining magic bytes | `file Firmware.bin` |
| **grep** | Searches for text patterns across files | `grep -r "password" ./` |
| **xxd** | Creates hex dumps of binary files | `xxd Firmware.bin \| head` |
| **hexedit** | Interactive hex editor (TUI) | `hexedit Firmware.bin` |
| **tree** | Displays directory structure as a tree | `tree -L 2 .` |

### Optional Advanced Tools

| Tool | What it does | How to launch |
|------|-------------|---------------|
| **Ghidra** | Full GUI reverse engineering framework (disassembler, decompiler) | `ghidra` |
| **radare2** | CLI-based reverse engineering framework | `r2 <binary>` |

### Not on the VM? Install manually:
```bash
sudo apt install binwalk xxd hexedit tree squashfs-tools
# Optional:
sudo apt install radare2
```

---

## ⏱️ Timeline

| Time | Activity |
|------|----------|
| 0–10 min | Intro, firmware basics, tool tour |
| 10–15 min | Demo: instructor runs `binwalk` together with the class |
| 15–45 min | Hands-on: extract and analyze the firmware |
| 45–50 min | Checkpoint: "Show me one thing you found" |
| 50–55 min | Teams share findings with the group |
| 55–60 min | Group discussion: "How would you secure this firmware?" |

---

## 👥 Teamwork Tips

- **Split roles** — one person runs extraction tools, another combs through extracted files
- **Discuss before acting** — "What do you think is in this directory?" before jumping to conclusions
- **Ask questions** — there are no dumb questions in cybersecurity
- **Help other teams** — if you finish early, walk around and share what you learned
- **It's about learning, not speed** — take time to understand *why* things work

---

## 🛠️ Investigation Resources

Use the tool table above as a reference while attempting the challenge. The detailed commands, evidence-recording pattern, and troubleshooting steps are in `cheatsheet/stepbystepguide.md`.

---

## 📝 What to Prepare for the Group Discussion

At the end of the lab, each team will briefly share:
1. **What you explored** — what tools you used, what you extracted
2. **What you discovered** — key findings, "aha!" moments
3. **What surprised you** — anything unexpected about the firmware contents
4. **What defense would you propose** — how would you protect sensitive data in firmware?

No formal report needed — just be ready to talk about your experience!

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| `binwalk: command not found` | `sudo apt install binwalk` or `pip3 install binwalk` |
| `strings: command not found` | `sudo apt install binutils` |
| `xxd: command not found` | `sudo apt install xxd` |
| `hexedit: command not found` | `sudo apt install hexedit` |
| `tree: command not found` | `sudo apt install tree` |
| No file systems extracted | Try `binwalk -e -M Firmware.bin` for recursive extraction |
| Permission denied | Use `sudo` for extraction commands |
| Can't find sensitive data | Review one level in `cheatsheet/hints.md`, then use `cheatsheet/stepbystepguide.md` |
| Tools not installed | Run `bash setup/lab-start.sh` to check, or ask instructor |

---

## ⚖️ Ethics & Safety

- **Provided firmware only** — never analyze firmware from unauthorized sources
- **Benign analysis only** — no destructive operations
- **Legal awareness** — understand responsible disclosure
- **Goal** — learn together to improve security and resilience
