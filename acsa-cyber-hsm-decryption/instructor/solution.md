# HSM Decryption — Instructor Solution

## Overview

This lab challenges students to reverse-engineer a Traveo II HSM update container (`flag_container.s19`) and decrypt it using a Pre-Shared Key (PSK) found in supervisory flash (`sflash_single_bank.srec`). The real HSM binary has been replaced with one containing a flag.

**Crypto chain:** PSK (KEK) → AES-ECB unwrap → Transport Key → AES-CBC decrypt → HSM binary (flag)

---

## Step 0 — Prerequisites

Ensure the following tools are available:
```bash
sudo apt install srecord xxd hexedit openssl
pip3 install pycryptodome intelhex bincopy
```

---

## Step 1 — Examine the SREC Files

```bash
# Check file structure
srec_info flag_container.s19
# Output:
#   Format: Motorola S-Record
#   warning: no header record  ← harmless, S0 is optional
#   Execution Start Address: 00000000
#   Data: 10180000 - 101B7FFF

srec_info sflash_single_bank.srec
# Output:
#   Data: 17000800 - 17007DFF
```

**Key info:**
- Container spans flash addresses `0x10180000` – `0x101B7FFF` (~256 KB)
- Sflash spans `0x17000800` – `0x17007DFF`

---

## Step 2 — Convert SREC to Binary

```bash
cd ~/hsm-decryption-lab/challenge_files/

# Convert both files to raw binary (rebase addresses to file offset 0)
srec_cat flag_container.s19 -offset -0x10180000 -o flag_container.bin -binary
srec_cat sflash_single_bank.srec -offset -0x17000800 -o sflash.bin -binary

# Verify sizes
ls -la flag_container.bin sflash.bin
# flag_container.bin: 229376 bytes (0x38000)
# sflash.bin: ~30 KB
```

**Address-to-offset conversion:**
- Container: `binary_offset = flash_address - 0x10180000`
- Sflash: `binary_offset = flash_address - 0x17000800`

---

## Step 3 — Find the PSK (KEK) in Supervisory Flash

```bash
# Search for key labels
strings sflash.bin
# Output includes: Key1, Key2, Key3

# Find Key1 location
xxd sflash.bin | grep -i "4b657931"
# 4b657931 = ASCII "Key1"
```

The sflash SREC line at address `0x17000838`:
```
S321 17000838 4B657931 DEADBEEFDEADBEEFDEADBEEFDEADBEEF 7C8C782E 4B657932 44
                ^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                Key1     PSK (16 bytes) = the KEK
```

**Extract the PSK:**
```bash
# PSK at offset 0x3C (0x1700083C - 0x17000800)
xxd -s 0x3C -l 16 sflash.bin
# Output: DEADBEEF DEADBEEF DEADBEEF DEADBEEF
```

**PSK (KEK):** `DEADBEEFDEADBEEFDEADBEEFDEADBEEF`

---

## Step 4 — Find the Wrapped Transport Key in the Container

The wrapped key is at flash address `0x1018024C` = binary offset `0x24C`:

```bash
# Extract the 16-byte wrapped key
xxd -s 0x24C -l 16 flag_container.bin
```

---

## Step 5 — Unwrap the Transport Key

The transport key is wrapped using **AES-128-ECB** with the PSK as the key:

```python
#!/usr/bin/env python3
"""unwrap_key.py — Unwrap the transport key using the PSK"""
from Crypto.Cipher import AES

# Read binary files
with open("flag_container.bin", "rb") as f:
    container = f.read()
with open("sflash.bin", "rb") as f:
    sflash = f.read()

# PSK (KEK) at sflash offset 0x3C
psk = sflash[0x3C:0x3C + 16]
print(f"PSK (KEK):     {psk.hex()}")

# Wrapped key at container offset 0x24C
wrapped_key = container[0x24C:0x24C + 16]
print(f"Wrapped key:   {wrapped_key.hex()}")

# Unwrap using AES-ECB
cipher = AES.new(psk, AES.MODE_ECB)
transport_key = cipher.decrypt(wrapped_key)
print(f"Transport key: {transport_key.hex()}")
```

