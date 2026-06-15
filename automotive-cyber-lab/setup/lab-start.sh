#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity Lab — Environment Launcher
# Usage: lab-start [--no-icsim]
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

if [[ -f /opt/SavvyCAN/SavvyCAN ]]; then
    echo -e "  ${GREEN}✓${NC} SavvyCAN"
else
    echo -e "  ${YELLOW}⚠${NC} SavvyCAN — not found at /opt/SavvyCAN"
fi

python3 -c "import can" 2>/dev/null && echo -e "  ${GREEN}✓${NC} python-can" || echo -e "  ${RED}✗${NC} python-can"
python3 -c "import isotp" 2>/dev/null && echo -e "  ${GREEN}✓${NC} isotp" || echo -e "  ${YELLOW}⚠${NC} isotp (needed for Track C)"
python3 -c "import udsoncan" 2>/dev/null && echo -e "  ${GREEN}✓${NC} udsoncan" || echo -e "  ${YELLOW}⚠${NC} udsoncan (needed for Track C)"

# --- Launch ICSim (unless --no-icsim) -----------------------------------------
if [[ "${1:-}" != "--no-icsim" ]] && [[ -x /opt/ICSim/icsim ]]; then
    echo -e "${GREEN}[3/4]${NC} Launching ICSim..."
    
    cd /opt/ICSim
    ./icsim vcan0 &
    ICSIM_PID=$!
    sleep 2
    
    ./controls vcan0 &
    CONTROLS_PID=$!
    sleep 1
    
    echo -e "  ${GREEN}✓${NC} ICSim dashboard (PID: $ICSIM_PID)"
    echo -e "  ${GREEN}✓${NC} ICSim controls  (PID: $CONTROLS_PID)"
    cd - >/dev/null
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
