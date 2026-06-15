# ICSim Signal Map — INSTRUCTOR ONLY

⚠️ **Do NOT distribute to students** — they should discover these through analysis.

## Signal Definitions

| ID (hex) | Signal | Byte Range | Encoding | Scale | Unit | Update Rate |
|----------|--------|-----------|----------|-------|------|-------------|
| 0x0AA | Brake Pedal | byte 3 | unsigned | 1 | bool | ~10 Hz |
| 0x0B4 | Steering Angle | bytes 2-3 | signed BE | 0.1 | degrees | ~3 Hz |
| 0x0C4 | Engine RPM | bytes 2-3 | unsigned BE | 1.0 | RPM | ~10 Hz |
| 0x188 | Turn Signals | bytes 0-4 | bitmask | 1 | flags | ~3 Hz |
| 0x19B | Door Lock Status | byte 3 | bitmask | 1 | flags | ~10 Hz |
| 0x244 | Vehicle Speed | bytes 3-4 | unsigned BE | 0.01 | km/h | ~10 Hz |

## Door Lock Bitmask (ID 0x19B, byte 3)

| Bit | Door | Locked | Unlocked |
|-----|------|--------|----------|
| 0 | Driver | 1 | 0 |
| 1 | Passenger | 1 | 0 |
| 2 | Rear-Left | 1 | 0 |
| 3 | Rear-Right | 1 | 0 |

- `0x0F` = all locked
- `0x00` = all unlocked
- `0x01` = only driver locked

## ICSim Controls Keyboard Map

| Key | Action | Affected ID |
|-----|--------|-------------|
| ↑ Up | Accelerate | 0x0C4, 0x244 |
| ↓ Down | Brake | 0x0C4, 0x244, 0x0AA |
| ← Left | Turn left | 0x0B4 |
| → Right | Turn right | 0x0B4 |
| 1 | Toggle driver door | 0x19B |
| 2 | Toggle passenger door | 0x19B |
| 3 | Toggle rear-left door | 0x19B |
| 4 | Toggle rear-right door | 0x19B |

## Expected Value Ranges (Normal Driving)

| Signal | Idle | City | Highway | Max |
|--------|------|------|---------|-----|
| RPM | 800 | 1500-3000 | 2500-4000 | ~8000 |
| Speed | 0 | 0-50 km/h | 60-130 km/h | ~200 km/h |
| Steering | 0 | -45 to +45 | -10 to +10 | ±180 |

## Attack Trace Answers

### Attack 1: Door Unlock Injection
- **ID:** 0x19B
- **Payload:** `0000000000` (byte 3 = 0x00 = all unlocked)
- **Normal:** `0000000F` (byte 3 = 0x0F = all locked)
- **Detection:** Value change on 0x19B while driving

### Attack 2: Speed Spoofing
- **ID:** 0x244
- **Payload:** `000000C800` to `000000F000` (200-240 km/h)
- **Normal:** `0000002000` (~32 km/h cruising)
- **Detection:** Value jump >80 km/h in one step

### Attack 3: DoS Flood
- **ID:** 0x666 (unknown ID)
- **Payload:** `DEADBEEFCAFEBABE`
- **Rate:** 20 frames in 20ms (1000 frames/sec)
- **Detection:** Unknown ID + rate burst

### Attack 4: RPM Spoofing
- **ID:** 0x0C4
- **Payload:** `0000FFFF` (65535 RPM = impossible)
- **Normal:** `00001900` (~6400 RPM cruising)
- **Detection:** Value jump + implausible value
