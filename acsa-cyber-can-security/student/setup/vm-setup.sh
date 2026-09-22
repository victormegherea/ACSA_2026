
#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity Lab — VM Setup Script
# Target: Ubuntu 26.04.1 LTS Desktop (VirtualBox or VMware)
# Run as root: sudo ./vm-setup.sh
# =============================================================================
# Re-exec under bash if invoked via `sh vm-setup.sh` (dash lacks [[ ]] and other bashisms used below).
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${RED}[!]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }

# --- Pre-flight checks -------------------------------------------------------
# Use `id -u` instead of $EUID: EUID is bash-only and errors under `set -u` if run with sh.
if [[ "$(id -u)" -ne 0 ]]; then
    warn "This script must be run as root (sudo)."
    exit 1
fi

UBUNTU_VERSION="$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-unknown}")"
if [[ "$UBUNTU_VERSION" != "26.04" ]]; then
    warn "This script targets Ubuntu 26.04 LTS (detected: $UBUNTU_VERSION). Continuing anyway."
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
LAB_DIR="$REAL_HOME/automotive-cyber-lab"

log "Setting up Automotive Cybersecurity Lab for user: $REAL_USER"
log "Lab directory: $LAB_DIR"

# --- System update ------------------------------------------------------------
log "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# --- Install core dependencies ------------------------------------------------
log "Installing core dependencies..."
apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    make \
    git \
    wget \
    curl \
    unzip \
    ca-certificates \
    software-properties-common

# --- Networking & CAN tools ---------------------------------------------------
log "Installing CAN/networking tools..."
apt-get install -y --no-install-recommends \
    iproute2 \
    iputils-ping \
    net-tools \
    can-utils

# vcan/can_gw live in linux-modules-extra. The package matching the *running*
# kernel may not exist in the archive, so try broader candidates and never fail.
log "Ensuring CAN kernel modules (linux-modules-extra) are available..."
if modinfo vcan >/dev/null 2>&1; then
    info "vcan module already present for kernel $(uname -r)"
else
    EXTRA_INSTALLED=0
    for pkg in "linux-modules-extra-$(uname -r)" \
               "linux-modules-extra-generic-hwe-26.04" \
               "linux-modules-extra-virtual" \
               "linux-image-generic"; do
        if apt-cache show "$pkg" >/dev/null 2>&1 && \
           apt-get install -y --no-install-recommends "$pkg"; then
            log "Installed $pkg"
            EXTRA_INSTALLED=1
            break
        fi
    done
    if [[ $EXTRA_INSTALLED -eq 0 ]]; then
        warn "Could not install linux-modules-extra for kernel $(uname -r)."
        warn "Reboot into the distro (generic) kernel and re-run this script."
    elif ! modinfo vcan >/dev/null 2>&1; then
        warn "vcan still not found for the running kernel - a reboot is likely required."
    fi
fi

# --- GUI / SDL libraries (for ICSim) -----------------------------------------
log "Installing SDL2 and GUI libraries..."
apt-get install -y --no-install-recommends \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    libpcap-dev

# --- Qt6 libraries (for SavvyCAN) --------------------------------------------
# Ubuntu 26.04 no longer ships the Qt5 dev stack; SavvyCAN builds against Qt6.
log "Installing Qt6 libraries..."
apt-get install -y --no-install-recommends \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    qt6-declarative-dev \
    qt6-serialbus-dev \
    qt6-multimedia-dev \
    qt6-serialport-dev \
    qt6-svg-dev \
    qt6-charts-dev \
    qt6-websockets-dev \
    libgl1-mesa-dev

# --- Python 3 + pip ----------------------------------------------------------
log "Installing Python 3 and pip..."
apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# --- Python CAN/UDS packages --------------------------------------------------
# Prefer distro packages; Ubuntu 26.04 python3 is PEP 668 "externally managed",
# so the remaining pip installs need --break-system-packages (fine on a lab VM).
log "Installing Python CAN/UDS packages (apt)..."
# Installed one-by-one: a single missing package would abort the whole batch.
for pkg in python3-can python3-serial python3-matplotlib python3-pandas; do
    apt-get install -y --no-install-recommends "$pkg" \
        || warn "apt package $pkg unavailable - pip will provide it."
