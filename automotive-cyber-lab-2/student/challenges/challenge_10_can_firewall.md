# Challenge 10: Build a CAN Firewall
**Difficulty:** 🔴 Hard | **Time:** 45 min | **Boards:** 2 (+ optional 3rd as monitor)

## 🎯 Objective
Switch from attacker to defender. Build a **CAN firewall/gateway** on the CANPico that detects and blocks the attacks from Challenges 3–8. This is what real automotive security engineers do.

## 📖 Background
In real vehicles, a **gateway ECU** sits between CAN bus segments and filters traffic. Modern cars also deploy **CAN IDS** (Intrusion Detection Systems) that monitor for anomalies. Your task: build one on the CANPico using MicroPython.

## 🔬 Exercise

### Part A: Basic frame rate monitor
Detect abnormal frame rates (DoS / flood attacks):
```python
from rp2 import CAN, CANFrame, CANID
from utime import ticks_ms, ticks_diff

c = CAN()

# Track frame counts per ID per second
frame_counts = {}
window_start = ticks_ms()
WINDOW_MS = 1000
MAX_RATE = 15  # Max frames per ID per second

print("CAN Firewall — Rate Monitor")
print("="*40)

while True:
    frames = c.recv()
    now = ticks_ms()
    
    for frame in frames:
        aid = frame.get_arbitration_id()
        frame_counts[aid] = frame_counts.get(aid, 0) + 1
    
    # Check every second
    if ticks_diff(now, window_start) >= WINDOW_MS:
        for aid, count in frame_counts.items():
            if count > MAX_RATE:
                print(f"  [ALERT] ID 0x{aid:03X}: {count} frames/sec — FLOOD DETECTED!")
        frame_counts = {}
        window_start = now
```

### Part B: ID whitelist filter
Only allow known IDs through — block unknown ones:
```python
from rp2 import CAN

c = CAN()

# Whitelist of allowed CAN IDs
ALLOWED_IDS = {0x100, 0x200, 0x300, 0x400, 0x7DF}

blocked = 0
allowed = 0

print("CAN Firewall — ID Whitelist")
print("="*40)

while True:
    frames = c.recv()
    for frame in frames:
        aid = frame.get_arbitration_id()
        if aid in ALLOWED_IDS:
            allowed += 1
            # In a real gateway, forward to the other bus segment
        else:
            blocked += 1
            print(f"  [BLOCKED] Unknown ID 0x{aid:03X} — data: {frame.get_data().hex()}")
    
    if (allowed + blocked) % 100 == 0 and (allowed + blocked) > 0:
        print(f"  Stats: {allowed} allowed, {blocked} blocked")
```

### Part C: Value plausibility checker
Detect spoofed values that are physically impossible:
```python
from rp2 import CAN
from struct import unpack

c = CAN()

# Plausibility rules
last_values = {}
MAX_JUMPS = {
    0x200: 500,   # Speed can't jump more than 5 km/h per frame
    0x100: 2000,  # RPM can't jump more than 2000 per frame
}

print("CAN Firewall — Plausibility Checker")
print("="*40)

while True:
    frames = c.recv()
    for frame in frames:
        aid = frame.get_arbitration_id()
        data = frame.get_data()
        
        if aid in MAX_JUMPS and len(data) >= 2:
            value = unpack('>H', data[:2])[0]
            
            if aid in last_values:
                jump = abs(value - last_values[aid])
                if jump > MAX_JUMPS[aid]:
                    print(f"  [ALERT] ID 0x{aid:03X}: value jump {last_values[aid]} → {value} (delta={jump}) — SPOOF?")
            
            last_values[aid] = value
```

