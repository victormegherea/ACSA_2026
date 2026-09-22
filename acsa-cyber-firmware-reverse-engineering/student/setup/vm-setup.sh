#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity — Firmware RE Tools Setup
# Target: Ubuntu 26.04.1 LTS VM
# Run as root: sudo ./vm-setup.sh
#
# This script installs firmware reverse engineering tools.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${RED}[!]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }

# --- Pre-flight checks -------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    warn "This script must be run as root (sudo)."
    exit 1
fi

info "Supported platform: Ubuntu 26.04.1 LTS. Run this script on that release."

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
LAB_DIR="$REAL_HOME/firmware-re-lab"

log "Setting up Firmware Reverse Engineering Lab for user: $REAL_USER"
log "Lab directory: $LAB_DIR"

# --- System update ------------------------------------------------------------
log "Updating system packages..."
apt-get update -qq

# --- Install core firmware RE tools -------------------------------------------
log "Installing firmware reverse engineering tools..."
apt-get install -y --no-install-recommends \
    squashfs-tools \
    cpio \
    mtd-utils \
    gzip \
    bzip2 \
    xz-utils \
    lzop \
    p7zip-full \
    unzip \
    cabextract \
    cramfsswap \
    sleuthkit

# --- Install binwalk ----------------------------------------------------------
# Try apt first (v2.x — works reliably), then optionally upgrade to v3.x
log "Installing binwalk..."
if command -v binwalk &>/dev/null; then
    info "binwalk already installed: $(binwalk --help 2>&1 | head -1 || echo 'unknown version')"
else
    log "Installing binwalk from apt..."
    apt-get install -y --no-install-recommends binwalk \
        || warn "Could not install binwalk from apt."
fi

# Optional: attempt binwalk v3.x upgrade (Rust-based, requires cargo + network)
# Uncomment the block below to try building v3.x from source:
# if command -v cargo &>/dev/null; then
#     log "Attempting binwalk v3.x upgrade (cargo)..."
#     cargo install binwalk 2>/dev/null \
#         && ln -sf "$HOME/.cargo/bin/binwalk" /usr/local/bin/binwalk \
#         && log "binwalk v3.x installed" \
#         || warn "binwalk v3.x build failed — keeping v2.x"
# fi

# --- Install analysis & string-search tools -----------------------------------
log "Installing binary analysis tools..."
apt-get install -y --no-install-recommends \
    file \
    xxd \
    hexedit \
    binutils \
    tree \
    jq

# --- Install Python 3 + pip --------------------------------------------------
log "Ensuring Python 3 and pip are available..."
apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# --- Install sasquatch (non-standard SquashFS extractor) ----------------------
# Required by binwalk to extract non-standard SquashFS found in many firmware images
# Uses pre-built .deb package from https://github.com/Tureto/sasquatch-deb
log "Installing sasquatch..."
if command -v sasquatch &>/dev/null; then
    info "sasquatch already installed"
else
    # Install runtime dependencies for sasquatch
    apt-get install -y --no-install-recommends \
        zlib1g liblzma5 liblzo2-2 liblz4-1 libzstd1 2>/dev/null || true

    # Locate the .deb package shipped alongside this script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SASQUATCH_DEB="$SCRIPT_DIR/sasquatch_1.0+ppa1.ubuntu24.04.1_amd64.deb"

    if [[ -f "$SASQUATCH_DEB" ]]; then
        log "Installing sasquatch from local .deb package..."
        dpkg -i "$SASQUATCH_DEB" || apt-get install -f -y
        log "sasquatch installed successfully from .deb"
    else
        # Fallback: download the .deb from GitHub
        log "Local .deb not found — downloading sasquatch .deb from GitHub..."
        SASQUATCH_DEB_URL="https://github.com/Tureto/sasquatch-deb/releases/download/v1.0/sasquatch_1.0+ppa1.ubuntu24.04.1_amd64.deb"
        SASQUATCH_DEB_TMP="/tmp/sasquatch.deb"
        if curl -fsSL "$SASQUATCH_DEB_URL" -o "$SASQUATCH_DEB_TMP"; then
            dpkg -i "$SASQUATCH_DEB_TMP" || apt-get install -f -y
            rm -f "$SASQUATCH_DEB_TMP"
            log "sasquatch installed successfully from downloaded .deb"
        else
            warn "Could not download sasquatch .deb package."
            warn "Install manually from: https://github.com/Tureto/sasquatch-deb"
        fi
    fi
