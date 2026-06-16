#!/usr/bin/env python3
"""
Simple CAN Intrusion Detection System (IDS) — Template for Track B (Medium)

This is a TEMPLATE with TODO sections for students to complete.
The IDS monitors CAN traffic and detects anomalies using three heuristics:
  1. Unknown ID detection — IDs not in the whitelist
  2. Rate burst detection — too many frames per second from one ID
  3. Value jump detection — implausible signal value changes

Usage:
    python3 simple_ids.py                          # Monitor live on vcan0
    python3 simple_ids.py --file attack_trace.log  # Analyze a log file
    python3 simple_ids.py --learn normal_drive.log # Learn baseline first

ETHICS: Simulation only. This is a teaching tool, not production-grade.
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


# ============================================================================
# CONFIGURATION — Students can tune these thresholds
# ============================================================================

# Whitelist of known/expected CAN IDs (from ICSim)
KNOWN_IDS = {
    0x0AA,  # Brake status
    0x0B4,  # Steering angle
    0x0C4,  # Engine RPM
    0x188,  # Turn signals
    0x19B,  # Door status
    0x244,  # Vehicle speed
}

# Maximum frames per second per ID before triggering a rate alert
MAX_RATE_PER_ID = 15  # frames/sec

# Maximum allowed value jump between consecutive frames (per ID)
# Students should tune these based on what's physically plausible
MAX_VALUE_JUMPS = {
    0x0C4: 5000,   # RPM shouldn't jump more than 5000 in one step
    0x244: 8000,   # Speed shouldn't jump more than 80 km/h in one step
    0x19B: None,    # Door status — any change is suspicious while driving
}

# Time window for rate calculation (seconds)
RATE_WINDOW = 1.0


# ============================================================================
# ALERT LOGGING
# ============================================================================

class AlertLog:
    """Simple alert logger with severity levels."""

    def __init__(self):
        self.alerts = []
        self.counts = defaultdict(int)

    def alert(self, severity, alert_type, message, arb_id=None, data=None):
        """Log an alert."""
        timestamp = time.time()
        entry = {
            "time": timestamp,
            "severity": severity,
            "type": alert_type,
            "message": message,
            "arb_id": arb_id,
            "data": data,
        }
        self.alerts.append(entry)
        self.counts[alert_type] += 1

        # Color-coded output
        colors = {"HIGH": "\033[91m", "MEDIUM": "\033[93m", "LOW": "\033[96m"}
        reset = "\033[0m"
        color = colors.get(severity, "")

        id_str = f"0x{arb_id:03X}" if arb_id else "---"
        print(f"  {color}[ALERT {severity:6s}]{reset} [{id_str}] "
              f"{alert_type}: {message}")

    def summary(self):
        """Print alert summary."""
        print(f"\n{'='*60}")
        print("  IDS Alert Summary")
        print(f"{'='*60}")
        print(f"  Total alerts: {len(self.alerts)}")
        for alert_type, count in sorted(self.counts.items()):
            print(f"    {alert_type}: {count}")
        print(f"{'='*60}")


# ============================================================================
# DETECTION HEURISTICS
# ============================================================================

class SimpleIDS:
    """Simple rule-based CAN IDS."""

    def __init__(self):
        self.log = AlertLog()
        self.last_values = {}           # Last decoded value per ID
        self.frame_times = defaultdict(list)  # Timestamps per ID
        self.total_frames = 0

    def check_unknown_id(self, arb_id, data):
        """
        HEURISTIC 1: Unknown ID Detection
        Alert if we see an arbitration ID not in our whitelist.
        """
        # TODO (students): Implement this check
        # Hint: Compare arb_id against KNOWN_IDS
        # If unknown, call self.log.alert(...)

        if arb_id not in KNOWN_IDS:
            self.log.alert(
                "HIGH", "UNKNOWN_ID",
                f"Unknown arbitration ID 0x{arb_id:03X} detected "
                f"(data: {data.hex().upper()})",
                arb_id=arb_id, data=data
            )
            return True
        return False

    def check_rate_burst(self, arb_id, timestamp):
        """
        HEURISTIC 2: Rate Burst Detection
        Alert if frames from one ID arrive faster than expected.
        """
        # TODO (students): Implement this check
        # Hint: Track timestamps per ID in self.frame_times
        # Count how many arrived in the last RATE_WINDOW seconds
        # If count > MAX_RATE_PER_ID, alert

        # Record this frame's timestamp
        self.frame_times[arb_id].append(timestamp)

        # Remove timestamps outside the window
        cutoff = timestamp - RATE_WINDOW
        self.frame_times[arb_id] = [
            t for t in self.frame_times[arb_id] if t > cutoff
        ]

        rate = len(self.frame_times[arb_id])
        if rate > MAX_RATE_PER_ID:
            self.log.alert(
                "HIGH", "RATE_BURST",
                f"Rate burst: {rate} frames/sec (max: {MAX_RATE_PER_ID})",
                arb_id=arb_id
            )
            return True
        return False

    def check_value_jump(self, arb_id, data):
        """
        HEURISTIC 3: Value Jump Detection
        Alert if a signal value changes more than physically plausible.
        """
        # TODO (students): Implement this check
        # Hint: Decode the value from data bytes, compare to self.last_values
        # If the jump exceeds MAX_VALUE_JUMPS, alert

        if arb_id not in MAX_VALUE_JUMPS:
            return False

        max_jump = MAX_VALUE_JUMPS[arb_id]
        if max_jump is None:
            # For door status: any change while driving is suspicious
            current = int.from_bytes(data[3:4], "big") if len(data) > 3 else 0
            if arb_id in self.last_values:
                if current != self.last_values[arb_id]:
                    self.log.alert(
                        "MEDIUM", "VALUE_CHANGE",
                        f"Door status changed: 0x{self.last_values[arb_id]:02X}"
                        f" → 0x{current:02X}",
                        arb_id=arb_id, data=data
                    )
                    self.last_values[arb_id] = current
                    return True
            self.last_values[arb_id] = current
            return False

        # Extract raw value (bytes 2-4 for RPM, 3-5 for speed)
        if arb_id == 0x0C4:
            current = int.from_bytes(data[2:4], "big") if len(data) >= 4 else 0
        elif arb_id == 0x244:
            current = int.from_bytes(data[3:5], "big") if len(data) >= 5 else 0
        else:
            return False

        if arb_id in self.last_values:
            jump = abs(current - self.last_values[arb_id])
            if jump > max_jump:
                self.log.alert(
                    "HIGH", "VALUE_JUMP",
                    f"Value jump: {self.last_values[arb_id]} → {current} "
                    f"(delta: {jump}, max: {max_jump})",
                    arb_id=arb_id, data=data
                )
                self.last_values[arb_id] = current
                return True

        self.last_values[arb_id] = current
        return False

    def process_frame(self, arb_id, data, timestamp=None):
        """Process a single CAN frame through all heuristics."""
        if timestamp is None:
            timestamp = time.time()

        self.total_frames += 1
        self.check_unknown_id(arb_id, data)
        self.check_rate_burst(arb_id, timestamp)
        self.check_value_jump(arb_id, data)


# ============================================================================
# MAIN — Live monitoring or file analysis
# ============================================================================

def monitor_live(interface="vcan0"):
    """Run IDS on live CAN traffic."""
    print(f"\n{'='*60}")
    print(f"  Simple CAN IDS — Live Monitor on {interface}")
    print(f"  Press Ctrl+C to stop")
    print(f"{'='*60}\n")

    ids = SimpleIDS()

    try:
        bus = can.interface.Bus(channel=interface, interface="socketcan")
    except Exception as e:
        print(f"ERROR: Cannot open {interface}: {e}")
        sys.exit(1)

    try:
        for msg in bus:
            ids.process_frame(msg.arbitration_id, msg.data)
    except KeyboardInterrupt:
        pass
    finally:
        bus.shutdown()
        ids.log.summary()


def analyze_file(filepath):
    """Run IDS on a log file."""
    print(f"\n{'='*60}")
    print(f"  Simple CAN IDS — File Analysis: {filepath}")
    print(f"{'='*60}\n")

    ids = SimpleIDS()

    with open(filepath, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                ts_str = line.split(")")[0].replace("(", "").strip()
                timestamp = float(ts_str)
                rest = line.split(")")[1].strip()
                parts = rest.split()
                id_data = parts[1]
                arb_id_str, data_str = id_data.split("#")
                arb_id = int(arb_id_str, 16)
                data = bytes.fromhex(data_str)
                ids.process_frame(arb_id, data, timestamp)
            except (ValueError, IndexError):
                continue

    ids.log.summary()
    print(f"\n  Processed {ids.total_frames} frames from {filepath}")


def main():
    parser = argparse.ArgumentParser(description="Simple CAN IDS")
    parser.add_argument("--interface", "-i", default="vcan0",
                        help="CAN interface for live monitoring")
    parser.add_argument("--file", "-f", default=None,
                        help="Analyze a log file instead of live")
    args = parser.parse_args()

    if args.file:
        analyze_file(args.file)
    else:
        monitor_live(args.interface)


if __name__ == "__main__":
    main()
