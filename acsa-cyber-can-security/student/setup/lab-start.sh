#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity Lab — Environment Launcher
# Usage: lab-start [--no-icsim]
#
# ICSim processes are tracked and cleaned up automatically when:
#   - You press Ctrl+C in this terminal
#   - You close this terminal
#   - You run: lab-stop
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- PID tracking file --------------------------------------------------------
PID_FILE="/tmp/icsim-lab.pids"

BANNER="
${CYAN}╔══════════════════════════════════════════════════════════════╗
║          🚗  AUTOMOTIVE CYBERSECURITY LAB  🔒               ║
║                                                              ║
║   Tracks:  Easy │ Medium │ Hard                              ║
║   Time:    120 minutes                                       ║
║   Ethics:  Simulation only • Benign payloads • Be safe       ║
╚══════════════════════════════════════════════════════════════╝${NC}
"

echo -e "$BANNER"

# --- Cleanup function ---------------------------------------------------------
cleanup() {
    echo ""
    echo -e "${YELLOW}[*] Shutting down lab processes...${NC}"
    if [[ -f "$PID_FILE" ]]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Stopped PID $pid" || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    # Also kill any remaining ICSim processes owned by this user
    pkill -f "icsim vcan0" 2>/dev/null || true
    pkill -f "controls vcan0" 2>/dev/null || true
    echo -e "${GREEN}[✓] Lab processes stopped.${NC}"
}

# Register cleanup on EXIT, INT (Ctrl+C), TERM, HUP
trap cleanup EXIT INT TERM HUP

# --- Check / bring up vcan0 ---------------------------------------------------
echo -e "${GREEN}[1/4]${NC} Checking virtual CAN interface..."

sudo modprobe can       2>/dev/null || true
sudo modprobe can_raw   2>/dev/null || true
sudo modprobe vcan      2>/dev/null || true

if ! ip link show vcan0 &>/dev/null; then
    echo "  Creating vcan0..."
    sudo ip link add dev vcan0 type vcan
fi

if ! ip link show vcan0 | grep -q "UP"; then
    sudo ip link set vcan0 up
fi

echo -e "  ${GREEN}✓${NC} vcan0 is UP"

# --- Verify tools -------------------------------------------------------------
echo -e "${GREEN}[2/4]${NC} Verifying tools..."

TOOLS_OK=true
for tool in candump cansniffer cansend canplayer python3; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${RED}✗${NC} $tool — NOT FOUND"
        TOOLS_OK=false
    fi
done

if [[ -x /opt/ICSim/icsim ]]; then
    echo -e "  ${GREEN}✓${NC} ICSim"
else
    echo -e "  ${YELLOW}⚠${NC} ICSim — not found at /opt/ICSim (GUI features limited)"
fi

if command -v savvycan >/dev/null 2>&1 \
   || [[ -x /opt/SavvyCAN/SavvyCAN || -x /opt/SavvyCAN/SavvyCAN.AppImage ]]; then
    echo -e "  ${GREEN}✓${NC} SavvyCAN"
else
    echo -e "  ${YELLOW}⚠${NC} SavvyCAN — not installed (optional GUI analyzer)"
fi

python3 -c "import can" 2>/dev/null && echo -e "  ${GREEN}✓${NC} python-can" || echo -e "  ${RED}✗${NC} python-can"
python3 -c "import isotp" 2>/dev/null && echo -e "  ${GREEN}✓${NC} isotp" || echo -e "  ${YELLOW}⚠${NC} isotp (needed for Track C)"
python3 -c "import udsoncan" 2>/dev/null && echo -e "  ${GREEN}✓${NC} udsoncan" || echo -e "  ${YELLOW}⚠${NC} udsoncan (needed for Track C)"

# --- Launch ICSim (unless --no-icsim) -----------------------------------------
ICSIM_LAUNCHED=false
if [[ "${1:-}" != "--no-icsim" ]] && [[ -x /opt/ICSim/icsim ]]; then
    echo -e "${GREEN}[3/4]${NC} Launching ICSim..."

    # Kill any leftover ICSim processes from a previous run
    pkill -f "icsim vcan0" 2>/dev/null || true
    pkill -f "controls vcan0" 2>/dev/null || true
    sleep 1

    # Clear PID file
    > "$PID_FILE"

    cd /opt/ICSim
    ./icsim vcan0 &
    ICSIM_PID=$!
    echo "$ICSIM_PID" >> "$PID_FILE"
    sleep 2

    ./controls vcan0 &
    CONTROLS_PID=$!
    echo "$CONTROLS_PID" >> "$PID_FILE"
    sleep 1

    echo -e "  ${GREEN}✓${NC} ICSim dashboard (PID: $ICSIM_PID)"
    echo -e "  ${GREEN}✓${NC} ICSim controls  (PID: $CONTROLS_PID)"
    cd - >/dev/null
    ICSIM_LAUNCHED=true
else
    echo -e "${GREEN}[3/4]${NC} Skipping ICSim launch"
fi

# --- Print quick reference ----------------------------------------------------
echo -e "${GREEN}[4/4]${NC} Ready!"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Quick Commands:${NC}"
echo "  candump vcan0                    — Watch all CAN traffic"
echo "  cansniffer -c vcan0              — Interactive signal monitor"
echo "  cansend vcan0 244#0000001000     — Send a single CAN frame"
echo "  canplayer -I logfile.log         — Replay a CAN log"
echo "  python3 scripts/can_monitor.py   — Python CAN monitor"
echo ""
echo -e "${YELLOW}Lab Files:${NC}"
echo "  ~/automotive-cyber-lab/tracks/   — Track handouts (A/B/C)"
echo "  ~/automotive-cyber-lab/scripts/  — Python templates"
echo "  ~/automotive-cyber-lab/logs/     — Sample CAN logs"
echo "  ~/automotive-cyber-lab/workspace/— Your work goes here"
echo ""
echo -e "${YELLOW}Tips:${NC}"
echo "  • Open multiple terminals (Ctrl+Alt+T)"
echo "  • Use candump in one, work in another"
echo "  • Save your work in ~/automotive-cyber-lab/workspace/"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$ICSIM_LAUNCHED" == "true" ]]; then
    echo -e "${YELLOW}ICSim is running. Press Ctrl+C to stop all lab processes.${NC}"
    echo -e "${YELLOW}Or run 'lab-stop' from another terminal.${NC}"
    echo ""
    # Wait for ICSim processes — this keeps the script alive so the
    # trap can fire on Ctrl+C and clean up the background processes.
    wait $ICSIM_PID 2>/dev/null || true
fi
