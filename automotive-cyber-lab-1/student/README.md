# Automotive Cybersecurity Lab — Student Guide

Welcome to the Automotive Cybersecurity Lab! In this 2-hour hands-on session, you'll work together in teams to explore CAN bus security using simulation tools in a safe, controlled environment.

**⚠️ Ethics First:** This lab uses simulation only. No real vehicles. Benign payloads only. Be responsible.

---

## 🚀 Getting Started

### Step 1: Start the lab environment
Open a terminal and run:
```bash
lab-start
```
This will:
- Bring up the virtual CAN interface (vcan0)
- Launch ICSim (dashboard + controls)
- Verify all tools are installed

### Step 2: Verify CAN traffic
In a new terminal:
```bash
candump vcan0
```
You should see CAN frames scrolling. If yes, you're ready!

### Step 3: Choose your track as a team
Discuss with your team and pick a track based on your collective experience:

| Track | Difficulty | Duration | Focus |
|-------|-----------|----------|-------|
| **A — Easy** | 🟢 Beginner | 30–45 min | CAN signal discovery & injection |
| **B — Medium** | 🟡 Intermediate | 45–60 min | Replay attack + build an IDS |
| **C — Hard** | 🔴 Advanced | 60–75 min | UDS security access & defenses |

💡 **Tip:** Split roles within your team! One person drives the terminal, another takes notes, another researches. Rotate roles between exercises.

Open your track handout from `tracks/` and follow the instructions together.

---

## 📁 What's in This Folder

```
student/
├── README.md              ← You are here
├── tracks/
│   ├── track_a_easy.md    ← Easy track instructions
│   ├── track_b_medium.md  ← Medium track instructions
│   └── track_c_hard.md   ← Hard track instructions
├── scripts/
│   ├── can_monitor.py     ← CAN bus monitor with signal decoding
│   ├── replay.py          ← Replay attack tool (Track B)
│   ├── simple_ids.py      ← IDS template to customize (Track B)
│   ├── seed_key.py        ← Virtual ECU + seed-key (Track C)
│   └── uds_client.py     ← UDS diagnostic client (Track C)
├── logs/
│   ├── normal_drive.log   ← Normal CAN traffic sample
│   └── attack_trace.log  ← Attack traffic (contains 4 attacks)
├── cheatsheet/
│   └── can_commands.md    ← Quick reference for CAN tools
└── workspace/             ← Save your team's work here
```

---

## ⏱️ Timeline

| Time | Activity |
|------|----------|
| 0–10 min | Intro, ethics, tool tour |
| 10–25 min | Environment setup (lab-start + candump) |
| 25–30 min | Form teams & choose your track |
| 30–100 min | Hands-on teamwork |
| 100–115 min | Teams share findings with the group |
| 115–120 min | Group discussion: "What did you learn? What surprised you?" |

---

## 👥 Teamwork Tips

- **Share screens** — one person types, everyone watches and suggests
- **Discuss before acting** — "What do you think this ID does?" before jumping to conclusions
- **Ask questions** — there are no dumb questions in cybersecurity
- **Help other teams** — if you finish early, walk around and share what you learned
- **It's about learning, not speed** — take time to understand *why* things work

---

## 🛠️ Quick Command Reference

```bash
# Watch CAN traffic
candump vcan0

# Interactive signal monitor (shows changes in color)
cansniffer -c vcan0

# Send a single CAN frame
cansend vcan0 244#0000002000

# Replay a log file
canplayer -I logs/attack_trace.log

# Python CAN monitor
python3 scripts/can_monitor.py

# Analyze a log file
python3 scripts/can_monitor.py --file logs/normal_drive.log
```

---

## 📝 What to Prepare for the Group Discussion

At the end of the lab, each team will briefly share:
1. **What you explored** — which track, what tools you used
2. **What you discovered** — key findings, "aha!" moments
3. **What surprised you** — anything unexpected about CAN security
4. **What defense would you propose** — if you were designing a secure car

No formal report needed — just be ready to talk about your experience!

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| `candump: command not found` | Run `lab-start` first |
| No CAN traffic visible | Check `ip link show vcan0` — must be UP |
| ICSim not launching | Run `/opt/ICSim/icsim vcan0 &` manually |
| Permission denied | Use `sudo` for network commands |
| Python import error | Run `pip3 install python-can` |

---

## ⚖️ Ethics & Safety

- **Simulation only** — never test on real vehicles or public networks
- **Benign payloads only** — no destructive operations
- **Legal awareness** — understand responsible disclosure
- **Goal** — learn together to improve safety and resilience
