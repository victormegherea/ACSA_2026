# Track C — Hard (UDS/ECU Security)
## UDS Interaction & Defense Proposals

**Duration:** 60–75 minutes  
**Difficulty:** 🔴 Advanced  
**Objective:** Interact with UDS on a virtual ECU, crack a weak seed-key, and propose defenses.

---

## 🎯 Learning Goals

By the end of this track you will be able to:
- Use UDS diagnostic services (0x10, 0x22, 0x27, 0x2E) on a virtual ECU
- Reverse-engineer a weak seed-key SecurityAccess algorithm
- Read and write ECU data identifiers (DIDs)
- Propose hardened security designs (rolling keys, rate limiting, gateways)
- Draw a UDS request/response sequence diagram

---

## 📋 Prerequisites

- VM is running and `lab-start` has been executed
- Comfortable with CAN basics (Track A level)
- Python 3 proficiency (functions, hex/bytes, basic crypto concepts)

---

## Part 1: Explore the Virtual ECU (15 min)

### Step 1.1 — Launch the virtual ECU
```bash
python3 scripts/seed_key.py
```
This starts an interactive UDS session with a simulated ECU.

### Step 1.2 — Check ECU status
```
UDS> status
```
Note: The ECU starts in "default" session, locked.

### Step 1.3 — Try reading public data
```
UDS> read F190
UDS> read F187
UDS> read F191
UDS> read F195
```
These are standard DIDs (VIN, Part Number, HW/SW versions).

### Step 1.4 — Try reading protected data
```
UDS> read 0100
UDS> read 0200
```
**Expected:** Security access denied (NRC 0x33). You need to unlock first.

### 📝 Task 1: Document the ECU interface

| DID (hex) | Name | Access Level | Value |
|-----------|------|-------------|-------|
| F190 | | Public / Protected | |
| F187 | | Public / Protected | |
| F191 | | Public / Protected | |
| F195 | | Public / Protected | |
| 0100 | | Public / Protected | |
| 0200 | | Public / Protected | |

---

## Part 2: UDS Session & Security Access (20 min)

### Step 2.1 — Switch diagnostic session
The ECU requires a non-default session for SecurityAccess:
```
UDS> session 3
```
This switches to "extended" diagnostic session (0x03).

### Step 2.2 — Request a seed
```
UDS> seed
```
The ECU returns a 16-bit seed value (e.g., `0xA1B2`).

### Step 2.3 — Try a wrong key
```
UDS> key 0000
```
**Expected:** Invalid key (NRC 0x35). You have 3 attempts.

### Step 2.4 — Analyze the weak algorithm
Open `scripts/seed_key.py` in a text editor and find the `weak_seed_key()` function:

```python
def weak_seed_key(seed):
    key = seed ^ ECU_SECRET      # XOR with 0xCAFE
    key = ((key << 3) | (key >> 13)) & 0xFFFF  # Rotate left 3 bits
    return key
```

**Questions to answer:**
1. What is the ECU secret? Where is it stored?
2. What operations does the algorithm perform?
3. Why is XOR with a fixed secret weak?
4. Why is a 16-bit key space insufficient?
5. How would you brute-force this? How many attempts needed?

### Step 2.5 — Crack it manually
Calculate the key for your seed:
```python
# In Python:
seed = 0xA1B2  # Replace with YOUR seed
secret = 0xCAFE
key = seed ^ secret
key = ((key << 3) | (key >> 13)) & 0xFFFF
print(f"Key: 0x{key:04X}")
```

Then enter it:
```
UDS> key <your_computed_key>
```

### Step 2.6 — Or use the auto-crack
```
UDS> crack
```
This demonstrates how trivial the weak algorithm is to break.

### Step 2.7 — Access protected data
Now that you're unlocked:
```
UDS> read 0100
UDS> read 0200
```

### Step 2.8 — Write data (benign)
```
UDS> write 0100 MY_NEW_CALIBRATION
UDS> read 0100
```
Verify the write succeeded, then revert:
```
UDS> write 0100 ORIGINAL_VALUE
```

---

## Part 3: Analyze & Propose Defenses (20 min)

### 📝 Task 2: Vulnerability analysis

List all vulnerabilities in the current ECU security:

| # | Vulnerability | Severity | Exploitability |
|---|--------------|----------|----------------|
| 1 | Fixed XOR secret | | |
| 2 | 16-bit key space | | |
| 3 | No session timeout | | |
| 4 | | | |
| 5 | | | |

