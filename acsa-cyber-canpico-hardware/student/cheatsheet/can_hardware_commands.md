# CANPico Hardware Lab — Cheatsheet

## 🔧 Tool Reference

| Tool | What it does | Install / Setup |
|------|-------------|-----------------|
| **Thonny IDE** | MicroPython IDE for Pico boards | `sudo apt install thonny` or [thonny.org](https://thonny.org) |
| **MicroPython** | Python runtime on the Pico | Pre-flashed on CANPico boards |
| **canpico.py** | CANPico utility functions | In `tools/canpico.py` |
| **canframe.py** | CAN bitstream tool (run on PC) | In `tools/canframe.py` |
| **CANPico firmware** | Board firmware (.uf2 file) | Provided by instructor on USB |

---

## Hardware Setup

### Wiring (per team)
```
  Board A (Attacker)          Board B (Victim)
  ┌──────────────┐            ┌──────────────┐
  │   CANPico    │            │   CANPico    │
  │  CAN-H ─────┼────────────┼───── CAN-H    │
  │  CAN-L ─────┼────────────┼───── CAN-L    │
  │  GND   ─────┼────────────┼───── GND      │
  │  USB ────────┤            ├──── USB      │
  └──────────────┘            └──────────────┘
       ↓                           ↓
    PC / Thonny               PC / Thonny
```

### Quick Start
1. Connect board via USB
2. Open Thonny → select correct COM port (bottom-right)
3. Test connection:
```python
from rp2 import CAN
c = CAN()
print("CAN initialized!")
```

---

## MicroPython CAN Quick Reference

### Initialize CAN
```python
from rp2 import CAN

# Standard CAN (for monitoring/sending)
c = CAN()

# For attack functions (error injection, etc.)
c = CAN(tx_open_drain=True)
```

### Send a CAN Frame
```python
from rp2 import CAN, CANFrame

c = CAN()
frame = CANFrame(0x123, data=b'\x01\x02\x03\x04')
c.send(frame)
```

### Receive CAN Frames
```python
from rp2 import CAN

c = CAN()
while True:
    frame = c.recv()
    if frame:
        print(f"ID: 0x{frame.arbitration_id:03X}  Data: {frame.data.hex()}")
```

### Monitor CAN Bus
```python
from rp2 import CAN
import time

c = CAN()
while True:
    frame = c.recv()
    if frame:
        print(f"[{time.ticks_ms():8d}] 0x{frame.arbitration_id:03X} [{frame.dlc}] {frame.data.hex()}")
```

---

## CANHack Attack Functions

**Important:** Attack functions require `tx_open_drain=True`!

```python
from rp2 import CAN

c = CAN(tx_open_drain=True)
```

### Spoof a Frame
```python
# Send a frame with a specific ID
from rp2 import CANFrame
spoofed = CANFrame(0x100, data=b'\xFF\xFF\xFF\xFF')
c.send(spoofed)
```

### Error Injection
```python
# Inject a transmit error and wait for the operation to finish or time out.
# The SDK does not provide a set_error_injection() method.
timed_out = c.error_attack(repeat=1, timeout=100_000)
print("timed out:", timed_out)
```

### Bus-Off Attack
```python
# Force a node into bus-off state by causing repeated errors
# (See challenge_05 for details)
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Board not detected | Check USB cable, try different port |
| No CAN traffic | Check wiring: CAN-H↔CAN-H, CAN-L↔CAN-L, GND↔GND |
| `ImportError: CAN` | Wrong firmware — reflash with CANPico firmware (.uf2) |
| CANHack errors | Must use `CAN(tx_open_drain=True)` for attack functions |
| Board freezes | Ctrl+C in Thonny, or disconnect/reconnect USB |
| Wrong COM port | Check Device Manager (Windows) or `ls /dev/ttyACM*` (Linux) |
| Thonny can't connect | Close other serial terminals, select correct interpreter |

---

## Reflashing the CANPico Board

1. Hold the **BOOTSEL** button on the Pico
2. While holding, plug in the USB cable
3. The Pico appears as a USB drive
4. Copy the `.uf2` firmware file to the drive
5. The board reboots automatically

---

## CAN Error Counter Reference

| Counter | Threshold | State |
|---------|-----------|-------|
| TEC/REC < 128 | Normal | **Error Active** |
| TEC/REC ≥ 128 | Warning | **Error Passive** |
| TEC ≥ 256 | Critical | **Bus-Off** |

- Each error increments the counter by **8**
- Each successful frame decrements by **1**
- Bus-off requires 128 × 11 consecutive recessive bits to recover

---

*Need help? Ask your instructor — they're here to guide you!*
