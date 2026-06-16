#!/usr/bin/env python3
"""
CAN Bus Monitor — Real-time CAN traffic viewer with signal decoding.

Usage:
    python3 can_monitor.py                  # Live monitor on vcan0
    python3 can_monitor.py --file log.log   # Analyze a log file
    python3 can_monitor.py --interface can0 # Use a different interface

Part of the Automotive Cybersecurity Lab.
"""

import argparse
import time
import sys
from collections import defaultdict

try:
    import can
except ImportError:
    print("ERROR: python-can not installed. Run: pip3 install python-can")
    sys.exit(1)


# Known ICSim signal definitions
SIGNAL_MAP = {
    0x0C4: {"name": "Engine RPM",      "bytes": (2, 4), "scale": 1.0,   "unit": "RPM"},
    0x244: {"name": "Vehicle Speed",    "bytes": (3, 5), "scale": 0.01,  "unit": "km/h"},
    0x19B: {"name": "Door Status",      "bytes": (3, 4), "scale": 1.0,   "unit": ""},
    0x188: {"name": "Turn Signals",     "bytes": (0, 5), "scale": 1.0,   "unit": ""},
    0x0B4: {"name": "Steering Angle",   "bytes": (2, 4), "scale": 0.1,   "unit": "deg"},
    0x0AA: {"name": "Brake Status",     "bytes": (3, 4), "scale": 1.0,   "unit": ""},
}

DOOR_BITS = {
    0x01: "Driver",
    0x02: "Passenger",
    0x04: "Rear-Left",
    0x08: "Rear-Right",
}


def decode_signal(arb_id, data):
    """Decode a known CAN signal from raw data bytes."""
    if arb_id not in SIGNAL_MAP:
        return None

    sig = SIGNAL_MAP[arb_id]
    start, end = sig["bytes"]
    raw_value = int.from_bytes(data[start:end], byteorder="big")
    value = raw_value * sig["scale"]

    # Special decoding for door status
    if arb_id == 0x19B:
        locked = []
        for bit, name in DOOR_BITS.items():
            if raw_value & bit:
                locked.append(name)
        status = ", ".join(locked) if locked else "ALL UNLOCKED"
        return f"{sig['name']}: {status} (raw: 0x{raw_value:02X})"

    return f"{sig['name']}: {value:.1f} {sig['unit']} (raw: 0x{raw_value:04X})"


def monitor_live(interface="vcan0", duration=None):
    """Monitor live CAN traffic on the given interface."""
    print(f"\n{'='*70}")
    print(f"  CAN Bus Monitor — Live on {interface}")
    print(f"  Press Ctrl+C to stop")
    print(f"{'='*70}\n")

    stats = defaultdict(int)
    start_time = time.time()

    try:
        bus = can.interface.Bus(channel=interface, interface="socketcan")
    except Exception as e:
        print(f"ERROR: Cannot open {interface}: {e}")
        print("Make sure vcan0 is up: sudo ip link set vcan0 up")
        sys.exit(1)

    try:
        for msg in bus:
            stats[msg.arbitration_id] += 1
            elapsed = time.time() - start_time

            decoded = decode_signal(msg.arbitration_id, msg.data)
            data_hex = msg.data.hex().upper()

            if decoded:
                print(f"[{elapsed:8.3f}s] 0x{msg.arbitration_id:03X} [{msg.dlc}] "
                      f"{data_hex:<16s}  → {decoded}")
            else:
                print(f"[{elapsed:8.3f}s] 0x{msg.arbitration_id:03X} [{msg.dlc}] "
                      f"{data_hex:<16s}  → UNKNOWN ID")

            if duration and elapsed > duration:
                break

    except KeyboardInterrupt:
        pass
    finally:
        bus.shutdown()
        print(f"\n{'='*70}")
        print("  Statistics:")
        for arb_id in sorted(stats.keys()):
            name = SIGNAL_MAP.get(arb_id, {}).get("name", "Unknown")
            print(f"    0x{arb_id:03X} ({name:20s}): {stats[arb_id]} frames")
        total = sum(stats.values())
        elapsed = time.time() - start_time
        print(f"  Total: {total} frames in {elapsed:.1f}s "
              f"({total/elapsed:.1f} frames/sec)")
        print(f"{'='*70}")


def analyze_file(filepath):
    """Analyze a candump log file."""
    print(f"\n{'='*70}")
    print(f"  CAN Log Analyzer — {filepath}")
    print(f"{'='*70}\n")

    stats = defaultdict(int)
    timestamps = []
    lines_parsed = 0

    try:
        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                try:
                    # Parse candump format: (timestamp) interface id#data
                    ts_str = line.split(")")[0].replace("(", "").strip()
                    timestamp = float(ts_str)
                    rest = line.split(")")[1].strip()
                    parts = rest.split()
                    iface = parts[0]
                    id_data = parts[1]
                    arb_id_str, data_str = id_data.split("#")
                    arb_id = int(arb_id_str, 16)
                    data = bytes.fromhex(data_str)

                    stats[arb_id] += 1
                    timestamps.append(timestamp)
                    lines_parsed += 1

                    decoded = decode_signal(arb_id, data)
                    if decoded:
                        print(f"  [{timestamp:.6f}] 0x{arb_id:03X} {data_str:<16s}  → {decoded}")
                    else:
                        print(f"  [{timestamp:.6f}] 0x{arb_id:03X} {data_str:<16s}  → UNKNOWN ID")

                except (ValueError, IndexError):
                    continue

    except FileNotFoundError:
        print(f"ERROR: File not found: {filepath}")
        sys.exit(1)

    # Summary
    print(f"\n{'='*70}")
    print("  Summary:")
    print(f"    Frames parsed: {lines_parsed}")
    if timestamps:
        duration = timestamps[-1] - timestamps[0]
        print(f"    Duration: {duration:.3f}s")
        print(f"    Avg rate: {lines_parsed/max(duration,0.001):.1f} frames/sec")
    print(f"\n  ID Distribution:")
    for arb_id in sorted(stats.keys()):
        name = SIGNAL_MAP.get(arb_id, {}).get("name", "UNKNOWN")
        pct = 100 * stats[arb_id] / lines_parsed if lines_parsed else 0
        bar = "█" * int(pct / 2)
        print(f"    0x{arb_id:03X} ({name:20s}): {stats[arb_id]:4d} ({pct:5.1f}%) {bar}")
    print(f"{'='*70}")


def main():
    parser = argparse.ArgumentParser(description="CAN Bus Monitor")
    parser.add_argument("--interface", "-i", default="vcan0",
                        help="CAN interface (default: vcan0)")
    parser.add_argument("--file", "-f", default=None,
                        help="Analyze a candump log file instead of live")
    parser.add_argument("--duration", "-d", type=float, default=None,
                        help="Monitor duration in seconds (live mode)")
    args = parser.parse_args()

    if args.file:
        analyze_file(args.file)
    else:
        monitor_live(args.interface, args.duration)


if __name__ == "__main__":
    main()