### Part D: Error counter watchdog
Monitor error counters and alert on attacks:
```python
from rp2 import CAN
from utime import sleep_ms

c = CAN()

prev_tec = 0
prev_rec = 0

print("CAN Firewall — Error Counter Watchdog")
print("="*40)

while True:
    tec = c.get_tec()
    rec = c.get_rec()
    state = c.get_bus_state()
    
    # Alert on rapid TEC/REC increase
    tec_delta = tec - prev_tec
    rec_delta = rec - prev_rec
    
    if tec_delta > 8:
        print(f"  [ALERT] TEC spike: {prev_tec} → {tec} (+{tec_delta}) — ERROR INJECTION?")
    if rec_delta > 8:
        print(f"  [ALERT] REC spike: {prev_rec} → {rec} (+{rec_delta}) — ERROR INJECTION?")
    if state == 'error-passive':
        print(f"  [CRITICAL] Node is ERROR PASSIVE — possible bus-off attack!")
    if state == 'bus-off':
        print(f"  [CRITICAL] NODE IS BUS-OFF — ATTACK CONFIRMED!")
    
    prev_tec = tec
    prev_rec = rec
    sleep_ms(100)
```

### Part E: Combined firewall
Put it all together into a comprehensive CAN firewall:
```python
from rp2 import CAN
from struct import unpack
from utime import ticks_ms, ticks_diff

c = CAN()

# Configuration
ALLOWED_IDS = {0x100, 0x200, 0x300, 0x400}
MAX_RATE = 15
MAX_JUMPS = {0x200: 500, 0x100: 2000}
WINDOW_MS = 1000

# State
frame_counts = {}
last_values = {}
window_start = ticks_ms()
alerts = []

def alert(level, msg):
    alerts.append(msg)
    symbol = "⚠️" if level == "WARN" else "🚨"
    print(f"  [{level}] {msg}")

print("="*50)
print("  CANPico Firewall v1.0")
print("  Monitoring: ID whitelist, rate, plausibility")
print("="*50)

while True:
    frames = c.recv()
    now = ticks_ms()
    
    for frame in frames:
        aid = frame.get_arbitration_id()
        data = frame.get_data()
        
        # Check 1: ID whitelist
        if aid not in ALLOWED_IDS:
            alert("CRIT", f"Unknown ID 0x{aid:03X} blocked")
            continue
        
        # Check 2: Rate tracking
        frame_counts[aid] = frame_counts.get(aid, 0) + 1
        
        # Check 3: Value plausibility
        if aid in MAX_JUMPS and len(data) >= 2:
            value = unpack('>H', data[:2])[0]
            if aid in last_values:
                jump = abs(value - last_values[aid])
                if jump > MAX_JUMPS[aid]:
                    alert("WARN", f"ID 0x{aid:03X} value jump: {jump}")
            last_values[aid] = value
    
    # Rate check every second
    if ticks_diff(now, window_start) >= WINDOW_MS:
        for aid, count in frame_counts.items():
            if count > MAX_RATE:
                alert("CRIT", f"ID 0x{aid:03X} flood: {count}/sec")
        
        # Error counter check
        tec = c.get_tec()
        rec = c.get_rec()
        if tec > 50:
            alert("WARN", f"TEC elevated: {tec}")
        if c.get_bus_state() != 'error-active':
            alert("CRIT", f"Bus state: {c.get_bus_state()}")
        
        frame_counts = {}
        window_start = now
```

### Part F: Test your firewall!
Now have your teammate run the attacks from Challenges 3–6 and see if your firewall catches them:

1. **Spoofing (Ch.3):** Does the plausibility checker catch the fake values?
2. **Error injection (Ch.4):** Does the error counter watchdog alert?
3. **Bus-off (Ch.5):** Does the firewall detect the bus state change?
4. **Flood (Ch.6):** Does the rate monitor catch the DoS?

**Questions:**
1. Which attacks did your firewall catch? Which did it miss?
2. What's the false positive rate during normal traffic?
3. Could your firewall prevent attacks, or only detect them?
4. What would you need to add for production use?

## 📝 What to Share
- Your firewall code
- Test results: which attacks were detected
- False positive analysis
- Discussion: detection vs prevention, and what's missing for production

## 🏆 Stretch
- [ ] Add ECU fingerprinting (timing-based) from Challenge 9
- [ ] Add message counter tracking (detect missing/duplicate frames)
- [ ] Implement a "learning mode" that auto-builds the whitelist
- [ ] Add LED indicators: green=normal, yellow=warning, red=attack
- [ ] Log alerts to the Pico's filesystem for post-analysis
- [ ] Research AUTOSAR IdsM (Intrusion Detection System Manager)
