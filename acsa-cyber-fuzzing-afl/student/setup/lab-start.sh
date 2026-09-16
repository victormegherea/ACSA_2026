#!/usr/bin/env bash
# =============================================================================
# Software Fuzzing Lab — Lab Start Script
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Software Fuzzing Lab (AFL++)${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

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

check_tool afl-fuzz
if command -v afl-clang-fast &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} afl-clang-fast"
elif command -v afl-clang-lto &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} afl-clang-lto (fallback AFL++ compiler)"
else
    echo -e "  ${RED}✗${NC} AFL++ compiler (afl-clang-fast or afl-clang-lto) — NOT FOUND"
    MISSING=$((MISSING + 1))
fi
check_tool afl-tmin
check_tool afl-cmin
check_tool gdb
check_tool objdump
check_tool nm
check_tool gcc

echo ""
if [[ $MISSING -gt 0 ]]; then
    echo -e "${RED}[!] $MISSING required tool(s) missing.${NC}"
    echo -e "    Ask your instructor for the VM setup script."
    echo ""
    exit 1
fi

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${CYAN}Lab directory:${NC} $LAB_DIR"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • afl-fuzz / afl-clang-fast or afl-clang-lto — Coverage-guided fuzzing"
echo "  • afl-tmin / afl-cmin        — Minimize crashes & corpora"
echo "  • gdb / objdump / nm         — Crash triage & manual analysis"
echo ""
echo -e "${CYAN}Quick start — Medium track:${NC}"
echo "  1. cd $LAB_DIR/challenge_files/medium/"
echo "  2. ./build.sh"
echo "  3. afl-fuzz -i seeds -o out -- ./vuln_medium @@"
echo "  4. ./vuln_medium out/default/crashes/<crash_file>   # replay the crash"
echo ""
echo -e "${CYAN}Quick start — Hard track:${NC}"
echo "  1. cd $LAB_DIR/challenge_files/hard/"
echo "  2. ./build.sh"
echo "  3. AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@"
echo "  4. Use gdb + the ASan report to understand the crash, then replay the exploit with ./vuln_hard"
echo ""
echo -e "${CYAN}AFL++ basics:${NC}"
echo "  afl-fuzz -i <seeds_dir> -o <out_dir> -- <target> @@   # @@ = path to input file"
echo "  Ctrl+C to stop fuzzing — progress is saved in <out_dir>"
echo "  out/default/crashes/  — inputs that made the target crash"
echo "  out/default/queue/    — all 'interesting' inputs found so far"
echo ""
echo -e "${GREEN}Happy fuzzing! 🐛${NC}"
echo ""
