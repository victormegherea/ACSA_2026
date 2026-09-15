# Firmware Reverse Engineering — Instructor Guide

## Overview

This folder contains **instructor-only** materials for the Firmware Reverse Engineering challenge.
**Do NOT distribute this folder to students.**

The student package is in the `../student/` folder.

### Lab Philosophy
This is a **collaborative learning experience**, not a competition or exam. Students work in **teams**, explore at their own pace, and share findings with the group at the end. The goal is curiosity, hands-on discovery, and understanding — not grades.

---

## Folder Contents

```
instructor/
├── README.md           # This file
├── solution.md         # Solution write-up
└── setup/
    └── vm-setup.sh     # VM provisioning script (extends Lab 1 VM)
```

---

## VM Build Instructions

This lab uses the **same VM** as the CAN Security Lab. The setup script adds firmware RE tools on top of the existing CAN Security environment and must be run on **Ubuntu 26.04.1 LTS**.

### If starting from the CAN Security Lab VM (recommended):

1. **Boot the CAN Security Lab VM** (`Automotive-Cyber-Lab`) running Ubuntu 26.04.1 LTS
2. **Copy the Firmware Reverse Engineering files** into the VM:
   ```bash
   cp -r student/ ~/firmware-re-lab/
   ```
3. **Run the Firmware Reverse Engineering setup script**:
   ```bash
   sudo ./setup/vm-setup.sh
   ```
4. **Verify**: Open a terminal and type `firmware-re-start`

### If building a fresh VM:

1. **Create a new VM** in VirtualBox:
   - Name: `Automotive-Cyber-Lab`
   - Type: Linux / Ubuntu 64-bit
   - RAM: 4096 MB, Disk: 20 GB, CPUs: 2

2. **Install Ubuntu 26.04.1 LTS Desktop**
   - Username: `student` / Password: `student`

3. **Run the CAN Security Lab setup first** (for base packages):
   ```bash
   sudo ../acsa-cyber-can-security/instructor/setup/vm-setup.sh
   ```

4. **Then run the Firmware Reverse Engineering setup**:
   ```bash
   sudo ./setup/vm-setup.sh
   ```

5. **Reboot** and verify: `firmware-re-start`

6. **Export as OVA** (optional): Use the CAN Security Lab's `create-ova.sh`

---

## Required Tools (installed by vm-setup.sh)

| Tool | Purpose | Install Command |
|------|---------|----------------|
| **binwalk** | Firmware signature scanning & extraction | `apt install binwalk` |
| **strings** | Extract printable strings from binaries | `apt install binutils` (usually pre-installed) |
| **file** | Identify file types by magic bytes | `apt install file` (usually pre-installed) |
| **grep** | Search for patterns in text/binary files | Pre-installed on Linux |
| **xxd** | Hex dump utility | `apt install xxd` |
| **hexedit** | Interactive TUI hex editor | `apt install hexedit` |
| **tree** | Directory structure viewer | `apt install tree` |
| **squashfs-tools** | SquashFS file system utilities | `apt install squashfs-tools` |
| **cpio** | CPIO archive extraction | `apt install cpio` |
| **p7zip-full** | 7-Zip archive support | `apt install p7zip-full` |

### Optional Advanced Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **Ghidra** | GUI reverse engineering framework (NSA) | Installed to `/opt/ghidra` by setup script |
| **radare2 (r2)** | CLI reverse engineering framework | `apt install radare2` |
| **HxD** | Hex editor (Windows — for reference only) | N/A on Linux VM |

---

## Lab Day — Facilitation Guide

### Before the Lab
- [ ] Review `solution.md`
- [ ] Verify `Firmware.bin` is in the student folder
- [ ] Confirm tools are installed: run `lab4-start` on the VM
- [ ] Prepare intro slides (if applicable)
- [ ] Set up the room for teamwork (groups of 2–4)

### During the Lab

| Time | What to do | Facilitator role |
|------|-----------|-----------------|
| 0–10 | Intro: firmware basics, tool tour (`lab4-start`) | Present, set the tone |
| 10–15 | Demo: run `binwalk Firmware.bin` together | Show output, explain signatures |
| 15–45 | Teams extract and analyze the firmware image | Circulate, ask guiding questions, don't give answers |
| 45–50 | **Checkpoint:** "Show me one thing you found" | Quick check-in with each team |
| 50–55 | Teams share findings | Facilitate discussion |
| 55–60 | **Debrief discussion** | Ask: "What would you do differently to secure this firmware?" |

### Tool Tour (first 10 minutes)

Show students these commands live:
```bash
# 1. What kind of file is this?
file Firmware.bin

# 2. Scan for embedded signatures
binwalk Firmware.bin

# 3. Extract embedded file systems
binwalk -e Firmware.bin

# 4. Look at what was extracted
tree -L 2 _Firmware.bin.extracted/

# 5. Search for interesting strings
strings Firmware.bin | head -50

# 6. Search for credentials
grep -r "password" _Firmware.bin.extracted/
```

### Guiding Questions (don't give answers — ask these instead)
- "Where do embedded devices typically store credentials?"
- "What file system did binwalk extract, and what looks interesting in it?"
- "What counts as 'sensitive information' in a firmware image?"
- "If you were the firmware developer, how would you protect these secrets?"
- "What directories in a Linux file system typically contain configuration?"

### If a Team is Stuck
1. First: point them to `student/cheatsheet/hints.md`
2. Then: suggest a specific tool ("Try `binwalk -e` to extract the file system")
3. Then: suggest a specific directory ("Look in the `etc/` directory")
4. Last resort: give a small, targeted hint from `solution.md`
5. Never: give them the full answer — the discovery IS the learning

### If a Team Finishes Early
- Ask them to look for additional sensitive data in the extracted file system
- Challenge: "Can you find any other credentials or configuration secrets?"
- Challenge: "Can you identify what kind of device this firmware is for?"
- Encourage them to try Ghidra on one of the extracted binaries
- Encourage them to help another team
- Discuss: "How would you harden this firmware?"

---

## Key Talking Points for Debrief

1. **Firmware often contains secrets in plaintext** — credentials, keys, configuration data
2. **Extraction tools are freely available** — binwalk and SquashFS utilities are sufficient for this image.
3. **Defense in depth** — encrypt sensitive data, use secure boot, strip debug info
4. **Real-world impact** — firmware leaks have exposed entire product lines
5. **Responsible disclosure** — if you find vulnerabilities in real firmware, report them properly
6. **Automotive relevance** — ECU firmware, infotainment systems, telematics units all contain extractable firmware

---

## Answer Key Location

See `solution.md` for the full solution write-up.

Use this to guide discussions, not to "grade" — if a team found something different but valid, that's great too!
