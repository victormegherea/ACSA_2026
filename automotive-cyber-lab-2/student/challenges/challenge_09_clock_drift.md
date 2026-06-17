# Challenge 9: Clock Drift & Timing Analysis
**Difficulty:** 🟡 Medium | **Time:** 30 min | **Boards:** 2

## 🎯 Objective
Measure **clock drift** between two CANPico boards and understand how timing affects CAN communication, synchronization, and attack precision.

## 📖 Background
Every CAN controller has a local oscillator. No two oscillators run at exactly the same frequency — they drift. CAN handles this with bit synchronization (hard sync at SOF, resync during stuff bits). But drift matters for:
- **Timestamps:** comparing events across nodes
- **Attack timing:** Janus frames and error passive spoofs need precise timing
- **ECU fingerprinting:** clock skew can identify individual ECUs

## 🔬 Exercise

### Part A: Heartbeat + Follow-up protocol
Use the built-in `heartbeat()` and `drift()` functions from canpico.py.

**Board A — send heartbeats with timestamps:**
```python
from rp2 import CAN, CANFrame, CANID
from struct import pack
from utime import sleep

c = CAN()

while True:
    # Send heartbeat frame
    f = CANFrame(CANID(0x100))
    c.send_frame(f)
    
    # Wait for transmit timestamp
    while f.get_timestamp() is None:
        pass
    
    # Send follow-up with the local transmit timestamp
    ts = f.get_timestamp()
    f2 = CANFrame(CANID(0x101), data=pack('>I', ts))
    c.send_frame(f2)
    
    print(f"Heartbeat sent, timestamp: {ts}")
    sleep(1)
```

**Board B — measure clock offset:**
```python
from rp2 import CAN
from struct import unpack

c = CAN()
c.recv()  # Clear old frames

local_ts = None
while True:
    frames = c.recv()
    for frame in frames:
        if frame.get_arbitration_id() == 0x100:
            # Record local receive timestamp
            local_ts = frame.get_timestamp()
        elif frame.get_arbitration_id() == 0x101:
            # Extract sender's transmit timestamp
            sender_ts = unpack('>I', frame.get_data())[0]
            if local_ts is not None:
                offset = sender_ts - local_ts
                print(f"Clock offset: {offset} ticks")
```

### Part B: Measure drift over time
```python
from rp2 import CAN
from struct import unpack

c = CAN()
c.recv()

offsets = []
local_ts = None

for i in range(60):  # Collect 60 seconds of data
    frames = c.recv()
    for frame in frames:
        if frame.get_arbitration_id() == 0x100:
            local_ts = frame.get_timestamp()
        elif frame.get_arbitration_id() == 0x101:
            sender_ts = unpack('>I', frame.get_data())[0]
            if local_ts is not None:
                offset = sender_ts - local_ts
                offsets.append(offset)
                print(f"[{len(offsets):3d}] Offset: {offset}")

# Calculate drift rate
if len(offsets) > 1:
    drift = offsets[-1] - offsets[0]
    drift_per_sec = drift / len(offsets)
    print(f"\nTotal drift over {len(offsets)}s: {drift} ticks")
    print(f"Drift rate: {drift_per_sec:.2f} ticks/sec")
    print(f"Drift PPM: {abs(drift_per_sec) / 125e6 * 1e6:.2f}")  # Assuming 125MHz clock
```

### Part C: ECU fingerprinting concept
Clock skew is unique to each physical oscillator. This can be used to **fingerprint ECUs** — detect if a frame is coming from the real ECU or an impersonator.

```python
from rp2 import CAN
from utime import ticks_us, ticks_diff

c = CAN()

# Measure inter-frame timing for ID 0x200
last_time = None
intervals = []

print("Measuring frame intervals for ID 0x200...")
while len(intervals) < 100:
    frames = c.recv()
    for frame in frames:
        if frame.get_arbitration_id() == 0x200:
            now = ticks_us()
            if last_time is not None:
                interval = ticks_diff(now, last_time)
                intervals.append(interval)
            last_time = now

# Statistics
avg = sum(intervals) / len(intervals)
variance = sum((x - avg) ** 2 for x in intervals) / len(intervals)
std_dev = variance ** 0.5

print(f"\nFrame interval statistics:")
print(f"  Average: {avg:.1f} us")
print(f"  Std dev: {std_dev:.1f} us")
print(f"  Min: {min(intervals)} us")
print(f"  Max: {max(intervals)} us")
print(f"\nThis timing signature can fingerprint the sending ECU!")
```

**Questions:**
1. How much do the two boards drift per second?
2. Is the drift constant or does it change over time?
3. How could you use timing to detect a spoofed frame?
4. What's the relationship between clock drift and Janus attack precision?

## 📝 What to Share
- Clock drift measurement (ticks/sec and PPM)
- Frame interval statistics
- Discussion: ECU fingerprinting as a defense mechanism

## 🏆 Stretch
- [ ] Plot drift over 5 minutes — is it linear?
- [ ] Compare timing signatures of two different boards sending the same ID
- [ ] Implement a simple ECU fingerprint detector that alerts on timing anomalies
- [ ] Research: how does temperature affect oscillator drift?
