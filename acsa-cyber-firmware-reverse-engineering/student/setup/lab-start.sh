#!/usr/bin/env bash
# =============================================================================
# Firmware Reverse Engineering — Lab Start Script
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Firmware Reverse Engineering Lab${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# --- Check tools are installed ------------------------------------------------
echo -e "${CYAN}Checking required tools...${NC}"
MISSING=0

check_tool() {
    if command -v "$1" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
    else
        echo -e "  ${RED}✗${NC} $1 — NOT FOUND"
        MISSING=$((MISSING + 1))
    fi
}

check_tool binwalk
check_tool strings
check_tool file
check_tool xxd
check_tool grep
check_tool tree

# Optional tools
echo ""
echo -e "${CYAN}Optional tools:${NC}"
for tool in hexedit ghidra r2; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${YELLOW}○${NC} $tool — not installed (optional)"
    fi
done

echo ""
if [[ $MISSING -gt 0 ]]; then
    echo -e "${RED}[!] $MISSING required tool(s) missing.${NC}"
    echo -e "    Run: ${YELLOW}sudo apt install binwalk xxd hexedit tree${NC}"
    echo -e "    Or ask your instructor for the VM setup script."
    echo ""
fi

# --- Show lab info ------------------------------------------------------------
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}Lab directory:${NC} $LAB_DIR"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • binwalk        — Firmware extraction & signature scanning"
echo "  • strings        — Extract printable strings from binaries"
echo "  • file           — Identify file types"
echo "  • xxd / hexdump  — Hex dump utilities"
echo "  • hexedit        — Interactive hex editor (TUI)"
echo "  • grep           — Search for patterns in files"
echo "  • tree           — Directory structure viewer"
echo "  • ghidra         — GUI reverse engineering framework (optional)"
echo "  • r2 (radare2)   — CLI reverse engineering framework (optional)"
echo ""
echo -e "${CYAN}Quick start:${NC}"
echo "  1. Read task.md and inspect Firmware.bin"
echo "  2. Work from $LAB_DIR/workspace/"
echo "  3. Use cheatsheet/hints.md for progressive prompts"
echo "  4. Use cheatsheet/stepbystepguide.md after an independent attempt"
echo ""
echo -e "${YELLOW}Tip:${NC} Check task.md for the full challenge brief."
echo -e "${YELLOW}Tip:${NC} Record commands, paths, and evidence as you investigate."
echo ""
echo -e "${GREEN}Happy hacking! 🔧${NC}"
echo ""
