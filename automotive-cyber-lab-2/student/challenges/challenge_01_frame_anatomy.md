# Challenge 1: CAN Frame Anatomy — Bit-Level Exploration
**Difficulty:** 🟢 Easy | **Time:** 20 min | **Boards:** 1 or 2

## 🎯 Objective
Understand CAN frames at the **bit level** — not just ID and data, but SOF, arbitration, DLC, CRC, ACK, EOF, stuff bits, and how they all fit together.

## 📖 Background
Most CAN tools show you `ID: 0x123, Data: [0xDE, 0xAD]`. But on the wire, a CAN frame is a carefully structured bitstream with error detection (CRC), acknowledgment, and bit stuffing. Understanding this is essential for advanced attacks.

## 🔬 Exercise

### Part A: Generate a bitstream (on your PC)
Use the `canframe.py` tool from the canhack repository:

```python
# Run on your PC (not the Pico)
from canframe import CANFrame

# Standard frame: ID=0x123, data=[0xDE, 0xAD]
f = CANFrame(id_a=0x123, data=bytes([0xDE, 0xAD]))
f.print(detailed=True)
```

**Questions:**
1. How many total bits is the frame (including stuff bits)?
2. Where are the stuff bits? Why are they inserted?
3. What is the CRC value? How many bits is it?
4. What does the ACK field look like when no one acknowledges?

### Part B: Extended ID frame
```python
# Extended frame: 29-bit ID
f_ext = CANFrame(id_a=0x123, id_b=0x45678, ide=True, data=bytes([0x01]))
f_ext.print(detailed=True)
```

**Questions:**
1. How does the extended frame differ from the standard frame?
2. What are the SRR and IDE bits? Where do they appear?
3. How much longer is the extended frame?

### Part C: Remote frame
```python
# Remote frame: request data from ID 0x200
f_rtr = CANFrame(id_a=0x200, rtr=True, dlc=4)
f_rtr.print(detailed=True)
```

**Questions:**
1. What's different about a remote frame vs a data frame?
2. Why does it have a DLC but no data?

### Part D: Decode a raw bitstream
```python
# Decode a mystery bitstream
mystery = "00010010001101101110101011010101001101100010010111111011111111111"
result = CANFrame.from_bitseq(mystery)
if 'can_frame' in result:
    result['can_frame'].print(detailed=True)
    print(f"ID: 0x{result['can_frame'].id_a:03X}")
    print(f"Data: {result['can_frame'].data.hex()}")
```

**Challenge:** What CAN ID and data does this bitstream encode?

### Part E: Stuff bit analysis
```python
# This payload creates maximum stuff bits
f_max = CANFrame(id_a=0x000, data=bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
f_min = CANFrame(id_a=0x7FF, data=bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))

print(f"All-zeros frame: {len(f_max.frame_bits)} bits")
print(f"All-ones frame:  {len(f_min.frame_bits)} bits")
```

**Question:** Why do different payloads produce different frame lengths?

## 📝 What to Share
- Your annotated bitstream diagram showing each field
- The decoded mystery frame
- Your understanding of why stuff bits exist (hint: clock recovery)

## 🏆 Stretch
- [ ] Find a payload that produces the maximum number of stuff bits for ID 0x123
- [ ] Use the `is_janus()` function to find two payloads that produce identical-length bitstreams
