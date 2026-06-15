#!/usr/bin/env bash
# =============================================================================
# Export VM as .ova for student distribution
# Run this on the HOST machine (not inside the VM)
#
# Prerequisites:
#   - VirtualBox installed with VBoxManage in PATH
#   - VM named "Automotive-Cyber-Lab" exists and is powered off
#
# Usage: ./create-ova.sh [vm-name]
# =============================================================================
set -euo pipefail

VM_NAME="${1:-Automotive-Cyber-Lab}"
OUTPUT_DIR="$(pwd)"
OUTPUT_FILE="$OUTPUT_DIR/Automotive-Cyber-Lab.ova"
TIMESTAMP=$(date +%Y%m%d)

echo "=============================================="
echo "  Automotive Cybersecurity Lab — OVA Export"
echo "=============================================="
echo ""
echo "  VM Name:    $VM_NAME"
echo "  Output:     $OUTPUT_FILE"
echo ""

# Check VBoxManage exists
if ! command -v VBoxManage &>/dev/null; then
    echo "ERROR: VBoxManage not found. Install VirtualBox first."
    exit 1
fi

# Check VM exists
if ! VBoxManage showvminfo "$VM_NAME" &>/dev/null; then
    echo "ERROR: VM '$VM_NAME' not found."
    echo ""
    echo "Available VMs:"
    VBoxManage list vms
    exit 1
fi

# Check VM is powered off
STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d'"' -f2)
if [[ "$STATE" != "poweroff" ]]; then
    echo "ERROR: VM must be powered off (current state: $STATE)"
    echo "Run: VBoxManage controlvm '$VM_NAME' poweroff"
    exit 1
fi

# Clean up VM before export
echo "[1/4] Preparing VM for export..."

# Remove shared folders (host-specific)
VBoxManage sharedfolder remove "$VM_NAME" --name workspace 2>/dev/null || true

# Compact the disk (optional, saves space)
echo "[2/4] Compacting virtual disk..."
DISK=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "SATA-0-0" | cut -d'"' -f4)
if [[ -n "$DISK" ]]; then
    VBoxManage modifymedium disk "$DISK" --compact 2>/dev/null || true
fi

# Export
echo "[3/4] Exporting to OVA (this may take several minutes)..."
VBoxManage export "$VM_NAME" \
    --output "$OUTPUT_FILE" \
    --ovf20 \
    --manifest \
    --options nomacs \
    --vsys 0 \
    --product "Automotive Cybersecurity Lab" \
    --producturl "https://github.com/your-org/automotive-cyber-lab" \
    --vendor "Cybersecurity Education" \
    --version "1.0-$TIMESTAMP" \
    --description "2-hour automotive cybersecurity lab with ICSim, can-utils, SavvyCAN, python-can. Three tracks: Easy/Medium/Hard." \
    --eula "For educational use only. Simulation-based. No real vehicles."

# Summary
echo "[4/4] Export complete!"
echo ""
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "=============================================="
echo "  OVA file: $OUTPUT_FILE"
echo "  Size:     $SIZE"
echo "=============================================="
echo ""
echo "  Distribution instructions:"
echo "  1. Upload to your course platform or shared drive"
echo "  2. Students import via: VirtualBox → File → Import Appliance"
echo "  3. Default credentials: student / cybersec2024"
echo "  4. After import, run: lab-start"
echo ""
echo "  Recommended VM settings for students:"
echo "    - 2 CPU cores"
echo "    - 4 GB RAM"
echo "    - 20 GB disk"
echo "    - NAT networking (no internet needed)"
echo ""
