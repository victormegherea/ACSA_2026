#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity — HSM Decryption Tools Setup
# Target: Ubuntu 26.04.1 LTS VM
# Run as root: sudo ./vm-setup.sh
#
# This script installs HSM/crypto reverse engineering tools.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${RED}[!]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
    warn "This script must be run as root (sudo)."
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
LAB_DIR="$REAL_HOME/hsm-decryption-lab"

log "Setting up HSM Decryption Lab for user: $REAL_USER"
log "Lab directory: $LAB_DIR"

# --- System update ------------------------------------------------------------
log "Updating system packages..."
apt-get update -qq

# --- Install hex editors & binary analysis tools ------------------------------
log "Installing hex editors and binary analysis tools..."
apt-get install -y --no-install-recommends \
    xxd \
    hexedit \
    file \
    tree \
    jq

# --- Install Python 3 + pip + crypto libraries --------------------------------
log "Ensuring Python 3 and crypto libraries are available..."
apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

log "Installing Python crypto and analysis packages..."
pip3 install --no-cache-dir --break-system-packages --root-user-action=ignore \
    pycryptodome \
    cryptography \
    intelhex \
    bincopy \
    pyelftools

# --- Install srec_cat (SRecord toolkit) ---------------------------------------
log "Installing SRecord toolkit (srec_cat, srec_info)..."
apt-get install -y --no-install-recommends srecord \
    || warn "srecord package not available — install manually if needed."

# --- Install OpenSSL CLI ------------------------------------------------------
log "Ensuring OpenSSL CLI is available..."
apt-get install -y --no-install-recommends openssl

# --- NOTE: Ghidra and radare2 are NOT required for this lab -------------------
# This lab can be solved entirely with srec_cat, xxd, strings, and python3.
# If students need Ghidra (e.g. for deeper binary analysis), it should already
# be installed from the firmware reverse-engineering lab's setup script.

# --- Copy lab files to user home ----------------------------------------------
log "Setting up lab directory..."
INSTRUCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -d "$INSTRUCTOR_DIR/../student" ]]; then
    SOURCE_DIR="$(cd "$INSTRUCTOR_DIR/../student" && pwd)"
else
    SOURCE_DIR="$INSTRUCTOR_DIR"
    warn "student/ folder not found — copying instructor files instead."
fi

mkdir -p "$LAB_DIR"
cp -r "$SOURCE_DIR"/. "$LAB_DIR/" 2>/dev/null || true
mkdir -p "$LAB_DIR/workspace"
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

# --- Install lab-start command ------------------------------------------------
log "Installing hsm-decrypt-start command..."
cat > /usr/local/bin/hsm-decrypt-start <<'LABEOF'
#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  HSM Decryption Lab${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • srec_cat       — SREC/S19 file manipulation"
echo "  • srec_info      — SREC/S19 file information"
echo "  • xxd / hexdump  — Hex dump utilities"
echo "  • hexedit        — Interactive hex editor"
echo "  • openssl        — Crypto operations (AES, RSA, etc.)"
echo "  • python3        — With pycryptodome, intelhex, bincopy"
echo "  • strings / grep — String search in binaries"
echo "  • file           — File type identification"
echo ""
echo -e "${CYAN}Quick start:${NC}"
echo "  1. cd ~/hsm-decryption-lab/challenge_files/"
echo "  2. srec_info flag_container.s19       # Examine SREC structure"
echo "  3. xxd flag_container.s19 | head      # View raw hex"
echo "  4. cat sflash_single_bank.srec | head # SREC is text — read it!"
echo "  5. strings sflash.bin                  # Find key labels"
echo ""
echo -e "${CYAN}SREC/S19 quick reference:${NC}"
echo "  S0 = header, S1/S2/S3 = data, S5 = count, S7/S8/S9 = end"
echo "  Format: Stype | byte_count | address | data | checksum"
echo ""
echo -e "${CYAN}Python crypto example:${NC}"
echo "  from Crypto.Cipher import AES"
echo "  cipher = AES.new(key, AES.MODE_CBC, iv)"
echo "  plaintext = cipher.decrypt(ciphertext)"
echo ""
LABEOF
chmod +x /usr/local/bin/hsm-decrypt-start

# --- Summary ------------------------------------------------------------------
echo ""
echo "=============================================="
log "HSM Decryption Lab Setup Complete!"
echo "=============================================="
echo ""
info "Installed tools:"
echo "  • srec_cat/info   — SRecord toolkit"
echo "  • xxd / hexedit   — hex editors"
echo "  • openssl         — crypto CLI"
echo "  • Python: pycryptodome, intelhex, bincopy"
echo ""
info "Lab files:  $LAB_DIR"
info "Quick start: hsm-decrypt-start"
echo ""
