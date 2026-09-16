# Automotive Cybersecurity — HSM Decryption Student Guide
## HSM Decryption

Welcome to the HSM Decryption Lab! In this hands-on session, you'll work together in teams to reverse-engineer a Traveo II HSM update container and decrypt it to extract a flag.

**⚠️ Ethics First:** Only use the provided challenge files. Never apply these techniques against real, unauthorized hardware.

---

## 🚀 Getting Started

### Step 1: Verify your tools
Run the lab-start script to check that all tools are installed:
```bash
bash setup/lab-start.sh
```

### Step 2: Read the challenge brief
Open `task.md` for the full brief and learning objectives.

### Step 3: Get the challenge files
The challenge files (`flag_container.s19`, `sflash_single_bank.srec`) are in the `challenge_files/` folder. Your instructor may also provide additional files.

### Step 4: Start analyzing
Use Ghidra/IDA, hex editors, and your knowledge of SREC formats to reverse-engineer the container. If you get stuck, check `cheatsheet/hints.md`. Still stuck after working through all the hints? `cheatsheet/step-by-step.md` has the complete walkthrough.

---

## 📁 What's in This Folder

```
student/
├── README.md                           ← You are here
├── task.md                             ← Challenge brief & learning objectives
├── setup/
│   └── lab-start.sh                    ← Tool check & quick reference
├── challenge_files/
│   ├── flag_container.s19              ← HSM update container with hidden flag
│   └── sflash_single_bank.srec        ← Supervisory flash (contains PSK)
├── cheatsheet/
│   ├── hints.md                         ← Tiered hints (try these first!)
│   └── step-by-step.md                 ← Full walkthrough (last resort)
└── workspace/                          ← Save your team's work here
```

---

## ⏱️ Timeline

| Time | Activity |
|------|----------|
| 0–15 min | Intro: Traveo II HSM, update containers, secure boot |
| 15–50 min | Hands-on: reverse the container format, begin decryption |
| 50–55 min | Checkpoint: "Show me one thing you found" |
| 55–90 min | Continue hands-on: decrypt the HSM, extract the flag |
| 90–100 min | Teams prepare to share findings |
| 100–110 min | Group sharing (2–3 min per team) |
| 110–120 min | Group discussion: "How would you improve this update process?" |

---

## 👥 Teamwork Tips

- **Split roles** — one person reverses the container format, another studies the datasheets for the crypto accelerator
- **Discuss before acting** — "What do you think this header field means?" before jumping to conclusions
- **Ask questions** — there are no dumb questions in cybersecurity
- **Help other teams** — if you finish early, walk around and share what you learned
- **It's about learning, not speed** — take time to understand *why* things work

---

## 🛠️ Tools You'll Need

### Required Tools (pre-installed on the lab VM)

| Tool | What it does | Example |
|------|-------------|---------|
| **Ghidra** | GUI disassembler/decompiler (ARM Thumb) | `ghidra` |
| **srec_cat** | SREC/S19 file conversion & manipulation | `srec_cat file.s19 -o file.bin -binary` |
| **srec_info** | Display SREC file structure & address ranges | `srec_info flag_container.s19` |
| **xxd** | Hex dump utility | `xxd file.bin \| head` |
| **hexedit** | Interactive hex editor (TUI) | `hexedit file.bin` |
| **openssl** | Crypto CLI (AES, RSA, etc.) | `openssl aes-128-cbc -d -K <key> -iv <iv>` |
| **strings** | Extract printable strings from binaries | `strings file.bin` |
| **file** | Identify file types by magic bytes | `file flag_container.s19` |
| **Python 3** | Scripting with pycryptodome, intelhex, bincopy | `python3 decrypt.py` |

### Optional Advanced Tools

| Tool | What it does | How to launch |
|------|-------------|---------------|
| **IDA** | Industry-standard disassembler (if licensed) | `ida` or `ida64` |
| **radare2** | CLI reverse engineering framework | `r2 <binary>` |
| **HxD** | Hex editor (Windows — for reference) | N/A on Linux VM |

### Not on the VM? Install manually:
```bash
sudo apt install srecord xxd hexedit openssl
pip3 install pycryptodome intelhex bincopy
```

---

## 📝 What to Prepare for the Group Discussion

At the end of the lab, each team will briefly share:
1. **What you explored** — which tools you used, what approach you took
2. **What you discovered** — key findings, "aha!" moments
3. **What surprised you** — anything unexpected about the container format or encryption
4. **What defense would you propose** — how would you improve the security of this update process?

No formal report needed — just be ready to talk about your experience!

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't open SREC files | They're text files — open with any text editor or hex editor |
| Ghidra won't load the binary | Check the instruction set (ARM Thumb) and base address |
| Don't know where to start | Read `task.md` first, then check `cheatsheet/hints.md`, then `cheatsheet/step-by-step.md` |
| Stuck for more than 15 min | Ask your instructor for a targeted hint |

---

## ⚖️ Ethics & Safety

- **Provided challenge files only** — never target real, unauthorized hardware
- **Benign analysis only** — no destructive operations
- **Legal awareness** — understand responsible disclosure
- **Goal** — learn together to improve security and resilience
