# Automotive Cybersecurity Lab 2 — Instructor Guide
## CANPico Hardware Hacking Lab

### Lab Philosophy
Collaborative team learning with real CAN hardware. Teams of 2-4 work through challenges at their own pace, share findings at the end. No grades — focus on discovery and understanding.

---

## Hardware Inventory

Per team:
- 2× CANPico boards (Raspberry Pi Pico + CANPico shield)
- 2× micro-USB cables
- CAN bus wiring (jumper wires: CAN-H, CAN-L, GND)
- 120Ω termination resistors (if not built into boards)

Per lab:
- Spare Pico boards + USB cables
- CANPico firmware files (.uf2) on USB stick for reflashing
- Thonny IDE pre-installed on lab PCs

---

## Pre-Lab Checklist

- [ ] Flash all CANPico boards with latest firmware (firmware-20220511.uf2)
- [ ] Test each board pair: Board A sends, Board B receives
- [ ] Install Thonny IDE on all lab PCs
- [ ] Copy `student/` folder to each lab PC
- [ ] Print challenge handouts (or share digitally)
- [ ] Prepare spare hardware for failures

---

## Facilitation Guide

| Time | Activity | Your Role |
|------|----------|-----------|
| 0–15 | Intro: CAN protocol recap, hardware setup, ethics | Present, help with wiring |
| 15–30 | Teams verify hardware: send/receive test | Walk around, debug connections |
| 30–40 | Teams choose their challenge path | Suggest based on experience |
| 40–90 | Hands-on challenges | Circulate, ask guiding questions |
| 90–100 | Teams prepare to share | "What was your biggest finding?" |
| 100–115 | Group sharing (2-3 min per team) | Facilitate, connect findings |
| 115–120 | Debrief: attack vs defense discussion | Lead discussion |

### Guiding Questions (don't give answers)
- "What happened on Board B when you attacked from Board A?"
- "How fast did the error counter increase? Why 8 per error?"
- "Could a real car detect this attack? How?"
- "What's the difference between this hardware attack and the software attacks from Lab 1?"
- "If you were designing CAN 3.0, what would you change?"

### Common Issues
| Problem | Solution |
|---------|----------|
| Board not detected | Check USB cable, try different port, reflash firmware |
| No CAN traffic | Check wiring: CAN-H↔CAN-H, CAN-L↔CAN-L, GND↔GND |
| `ImportError: CAN` | Wrong firmware — reflash with CANPico firmware |
| CANHack errors | Must use `CAN(tx_open_drain=True)` for attack functions |
| Board freezes | Ctrl+C in Thonny, or disconnect/reconnect USB |

---

## Challenge Difficulty Guide

| Challenge | Recommended For | Prerequisites |
|-----------|----------------|---------------|
| 1 (Frame Anatomy) | Everyone | None — good warm-up |
| 2 (Arbitration) | Everyone | Basic CAN understanding |
| 3 (Spoofing) | Intermediate+ | Completed 1 or 2 |
| 4 (Error Injection) | Intermediate+ | Understands CAN errors |
| 5 (Bus-Off) | Advanced | Completed 4 |
| 6 (Targeted Destruction) | Advanced | Completed 4 |
| 7 (Janus Frame) | Expert only | Strong bit-level understanding |
| 8 (Error Passive Spoof) | Expert only | Completed 4 and 5 |
| 9 (Clock Drift) | Intermediate+ | Basic timing concepts |
| 10 (CAN Firewall) | All levels | Great finale for any path |

---

## Key Talking Points for Debrief

1. **Hardware attacks are more powerful than software** — bit-level manipulation can't be detected by application-layer IDS
2. **CAN was designed for reliability, not security** — no authentication, broadcast bus, error handling can be weaponized
3. **Real-world attacks exist** — Charlie Miller/Chris Valasek (Jeep), Keen Security Lab (Tesla), academic papers on bus-off
4. **Industry response** — AUTOSAR SecOC, ISO 21434, UNECE WP.29 R155/R156
5. **Defense in depth** — no single solution; MACs, gateways, IDS, ECU fingerprinting, secure boot
6. **CAN FD and CAN XL** — newer protocols with some security improvements but still challenges

---

## Relationship to Lab 1

| Aspect | Lab 1 (ICSim/VM) | Lab 2 (CANPico) |
|--------|------------------|-----------------|
| Hardware | Virtual (vcan0) | Real CAN bus |
| Attack level | Application layer | Protocol + physical layer |
| Tools | can-utils, Python | MicroPython, CANHack toolkit |
| Attacks | Injection, replay, IDS | Spoofing, error injection, bus-off, Janus |
| Defense | Software IDS | Hardware firewall |
| Difficulty | Beginner–Advanced | Intermediate–Expert |

Students who completed Lab 1 will have the CAN fundamentals needed for Lab 2's deeper protocol-level attacks.