fi

# --- Install Python firmware analysis packages --------------------------------
log "Installing Python firmware analysis packages..."
pip3 install --no-cache-dir --break-system-packages --root-user-action=ignore \
    ubi_reader \
    jefferson 2>/dev/null || true

# --- Install Ghidra (NSA reverse engineering framework) -----------------------
log "Installing Ghidra..."
GHIDRA_DIR="/opt/ghidra"
if [[ -d "$GHIDRA_DIR" ]]; then
    info "Ghidra already installed at $GHIDRA_DIR"
else
    # Install Java (Ghidra dependency)
    log "Installing Java JDK (Ghidra dependency)..."
    apt-get install -y --no-install-recommends \
        openjdk-21-jdk \
        || apt-get install -y --no-install-recommends openjdk-17-jdk \
        || warn "Could not install Java JDK — Ghidra will not work without it."

    # Download latest Ghidra release (auto-detect URL from GitHub API)
    GHIDRA_ZIP="/tmp/ghidra.zip"
    GHIDRA_URL="$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
        | grep -oE 'https://[^"]+ghidra_[^"]+_PUBLIC_[^"]+\.zip' | head -n1 || true)"

    if [[ -z "$GHIDRA_URL" ]]; then
        warn "Could not determine latest Ghidra release URL from GitHub API."
        warn "Install Ghidra manually from https://ghidra-sre.org/"
    else
        log "Downloading Ghidra from: $GHIDRA_URL"
    fi

    if [[ -n "$GHIDRA_URL" ]] && curl -fsSL -L "$GHIDRA_URL" -o "$GHIDRA_ZIP"; then
        unzip -q "$GHIDRA_ZIP" -d /opt/
        rm -f "$GHIDRA_ZIP"
        # The zip extracts to a versioned directory (e.g. ghidra_12.1.3_PUBLIC) — rename it
        EXTRACTED_DIR=$(find /opt -maxdepth 1 -name "ghidra_*" -type d | head -n1)
        if [[ -n "$EXTRACTED_DIR" && "$EXTRACTED_DIR" != "$GHIDRA_DIR" ]]; then
            mv "$EXTRACTED_DIR" "$GHIDRA_DIR"
        fi
        log "Ghidra installed at $GHIDRA_DIR"

        # Create launcher symlink
        ln -sf "$GHIDRA_DIR/ghidraRun" /usr/local/bin/ghidra
    else
        warn "Could not download Ghidra — install it manually from https://ghidra-sre.org/"
    fi
fi

# --- Install radare2 (CLI reverse engineering framework) ----------------------
log "Installing radare2..."
if command -v r2 &>/dev/null; then
    info "radare2 already installed"
else
    apt-get install -y --no-install-recommends radare2 \
        || {
            log "Installing radare2 from GitHub..."
            git clone --depth=1 https://github.com/radareorg/radare2.git /tmp/radare2
            cd /tmp/radare2
            sys/install.sh
            cd -
            rm -rf /tmp/radare2
        } \
        || warn "Could not install radare2 — install it manually."
fi

# --- Copy lab files to user home ----------------------------------------------
log "Setting up lab directory..."
INSTRUCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -d "$INSTRUCTOR_DIR/../student" ]]; then
    SOURCE_DIR="$(cd "$INSTRUCTOR_DIR/../student" && pwd)"
else
    LAB_NAME_DIR="$(cd "$INSTRUCTOR_DIR/.." && pwd)"
    LAB_NAME="$(basename "$LAB_NAME_DIR")"
    REPO_ROOT="$(cd "$LAB_NAME_DIR/../.." && pwd)"
    SOURCE_DIR="$REPO_ROOT/$LAB_NAME/student"
    if [[ ! -d "$SOURCE_DIR" ]]; then
        warn "student/ folder not found at $SOURCE_DIR"
        exit 1
    fi
