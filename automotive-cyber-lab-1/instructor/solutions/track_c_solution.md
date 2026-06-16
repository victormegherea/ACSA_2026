# Track C — Hard: Expected Answers & Solutions

## Task 1: ECU Interface Documentation

| DID (hex) | Name | Access Level | Value |
|-----------|------|-------------|-------|
| F190 | VIN | Public | WBA12345678901234 |
| F187 | Part Number | Public | ECU-SIM-001 |
| F191 | HW Version | Public | 1.0.0 |
| F195 | SW Version | Public | 2.3.1 |
| 0100 | Calibration Data | Protected | SECRET_CAL_DATA_42 |
| 0200 | Crypto Keys | Protected | AES256_KEY_REDACTED |

## Task 2: Vulnerability Analysis

| # | Vulnerability | Severity | Exploitability |
|---|--------------|----------|----------------|
| 1 | Fixed XOR secret (0xCAFE) | Critical | Trivial — hardcoded in source |
| 2 | 16-bit key space (65536 values) | Critical | Brute-force in <1 second |
| 3 | No session timeout | High | Unlimited time to attempt |
| 4 | Static secret (never rotates) | High | Once known, always works |
| 5 | No replay protection (no counter/nonce) | High | Captured key reusable |
| 6 | Attempt limit easily bypassed (restart session) | Medium | Reset by re-requesting seed |
| 7 | No transport encryption | Medium | Seed/key visible on bus |

## Seed-Key Algorithm Walkthrough

```python
ECU_SECRET = 0xCAFE

def weak_seed_key(seed):
    key = seed ^ 0xCAFE           # Step 1: XOR with fixed secret
    key = ((key << 3) | (key >> 13)) & 0xFFFF  # Step 2: Rotate left 3 bits
    return key

# Example:
# seed = 0x1234
# step1: 0x1234 ^ 0xCAFE = 0xD8CA
# step2: rotate left 3: 0xC656 (binary shift)
# key = 0xC656
```

## Task 3: Weak vs Strong Comparison

| Property | Weak Algorithm | Strong Algorithm |
|----------|---------------|-----------------|
| Hash function | None (XOR) | HMAC-SHA256 |
| Key space | 16-bit (65536) | 256-bit (2^256) |
| Secret rotation | Never | Per-ECU unique |
| Replay protection | None | Counter-based |
| Brute-force time | <1 second | Computationally infeasible |
| Secret storage | Hardcoded in source | Secure element / HSM |

## Task 4: Expected Sequence Diagram

```
Tester                              ECU
  |                                  |
  |-- 0x10 03 (ExtendedSession) --->|
  |<--- 0x50 03 (Positive) ---------|
  |                                  |
  |-- 0x27 01 (RequestSeed) ------->|
  |<--- 0x67 01 [SEED] -------------|
  |                                  |
  |-- 0x27 02 [WRONG_KEY] --------->|
  |<--- 0x7F 27 35 (InvalidKey) ----|  ← NRC 0x35
  |                                  |
  |-- 0x27 02 [WRONG_KEY] --------->|
  |<--- 0x7F 27 35 (InvalidKey) ----|  ← Attempt 2
  |                                  |
  |-- 0x27 02 [WRONG_KEY] --------->|
  |<--- 0x7F 27 36 (ExceedAttempts)-|  ← NRC 0x36, locked out
  |                                  |
  |  ... wait / restart session ...  |
  |                                  |
  |-- 0x27 01 (RequestSeed) ------->|
  |<--- 0x67 01 [NEW_SEED] ---------|
  |                                  |
  |-- 0x27 02 [CORRECT_KEY] ------->|
  |<--- 0x67 02 (Granted) ----------|  ← Unlocked!
  |                                  |
  |-- 0x22 01 00 (ReadDID 0100) --->|
  |<--- 0x62 01 00 [DATA] ----------|  ← Protected data
  |                                  |
  |-- 0x2E 01 00 [NEW_VAL] -------->|  ← Write (with MAC)
  |<--- 0x6E 01 00 (Written) -------|
  |                                  |
```

## Task 5: Defense Proposal Key Points

Students should cover at minimum:

1. **Seed-Key Hardening:** HMAC-SHA256 or AES-CMAC, per-ECU secrets in HSM, monotonic counter
2. **Access Control:** 30s session timeout, exponential backoff (1s, 2s, 4s, 8s...), DID write restrictions
3. **Network Defenses:** Gateway ECU, SecOC for CAN, separate diagnostic bus
4. **Monitoring:** Log all 0x27 attempts, alert on failures, anomaly detection

**Bonus points for mentioning:**
- ISO 14229 security levels (different access for different operations)
- Hardware Security Module (HSM) for key storage
- Secure boot chain for ECU firmware integrity
- AUTOSAR SecOC standard specifics
