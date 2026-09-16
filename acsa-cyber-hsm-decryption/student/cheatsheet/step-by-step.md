# Step-by-Step Walkthrough — HSM Decryption

This is the **full solution walkthrough** with exact commands, offsets, and scripts. Only use this if you've tried the hints in `hints.md` and are still stuck — working it out yourself is the whole point of the exercise!

---

## Step 1 — Getting Started (Understanding the Files)

You have two files:
- **`flag_container.s19`** — The HSM update container (contains the encrypted HSM binary + metadata)
- **`sflash_single_bank.srec`** — A dump of the supervisory flash (contains crypto keys)

```bash
# 1. SREC files are plain text — just read them!
cat flag_container.s19 | head -20
cat sflash_single_bank.srec | head -20

# 2. Get structure info (ignore the "no header record" warning — it's harmless)
srec_info flag_container.s19
# Output: Data: 10180000 - 101B7FFF  (this is the address range)

srec_info sflash_single_bank.srec
# Output: Data: 17000800 - 17007DFF  (supervisory flash address range)

# 3. Convert to binary for easier analysis (rebase addresses to file offset 0)
srec_cat flag_container.s19 -offset -0x10180000 -o flag_container.bin -binary
srec_cat sflash_single_bank.srec -offset -0x17000800 -o sflash.bin -binary

# 4. Look at the raw hex of the container header
xxd flag_container.bin | head -20
```