### 📝 Task 3: Design a hardened seed-key

Review the `strong_seed_key()` function in `seed_key.py`:
```bash
python3 scripts/seed_key.py --demo
```

Compare weak vs strong:

| Property | Weak Algorithm | Strong Algorithm |
|----------|---------------|-----------------|
| Hash function | None (XOR) | HMAC-SHA256 |
| Key space | 16-bit (65536) | 256-bit |
| Secret rotation | Never | Per-ECU unique |
| Replay protection | None | Counter-based |
| Brute-force time | <1 second | Infeasible |

### 📝 Task 4: Draw a sequence diagram

Create a sequence diagram showing the full UDS security flow:

```
Tester                          ECU
  |                              |
  |-- 0x10 03 (ExtSession) ---->|
  |<---- 0x50 03 (Positive) ----|
  |                              |
  |-- 0x27 01 (RequestSeed) --->|
  |<---- 0x67 01 SEED ----------|
  |                              |
  |-- 0x27 02 KEY ------------->|
  |<---- 0x67 02 (Granted) -----|
  |                              |
  |-- 0x22 01 00 (ReadDID) ---->|
  |<---- 0x62 01 00 DATA -------|
  |                              |
```

Extend this diagram to show:
- What happens with a wrong key (NRC 0x35)
- What happens after 3 failed attempts (NRC 0x36)
- Where you would add a MAC for authentication

### 📝 Task 5: Defense proposal

Write a 1-page defense proposal covering:

1. **Seed-Key Hardening**
   - Replace XOR with HMAC-SHA256 or AES-CMAC
   - Use per-ECU unique secrets (derived from VIN + ECU ID)
   - Add monotonic counter to prevent replay

2. **Access Control**
   - Session timeouts (return to default after 30s inactivity)
   - Progressive delay after failed attempts (exponential backoff)
   - Limit writable DIDs to calibration-only parameters

3. **Network-Level Defenses**
   - Gateway ECU filtering diagnostic requests by source
   - SecOC (Secure On-board Communication) for CAN frames
   - Separate diagnostic CAN bus from vehicle CAN bus

4. **Monitoring**
   - Log all SecurityAccess attempts
   - Alert on repeated failures from same tester ID
   - Anomaly detection on diagnostic session patterns

---

## 📝 Deliverables

Create files in `~/automotive-cyber-lab/workspace/`:

1. **track_c_report.md** — Report containing:
   - ECU interface documentation (Task 1)
   - Vulnerability analysis table (Task 2)
   - Weak vs strong algorithm comparison (Task 3)
   - Sequence diagram (Task 4, text or image)
   - 1-page defense proposal (Task 5)

2. **track_c_sequence.txt** — Your UDS sequence diagram

3. **track_c_commands.txt** — All UDS commands you used (copy from terminal)

---

## ✅ Checkpoints

| Time | Checkpoint | Status |
|------|-----------|--------|
| +15 min | ECU explored, public DIDs read | ☐ |
| +30 min | Seed-key cracked, protected DIDs accessed | ☐ |
| +45 min | Write + revert completed | ☐ |
| +60 min | Vulnerability analysis and sequence diagram done | ☐ |
| +75 min | Defense proposal written | ☐ |

---

## 💡 Hints (only if stuck)

<details>
<summary>Hint 1: Session required</summary>
You must switch to session 2 or 3 before requesting a seed.
Use: session 3
</details>

<details>
<summary>Hint 2: Computing the key</summary>
ECU_SECRET = 0xCAFE. XOR your seed with it, then rotate left 3 bits.
Example: seed=0x1234, key = ((0x1234 ^ 0xCAFE) << 3 | (0x1234 ^ 0xCAFE) >> 13) & 0xFFFF
</details>

<details>
<summary>Hint 3: Brute force approach</summary>
With only 16 bits, you could try all 65536 possible keys in under a second.
But the ECU limits you to 3 attempts — so you need the algorithm.
</details>

---

## 🏆 Stretch Goals (if you finish early)

- [ ] Write a Python brute-force script that tries all 65536 keys
- [ ] Implement the strong_seed_key in the VirtualECU and verify it works
- [ ] Add session timeout to the VirtualECU (auto-lock after 30s)
- [ ] Research ISO 14229 SecurityAccess levels and document the differences
- [ ] Compare UDS security to OBD-II — what's different about access control?
- [ ] Sketch how SecOC (AUTOSAR Secure On-board Communication) would protect CAN frames
