# Track A — Easy: Expected Answers & Solutions

## Task 1: Signal Discovery Table

| Action | CAN ID (hex) | Which bytes change? | Notes |
|--------|-------------|---------------------|-------|
| Accelerate | 0x0C4, 0x244 | 0C4: bytes 2-3; 244: bytes 3-4 | RPM + Speed increase together |
| Brake | 0x0C4, 0x244, 0x0AA | 0AA: byte 3 → 0x01 | Brake flag + RPM/speed decrease |
| Turn left | 0x0B4 | bytes 2-3 | Negative angle values |
| Door 1 lock/unlock | 0x19B | byte 3, bit 0 | Toggles between 0x0F and 0x0E |

## Task 2: Speed Signal Decoding

| Speed (gauge) | Raw hex (bytes 3-4) | Decimal value | Calculated km/h |
|--------------|---------------------|---------------|-----------------|
| 0 km/h | 0x0000 | 0 | 0 × 0.01 = 0 |
| ~20 km/h | 0x07D0 | 2000 | 2000 × 0.01 = 20 |
| ~40 km/h | 0x0FA0 | 4000 | 4000 × 0.01 = 40 |
| ~60 km/h | 0x1770 | 6000 | 6000 × 0.01 = 60 |

**Formula:** `speed_kmh = raw_value × 0.01`

## Task 3: Door Lock Decoding

- Byte 3 of ID 0x19B is a bitmask
- Bit 0 = Driver (key 1), Bit 1 = Passenger (key 2), Bit 2 = Rear-Left (key 3), Bit 3 = Rear-Right (key 4)
- 0x0F (1111) = all locked, 0x00 (0000) = all unlocked

## Injection Commands

```bash
# Set speed to ~80 km/h
cansend vcan0 244#0000001F40

# Unlock all doors
cansend vcan0 19B#0000000000

# Lock all doors
cansend vcan0 19B#0000000F
```

## Expected Reflection Points

Students should mention:
1. CAN has **no authentication** — any node can send any ID
2. **Replay attacks** work because frames are identical each time (no nonce/counter)
3. Defenses: **message authentication codes (MACs)**, gateway filtering, SecOC