### SREC format refresher
- `S0` = header record (optional — this file doesn't have one)
- `S1`/`S2`/`S3` = data records (16/24/32-bit addresses)
- `S5` = record count
- `S7`/`S8`/`S9` = end record (S7 = 32-bit start address)
- Each line format: `Stype` | `byte_count` | `address` | `data` | `checksum`

### How to read an S3 record
Example: `S321 10180000 007F0300028007010000000001000000F0030000000000C61A1B1C1D 82`
- `S3` = data record with 32-bit address
- `21` = byte count (33 bytes: 4 addr + 28 data + 1 checksum)
- `10180000` = address (the data starts at 0x10180000 in flash)
- `007F030002...` = the actual data bytes
- `82` = checksum

---

## Step 2 — Understanding the Container Structure

The update container uses the **CySAF** (Cypress Secure Application Format) header. The first bytes of the container contain metadata about the update.

```bash
# Look at the first 64 bytes of the container header
xxd flag_container.bin | head -4
```

The container is structured as:
1. **Header** (at the beginning) — contains metadata, version info, sizes
2. **Wrapped key** (at a specific offset) — the encrypted transport key
3. **Encrypted payload** (bulk of the file) — the actual HSM binary, encrypted
4. **Signature** (at the end) — integrity verification

### Key observation

Look at the raw data in the container. You'll notice large blocks of `DEDEDEDE...` — this is the encrypted payload. The header area before it contains the metadata and the wrapped key.

```bash
# Find where the encrypted data starts
xxd flag_container.bin | grep -n "dede" | head -5
```

### Converting addresses

The S19 file uses flash addresses (starting at `0x10180000`). Since we rebased with `-offset` during conversion, the binary starts at offset 0. So:
- Flash address `0x10180000` = binary offset `0x000`
- Flash address `0x1018024C` = binary offset `0x24C`

To calculate: `binary_offset = flash_address - 0x10180000`

---

## Step 3 — Finding the PSK in Supervisory Flash

The Pre-Shared Key (PSK) is stored in the supervisory flash (`sflash_single_bank.srec`). Look for it in the HSM config area.

```bash
# Convert sflash to binary (rebase addresses to file offset 0)
srec_cat sflash_single_bank.srec -offset -0x17000800 -o sflash.bin -binary

# Look at the beginning of the sflash dump
xxd sflash.bin | head -20
```

### What to look for

Search for the string "Key1" in the sflash — it marks the location of the first key:

```bash
# Search for readable strings
strings sflash.bin
# You should see: Key1, Key2, Key3

# Find the exact location (byte offset, works reliably regardless of xxd formatting)
grep -boa "Key1" sflash.bin
# Output: 56:Key1   (56 decimal = 0x38)
```

### The key structure in sflash

Look at the SREC line containing address `0x17000838`:
```
S321 17000838 4B657931 DEADBEEFDEADBEEFDEADBEEFDEADBEEF 7C8C782E 4B657932 44
```

Breaking this down:
- `4B657931` = ASCII "Key1" (key label)
- The next 16 bytes after "Key1" = **the PSK (KEK)**
- `4B657932` = ASCII "Key2" (next key label)

The PSK starts at address `0x1700083C` (4 bytes after "Key1" label).

**Extract the 16-byte PSK:**
```bash
# The PSK is at offset 0x3C from the start of sflash
# (0x1700083C - 0x17000800 = 0x3C)
xxd -s 0x3C -l 16 sflash.bin
```

---

## Step 4 — Finding the Wrapped Key in the Container

The transport key is stored **inside the update container**, encrypted with the PSK. It's located in the container header area.

The wrapped key is at flash address `0x1018024C`, which is binary offset `0x24C`:

```bash
# Extract the 16-byte wrapped key from the container
xxd -s 0x24C -l 16 flag_container.bin
```

### The crypto chain

The encryption uses a two-layer key scheme:
1. **PSK** (from sflash) is the **KEK** (Key Encryption Key)
2. PSK encrypts/wraps the **transport key** (stored in the container)
3. The **transport key** encrypts the actual HSM binary payload

```
PSK (from sflash) → unwraps → Transport Key (from container) → decrypts → HSM binary
```

### Why two layers?

This is a common pattern in secure update systems:
- The PSK is device-specific (stored in protected flash)
- The transport key is container-specific (changes per update)
- This way, the same PSK can be used to decrypt different update containers

---

## Step 5 — Unwrapping the Transport Key

The transport key is wrapped using **AES-ECB** with the PSK as the key:

```python
#!/usr/bin/env python3
"""Step 1: Unwrap the transport key using the PSK from sflash"""
from Crypto.Cipher import AES

# Read the binary files
with open("flag_container.bin", "rb") as f:
    container = f.read()

with open("sflash.bin", "rb") as f:
    sflash = f.read()

# Extract the PSK (KEK) from sflash
# PSK is at offset 0x3C (address 0x1700083C - base 0x17000800)
psk = sflash[0x3C:0x3C + 16]
print(f"PSK (KEK): {psk.hex()}")

# Extract the wrapped transport key from the container
# Wrapped key is at offset 0x24C (address 0x1018024C - base 0x10180000)
wrapped_key = container[0x24C:0x24C + 16]
print(f"Wrapped key: {wrapped_key.hex()}")

# Unwrap the transport key using AES-ECB
cipher = AES.new(psk, AES.MODE_ECB)
transport_key = cipher.decrypt(wrapped_key)
print(f"Transport key: {transport_key.hex()}")
```

Run this script:
```bash
python3 unwrap_key.py
```

The script should print out the unwrapped transport key in hex — you'll need it as input for Step 6.

---

## Step 6 — Decrypting the HSM Binary

Now that you have the transport key, you need to decrypt the encrypted payload in the container. The encrypted data is the large block of seemingly random bytes (the `DEDEDEDE...` pattern you saw earlier was a placeholder/padding — the actual encrypted data follows the header).

```python
#!/usr/bin/env python3
"""Step 2: Decrypt the HSM binary using the transport key"""
import sys
from Crypto.Cipher import AES

if len(sys.argv) != 2:
    print("Usage: python3 decrypt_hsm.py <transport_key_hex>")
    sys.exit(1)

# Transport key — pass it in from Step 5's output, don't hardcode it
transport_key = bytes.fromhex(sys.argv[1])

# Read the container binary
with open("flag_container.bin", "rb") as f:
    container = f.read()

# The encrypted payload starts after the header
# You need to identify the exact offset and IV from the container header
# Look at the container structure to find:
# - The IV (initialization vector) for AES-CBC
# - The start offset of the encrypted data
# - The length of the encrypted data

# The IV is typically stored near the wrapped key in the header
# Try extracting 16 bytes right after the wrapped key:
iv = container[0x25C:0x25C + 16]  # Adjust offset based on your analysis
print(f"IV: {iv.hex()}")

# The encrypted payload (adjust offsets based on your analysis)
# Look for where the header ends and data begins
encrypted_data = container[0xC00:]  # Example offset — verify from header

# Decrypt using AES-CBC
cipher = AES.new(transport_key, AES.MODE_CBC, iv)
decrypted = cipher.decrypt(encrypted_data)

# Save the decrypted binary
with open("hsm_decrypted.bin", "wb") as f:
    f.write(decrypted)

print(f"Decrypted {len(decrypted)} bytes → hsm_decrypted.bin")
```

### Alternative: search for the flag after decryption

```bash
# After decrypting, search for readable strings
strings hsm_decrypted.bin | grep -i flag
strings hsm_decrypted.bin | tail -20
```

### Key addresses summary

| What | File | Flash Address | Binary Offset |
|------|------|---------------|---------------|
| Container header | flag_container.s19 | `0x10180000` | `0x000` |
| Wrapped transport key | flag_container.s19 | `0x1018024C` | `0x24C` |
| PSK label "Key1" | sflash_single_bank.srec | `0x17000838` | `0x38` |
| PSK (KEK) value | sflash_single_bank.srec | `0x1700083C` | `0x3C` |
| Encrypted payload | flag_container.s19 | `0x10180C00` | `0xC00` |

### The complete crypto chain

```
sflash[0x3C:0x4C]  →  PSK (16 bytes, the KEK)
                          │
                          ▼  AES-ECB decrypt
container[0x24C:0x25C]  →  Wrapped Key (16 bytes)
                          │
                          ▼  Result = Transport Key
                          │
                          ▼  AES-CBC decrypt (with IV from header)
container[0xC00:]  →  Encrypted HSM binary
                          │
                          ▼  Result = Decrypted HSM (contains the flag!)
```

### Troubleshooting

- If the decrypted output looks like garbage, double-check your offsets and key values
- The IV offset may need adjustment — try examining bytes around the wrapped key area
- Use `xxd hsm_decrypted.bin | head` to verify the output looks like valid ARM code or data
- The flag is typically near the end of the decrypted binary

---

*Still stuck after this? Ask your instructor for help.*
