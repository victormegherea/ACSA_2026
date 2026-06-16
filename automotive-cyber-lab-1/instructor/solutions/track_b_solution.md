# Track B — Medium: Expected Answers & Solutions

## Task 1: Attack Documentation

| Attack # | Type | CAN ID | Evidence | Danger Level |
|----------|------|--------|----------|-------------|
| 1 | Door unlock injection | 0x19B | Data changes from 0x0F to 0x00 (3 rapid frames) | High — physical security breach |
| 2 | Speed spoofing | 0x244 | Values jump to 0xC800–0xF000 (200–240 km/h) | Critical — driver confusion, ADAS interference |
| 3 | DoS flood | 0x666 | Unknown ID, 20 frames in 20ms, payload DEADBEEFCAFEBABE | High — bus saturation |
| 4 | RPM spoofing | 0x0C4 | Value jumps to 0xFFFF (65535 RPM — impossible) | Critical — gauge damage, driver panic |

## Task 2: Replay Observations

1. **Yes** — the dashboard responds to replayed frames (speed gauge spikes, doors unlock, RPM redlines)
2. **No** — visually in candump, attack frames look identical to normal frames (same format). Only the values and timing are anomalous.
3. Replay works because CAN has **no authentication, no sequence numbers, no timestamps**. The attacker doesn't need to understand the protocol — just record and play back.

## Task 3: Detection Accuracy (Expected Results)

| Metric | Normal Log | Attack Log |
|--------|-----------|------------|
| Total frames | ~115 | ~85 |
| Alerts triggered | 0–2 | 28+ |
| True positives | 0 | 28 |
| False positives | 0–2 (value changes during braking) | 0 |
| Missed attacks | 0 | 0 |

**Note:** Students may get 1-2 false positives on the normal log during braking (door status value change alert). This is acceptable and a good discussion point about threshold tuning.

## Task 4: Defense Proposals (Expected)

| Attack | Detection Method | Prevention Method |
|--------|-----------------|-------------------|
| Unknown ID flood | ID whitelist | Gateway filtering — block unknown IDs |
| Speed spoofing | Value jump detection + plausibility (speed vs RPM) | SecOC MAC on speed frames |
| Door unlock injection | Value change alert while driving | MAC + gateway: only body ECU sends 0x19B |
| RPM spoofing | Value jump + max range check | MAC + ECU authentication |

## IDS Threshold Recommendations

- `MAX_RATE_PER_ID = 12–15` — catches DoS without false positives during normal driving
- `MAX_VALUE_JUMPS[0x0C4] = 3000–5000` — catches RPM spoofing, allows normal acceleration
- `MAX_VALUE_JUMPS[0x244] = 5000–8000` — catches speed spoofing, allows normal driving
- Door status: any change while speed > 0 should alert (MEDIUM severity)
