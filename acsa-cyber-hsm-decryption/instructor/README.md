# Automotive Cybersecurity — HSM Decryption Instructor Guide
## HSM Decryption

## Overview

This folder contains **instructor-only** materials for the HSM Decryption challenge.
**Do NOT distribute this folder to students.**

The student package is in the `../student/` folder.

### Lab Philosophy
This is a **collaborative learning experience**, not a competition or exam. Students work in **teams**, explore at their own pace, and share findings with the group at the end. The goal is curiosity, hands-on discovery, and understanding — not grades.

---

## Folder Contents

```
instructor/
├── README.md                   # This file
├── solution.md                 # Solution write-up
├── flag_container.s19          # Challenge file (master copy)
├── sflash_single_bank.srec    # Challenge file (master copy)
└── setup/
   └── vm-setup.sh             # VM provisioning script (extends the CAN Security Lab VM)
```

---

## VM Build Instructions

This lab uses the **same VM** as the CAN Security Lab. The setup script adds crypto/RE tools on top of the existing environment.

### If starting from the CAN Security Lab VM (recommended):

1. **Boot the CAN Security Lab VM** (`Automotive-Cyber-Lab`)
2. **Copy the HSM Decryption Lab files** into the VM:
   ```bash
   cp -r student/ ~/hsm-decryption-lab/
   ```
3. **Run the HSM Decryption Lab setup script**:
   ```bash
   sudo ./setup/vm-setup.sh
   ```
4. **Verify**: Open a terminal and type `hsm-decrypt-start`

### If building a fresh VM:

1. Create a VM with Ubuntu 26.04.1 LTS Desktop (user: `student` / pass: `student`)
2. Run the CAN Security Lab setup first: `sudo ../acsa-cyber-can-security/instructor/setup/vm-setup.sh`
3. Then run the HSM Decryption Lab setup: `sudo ./setup/vm-setup.sh`
4. Reboot and verify: `hsm-decrypt-start`

---

## Required Tools (installed by vm-setup.sh)

| Tool | Purpose | Install Command |
|------|---------|----------------|
| **Ghidra** | GUI disassembler/decompiler (ARM Thumb support) | Installed to `/opt/ghidra` by setup script |
| **radare2 (r2)** | CLI reverse engineering framework | `apt install radare2` |
| **srec_cat / srec_info** | SREC/S19 file parsing, conversion, manipulation | `apt install srecord` |
| **xxd** | Hex dump utility | `apt install xxd` |
| **hexedit** | Interactive TUI hex editor | `apt install hexedit` |
| **openssl** | Crypto CLI (AES encrypt/decrypt, key operations) | `apt install openssl` |
| **strings** | Extract printable strings from binaries | Pre-installed |
| **file** | Identify file types by magic bytes | Pre-installed |
| **Python 3** | Scripting (with pycryptodome, intelhex, bincopy) | `apt install python3 python3-pip` |

### Python Packages

| Package | Purpose |
|---------|---------|
| **pycryptodome** | AES, RSA, and other crypto primitives |
| **cryptography** | High-level crypto API |
| **intelhex** | Intel HEX file parsing |
| **bincopy** | SREC/HEX/BIN file conversion |
| **pyelftools** | ELF binary analysis |

---

## Lab Day — Facilitation Guide

### Before the Lab
- [ ] Review `solution.md`
- [ ] Prepare/provide the update container, encrypted HSM, `flag_container`, and `sflash_single_bank` files referenced in the student task
- [ ] Confirm Ghidra/IDA and hex editors are available on lab machines
- [ ] Prepare intro slides (if applicable)
- [ ] Set up the room for teamwork (groups of 2–4)

### During the Lab

| Time | What to do | Facilitator role |
|------|-----------|-----------------|
| 0–15 | Intro: Traveo II HSM, update container structure, secure boot | Present, set the tone |
| 15–50 | Teams reverse the container format and begin decryption | Circulate, ask guiding questions, don't give answers |
| 50–55 | **Checkpoint:** "Show me one thing you found" | Quick check-in with each team |
| 55–90 | Continue hands-on work — decrypt the HSM to extract the flag | Help stuck teams, encourage exploration |
| 90–100 | Teams prepare to share | "What's your biggest finding?" |
| 100–110 | **Group sharing** — each team presents 2–3 min | Facilitate, connect findings across teams |
| 110–120 | **Debrief discussion** | Ask: "How would you improve the security of this update process?" |

### Guiding Questions (don't give answers — ask these instead)
- "Where is the pre-shared key stored, and what does it actually encrypt?"
- "What's the difference between the PSK and the transport key?"
- "What crypto accelerator does the Traveo II use, and are there comparable, better-documented parts?"
- "What does the CySAF header tell you about the container structure?"
- "If you were designing this system, what would you change?"

### If a Team is Stuck
1. First: point them to `student/cheatsheet/hints.md`
2. Then: suggest a specific approach ("Try looking at the SREC format — it's a text file describing data at specific addresses")
3. Last resort: give a small, targeted hint from `solution.md`
4. Never: give them the full answer — the discovery IS the learning

### If a Team Finishes Early
- Challenge them to understand the full crypto chain (PSK → transport key → HSM binary)
- Ask them to document the container format they reverse-engineered
- Encourage them to help another team
- Discuss: "How would you re-sign and re-encrypt the HSM with your own keys?"

---

## Key Talking Points for Debrief

1. **HSM update containers use layered encryption** — transport keys wrapped by pre-shared keys
2. **Datasheets are your friend** — cross-referencing similar hardware (PSoC6 ↔ Traveo II) can unlock undocumented features
3. **SREC/S19 formats** — understanding binary container formats is essential for embedded security
4. **Defense in depth** — secure boot, encrypted updates, and key management all work together
5. **Real-world relevance** — automotive OEMs need to manage HSM keys across their supply chain

---

## Answer Key Location

See `solution.md` for the full solution write-up.

Use this to guide discussions, not to "grade" — if a team found something different but valid, that's great too!
