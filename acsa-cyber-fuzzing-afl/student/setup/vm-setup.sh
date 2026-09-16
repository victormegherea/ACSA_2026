#!/usr/bin/env bash
# ACSA 2026 Academy — AFL++ student VM setup
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo bash setup/vm-setup.sh"
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends \
    build-essential clang llvm libclang-rt-dev afl++ gdb binutils file tree

# Shared folders may lose executable bits; restore them in the student copy.
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
find "$LAB_DIR" -type f -name '*.sh' -exec chmod +x {} +

echo "AFL++ student environment is ready."
echo "Run: bash setup/lab-start.sh"
