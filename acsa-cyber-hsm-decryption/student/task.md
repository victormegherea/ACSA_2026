# HSM Decryption

## Background

The HSM (Hardware Security Module) for the Traveo II is delivered only as an update container to projects. Both the update container and the HSM inside it are protected with secure boot signatures, and the HSM itself is stored **encrypted** inside the container.

In this scenario, the customer wants to sign the HSM with their own keys. Since the HSM team doesn't provide the unencrypted binary, you need to figure out how to:

1. Decrypt the HSM stored in the update container
2. Re-sign the HSM
3. Re-encrypt it
4. Re-sign the update container

For this challenge, the real HSM binary has been replaced with one that ends in a flag you need to extract.

A pre-shared key (PSK) is stored in supervisory flash (sflash) as part of the HSM config area, and is used in the decryption process.

**Provided files** (see `challenge_files/`): `flag_container.s19`, `sflash_single_bank.srec`

## Learning Objectives

- SREC format
- Crypto algorithms
- Binary reverse engineering
- Reading datasheets
- Information gathering

---
*Need a hint? Check `../cheatsheet/hints.md`. Still stuck? `../cheatsheet/step-by-step.md` has the full walkthrough.*
