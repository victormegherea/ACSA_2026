#!/usr/bin/env bash
# Build the medium-track challenge for fuzzing with AFL++.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -n "${AFL_CC:-}" ]]; then
    if ! command -v "$AFL_CC" &>/dev/null; then
        echo "[!] AFL_CC='$AFL_CC' was requested but is not available."
        exit 1
    fi
    AFL_COMPILER="$AFL_CC"
elif command -v afl-clang-fast &>/dev/null; then
    AFL_COMPILER=afl-clang-fast
elif command -v afl-clang-lto &>/dev/null; then
    AFL_COMPILER=afl-clang-lto
else
    echo "[!] AFL++ compiler not found (tried afl-clang-fast and afl-clang-lto)."
    echo "    Install AFL++ first: sudo apt install afl++"
    exit 1
fi

echo "[+] Building with $AFL_COMPILER (instrumented for AFL++)..."
"$AFL_COMPILER" -g -O1 -o vuln_medium vuln_medium.c

echo "[+] Built ./vuln_medium"

mkdir -p seeds
if [[ ! -e seeds/seed1 ]]; then
    printf 'hello world, this is just a normal message\n' > seeds/seed1
fi
if [[ ! -e seeds/seed2 ]]; then
    printf '\x00\x00\x00\x00\x00\x00\x00\x00' > seeds/seed2
fi
# A full-size partial-match seed lets AFL++ spend its mutations on the
# staged magic bytes instead of first having to grow a 44-byte input to 68
# bytes.  It deliberately stops before stage 4, so the final path remains
# something students discover.
if [[ ! -e seeds/seed3 ]]; then
    printf 'A%.0s' {1..64} > seeds/seed3
    printf '\x41\x42\x43\x00' >> seeds/seed3
fi

echo ""
echo "Next steps:"
echo "  afl-fuzz -i seeds -o out -- ./vuln_medium @@"