fi
info "Lab source: $SOURCE_DIR"

mkdir -p "$LAB_DIR"
cp -r "$SOURCE_DIR"/. "$LAB_DIR/" 2>/dev/null || true

# Create workspace directory
mkdir -p "$LAB_DIR/workspace"

# Fix ownership
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

# --- Install lab-start command ------------------------------------------------
log "Installing firmware-re-start command..."
cat > /usr/local/bin/firmware-re-start <<'LABEOF'
#!/usr/bin/env bash
# Firmware Reverse Engineering — Quick Start
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Firmware Reverse Engineering Lab${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • binwalk        — Firmware extraction & analysis"
echo "  • strings        — Extract printable strings from binaries"
echo "  • file           — Identify file types"
echo "  • xxd / hexdump  — Hex dump utilities"
echo "  • hexedit        — Interactive hex editor"
echo "  • grep           — Search for patterns in files"
echo "  • tree           — Directory structure viewer"
echo "  • ghidra         — GUI reverse engineering framework"
echo "  • r2 (radare2)   — CLI reverse engineering framework"
echo ""
echo -e "${CYAN}Quick start:${NC}"
echo "  1. cd ~/firmware-re-lab"
echo "  2. binwalk Firmware.bin"
echo "  3. binwalk -e Firmware.bin"
echo "  4. cd _Firmware.bin.extracted/"
echo "  5. Explore the extracted file system!"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  binwalk Firmware.bin              # Scan for signatures"
echo "  binwalk -e Firmware.bin           # Extract file systems"
echo "  binwalk -e -M Firmware.bin        # Recursive extraction"
echo "  strings <file> | grep -i pass     # Search for passwords"
echo "  file <file>                       # Identify file type"
echo "  grep -r 'password' ./             # Recursive text search"
echo "  tree -L 2 .                       # Show directory tree"
echo ""
LABEOF
chmod +x /usr/local/bin/firmware-re-start

# --- Create desktop shortcut --------------------------------------------------
log "Creating desktop shortcut..."
DESKTOP_DIR="$REAL_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/Firmware-RE-Lab.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Firmware RE Lab
Comment=Start the Firmware Reverse Engineering Lab
Exec=bash -c 'cd $LAB_DIR && gnome-terminal -- /usr/local/bin/firmware-re-start'
Icon=utilities-terminal
Terminal=false
Categories=Education;
EOF

if [[ -d /opt/ghidra ]]; then
    cat > "$DESKTOP_DIR/Ghidra.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Ghidra
Comment=NSA Reverse Engineering Framework
Exec=/usr/local/bin/ghidra
Icon=applications-engineering
Terminal=false
Categories=Education;Development;
EOF
fi

chmod +x "$DESKTOP_DIR"/*.desktop 2>/dev/null || true
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR"/*.desktop 2>/dev/null || true

# --- Summary ------------------------------------------------------------------
echo ""
echo "=============================================="
log "Firmware RE Lab Setup Complete!"
echo "=============================================="
echo ""
info "Installed tools:"
echo "  • binwalk         — firmware extraction & signature scanning"
echo "  • strings / grep  — string search in binaries"
echo "  • file            — file type identification"
echo "  • xxd / hexdump   — hex dump utilities"
echo "  • hexedit         — interactive hex editor (TUI)"
echo "  • Ghidra          → ${GHIDRA_DIR:-/opt/ghidra}"
echo "  • radare2 (r2)    — CLI reverse engineering framework"
echo "  • squashfs-tools, cpio, mtd-utils — file system utilities"
echo ""
info "Lab files:  $LAB_DIR"
info "Workspace:  $LAB_DIR/workspace"
echo ""
info "Quick start:"
echo "  1. Open a terminal and type: firmware-re-start"
echo "  2. cd ~/firmware-re-lab"
echo "  3. binwalk -e Firmware.bin"
echo "  4. Explore the extracted file system!"
echo ""
