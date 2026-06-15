# Automotive Cybersecurity Lab

A 2-hour, simulator-based automotive cybersecurity lab with three difficulty tracks.

## Overview

Students explore CAN bus security using simulation tools in a safe, controlled Ubuntu VM environment. No real vehicles are used.

### Tracks
- **Easy (Analyst)** — CAN signal discovery & benign injection
- **Medium (Attacker–Defender)** — Replay attack + simple IDS
- **Hard (UDS/ECU)** — UDS interaction & defense proposals

## VM Setup

### Option A: Pre-built VM (Recommended for students)
1. Download the `.ova` file (link provided by instructor)
2. Import into VirtualBox: `File → Import Appliance`
3. Start the VM (credentials: `student` / `cybersec2024`)
4. Open a terminal and run: `lab-start`

### Option B: Build from scratch
1. Install Ubuntu 22.04 Desktop in VirtualBox/VMware
2. Copy this project folder to the VM
3. Run the setup script:
   ```bash
   cd ~/automotive-cyber-lab
   chmod +x setup/vm-setup.sh
   sudo ./setup/vm-setup.sh
   ```
4. Reboot and run: `lab-start`

## Project Structure

```
automotive-cyber-lab/
├── README.md
├── setup/
│   ├── vm-setup.sh             # Main VM setup script
│   ├── lab-start.sh            # Lab environment launcher
│   └── create-ova.sh           # Script to export VM as .ova
├── logs/
│   ├── normal_drive.log        # Normal CAN traffic capture
│   └── attack_trace.log        # Replay attack traffic
├── scripts/
│   ├── replay.py               # Replay attack template
│   ├── simple_ids.py           # Simple IDS template
│   ├── seed_key.py             # Weak seed-key (for Track C)
│   ├── uds_client.py           # UDS client template
│   └── can_monitor.py          # CAN bus monitor utility
├── tracks/
│   ├── track_a_easy.md         # Easy track handout
│   ├── track_b_medium.md       # Medium track handout
│   └── track_c_hard.md         # Hard track handout
└── cheatsheet/
    ├── can_commands.md          # Quick reference for can-utils
    └── icsim_signals.md        # ICSim signal map (instructor)
```

## Requirements

- VirtualBox 7.x or VMware Workstation/Player
- Host machine: 8GB+ RAM, 20GB free disk
- VM specs: 2 CPU cores, 4GB RAM, 20GB disk
- No internet required during the lab (all tools pre-installed)

## Timeline (120 minutes)

| Time | Activity |
|------|----------|
| 0–10 | Introduction, ethics, tool tour |
| 10–25 | Environment bring-up (vcan0 + ICSim) |
| 25–30 | Track briefing & selection |
| 30–100 | Hands-on work (checkpoints every ~20 min) |
| 100–115 | Deliverables & peer review |
| 115–120 | Debrief & defenses discussion |

## Ethics & Safety

- **Simulation only** — no real vehicles or public networks
- **Benign payloads only** — no destructive operations
- **Legal awareness** — responsible disclosure principles
- **Goal** — improve safety and resilience
