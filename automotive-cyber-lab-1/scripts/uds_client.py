#!/usr/bin/env python3
"""
UDS Client over CAN — Template for Track C (Hard)

Sends UDS requests over ISO-TP on vcan0 to interact with a virtual ECU.
Demonstrates DiagnosticSessionControl, SecurityAccess, ReadData, WriteData.

Usage:
    python3 uds_client.py              # Interactive mode
    python3 uds_client.py --demo       # Run demo sequence

Requires: python-can, isotp, udsoncan
ETHICS: Simulation only.
"""

import sys
import time

try:
    import can
except ImportError:
    print("ERROR: pip3 install python-can")
    sys.exit(1)

# ============================================================================
# SIMPLE UDS-OVER-CAN CLIENT (no isotp dependency required)
# ============================================================================

# Standard UDS Service IDs
SID_DIAGNOSTIC_SESSION = 0x10
SID_SECURITY_ACCESS    = 0x27
SID_READ_DATA          = 0x22
SID_WRITE_DATA         = 0x2E
SID_TESTER_PRESENT     = 0x3E

# UDS Negative Response Codes
NRC_NAMES = {
    0x10: "General reject",
    0x11: "Service not supported",
    0x12: "SubFunction not supported",
    0x13: "Incorrect message length",
    0x14: "Response too long",
    0x22: "Conditions not correct",
    0x24: "Request sequence error",
    0x25: "No response from subnet",
    0x31: "Request out of range",
    0x33: "Security access denied",
    0x35: "Invalid key",
    0x36: "Exceeded number of attempts",
    0x37: "Required time delay not expired",
}


class SimpleUDSClient:
    """Minimal UDS client that sends/receives single-frame messages on CAN."""

    def __init__(self, interface="vcan0", tx_id=0x7E0, rx_id=0x7E8):
        self.tx_id = tx_id
        self.rx_id = rx_id
        self.interface = interface
        self.bus = None

    def connect(self):
        """Open the CAN bus."""
        try:
            self.bus = can.interface.Bus(
                channel=self.interface, interface="socketcan"
            )
            print(f"  [UDS] Connected to {self.interface} "
                  f"(TX: 0x{self.tx_id:03X}, RX: 0x{self.rx_id:03X})")
            return True
        except Exception as e:
            print(f"  [UDS] Connection failed: {e}")
            return False

    def disconnect(self):
        """Close the CAN bus."""
        if self.bus:
            self.bus.shutdown()
            print("  [UDS] Disconnected.")

    def send_request(self, data, timeout=2.0):
        """Send a UDS request and wait for response."""
        # Pad to 8 bytes (single frame: first byte = length)
        payload = bytes([len(data)] + list(data))
        payload = payload.ljust(8, b'\x00')

        msg = can.Message(
            arbitration_id=self.tx_id,
            data=payload,
            is_extended_id=False
        )

        print(f"  [TX] 0x{self.tx_id:03X}: {payload.hex().upper()}")
        self.bus.send(msg)

        # Wait for response
        deadline = time.time() + timeout
        while time.time() < deadline:
            rx = self.bus.recv(timeout=0.5)
            if rx and rx.arbitration_id == self.rx_id:
                print(f"  [RX] 0x{self.rx_id:03X}: {rx.data.hex().upper()}")
                return self._parse_response(rx.data)

        print("  [RX] Timeout — no response")
        return None

    def _parse_response(self, data):
        """Parse a UDS response frame."""
        length = data[0]
        if length == 0:
            return {"status": "empty"}

        sid = data[1]

        # Negative response
        if sid == 0x7F:
            rejected_sid = data[2]
            nrc = data[3]
            nrc_name = NRC_NAMES.get(nrc, "Unknown")
            return {
                "status": "negative",
                "sid": rejected_sid,
                "nrc": nrc,
                "nrc_name": nrc_name,
            }

        # Positive response (SID + 0x40)
        return {
            "status": "positive",
            "sid": sid - 0x40,
            "data": data[2:1+length],
        }

    # --- High-level UDS services ---

    def diagnostic_session(self, session_type=0x03):
        """Service 0x10: DiagnosticSessionControl."""
        print(f"\n  --- DiagnosticSessionControl (session={session_type}) ---")
        return self.send_request([SID_DIAGNOSTIC_SESSION, session_type])

    def request_seed(self):
        """Service 0x27/01: SecurityAccess — Request Seed."""
        print("\n  --- SecurityAccess: Request Seed ---")
        return self.send_request([SID_SECURITY_ACCESS, 0x01])

    def send_key(self, key_bytes):
        """Service 0x27/02: SecurityAccess — Send Key."""
        print(f"\n  --- SecurityAccess: Send Key ---")
        return self.send_request(
            [SID_SECURITY_ACCESS, 0x02] + list(key_bytes)
        )

    def read_data_by_id(self, did):
        """Service 0x22: ReadDataByIdentifier."""
        did_hi = (did >> 8) & 0xFF
        did_lo = did & 0xFF
        print(f"\n  --- ReadDataByIdentifier (DID=0x{did:04X}) ---")
        return self.send_request([SID_READ_DATA, did_hi, did_lo])

    def write_data_by_id(self, did, value_bytes):
        """Service 0x2E: WriteDataByIdentifier."""
        did_hi = (did >> 8) & 0xFF
        did_lo = did & 0xFF
        print(f"\n  --- WriteDataByIdentifier (DID=0x{did:04X}) ---")
        return self.send_request(
            [SID_WRITE_DATA, did_hi, did_lo] + list(value_bytes)
        )

    def tester_present(self):
        """Service 0x3E: TesterPresent."""
        return self.send_request([SID_TESTER_PRESENT, 0x00])


def print_result(result):
    """Pretty-print a UDS response."""
    if result is None:
        print("  Result: No response (timeout)")
        return

    if result["status"] == "positive":
        data_hex = result["data"].hex().upper() if result.get("data") else ""
        print(f"  Result: POSITIVE (SID 0x{result['sid']:02X}) "
              f"Data: {data_hex}")
    elif result["status"] == "negative":
        print(f"  Result: NEGATIVE — NRC 0x{result['nrc']:02X} "
              f"({result['nrc_name']})")
    else:
        print(f"  Result: {result}")


def demo_sequence():
    """Run a demo UDS sequence."""
    client = SimpleUDSClient()
    if not client.connect():
        return

    print("\n" + "="*60)
    print("  UDS Demo Sequence")
    print("  Note: Requires a UDS responder on vcan0 (e.g., udsim)")
    print("="*60)

    try:
        # Step 1: Switch to extended session
        r = client.diagnostic_session(0x03)
        print_result(r)

        # Step 2: Request seed
        r = client.request_seed()
        print_result(r)

        # Step 3: Read VIN (public DID)
        r = client.read_data_by_id(0xF190)
        print_result(r)

        # Step 4: Try reading protected DID (should fail)
        r = client.read_data_by_id(0x0100)
        print_result(r)

        # Step 5: Tester present
        r = client.tester_present()
        print_result(r)

    finally:
        client.disconnect()


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        demo_sequence()
    else:
        print("\n  UDS Client — Track C")
        print("  Usage:")
        print("    python3 uds_client.py --demo    Run demo sequence")
        print("    Import and use SimpleUDSClient in your own scripts")
        print()
        print("  Example:")
        print("    from uds_client import SimpleUDSClient")
        print("    client = SimpleUDSClient()")
        print("    client.connect()")
        print("    client.diagnostic_session(0x03)")
        print("    client.request_seed()")
        print("    client.disconnect()")


if __name__ == "__main__":
    main()
