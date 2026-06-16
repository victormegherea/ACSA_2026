# Track B — Medium (Attacker–Defender)
## Replay Attack + Simple Intrusion Detection System

**Duration:** 45–60 minutes  
**Difficulty:** 🟡 Intermediate  
**Objective:** Work as a team to execute a replay attack, then build a simple IDS to detect it.

---

## 🎯 Learning Goals

By the end of this track you will be able to:
- Execute a CAN replay attack using captured traffic
- Understand why replay attacks bypass simple defenses
- Design and implement a lightweight IDS with at least two detection heuristics
- Evaluate detection accuracy (true positives vs false positives)
- Propose mitigation strategies (gateway filtering, MACs)

---

## 📋 Prerequisites

- VM is running and `lab-start` has been executed
- Familiar with `candump`, `cansniffer`, `cansend` (do Track A warm-up if needed)
- Python 3 basics (variables, loops, if/else)

---

## Part 1: Understand the Attack Logs (10 min)

### Step 1.1 — Examine normal traffic
```bash
python3 scripts/can_monitor.py --file logs/normal_drive.log
```

**Questions:**
- How many unique CAN IDs appear in normal traffic?
- What is the typical frame rate per ID?
- What value ranges do you see for speed (0x244) and RPM (0x0C4)?

### Step 1.2 — Examine attack traffic
```bash
python3 scripts/can_monitor.py --file logs/attack_trace.log
```

**Questions:**
- Can you spot the attacks? What looks different from normal?
- How many attack types can you identify?
- What IDs are involved in the attacks?

### 📝 Task 1: Document the attacks

| Attack # | Type | CAN ID | Evidence | Danger Level |
|----------|------|--------|----------|-------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |

---

## Part 2: Execute a Replay Attack (15 min)

### Step 2.1 — Replay the full attack trace
Open two terminals:

**Terminal 1 — Monitor:**
```bash
candump vcan0
```

**Terminal 2 — Replay:**
```bash
canplayer -I logs/attack_trace.log
```

Watch the ICSim dashboard — what happens during each attack phase?

### Step 2.2 — Targeted replay
Replay only the speed spoofing frames:
```bash
python3 scripts/replay.py --file logs/attack_trace.log --filter 244
```

### Step 2.3 — Replay at different speeds
```bash
# 2x speed — attacks happen faster
python3 scripts/replay.py --file logs/attack_trace.log --speed 2.0

# 0.5x speed — slow motion to observe effects
python3 scripts/replay.py --file logs/attack_trace.log --speed 0.5
```

### 📝 Task 2: Answer these questions
1. Did the dashboard respond to the replayed attack frames?
2. Could you visually distinguish attack frames from normal frames in `candump`?
3. Why does a replay attack work even if the attacker doesn't understand the protocol?

---

## Part 3: Build a Simple IDS (25 min)

Now switch from attacker to defender. Your goal is to detect the attacks automatically.

### Step 3.1 — Review the IDS template
```bash
cat scripts/simple_ids.py
```

The template has three detection heuristics with `TODO` markers:
1. **Unknown ID detection** — flag IDs not in the whitelist
2. **Rate burst detection** — flag abnormal frame rates
3. **Value jump detection** — flag implausible value changes

### Step 3.2 — Test the IDS against the attack log
```bash
python3 scripts/simple_ids.py --file logs/attack_trace.log
```

**Expected output:** The IDS should flag multiple alerts for each attack type.

### Step 3.3 — Test against normal traffic (false positive check)
```bash
python3 scripts/simple_ids.py --file logs/normal_drive.log
```

**Goal:** Zero or minimal alerts on normal traffic. If you get false positives, tune the thresholds.

### Step 3.4 — Customize and improve the IDS

Open `scripts/simple_ids.py` in a text editor and try these improvements:

**Improvement A — Add a new heuristic:**
```python
def check_data_pattern(self, arb_id, data):
    """Detect known malicious data patterns."""
    # Example: 0x666 with DEADBEEF is always suspicious
    if data[:4] == b'\xDE\xAD\xBE\xEF':
        self.log.alert("HIGH", "KNOWN_PATTERN",
                      "Known malicious payload detected",
                      arb_id=arb_id, data=data)
        return True
    return False
```

