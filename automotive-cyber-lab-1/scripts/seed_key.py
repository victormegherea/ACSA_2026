#!/usr/bin/env python3
"""
UDS Seed-Key Security Access — Template for Track C (Hard)

This script demonstrates a WEAK seed-key algorithm used for UDS
SecurityAccess (service 0x27). Students must:
  1. Understand how the seed-key challenge works
  2. Reverse-engineer the weak algorithm
  3. Propose a stronger alternative

The weak algorithm is intentionally simple for educational purposes.

ETHICS: Simulation only. Never use on real ECUs or vehicles.
"""

import sys
import struct
import hashlib


# ============================================================================
# WEAK SEED-KEY ALGORITHM (intentionally vulnerable)
# ============================================================================

# Secret "key" used by the ECU (in real life this would be hidden)
ECU_SECRET = 0xCAFE

def weak_seed_key(seed):
    """
    Weak seed-key algorithm — intentionally vulnerable.
    
    Vulnerabilities:
      - Simple XOR with a fixed secret
      - No time-based component
      - Secret is static (never rotates)
      - Only 16-bit key space
    
    Args:
        seed: 2-byte seed value from ECU (int, 0x0000-0xFFFF)
    
    Returns:
        key: 2-byte response key (int)
    """
    # The "algorithm": XOR seed with secret, then rotate bits
    key = seed ^ ECU_SECRET
    # Rotate left by 3 bits (16-bit)
    key = ((key << 3) | (key >> 13)) & 0xFFFF
    return key


def generate_seed():
    """Generate a random seed (simulating ECU behavior)."""
    import random
    return random.randint(0x0001, 0xFFFF)


# ============================================================================
# ECU SIMULATOR
# ============================================================================

class VirtualECU:
    """Simulates a basic ECU with UDS SecurityAccess."""

    def __init__(self):
        self.locked = True
        self.current_seed = None
        self.attempts = 0
        self.max_attempts = 3
        self.session = "default"  # default, extended, programming

    def diagnostic_session_control(self, session_type):
        """UDS Service 0x10 — DiagnosticSessionControl."""
        sessions = {
            0x01: "default",
            0x02: "programming",
            0x03: "extended",
        }
        if session_type in sessions:
            self.session = sessions[session_type]
            print(f"  [ECU] Session changed to: {self.session}")
            return True, f"Positive response: session={self.session}"
        return False, "NRC 0x12: SubFunction not supported"

    def security_access_request_seed(self):
        """UDS Service 0x27 subfunction 0x01 — Request Seed."""
        if self.session == "default":
            return False, "NRC 0x22: Conditions not correct (switch session first)"

        if not self.locked:
            # Already unlocked — return zero seed
            return True, "Seed: 0x0000 (already unlocked)"

        if self.attempts >= self.max_attempts:
            return False, "NRC 0x36: Exceeded number of attempts (wait 10s)"

        self.current_seed = generate_seed()
        print(f"  [ECU] Generated seed: 0x{self.current_seed:04X}")
        return True, f"Seed: 0x{self.current_seed:04X}"

    def security_access_send_key(self, key):
        """UDS Service 0x27 subfunction 0x02 — Send Key."""
        if self.current_seed is None:
            return False, "NRC 0x24: Request sequence error (request seed first)"

        expected_key = weak_seed_key(self.current_seed)
        self.attempts += 1

        if key == expected_key:
            self.locked = False
            self.attempts = 0
            print(f"  [ECU] Key accepted! ECU UNLOCKED.")
            return True, "Positive response: Security Access granted"
        else:
            remaining = self.max_attempts - self.attempts
            print(f"  [ECU] Wrong key! Expected 0x{expected_key:04X}, "
                  f"got 0x{key:04X}. Attempts remaining: {remaining}")
            return False, f"NRC 0x35: Invalid key ({remaining} attempts left)"

    def read_data(self, did):
        """UDS Service 0x22 — ReadDataByIdentifier."""
        # Some DIDs require security access
        data_store = {
            0xF190: ("VIN", "WBA12345678901234"),
            0xF187: ("Part Number", "ECU-SIM-001"),
            0xF191: ("HW Version", "1.0.0"),
            0xF195: ("SW Version", "2.3.1"),
            0x0100: ("Calibration Data", "SECRET_CAL_DATA_42"),
            0x0200: ("Crypto Keys", "AES256_KEY_REDACTED"),
        }

        protected_dids = {0x0100, 0x0200}

        if did in protected_dids and self.locked:
            return False, "NRC 0x33: Security access denied"

        if did in data_store:
            name, value = data_store[did]
            return True, f"{name}: {value}"

        return False, "NRC 0x31: Request out of range"

    def write_data(self, did, value):
        """UDS Service 0x2E — WriteDataByIdentifier."""
        if self.locked:
            return False, "NRC 0x33: Security access denied"

        writable_dids = {0x0100}
        if did not in writable_dids:
            return False, "NRC 0x31: Request out of range (read-only)"

        print(f"  [ECU] DID 0x{did:04X} written: {value}")
        return True, f"Positive response: DID 0x{did:04X} updated"


# ============================================================================
# INTERACTIVE SESSION
# ============================================================================

