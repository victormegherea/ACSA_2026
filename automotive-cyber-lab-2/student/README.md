# Automotive Cybersecurity Lab 2 — CANPico Hardware Hacking

## 🚗🔒 Welcome

This is the **hardware-based** follow-up to Lab 1. Instead of simulated CAN (ICSim/vcan), you'll work with **real CAN hardware** — two CANPico boards connected on a physical CAN bus. You'll execute real protocol-level attacks and build real defenses.

**⚠️ Ethics:** These are real attacks that work on real vehicles. We use isolated lab hardware ONLY. Never connect to a real car.

---

## 🔧 Hardware Setup

Each team needs:
- **2× CANPico boards** (Raspberry Pi Pico + CANPico shield)
- **2× USB cables** (micro-USB to PC)
- **CAN bus wiring:** CAN-H to CAN-H, CAN-L to CAN-L, GND to GND
- **Thonny IDE** installed on your PC (or any MicroPython REPL)

### Wiring Diagram
```
  Board A (Attacker)          Board B (Victim)
  ┌──────────────┐            ┌──────────────┐
  │   CANPico    │            │   CANPico    │
  │              │            │              │
  │  CAN-H ─────┼────────────┼───── CAN-H   │
  │  CAN-L ─────┼────────────┼───── CAN-L   │
  │  GND   ─────┼────────────┼───── GND     │
  │              │            │              │
  │  USB ────────┤            ├──── USB      │
  └──────────────┘            └──────────────┘
       ↓                           ↓
    PC / Thonny               PC / Thonny
```

### Quick Start
1. Connect both boards via USB
2. Open Thonny IDE → select the correct COM port
3. Test with a simple monitor:
```python
from rp2 import CAN
c = CAN()
print("CAN initialized!")
```

---

## 📁 What's in This Folder

```
student/
├── README.md                          ← You are here
├── challenges/
│   ├── README.md                     ← Challenge map & suggested paths
│   ├── challenge_01_frame_anatomy.md  ← 🟢 Bit-level CAN frames
│   ├── challenge_02_arbitration_race.md ← 🟢 Bus priority & DoS
│   ├── challenge_03_frame_spoofing.md  ← 🟡 Inject fake frames
│   ├── challenge_04_error_injection.md ← 🟡 Corrupt specific frames
│   ├── challenge_05_busoff_attack.md   ← 🔴 Silence an ECU
│   ├── challenge_06_targeted_destruction.md ← 🔴 Surgical DoS
│   ├── challenge_07_janus_frame.md     ← 🔴🔴 Two-faced frames
│   ├── challenge_08_error_passive_spoof.md ← 🔴🔴 Stealth attack
│   ├── challenge_09_clock_drift.md     ← 🟡 Timing & fingerprinting
│   └── challenge_10_can_firewall.md    ← 🔴 Build a defense!
├── tools/
│   ├── canframe.py                    ← CAN bitstream tool (run on PC)
│   └── canpico.py                     ← CANPico utility functions
├── docs/                              ← Reference manuals (if provided)
└── workspace/                         ← Save your team's work here
```

---

## 🎯 Choose Your Path

### 2-hour session (pick 3-4 challenges)
| Path | Challenges | Focus |
|------|-----------|-------|
| **Intro** | 1 → 2 → 3 → 10 | Basics + first attack + defense |
| **Attack-focused** | 3 → 4 → 5 → 6 | Spoofing → errors → bus-off → destruction |
| **Expert** | 7 → 8 → 9 | Janus + stealth + timing |

### 4-hour session
- **Full attack chain:** 1 → 2 → 3 → 4 → 5 → 6 → 10

### Full day
- All 10 challenges: 1 → 2 → 3 → 4 → 5 → 6 → 9 → 7 → 8 → 10

---

## 👥 Teamwork

- **Split roles:** One person on Board A (attacker), one on Board B (victim). Rotate!
- **Discuss before attacking:** "What do we expect to happen?"
- **Observe together:** Watch both terminals simultaneously
- **Document findings:** Take notes in `workspace/`

---

## 📝 Group Sharing

At the end, each team presents:
1. **Which challenges you completed** and what you learned
2. **Most surprising finding** — what was your "aha!" moment?
3. **Attack vs defense** — which was harder? Why?
4. **Real-world implications** — what would this mean for a real car?

---

## ⚖️ Ethics & Safety

- **Isolated hardware ONLY** — never connect to a real vehicle
- **These attacks are real** — they work on production CAN buses
- **Goal:** Learn to attack so you can learn to defend
- **Automotive cybersecurity is a career** — this is what security engineers do daily