done

log "Installing remaining Python packages (pip)..."
pip3 install --no-cache-dir --break-system-packages --root-user-action=ignore \
    python-can \
    "python-can[serial]" \
    can-isotp \
    udsoncan \
    cantools

# --- Load CAN kernel modules -------------------------------------------------
log "Loading CAN kernel modules..."
modprobe can       2>/dev/null || true
modprobe can_raw   2>/dev/null || true
modprobe can_bcm   2>/dev/null || true
modprobe vcan      2>/dev/null || true
modprobe can_gw    2>/dev/null || true

if ! lsmod | grep -q '^vcan'; then
    warn "vcan module not loaded. Reboot and re-run this script before using the lab."
fi

# Persist modules across reboots
cat > /etc/modules-load.d/can.conf <<EOF
can
can_raw
can_bcm
vcan
can_gw
EOF

log "CAN modules loaded and persisted."

# --- Create vcan0 interface on boot ------------------------------------------
log "Setting up vcan0 to start on boot..."
cat > /etc/systemd/network/80-vcan0.netdev <<EOF
[NetDev]
Name=vcan0
Kind=vcan
EOF

cat > /etc/systemd/network/80-vcan0.network <<EOF
[Match]
Name=vcan0
EOF

systemctl enable systemd-networkd 2>/dev/null || true
systemctl restart systemd-networkd 2>/dev/null || true

# Also bring it up now
ip link add dev vcan0 type vcan 2>/dev/null || true
ip link set vcan0 up 2>/dev/null || true

# --- Install ICSim ------------------------------------------------------------
log "Installing ICSim (Instrument Cluster Simulator)..."
if [[ ! -d /opt/ICSim ]]; then
    git clone --depth=1 https://github.com/zombieCraig/ICSim.git /opt/ICSim
    cd /opt/ICSim
    make
    cd -
else
    info "ICSim already installed at /opt/ICSim"
fi

# --- Install SavvyCAN ---------------------------------------------------------
# The upstream sources do not compile against the Qt 6.9 shipped in 26.04
# (removed QSerialPort error enums), so prefer the released AppImage.
log "Installing SavvyCAN (CAN bus GUI analyzer)..."
SAVVY_BIN=""
if [[ -x /opt/SavvyCAN/SavvyCAN ]]; then
    SAVVY_BIN=/opt/SavvyCAN/SavvyCAN
    info "SavvyCAN already built at /opt/SavvyCAN"
elif [[ -x /opt/SavvyCAN/SavvyCAN.AppImage ]]; then
    SAVVY_BIN=/opt/SavvyCAN/SavvyCAN.AppImage
    info "SavvyCAN AppImage already installed"
else
    mkdir -p /opt/SavvyCAN
    APPIMAGE_URL="$(curl -fsSL https://api.github.com/repos/collin80/SavvyCAN/releases/latest \
        | grep -oE 'https://[^"]+x86_64\.AppImage' | head -n1 || true)"
    if [[ -n "$APPIMAGE_URL" ]] && curl -fsSL "$APPIMAGE_URL" -o /opt/SavvyCAN/SavvyCAN.AppImage; then
        chmod +x /opt/SavvyCAN/SavvyCAN.AppImage
        apt-get install -y --no-install-recommends libfuse2t64 fuse3 2>/dev/null || true
        SAVVY_BIN=/opt/SavvyCAN/SavvyCAN.AppImage
        log "Installed SavvyCAN AppImage"
    else
        warn "Could not fetch the SavvyCAN AppImage - trying a source build..."
        [[ -d /opt/SavvyCAN/.git ]] \
            || git clone --depth=1 https://github.com/collin80/SavvyCAN.git /opt/SavvyCAN-src
        SRC_DIR=$([[ -d /opt/SavvyCAN/.git ]] && echo /opt/SavvyCAN || echo /opt/SavvyCAN-src)
        QMAKE_BIN="$(command -v qmake6 || command -v qmake || true)"
        if [[ -n "$QMAKE_BIN" ]] \
           && ( cd "$SRC_DIR" && rm -f .qmake.stash && "$QMAKE_BIN" && make -j"$(nproc)" ); then
            SAVVY_BIN="$SRC_DIR/SavvyCAN"
        else
            warn "SavvyCAN unavailable - the rest of the lab is unaffected."
        fi
    fi