**Expected output:**
```
PSK (KEK):     deadbeefdeadbeefdeadbeefdeadbeef
Wrapped key:   <16 hex bytes from container>
Transport key: d9cd10a30d44f430781b03a34a18fe7f
```

**Unwrapped transport key:** `D9 CD 10 A3 0D 44 F4 30 78 1B 03 A3 4A 18 FE 7F`

---

## Step 6 — Decrypt the HSM Binary

The encrypted HSM payload starts at offset `0xC00` (flash address `0x10180C00`). The IV for AES-CBC decryption is located in the container header near the wrapped key.

```python
#!/usr/bin/env python3
"""decrypt_hsm.py — Full decryption pipeline"""
from Crypto.Cipher import AES
import re

# Read binary files
with open("flag_container.bin", "rb") as f:
    container = f.read()
with open("sflash.bin", "rb") as f:
    sflash = f.read()

# === Step 1: Extract keys ===
psk = sflash[0x3C:0x3C + 16]
wrapped_key = container[0x24C:0x24C + 16]

# Unwrap transport key
cipher_ecb = AES.new(psk, AES.MODE_ECB)
transport_key = cipher_ecb.decrypt(wrapped_key)

print(f"PSK (KEK):       {psk.hex()}")
print(f"Wrapped key:     {wrapped_key.hex()}")
print(f"Transport key:   {transport_key.hex()}")

# === Step 2: Extract IV ===
# The IV is stored near the wrapped key in the header
# Try offset 0x25C (right after the wrapped key)
iv = container[0x25C:0x25C + 16]
print(f"IV:              {iv.hex()}")

# === Step 3: Decrypt the payload ===
# Encrypted data starts at offset 0xC00
encrypted_data = container[0xC00:]
print(f"Encrypted size:  {len(encrypted_data)} bytes")

cipher_cbc = AES.new(transport_key, AES.MODE_CBC, iv)
decrypted = cipher_cbc.decrypt(encrypted_data)

# Save decrypted binary
with open("hsm_decrypted.bin", "wb") as f:
    f.write(decrypted)
print(f"Saved:           hsm_decrypted.bin")

# === Step 4: Search for the flag ===
text = decrypted.decode("ascii", errors="ignore")
flags = re.findall(r'[A-Za-z_]+\{[^}]+\}', text)
if flags:
    for flag in flags:
        print(f"\n🏁 FLAG FOUND: {flag}")
else:
    print("\nNo flag pattern found in decoded text.")
    print("Try: strings hsm_decrypted.bin | grep -i flag")
    print("Or:  strings hsm_decrypted.bin | tail -30")
```

```bash
python3 decrypt_hsm.py

# Alternative manual search after decryption:
strings hsm_decrypted.bin | grep -i flag
strings hsm_decrypted.bin | tail -30
```

---

## Key Addresses Summary

| What | File | Flash Address | Binary Offset | Size |
|------|------|---------------|---------------|------|
| Container header | flag_container.s19 | `0x10180000` | `0x000` | Variable |
| Wrapped transport key | flag_container.s19 | `0x1018024C` | `0x24C` | 16 bytes |
| IV (initialization vector) | flag_container.s19 | `0x1018025C` | `0x25C` | 16 bytes |
| Encrypted HSM payload | flag_container.s19 | `0x10180C00` | `0xC00` | ~225 KB |
| PSK label "Key1" | sflash_single_bank.srec | `0x17000838` | `0x38` | 4 bytes |
| **PSK (KEK) value** | sflash_single_bank.srec | `0x1700083C` | `0x3C` | 16 bytes |

---

## Complete Crypto Chain

