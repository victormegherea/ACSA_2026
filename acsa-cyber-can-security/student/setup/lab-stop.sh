#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity Lab — Stop All Lab Processes
# Usage: lab-stop
#
# Stops ICSim dashboard and controls processes that were started by lab-start.
# Safe to run multiple times — it won't error if nothing is running.
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PID_FILE="/tmp/icsim-lab.pids"

echo -e "${YELLOW}[*] Stopping lab processes...${NC}"

STOPPED=0

# Kill tracked PIDs from the PID file
if [[ -f "$PID_FILE" ]]; then
    while read -r pid; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo -e "  ${GREEN}✓${NC} Stopped PID $pid"
            STOPPED=$((STOPPED + 1))
        fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
fi

# Also kill any remaining ICSim processes by name (safety net)
if pkill -f "icsim vcan0" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Stopped icsim"
    STOPPED=$((STOPPED + 1))
fi

if pkill -f "controls vcan0" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Stopped controls"
    STOPPED=$((STOPPED + 1))
fi

if [[ $STOPPED -eq 0 ]]; then
    echo -e "  No lab processes were running."
else
    echo -e "${GREEN}[✓] All lab processes stopped.${NC}"
fi
