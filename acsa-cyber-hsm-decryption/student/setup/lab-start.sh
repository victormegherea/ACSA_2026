#!/usr/bin/env bash
# =============================================================================
# HSM Decryption — Lab Start Script
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  HSM Decryption Lab${NC}"
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

check_tool python3
check_tool xxd
check_tool file
check_tool strings
check_tool grep
check_tool openssl
check_tool srec_cat
check_tool srec_info

echo ""
echo -e "${CYAN}Optional tools:${NC}"
for tool in hexedit; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${YELLOW}○${NC} $tool — not installed (optional)"
    fi
done

echo ""
echo -e "${CYAN}Checking Python crypto packages...${NC}"
python3 -c "from Crypto.Cipher import AES" 2>/dev/null && echo -e "  ${GREEN}✓${NC} pycryptodome" || echo -e "  ${RED}✗${NC} pycryptodome (pip install pycryptodome)"
python3 -c "import intelhex" 2>/dev/null && echo -e "  ${GREEN}✓${NC} intelhex" || echo -e "  ${YELLOW}○${NC} intelhex (pip install intelhex)"
python3 -c "import bincopy" 2>/dev/null && echo -e "  ${GREEN}✓${NC} bincopy" || echo -e "  ${YELLOW}○${NC} bincopy (pip install bincopy)"

echo ""
if [[ $MISSING -gt 0 ]]; then
    echo -e "${RED}[!] $MISSING required tool(s) missing.${NC}"
    echo -e "    Ask your instructor for the VM setup script."
    echo ""
fi

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${CYAN}Lab directory:${NC} $LAB_DIR"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • srec_cat/info   — SREC/S19 file parsing & manipulation"
echo "  • xxd / hexedit   — Hex dump & editing"
echo "  • openssl         — Crypto operations (AES, key wrapping, etc.)"
echo "  • python3         — With pycryptodome, intelhex, bincopy"
echo "  • strings / grep  — String search in binaries"
echo ""
echo -e "${CYAN}Quick start:${NC}"
echo "  1. cd $LAB_DIR/challenge_files/"
echo "  2. srec_info flag_container.s19              # Examine structure"
echo "  3. srec_cat flag_container.s19 -offset -0x10180000 -o flag.bin -binary"
echo "  4. srec_cat sflash_single_bank.srec -offset -0x17000800 -o sflash.bin -binary"
echo "  5. xxd flag.bin | head                       # View raw hex"
echo "  6. strings sflash.bin                        # Find key labels"
echo ""
echo -e "${CYAN}SREC format:${NC}"
echo "  S0 = header | S1/S2/S3 = data | S5 = count | S7/S8/S9 = end"
echo "  Each line: Stype | byte_count | address | data | checksum"
echo ""
echo -e "${CYAN}Python crypto example:${NC}"
echo "  from Crypto.Cipher import AES"
echo "  cipher = AES.new(key, AES.MODE_ECB)"
echo "  transport_key = cipher.decrypt(wrapped_key)"
echo ""
echo -e "${GREEN}Happy hacking! 🔐${NC}"
echo ""