```
sflash @ 0x1700083C          container @ 0x1018024C
┌──────────────────┐         ┌──────────────────────┐
│ PSK (KEK)        │         │ Wrapped Transport Key │
│ DEADBEEF...      │         │ (16 bytes, encrypted) │
│ (16 bytes)       │         └──────────┬───────────┘
└────────┬─────────┘                    │
         │                              │
         └──────── AES-128-ECB ─────────┘
                        │
                        ▼
              ┌─────────────────┐
              │ Transport Key   │
              │ D9CD10A3...     │
              │ (16 bytes)      │
              └────────┬────────┘
                       │
                       │     container @ 0x1018025C    container @ 0x10180C00
                       │     ┌──────────────┐          ┌─────────────────────┐
                       │     │ IV           │          │ Encrypted HSM       │
                       │     │ (16 bytes)   │          │ (~225 KB)           │
                       │     └──────┬───────┘          └──────────┬──────────┘
                       │            │                             │
                       └──── AES-128-CBC ─────────────────────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │ Decrypted HSM   │
                          │ (contains flag) │
                          └─────────────────┘
```

---

## Background Research Notes

### Analysis (Alexej Hensler)

**Initial findings from Ghidra decompilation:**
- 3 parts of the container are copied to RAM (`0x80000800` / `0x80000840` / `0x80000C00`) after RESET
- Core0 vector table is set to `0x80000C00` accordingly
- Key1 is accessed by the caller of the functions referenced in the handout

**Blocking points encountered:**
- The CRYPTO component instruction set of Traveo II is **not documented** in publicly accessible User Manuals/Application Notes
- Key crypto drivers are provided as a **statically linked library** instead of source code
- Bug in the Ghidra "SVD-Loader" script — unable to import the Traveo II SVD file (fixed)

**Workaround:** Infineon's PSoC6 uses a nearly identical crypto accelerator to Traveo II. Comparing the PSoC6 Technical Reference Manual showed only the register addresses differ — the instruction set for AES (and related register data encoding) is the same.

### PSoC6 TRM References
- [Architecture TRM](https://www.infineon.com/dgdl/Infineon-PSoC_6_MCU_CY8C61x4_CY8C62x4_Architecture_Technical_Reference_Manual_PSoC_61_PSoC_62_MCU-AdditionalTechnicalInformation-v04_00-EN.pdf) — describes the crypto accelerator instruction set
- [Registers TRM](https://www.infineon.com/dgdl/Infineon-PSOC_6_MCU_CY8C61X4CY8C62X4_REGISTERS_TECHNICAL_REFERENCE_MANUAL_(TRM)_PSOC_61_PSOC_62_MCU-AdditionalTechnicalInformation-v03_00-EN.pdf) — register addresses and bit fields

### SVD File
The SVD file for Traveo II is available in the TVII SDK (requires a trivial Infineon site registration — no AURIX-style authorization needed). Can be loaded with Ghidra's SVD-Loader script for register name resolution.

---

## Instructor Tips

### Common Student Struggles
1. **"What is SREC?"** — Remind them it's just a text format. `cat` the file and explain the line structure.
2. **"srec_info shows a warning"** — The "no header record" warning is harmless. S0 headers are optional.
3. **"How do I find the key?"** — Point them to `strings sflash.bin` — "Key1" is a literal string label.
4. **"What is a KEK?"** — Key Encryption Key. Explain the two-layer scheme: device key wraps container-specific transport key.
5. **"Ghidra shows garbage"** — Make sure they set ARM:LE:32:v7 with Thumb compiler when importing.
6. **"The decrypted output is garbage"** — Check offsets, key values, and IV. Most common mistake is wrong offset calculation.

### Hint Progression
The student `cheatsheet/hints.md` has 6 progressive levels. Recommend students try each level for ~10 minutes before revealing the next. For a 2-hour lab:
- Levels 1-2: First 30 minutes
- Levels 3-4: Next 30 minutes  
- Levels 5-6: Final hour (if needed)

### Quick Verification
To verify a student's decryption worked:
```bash
strings hsm_decrypted.bin | grep -i flag
```
