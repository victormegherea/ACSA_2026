# Automotive Cybersecurity Lab — Instructor Guide

## Overview

This folder contains **instructor-only** materials for the Automotive Cybersecurity Lab.  
**Do NOT distribute this folder to students.**

The student package is in the `../student/` folder.

### Lab Philosophy
This is a **collaborative learning experience**, not a competition or exam. Students work in **teams**, explore at their own pace, and share findings with the group at the end. The goal is curiosity, hands-on discovery, and understanding — not grades.

---

## Folder Contents

```
instructor/
├── README.md                    # This file
├── answer_key/
│   └── icsim_signals.md        # Full signal map + attack trace answers
├── solutions/
│   ├── track_a_solution.md     # Easy track — expected discoveries
│   ├── track_b_solution.md     # Medium track — expected discoveries
│   └── track_c_solution.md     # Hard track — expected discoveries
├── learning_objectives/
│   └── checklist.md            # Learning objectives checklist per track
└── setup/
    ├── vm-setup.sh             # VM provisioning script (run on Ubuntu 22.04)
    └── create-ova.sh           # Export VM as .ova for distribution
```

---

## VM Build Instructions

1. **Create a new VM** in VirtualBox:
   - Name: `Automotive-Cyber-Lab`
   - Type: Linux / Ubuntu 64-bit
   - RAM: 4096 MB, Disk: 20 GB, CPUs: 2

2. **Install Ubuntu 22.04 Desktop**
   - Username: `student` / Password: `cybersec2024`

3. **Copy the student folder** into the VM:
   ```bash
   cp -r student/ ~/automotive-cyber-lab/
   ```

4. **Run the setup script**:
   ```bash
   sudo ./setup/vm-setup.sh
   ```

5. **Reboot** and verify: `lab-start`

6. **Export as OVA**: `./setup/create-ova.sh`

---

## Lab Day — Facilitation Guide

### Before the Lab
- [ ] Upload .ova to course platform (or USB drives)
- [ ] Test import on a clean machine
- [ ] Prepare intro slides (see presentations in parent folder)
- [ ] Set up the room for teamwork (groups of 2–4)

### During the Lab

| Time | What to do | Facilitator role |
|------|-----------|-----------------|
| 0–10 | Intro presentation, ethics, tool tour | Present, set the tone |
| 10–25 | Teams run `lab-start`, verify candump | Walk around, help with setup issues |
| 25–30 | Teams choose their track | Suggest tracks based on team experience |
| 30–50 | Hands-on work | Circulate, ask guiding questions, don't give answers |
| 50–55 | **Checkpoint:** "Show me one thing you found" | Quick check-in with each team |
| 55–90 | Continue hands-on work | Help stuck teams, encourage exploration |
| 90–100 | Teams prepare to share | "What's your biggest finding?" |
| 100–115 | **Group sharing** — each team presents 2–3 min | Facilitate, connect findings across teams |
| 115–120 | **Debrief discussion** | Ask: "What defense would you add to a real car?" |

### Guiding Questions (don't give answers — ask these instead)
- "What changes when you press the accelerator? Which ID?"
- "How would you know if a frame is legitimate or injected?"
- "What's different about the attack traffic vs normal traffic?"
- "If you were designing a car, how would you prevent this?"
- "Why doesn't CAN have authentication? What were the tradeoffs?"

### If a Team is Stuck
1. First: point them to the cheatsheet (`cheatsheet/can_commands.md`)
2. Then: suggest a specific tool ("Try cansniffer — it highlights changes")
3. Last resort: give a small hint ("Look at ID 0x244 when you accelerate")
4. Never: give them the full answer — the discovery IS the learning

### If a Team Finishes Early
- Encourage them to try a harder track
- Ask them to help another team
- Suggest stretch goals from their track handout
- Challenge: "Can you write a Python script that does X?"

---

## Key Talking Points for Debrief

1. **CAN has no authentication** — any node can impersonate any other
2. **Broadcast bus** — every ECU sees every message
3. **Real-world attacks exist** — Charlie Miller & Chris Valasek (Jeep hack, 2015)
4. **Industry response** — AUTOSAR SecOC, ISO 21434, UNECE WP.29
5. **Defense in depth** — no single solution; layers of protection
6. **Career paths** — automotive cybersecurity is a growing field

---

## Answer Key Location

The full signal map and attack answers are in `answer_key/icsim_signals.md`.  
Track-specific expected discoveries are in `solutions/`.

Use these to guide discussions, not to "grade" — if a team found something different but valid, that's great too!