**Improvement B — Tune thresholds:**
- Try `MAX_RATE_PER_ID = 10` instead of 15 — does it catch more attacks?
- Try `MAX_VALUE_JUMPS[0x0C4] = 2000` — more sensitive to RPM spikes?
- What happens if you make thresholds too tight? (false positives)

**Improvement C — Add logging to file:**
```python
# At the top of your modified IDS:
import json

# In the AlertLog.alert() method, add:
with open("workspace/ids_alerts.json", "a") as f:
    json.dump(entry, f, default=str)
    f.write("\n")
```

### Step 3.5 — Live IDS monitoring
In one terminal, start the IDS:
```bash
python3 scripts/simple_ids.py
```

In another terminal, replay the attack:
```bash
canplayer -I logs/attack_trace.log
```

Watch the IDS detect attacks in real-time!

---

## Part 4: Evaluate & Propose Defenses (10 min)

### 📝 Task 3: Detection accuracy

Run your IDS against both logs and fill in:

| Metric | Normal Log | Attack Log |
|--------|-----------|------------|
| Total frames | | |
| Alerts triggered | | |
| True positives | | |
| False positives | | |
| Missed attacks | | |

### 📝 Task 4: Defense proposals

For each attack type, propose a defense:

| Attack | Detection Method | Prevention Method |
|--------|-----------------|-------------------|
| Unknown ID flood | | |
| Speed spoofing | | |
| Door unlock injection | | |
| RPM spoofing | | |

**Consider these defense categories:**
- **Gateway filtering** — block unauthorized IDs between bus segments
- **Message authentication (MAC)** — cryptographic proof of sender
- **Rate limiting** — cap frames per ID per time window
- **Plausibility checks** — cross-reference signals (speed vs RPM)
- **ECU fingerprinting** — detect impostor ECUs by timing patterns

---

## 📝 What to Share with the Group

Be ready to show/discuss with the other teams:

1. **Attack Demo** — Replay an attack live and show the IDS catching it
2. **IDS Results** — Show your alert output and explain your heuristics
3. **Discussion points:**
   - Which attack was hardest to detect? Why?
   - What's the tradeoff between catching attacks and false positives?
   - What defense would you add to a real car?

💡 Optionally save your modified IDS script and notes in `~/automotive-cyber-lab/workspace/`.

---

## ✅ Team Checkpoints

| Time | Checkpoint | Status |
|------|-----------|--------|
| +10 min | Team analyzed attack log, identified attacks | ☐ |
| +25 min | Replay attack executed and observed together | ☐ |
| +45 min | IDS running and detecting attacks | ☐ |
| +55 min | Ready to demo and discuss with the group | ☐ |

---

## 💡 Hints (only if stuck)

<details>
<summary>Hint 1: The four attacks in attack_trace.log</summary>

1. Door unlock injection — ID 0x19B with data 0x00 (unlocked)
2. Speed spoofing — ID 0x244 with values >200 km/h
3. DoS flood — Unknown ID 0x666, 20 frames in 20ms
4. RPM spoofing — ID 0x0C4 with value 0xFFFF (redline)
</details>

<details>
<summary>Hint 2: Rate burst threshold</summary>
Normal traffic sends each ID about 10 times/second.
The DoS flood sends 20 frames in 0.02 seconds = 1000 frames/sec.
A threshold of 15 frames/sec should catch it.
</details>

<details>
<summary>Hint 3: Value jump for speed</summary>
Normal speed changes ~0x500 per step (~5 km/h).
Attack jumps from 0x2000 to 0xC800 in one step = delta of 0xA800.
MAX_VALUE_JUMPS of 8000 should catch this.
</details>

---

## 🏆 Stretch Goals (if you finish early)

- [ ] Add a 4th heuristic: detect duplicate frames (same ID+data within 1ms)
- [ ] Compute bus load percentage and alert if >70%
- [ ] Create a simple dashboard that shows IDS status in real-time
- [ ] Compare your IDS against a machine-learning approach (sketch the idea)
- [ ] Add a "learning mode" that auto-builds the whitelist from normal traffic
