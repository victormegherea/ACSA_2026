# Firmware Reverse Engineering

## Short Description

Embedded devices run firmware — the actual code and configuration that controls the device. Firmware images often contain entire file systems with configuration files, scripts, and binaries. This challenge teaches you how to extract and analyze a firmware image to find sensitive information that should never have been left in plaintext.

## Learning Objectives

By the end of this lab, you will be able to:
1. Use `binwalk` to scan a firmware binary for embedded file systems and signatures
2. Extract embedded file systems from firmware images
3. Navigate an extracted Linux root file system
4. Identify sensitive information (credentials, keys, configuration) stored in firmware
5. Discuss how firmware should be hardened to prevent information leakage

## Task

Use the tools below to reverse engineer the provided firmware binary (`Firmware.bin`) and identify any sensitive information stored within it.

### Your Mission
1. **Scan** the firmware binary to identify what's inside it
2. **Extract** the embedded file system(s)
3. **Explore** the extracted file system — look at directories, scripts, and configuration files
4. **Find** any sensitive information: credentials, passwords, keys, or secrets
5. **Document** what you found and how you found it

### Tools at Your Disposal

| Tool | Purpose | Key Command |
|------|---------|-------------|
| `binwalk` | Scan & extract firmware | `binwalk -e Firmware.bin` |
| `strings` | Find readable text in binaries | `strings Firmware.bin` |
| `file` | Identify file types | `file Firmware.bin` |
| `grep` | Search for patterns | `grep -ri "password" .` |
| `xxd` | Hex dump viewer | `xxd Firmware.bin \| head` |
| `hexedit` | Interactive hex editor | `hexedit Firmware.bin` |
| `tree` | View directory structure | `tree -L 2 .` |
| `find` | Locate files by name/type | `find . -name "*.conf"` |

### Investigation Expectations

Develop your own approach before using guided material. Start by establishing what the image contains, extract any embedded file systems, and trace how configuration and service files relate to each other. Record evidence and reasoning in `workspace/`.

Use `cheatsheet/hints.md` for progressive prompts. After an independent attempt, `cheatsheet/stepbystepguide.md` provides a detailed, repeatable workflow without disclosing the final files or values.

### What to Look For
- Hardcoded usernames and passwords
- Service credentials (Telnet, SSH, FTP, HTTP)
- Private keys or certificates
- Configuration files with sensitive defaults
- Debug or development artifacts left in production firmware

---
*Need a hint? Check `cheatsheet/hints.md`.*
