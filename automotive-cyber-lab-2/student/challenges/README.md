# CANPico Advanced Hacking Challenges

## Overview

10 hands-on challenges that go beyond basic CAN send/receive, exploiting the full power of the CANHack toolkit on the CANPico board. Covers real-world CAN protocol attacks from bit-level frame analysis to stealth spoofing and defense.

**Hardware required:** 2× CANPico boards connected via CAN bus (CAN-H, CAN-L, GND)  
**Software:** Thonny IDE (or any MicroPython REPL), `canframe.py` from canhack repo for PC exercises  
**Ethics:** These attacks are for educational purposes on isolated lab hardware only. Never on real vehicles.

---

## Challenge Map

| # | Challenge | Difficulty | Key Concepts | Time |
|---|-----------|-----------|-------------|------|
| [1](challenge_01_frame_anatomy.md) | **CAN Frame Anatomy** | 🟢 Easy | Bit-level CAN, stuff bits, CRC, SOF/EOF | 20 min |
| [2](challenge_02_arbitration_race.md) | **Bus Arbitration Race** | 🟢 Easy | Priority, dominant/recessive, ID conflicts, DoS | 20 min |
| [3](challenge_03_frame_spoofing.md) | **Frame Spoofing** | 🟡 Medium | Impersonation, `spoof_frame()`, timing | 30 min |
| [4](challenge_04_error_injection.md) | **Error Injection Attack** | 🟡 Medium | Error frames, TEC/REC counters, `error_attack()` | 30 min |
| [5](challenge_05_busoff_attack.md) | **Bus-Off Attack** | 🔴 Hard | Forcing ECU offline, doom loop, recovery | 40 min |
| [6](challenge_06_targeted_destruction.md) | **Targeted Frame Destruction** | 🔴 Hard | Selective DoS, mask/match, destroy+replace | 40 min |
| [7](challenge_07_janus_frame.md) | **Janus Frame Attack** | 🔴🔴 Expert | Split-personality frames, sampling points, `is_janus()` | 60 min |
| [8](challenge_08_error_passive_spoof.md) | **Error Passive Spoofing** | 🔴🔴 Expert | Stealth frame replacement, loopback offset | 60 min |
| [9](challenge_09_clock_drift.md) | **Clock Drift & Timing** | 🟡 Medium | Timestamps, synchronization, ECU fingerprinting | 30 min |
| [10](challenge_10_can_firewall.md) | **Build a CAN Firewall** | 🔴 Hard | Defense! ID whitelist, rate monitor, plausibility | 45 min |

**Total lab time:** ~6 hours (pick challenges based on your session length)

---

## Suggested Paths

### 2-hour session (pick 3-4 challenges)
- **Intro path:** 1 → 2 → 3 → 10
- **Attack-focused:** 3 → 4 → 5 → 6
- **Expert path:** 7 → 8 → 9

### 4-hour session (pick 6-7 challenges)
- **Full attack chain:** 1 → 2 → 3 → 4 → 5 → 6 → 10
- **Research path:** 1 → 7 → 8 → 9 → 10

### Full day (all 10)
- Follow 1 → 2 → 3 → 4 → 5 → 6 → 9 → 7 → 8 → 10

---

## Attack Taxonomy

```
CAN Protocol Attacks (covered in these challenges)
├── Application Layer
│   ├── Frame Injection (Ch.2, Ch.3)
│   └── Replay Attack (basic lab)
├── Protocol Layer
│   ├── Error Injection (Ch.4)
│   ├── Bus-Off Attack (Ch.5)
│   ├── Targeted Destruction (Ch.6)
│   └── Error Passive Spoofing (Ch.8)
├── Physical Layer
│   ├── Janus Frame (Ch.7)
│   └── Clock Exploitation (Ch.9)
└── Defense
    ├── ID Filtering (Ch.10)
    ├── Rate Monitoring (Ch.10)
    ├── Plausibility Checks (Ch.10)
    ├── Error Counter Watchdog (Ch.10)
    └── ECU Fingerprinting (Ch.9)
```

---

## CANHack API Quick Reference

| Function | Description | Used in |
|----------|------------|---------|
| `CAN()` | Initialize CAN controller | All |
| `CAN(tx_open_drain=True)` | Init for CANHack attacks | Ch.3-8 |
| `CANHack()` | Initialize CANHack toolkit | Ch.3-8 |
| `ch.set_frame(can_id, data)` | Define attack frame | Ch.3-8 |
| `ch.set_attack(can_id)` | Set target for attack | Ch.3-8 |
| `ch.spoof_frame(timeout)` | Inject frame after target | Ch.3, 6 |
| `ch.error_attack(repeat, inject_error)` | Inject errors on target | Ch.4, 5, 6 |
| `ch.send_janus_frame(sync, split, retries)` | Send Janus frame | Ch.7 |
| `ch.spoof_frame_error_passive(offset)` | Stealth spoof | Ch.8 |
| `c.get_tec()` / `c.get_rec()` | Read error counters | Ch.4, 5, 10 |
| `c.get_bus_state()` | Check error state | Ch.5, 10 |
| `f.get_timestamp()` | Frame timestamp | Ch.9 |

---

## Safety & Ethics

⚠️ **These are real CAN protocol attacks.** They work on real vehicles.

- **NEVER** connect to a real vehicle's CAN bus
- **ONLY** use on isolated lab hardware (two CANPico boards)
- **UNDERSTAND** that these attacks can disable safety systems (ABS, airbags, steering)
- **GOAL:** Learn to attack so you can learn to defend
- **CAREER:** Automotive cybersecurity engineers use these skills to make cars safer
