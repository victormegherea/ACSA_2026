#!/usr/bin/env bash
# =============================================================================
# Automotive Cybersecurity Lab — VM Setup Script
# Target: Ubuntu 22.04 Desktop (VirtualBox or VMware)
# Run as root: sudo ./vm-setup.sh
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
    can-utils \
    linux-modules-extra-$(uname -r)

# --- GUI / SDL libraries (for ICSim) -----------------------------------------
log "Installing SDL2 and GUI libraries..."
apt-get install -y --no-install-recommends \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    libpcap-dev

# --- Qt5 libraries (for SavvyCAN) --------------------------------------------
log "Installing Qt5 libraries..."
apt-get install -y --no-install-recommends \
    qtbase5-dev \
    qtchooser \
    qttools5-dev-tools \
    qt5-qmake \
    qtmultimedia5-dev \
    libqt5serialport5-dev \
    libqt5svg5-dev \
    libqt5charts5-dev \
    libqt5websockets5-dev

# --- Python 3 + pip ----------------------------------------------------------
log "Installing Python 3 and pip..."
apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# --- Python packages for CAN/UDS ---------------------------------------------
log "Installing Python CAN/UDS packages..."
pip3 install --no-cache-dir \
    python-can \
    python-can[serial] \
    isotp \
    udsoncan \
    cantools \
    matplotlib \
    pandas

# --- Load CAN kernel modules -------------------------------------------------
log "Loading CAN kernel modules..."
modprobe can       2>/dev/null || true
modprobe can_raw   2>/dev/null || true
modprobe can_bcm   2>/dev/null || true
modprobe vcan      2>/dev/null || true
modprobe can_gw    2>/dev/null || true

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
log "Installing SavvyCAN (CAN bus GUI analyzer)..."
if [[ ! -d /opt/SavvyCAN ]]; then
    git clone --depth=1 https://github.com/collin80/SavvyCAN.git /opt/SavvyCAN
    cd /opt/SavvyCAN
    qmake
    make -j"$(nproc)"
    cd -
else
    info "SavvyCAN already installed at /opt/SavvyCAN"
fi

# --- Copy lab files to user home ----------------------------------------------
log "Setting up lab directory..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$LAB_DIR"
cp -r "$SCRIPT_DIR"/* "$LAB_DIR/" 2>/dev/null || true

# Fix ownership
chown -R "$REAL_USER:$REAL_USER" "$LAB_DIR"

# --- Install lab-start command globally ---------------------------------------
log "Installing lab-start command..."
cp "$LAB_DIR/setup/lab-start.sh" /usr/local/bin/lab-start
chmod +x /usr/local/bin/lab-start

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

cat > "$DESKTOP_DIR/SavvyCAN.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SavvyCAN
Comment=CAN Bus Reverse Engineering Tool
Exec=/opt/SavvyCAN/SavvyCAN
Icon=applications-engineering
Terminal=false
Categories=Education;Development;
EOF

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
echo "  • SavvyCAN   → /opt/SavvyCAN"
echo "  • python-can, isotp, udsoncan, cantools"
echo ""
info "Lab files:  $LAB_DIR"
info "Workspace:  $LAB_DIR/workspace"
echo ""
info "Quick start:"
echo "  1. Reboot (or run: lab-start)"
echo "  2. Open a terminal and type: lab-start"
echo "  3. ICSim dashboard + controls will launch"
echo "  4. Use candump/cansniffer in another terminal"
echo ""
info "vcan0 will auto-start on every boot."
echo ""