fi

if [[ -n "$SAVVY_BIN" ]]; then
    printf '#!/bin/sh\nexec %s "$@"\n' "$SAVVY_BIN" > /usr/local/bin/savvycan
    chmod +x /usr/local/bin/savvycan
fi

# --- Copy lab files to user home ----------------------------------------------
log "Setting up lab directory..."
INSTRUCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The student material is the sibling of instructor/ in the repo checkout.
if [[ -d "$INSTRUCTOR_DIR/../student" ]]; then
    SOURCE_DIR="$(cd "$INSTRUCTOR_DIR/../student" && pwd)"
else
    SOURCE_DIR="$INSTRUCTOR_DIR"
    warn "student/ folder not found next to instructor/ - copying instructor files instead."
fi
info "Lab source: $SOURCE_DIR"

mkdir -p "$LAB_DIR"
cp -r "$SOURCE_DIR"/. "$LAB_DIR/" 2>/dev/null || true

# Fix ownership
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

# --- Install lab-start and lab-stop commands globally -------------------------
log "Installing lab-start and lab-stop commands..."
if [[ -f "$LAB_DIR/setup/lab-start.sh" ]]; then
    install -m 755 "$LAB_DIR/setup/lab-start.sh" /usr/local/bin/lab-start
else
    warn "lab-start.sh not found in $LAB_DIR/setup - skipping lab-start install."
fi
if [[ -f "$LAB_DIR/setup/lab-stop.sh" ]]; then
    install -m 755 "$LAB_DIR/setup/lab-stop.sh" /usr/local/bin/lab-stop
else
    warn "lab-stop.sh not found in $LAB_DIR/setup - skipping lab-stop install."
fi

# --- Create desktop shortcuts -------------------------------------------------
log "Creating desktop shortcuts..."
DESKTOP_DIR="$REAL_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/Automotive-Cyber-Lab.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Automotive Cyber Lab
Comment=Start the Automotive Cybersecurity Lab
Exec=bash -c 'cd $LAB_DIR && gnome-terminal -- /usr/local/bin/lab-start'
Icon=utilities-terminal
Terminal=false
Categories=Education;
EOF

if [[ -n "$SAVVY_BIN" ]]; then
    cat > "$DESKTOP_DIR/SavvyCAN.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SavvyCAN
Comment=CAN Bus Reverse Engineering Tool
Exec=/usr/local/bin/savvycan
Icon=applications-engineering
Terminal=false
Categories=Education;Development;
EOF
fi

chmod +x "$DESKTOP_DIR"/*.desktop
chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR"/*.desktop

# --- Create workspace directory -----------------------------------------------
mkdir -p "$LAB_DIR/workspace"
chown "$REAL_USER:$REAL_USER" "$LAB_DIR/workspace"

# --- Summary ------------------------------------------------------------------
echo ""
echo "=============================================="
log "Setup complete!"
echo "=============================================="
echo ""
info "Installed tools:"
echo "  • can-utils (candump, cansniffer, cansend, canplayer)"
echo "  • ICSim      → /opt/ICSim"
echo "  • SavvyCAN   → ${SAVVY_BIN:-not installed}"
echo "  • python-can, can-isotp, udsoncan, cantools"
echo ""
info "Lab files:  $LAB_DIR"
info "Workspace:  $LAB_DIR/workspace"
echo ""
info "Quick start:"
echo "  1. Reboot (or run: lab-start)"
echo "  2. Open a terminal and type: lab-start"
echo "  3. ICSim dashboard + controls will launch"
echo "  4. Use candump/cansniffer in another terminal"
echo "  5. When done: press Ctrl+C or run: lab-stop"
echo ""
info "vcan0 will auto-start on every boot."
info "lab-stop will kill all ICSim processes cleanly."
echo ""
