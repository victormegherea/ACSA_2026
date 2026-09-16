#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity — Software Fuzzing (AFL++) Tools Setup
# Target: Ubuntu 26.04.1 LTS VM
# Run as root: sudo ./vm-setup.sh
#
# This script installs AFL++ and supporting binary analysis tools.
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

REAL_USER="${SUDO_USER:-${USER:-root}}"
if ! REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)" || [[ -z "$REAL_HOME" ]]; then
    warn "Could not resolve a home directory for user '$REAL_USER'."
    exit 1
fi
LAB_DIR="$REAL_HOME/fuzzing-lab"

log "Setting up Software Fuzzing Lab for user: $REAL_USER"
log "Lab directory: $LAB_DIR"

# --- System update ------------------------------------------------------------
log "Updating system packages..."
apt-get update -qq

# --- Install build toolchain ---------------------------------------------------
log "Installing build toolchain..."
apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    llvm \
    libclang-rt-dev \
    cmake \
    git \
    gdb \
    binutils \
    file \
    tree

# --- Install AFL++ --------------------------------------------------------------
log "Installing AFL++..."
if command -v afl-fuzz &>/dev/null \
    && { command -v afl-clang-fast &>/dev/null || command -v afl-clang-lto &>/dev/null; } \
    && command -v afl-tmin &>/dev/null \
    && command -v afl-cmin &>/dev/null; then
    info "AFL++ already installed: $(afl-fuzz --help 2>&1 | head -1 || echo 'unknown version')"
else
    if apt-get install -y --no-install-recommends afl++ 2>/dev/null; then
        log "AFL++ installed from apt."
    else
        warn "afl++ package not available via apt — building from source instead."
        apt-get install -y --no-install-recommends \
            gcc-multilib \
            python3 \
            python3-pip \
            libglib2.0-dev

        AFL_SRC_DIR="/opt/AFLplusplus"
        if [[ ! -d "$AFL_SRC_DIR" ]]; then
            git clone --depth=1 https://github.com/AFLplusplus/AFLplusplus.git "$AFL_SRC_DIR"
        fi
        (
            cd "$AFL_SRC_DIR"
            make distrib -j"$(nproc)"
            make install
        ) || warn "AFL++ source build failed — install manually from https://aflplus.plus/"
    fi
fi

# --- Verify core AFL++ binaries -------------------------------------------------
for tool in afl-fuzz afl-tmin afl-cmin; do
    if command -v "$tool" &>/dev/null; then
        info "$tool available"
    else
        warn "$tool not found — check the AFL++ install."
    fi
done

MISSING_AFL=0
for tool in afl-fuzz afl-tmin afl-cmin; do
    command -v "$tool" &>/dev/null || MISSING_AFL=$((MISSING_AFL + 1))
done
if command -v afl-clang-fast &>/dev/null; then
    info "afl-clang-fast available"
elif command -v afl-clang-lto &>/dev/null; then
    info "afl-clang-lto available (build-script fallback)"
else
    warn "No AFL++ compiler wrapper found (afl-clang-fast or afl-clang-lto)."
    MISSING_AFL=$((MISSING_AFL + 1))
fi
if [[ $MISSING_AFL -gt 0 ]]; then
    warn "$MISSING_AFL required AFL++ tool(s) are unavailable after installation."
    exit 1
fi

# --- Enable core dumps to go to a predictable place (needed by afl-fuzz) -------
log "Configuring core_pattern for AFL++ (afl-fuzz requires this)..."
echo core > /proc/sys/kernel/core_pattern 2>/dev/null \
    || warn "Could not set core_pattern now — run 'echo core | sudo tee /proc/sys/kernel/core_pattern' before fuzzing."

# --- Copy lab files to user home ------------------------------------------------
log "Setting up lab directory..."
INSTRUCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -d "$INSTRUCTOR_DIR/../student" ]]; then
    SOURCE_DIR="$(cd "$INSTRUCTOR_DIR/../student" && pwd)"
else
    SOURCE_DIR="$INSTRUCTOR_DIR"
    warn "student/ folder not found — copying instructor files instead."
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    warn "Student lab directory not found: $SOURCE_DIR"
    exit 1
fi
mkdir -p "$LAB_DIR"
cp -a "$SOURCE_DIR"/. "$LAB_DIR/"
mkdir -p "$LAB_DIR/workspace"
find "$LAB_DIR" -type f -name '*.sh' -exec chmod +x {} +
if ! id "$REAL_USER" &>/dev/null; then
    warn "User '$REAL_USER' does not exist; cannot set lab ownership."
    exit 1
fi
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

# --- Install lab-start command ---------------------------------------------------
log "Installing fuzzing-start command..."
cat > /usr/local/bin/fuzzing-start <<'LABEOF'
#!/usr/bin/env bash
set -euo pipefail
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Software Fuzzing Lab (AFL++)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Available tools:${NC}"
echo "  • afl-fuzz          — Coverage-guided fuzzer"
echo "  • afl-clang-fast/lto — Instrumenting compiler wrapper"
echo "  • afl-tmin          — Minimize a crashing input"
echo "  • afl-cmin          — Minimize a seed corpus"
echo "  • gdb               — Crash triage / manual exploitation"
echo "  • objdump / nm      — Inspect binaries, find function addresses"
echo ""
echo -e "${CYAN}Quick start (medium track):${NC}"
echo "  1. cd ~/fuzzing-lab/challenge_files/medium/"
echo "  2. ./build.sh"
echo "  3. afl-fuzz -i seeds -o out -- ./vuln_medium @@"
echo "  4. Once it finds a crash: ./vuln_medium out/default/crashes/<file>"
echo ""
echo -e "${CYAN}Quick start (hard track):${NC}"
echo "  1. cd ~/fuzzing-lab/challenge_files/hard/"
echo "  2. ./build.sh"
echo "  3. AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@"
echo "  4. Analyze the crash with gdb / the ASan report, then craft the final input for ./vuln_hard"
echo ""
LABEOF
chmod +x /usr/local/bin/fuzzing-start

# --- Summary ----------------------------------------------------------------------
echo ""
echo "=============================================="
log "Software Fuzzing Lab Setup Complete!"
echo "=============================================="
echo ""
info "Installed tools:"
echo "  • AFL++ (afl-fuzz, AFL++ compiler wrapper, afl-tmin, afl-cmin)"
echo "  • clang / llvm — instrumentation toolchain"
echo "  • gdb, objdump, nm — crash triage"
echo ""
info "Lab files:  $LAB_DIR"
info "Quick start: fuzzing-start"
echo ""