def interactive_session():
    """Run an interactive UDS session with the virtual ECU."""
    ecu = VirtualECU()

    print(f"\n{'='*60}")
    print("  Virtual ECU — UDS Security Access Lab")
    print("  Track C (Hard)")
    print(f"{'='*60}")
    print()
    print("  Commands:")
    print("    session <1|2|3>     — DiagnosticSessionControl (0x10)")
    print("    seed               — Request Seed (0x27/01)")
    print("    key <hex_value>    — Send Key (0x27/02)")
    print("    read <hex_did>     — ReadDataByIdentifier (0x22)")
    print("    write <hex_did> <value> — WriteDataByIdentifier (0x2E)")
    print("    crack              — Auto-crack using weak algorithm")
    print("    status             — Show ECU status")
    print("    help               — Show this help")
    print("    quit               — Exit")
    print(f"{'='*60}\n")

    while True:
        try:
            cmd = input("  UDS> ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print("\n  Goodbye!")
            break

        if not cmd:
            continue

        parts = cmd.split()
        action = parts[0]

        if action == "quit" or action == "exit":
            print("  Goodbye!")
            break

        elif action == "help":
            print("  Commands: session, seed, key, read, write, crack, status, quit")

        elif action == "status":
            print(f"  Session: {ecu.session}")
            print(f"  Locked:  {ecu.locked}")
            print(f"  Attempts: {ecu.attempts}/{ecu.max_attempts}")

        elif action == "session":
            if len(parts) < 2:
                print("  Usage: session <1|2|3>")
                continue
            try:
                sess = int(parts[1])
                ok, msg = ecu.diagnostic_session_control(sess)
                print(f"  {'OK' if ok else 'FAIL'}: {msg}")
            except ValueError:
                print("  Invalid session number")

        elif action == "seed":
            ok, msg = ecu.security_access_request_seed()
            print(f"  {'OK' if ok else 'FAIL'}: {msg}")

        elif action == "key":
            if len(parts) < 2:
                print("  Usage: key <hex_value>  (e.g., key ABCD)")
                continue
            try:
                key_val = int(parts[1], 16)
                ok, msg = ecu.security_access_send_key(key_val)
                print(f"  {'OK' if ok else 'FAIL'}: {msg}")
            except ValueError:
                print("  Invalid hex value")

        elif action == "read":
            if len(parts) < 2:
                print("  Usage: read <hex_did>  (e.g., read F190)")
                continue
            try:
                did = int(parts[1], 16)
                ok, msg = ecu.read_data(did)
                print(f"  {'OK' if ok else 'FAIL'}: {msg}")
            except ValueError:
                print("  Invalid hex DID")

        elif action == "write":
            if len(parts) < 3:
                print("  Usage: write <hex_did> <value>")
                continue
            try:
                did = int(parts[1], 16)
                value = " ".join(parts[2:])
                ok, msg = ecu.write_data(did, value)
                print(f"  {'OK' if ok else 'FAIL'}: {msg}")
            except ValueError:
                print("  Invalid hex DID")

        elif action == "crack":
            print("  [*] Auto-cracking using known weak algorithm...")
            if ecu.current_seed is None:
                print("  [!] Request a seed first: seed")
                continue
            computed_key = weak_seed_key(ecu.current_seed)
            print(f"  [*] Seed: 0x{ecu.current_seed:04X}")
            print(f"  [*] Computed key: 0x{computed_key:04X}")
            ok, msg = ecu.security_access_send_key(computed_key)
            print(f"  {'OK' if ok else 'FAIL'}: {msg}")

        else:
            print(f"  Unknown command: {action}. Type 'help' for commands.")


# ============================================================================
# STRONGER ALGORITHM (for discussion / comparison)
# ============================================================================

def strong_seed_key(seed, secret, counter):
    """
    Example of a STRONGER seed-key algorithm.
    
    Improvements over the weak version:
      - Uses HMAC-SHA256 (cryptographic hash)
      - Includes a counter to prevent replay
      - 256-bit key space
      - Secret should be unique per ECU
    
    Students should discuss:
      - Why is this better?
      - What attacks does it prevent?
      - What are the remaining weaknesses?
    """
    import hmac
    message = struct.pack(">HI", seed, counter)
    mac = hmac.new(secret.encode(), message, hashlib.sha256)
    return mac.hexdigest()[:8]  # Truncate for demo


def main():
    print("\n  Automotive Cybersecurity Lab — Track C: UDS Security")
    print("  " + "="*55)
    print()
    print("  This script provides:")
    print("    1. A weak seed-key algorithm to analyze")
    print("    2. A virtual ECU to interact with")
    print("    3. A stronger algorithm for comparison")
    print()

    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        # Quick demo of the weak algorithm
        seed = generate_seed()
        key = weak_seed_key(seed)
        print(f"  Demo — Weak Algorithm:")
        print(f"    Seed:   0x{seed:04X}")
        print(f"    Key:    0x{key:04X}")
        print(f"    Secret: 0x{ECU_SECRET:04X}")
        print()
        print(f"  Demo — Strong Algorithm:")
        strong = strong_seed_key(seed, "my_ecu_secret_key", 1)
        print(f"    Seed:    0x{seed:04X}")
        print(f"    Key:     {strong}")
        print(f"    Counter: 1")
    else:
        interactive_session()


if __name__ == "__main__":
    main()
