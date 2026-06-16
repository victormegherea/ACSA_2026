# Track A — Easy (Analyst)
## CAN Signal Discovery & Benign Injection

**Duration:** 30–45 minutes  
**Difficulty:** 🟢 Beginner  
**Objective:** Work as a team to decode two CAN signals and demonstrate a benign injection in the simulator.

---

## 🎯 Learning Goals

By the end of this track you will be able to:
- Identify CAN arbitration IDs and their corresponding vehicle signals
- Map raw byte values to physical quantities (speed, RPM)
- Craft and send a single CAN frame to control the simulator
- Explain why unprotected CAN is vulnerable to injection

---

## 📋 Prerequisites

- VM is running and `lab-start` has been executed
- ICSim dashboard and controls windows are visible
- You can see CAN traffic with `candump vcan0`

---

## Part 1: Observe CAN Traffic (10 min)

### Step 1.1 — Start candump
Open a new terminal and run:
```bash
candump vcan0
```
You should see a stream of CAN frames. Each line looks like:
```
vcan0  0C4   [4]  00 00 19 00
       ^^^         ^^^^^^^^^^^
       ID          Data bytes
```

### Step 1.2 — Use cansniffer for a cleaner view
In another terminal:
```bash
cansniffer -c vcan0
```
This shows only **changing** bytes highlighted in color.

### Step 1.3 — Interact with ICSim controls
Click the ICSim **controls** window and:
- Press **↑ (Up arrow)** to accelerate
- Press **↓ (Down arrow)** to brake
- Press **← → (Left/Right)** to turn
- Press **1, 2, 3, 4** to lock/unlock doors

**Watch cansniffer** — which IDs change when you press each control?

### 📝 Task 1: Fill in this table

| Action | CAN ID (hex) | Which bytes change? | Notes |
|--------|-------------|---------------------|-------|
| Accelerate | | | |
| Brake | | | |
| Turn left | | | |
| Door 1 lock/unlock | | | |

---

## Part 2: Decode Signals (15 min)

### Step 2.1 — Identify the Speed signal
1. Start with the car stopped (speed = 0)
2. Watch `cansniffer` and note the ID that changes when you accelerate
3. Gradually increase speed and record several data values
4. The speed signal should be in **ID 0x244**

**Record your observations:**

| Speed (gauge) | Raw hex bytes | Decimal value |
|--------------|---------------|---------------|
| 0 km/h | | |
| ~20 km/h | | |
| ~40 km/h | | |
| ~60 km/h | | |

### Step 2.2 — Identify the Door Lock signal
1. With `cansniffer` running, press keys **1, 2, 3, 4** to toggle doors
2. The door signal should be in **ID 0x19B**
3. Note which bit corresponds to which door

**Questions to answer:**
- What byte position contains the door lock data?
- What value means "all locked"? What means "all unlocked"?
- Is there a pattern (one bit per door)?

### Step 2.3 — Calculate the scaling
For the speed signal:
- What is the raw value at 0 km/h?
- What is the raw value at ~60 km/h?
- Can you figure out the formula: `speed_kmh = raw_value * ???`

**Hint:** Try `python3 scripts/can_monitor.py` — it has a built-in signal decoder you can compare against.

---

## Part 3: Benign Injection (10 min)

### Step 3.1 — Send a single CAN frame
Now that you know the IDs and byte positions, craft a frame to control the dashboard.

**Set the speed gauge to a specific value:**
```bash
# Format: cansend <interface> <ID>#<data_bytes>
cansend vcan0 244#0000002000
```

Watch the ICSim dashboard — did the speed gauge move?

### Step 3.2 — Toggle a door lock
```bash
# Try unlocking all doors (hint: what byte pattern means "unlocked"?)
cansend vcan0 19B#0000000000
```

### Step 3.3 — Experiment
Try sending different values and observe the effect:
```bash
# High speed
cansend vcan0 244#000000FF00

# Different door combinations
cansend vcan0 19B#0000000100
cansend vcan0 19B#0000000F00
```

**⚠️ Note:** Your injected frame competes with the legitimate frames from ICSim controls. The dashboard may flicker between your value and the real value. This is normal and demonstrates a real challenge of CAN injection.

---

## 📝 What to Share with the Group

Be ready to show/discuss with the other teams:

1. **Signal Map** — Table of IDs your team discovered, byte positions, and scaling
2. **Live Demo** — Show the dashboard responding to your injected frame
3. **Discussion points:**
   - Why is this possible on CAN?
   - What is a replay attack and how does it relate?
   - What defense would you propose?

💡 Optionally save notes in `~/automotive-cyber-lab/workspace/` for reference.

---

## ✅ Team Checkpoints

| Time | Checkpoint | Status |
|------|-----------|--------|
| +10 min | Everyone can see traffic in candump/cansniffer | ☐ |
| +20 min | Team identified speed and door IDs | ☐ |
| +30 min | Successfully injected a frame together | ☐ |
| +40 min | Ready to share findings with the group | ☐ |

---

## 💡 Hints (only if stuck)

<details>
<summary>Hint 1: Speed ID</summary>
The speed signal is on ID 0x244, bytes 3-4 (big-endian).
</details>

<details>
<summary>Hint 2: Door ID</summary>
Door status is on ID 0x19B, byte 3. Each bit = one door.
Bit 0 = Driver, Bit 1 = Passenger, Bit 2 = Rear-Left, Bit 3 = Rear-Right.
0x0F = all locked, 0x00 = all unlocked.
</details>

<details>
<summary>Hint 3: Speed scaling</summary>
Speed in km/h ≈ raw_value × 0.01
So raw 0x2000 = 8192 → ~82 km/h
</details>

---

## 🏆 Stretch Goals (if you finish early)

- [ ] Find the RPM signal (ID 0x0C4) and decode its scaling
- [ ] Find the turn signal ID and toggle left/right blinkers
- [ ] Use `python3 scripts/can_monitor.py` to verify your mappings
- [ ] Calculate the bus load: how many frames/second on vcan0?
- [ ] Write a Python script that continuously injects speed values to "animate" the gauge
