# CAN-Utils Quick Reference Cheatsheet

## 🔧 Setup

```bash
# Load kernel modules
sudo modprobe vcan
sudo modprobe can
sudo modprobe can_raw

# Create and bring up virtual CAN interface
sudo ip link add dev vcan0 type vcan
sudo ip link set vcan0 up

# Verify interface is up
ip link show vcan0
```

---

## 📡 candump — Capture CAN Traffic

```bash
# Basic capture (all frames)
candump vcan0

# With timestamps
candump -t a vcan0

# Filter by ID (only 0x244)
candump vcan0,244:7FF

# Filter multiple IDs
candump vcan0,244:7FF,0C4:7FF,19B:7FF

# Log to file
candump -l vcan0
# Creates: candump-YYYY-MM-DD_HHMMSS.log

# Log to specific file
candump vcan0 > my_capture.log
```

---

## 🔍 cansniffer — Interactive Monitor

```bash
# Basic sniffer (shows changing bytes in color)
cansniffer -c vcan0

# With binary display
cansniffer -c -b vcan0

# Filter specific IDs (show only 244 and 0C4)
cansniffer -c vcan0
# Then press 'f' and type the ID to filter
```

**Keyboard shortcuts in cansniffer:**
- `q` — Quit
- `f` — Add filter
- `-` — Remove filter
- `c` — Toggle color

---

## ✉️ cansend — Send a Single Frame

```bash
# Format: cansend <interface> <ID>#<data_hex>
cansend vcan0 244#0000002000        # Speed signal
cansend vcan0 19B#0000000F          # Door lock (all locked)
cansend vcan0 19B#0000000000        # Door unlock (all unlocked)
cansend vcan0 0C4#00001900          # RPM value
cansend vcan0 666#DEADBEEFCAFEBABE  # Custom 8-byte frame

# Extended ID (29-bit)
cansend vcan0 18DA00F1#0210010000000000
```

---

## 🔄 canplayer — Replay a Log File

```bash
# Replay a candump log file
canplayer -I capture.log

# Replay with timing preserved
canplayer -I capture.log vcan0=vcan0

# Replay in a loop
canplayer -l i -I capture.log
```

---

## 📊 cangen — Generate Random Traffic

```bash
# Generate random CAN frames
cangen vcan0

# Fixed ID, random data, 100ms interval
cangen vcan0 -I 244 -g 100

# Fixed ID and data length
cangen vcan0 -I 0C4 -L 4 -g 50

# Specific number of frames
cangen vcan0 -n 100
```

---

## 🔗 cansequence — Test Frame Ordering

```bash
# Send sequential frames (for testing)
cansequence vcan0

# Receive and check sequence
cansequence -r vcan0
```

---

## 🐍 Python (python-can)

```python
import can

# Open bus
bus = can.interface.Bus(channel='vcan0', interface='socketcan')

# Send a frame
msg = can.Message(arbitration_id=0x244, data=[0,0,0,0x20,0x00], is_extended_id=False)
bus.send(msg)

# Receive frames
for msg in bus:
    print(f"ID: 0x{msg.arbitration_id:03X}  Data: {msg.data.hex()}")

# Close
bus.shutdown()
```

---

## 📐 Common ICSim Signal IDs

| ID (hex) | Signal | Data Bytes | Notes |
|----------|--------|-----------|-------|
| 0x0AA | Brake | byte 3 | 0=off, 1=on |
| 0x0B4 | Steering | bytes 2-3 | Angle value |
| 0x0C4 | RPM | bytes 2-3 | Engine speed |
| 0x188 | Turn Signals | bytes 0-4 | Blinker state |
| 0x19B | Door Status | byte 3 | Bit per door |
| 0x244 | Speed | bytes 3-4 | Vehicle speed |

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `Cannot find device "vcan0"` | `sudo modprobe vcan && sudo ip link add dev vcan0 type vcan` |
| `Operation not permitted` | Use `sudo` |
| `No buffer space available` | Too many frames; reduce rate |
| candump shows nothing | Check `ip link show vcan0` — must be UP |
| cansniffer blank | Traffic may be static; interact with ICSim controls |
