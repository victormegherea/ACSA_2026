# Hints — HSM Decryption

Use these hints progressively — try each level yourself before revealing the next one. If you're still stuck after Level 6, open `step-by-step.md` for the full walkthrough with exact commands, offsets, and scripts.

---

## 🔧 Tool Reference

| Tool | What it does | Install if missing | Example usage |
|------|-------------|---------------------|---------------|
| **srec_cat** | Convert SREC/S19 to binary and manipulate records | `sudo apt install srecord` | `srec_cat input.srec -offset -0xBASEADDR -o output.bin -binary` |
| **srec_info** | Display SREC file structure & address ranges | `sudo apt install srecord` | `srec_info input.srec` |
| **xxd** | Hex dump utility — view raw bytes | `sudo apt install xxd` | `xxd -s 0xOFFSET -l 16 output.bin` |
| **hexedit** | Interactive hex editor (TUI) | `sudo apt install hexedit` | `hexedit output.bin` |
| **openssl** | Crypto CLI — AES encrypt/decrypt, key operations | `sudo apt install openssl` | `openssl enc -aes-128-ecb -d -K <hex_key> -in wrapped.bin -out unwrapped.bin -nopad` |
| **Python 3** | Scripting with pycryptodome, intelhex, bincopy | `pip install pycryptodome intelhex bincopy` | `AES.new(key, AES.MODE_ECB).decrypt(data)` |
| **strings** | Extract printable strings from binaries | Pre-installed | `strings output.bin \| head` |
| **grep** | Search bytes/text and report byte offsets | Pre-installed | `grep -boa "SOME_LABEL" output.bin` |
| **file** | Identify file types by magic bytes | Pre-installed | `file output.bin` |

---

## Level 1 — Getting Started (Understanding the Files)

<details>
<summary>Click to reveal</summary>

You have two files:
- **`flag_container.s19`** — The HSM update container (contains the encrypted HSM binary + metadata)
- **`sflash_single_bank.srec`** — A dump of the supervisory flash (contains crypto keys)

- SREC files are plain text — just `cat` them and read the format yourself.
- `srec_info` will tell you the flash address range each file covers. Note both ranges down.
- To analyze the data as raw bytes, convert each SREC to a flat binary with `srec_cat`. Look up the `-offset` option so the binary starts at file offset 0 instead of the real flash address — otherwise your byte offsets won't line up later.
- SREC line format is `Stype | byte_count | address | data | checksum`. `S3` records use a 4-byte address.

</details>

---

## Level 2 — Understanding the Container Structure

<details>
<summary>Click to reveal</summary>

- Look at the first chunk of `flag_container.bin` with `xxd`. What kind of structure do you see (header, metadata, repeating filler bytes)?
- The container is generally laid out as: header → wrapped key → encrypted payload → signature.
- Once you rebased the binary to offset 0 during conversion, `binary_offset = flash_address - base_address` for any address you find in the SREC.

</details>

---

## Level 3 — Finding the PSK in Supervisory Flash

<details>
<summary>Click to reveal</summary>

- The Pre-Shared Key (PSK) lives in `sflash.bin`, tagged with a readable ASCII label.
- Run `strings` on `sflash.bin` — what key-like labels do you see?
- `grep -boa "<label>" sflash.bin` gives you the exact byte offset of a label without any hex-formatting headaches.
- Once you know where the label starts and how many bytes it is, the key material follows immediately after it. How many bytes is a typical AES key?

</details>

---

## Level 4 — Finding the Wrapped Key in the Container

<details>
<summary>Click to reveal</summary>

- The transport key isn't stored in the clear — it's encrypted ("wrapped") using the PSK, and it lives inside the container header, before the bulk encrypted payload.
- This is a two-layer key scheme: PSK unwraps the transport key, and the transport key decrypts the actual HSM binary.
- Why might a system use two layers like this instead of one key? (Think about what's device-specific vs. update-specific.)

</details>

---

## Level 5 — Unwrapping the Transport Key

<details>
<summary>Click to reveal</summary>

- The wrap algorithm here is AES in **ECB mode**, keyed with the PSK.
- Use `pycryptodome`'s `Crypto.Cipher.AES` in Python to read both binaries, slice out the PSK and the wrapped key at their respective offsets, and decrypt.
- Print the result as hex and sanity-check that it looks like a plausible 16-byte AES key (not all zeros/garbage).

</details>

---

## Level 6 — Decrypting the HSM Binary

<details>
<summary>Click to reveal (last resort!)</summary>

- The payload is encrypted with AES in **CBC mode**, which needs an IV in addition to the key.
- Look at the bytes immediately following the wrapped key in the container header — that's a good place to start looking for the IV.
- The bulk of the container after the header is the encrypted payload. Slice it out, decrypt with the transport key + IV, and search the result with `strings` for a flag pattern.
- If the decrypted output looks like garbage, double-check your offsets — a single-byte offset error will corrupt everything after it in CBC mode.

</details>

---

## 📚 Reference: Traveo II Crypto Accelerator

<details>
<summary>Click to reveal</summary>

The Traveo II crypto accelerator is **not publicly documented**, but Infineon's **PSoC6** uses a nearly identical crypto accelerator. The only difference is the register base addresses — the instruction set and data encoding are the same.

**PSoC6 Technical Reference Manuals:**
- [Architecture TRM](https://www.infineon.com/dgdl/Infineon-PSoC_6_MCU_CY8C61x4_CY8C62x4_Architecture_Technical_Reference_Manual_PSoC_61_PSoC_62_MCU-AdditionalTechnicalInformation-v04_00-EN.pdf) — describes the crypto accelerator instruction set
- [Registers TRM](https://www.infineon.com/dgdl/Infineon-PSOC_6_MCU_CY8C61X4CY8C62X4_REGISTERS_TECHNICAL_REFERENCE_MANUAL_(TRM)_PSOC_61_PSOC_62_MCU-AdditionalTechnicalInformation-v03_00-EN.pdf) — register addresses and bit fields

**Ghidra tip:** The SVD file for Traveo II is available in the TVII SDK (free registration on Infineon's site). You can load it with Ghidra's SVD-Loader script to get register names in the disassembly.

</details>

---

*Still stuck? Ask your instructor for a targeted hint — they're here to help!*
