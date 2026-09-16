#!/usr/bin/env bash
# Build the hard-track challenge for fuzzing with AFL++ + ASan.
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

ASAN_CHECK_DIR="$(mktemp -d -t acsa-afl-asan.XXXXXX)"
trap 'rm -rf "$ASAN_CHECK_DIR"' EXIT
if ! printf 'int main(void) { return 0; }\n' | "$AFL_COMPILER" -fsanitize=address -x c - -o "$ASAN_CHECK_DIR/check" 2>"$ASAN_CHECK_DIR/error"; then
    echo "[!] AddressSanitizer runtime is missing or incompatible with the installed Clang."
    echo "    Install it with: sudo apt install libclang-rt-dev"
    echo "    Then rerun: bash build.sh"
    cat "$ASAN_CHECK_DIR/error"
    exit 1
fi

echo "[+] Building ASan fuzzing target with $AFL_COMPILER..."
AFL_USE_ASAN=1 "$AFL_COMPILER" -fsanitize=address -g -O0 \
    -fno-stack-protector -no-pie -o vuln_hard_asan vuln_hard.c
echo "[+] Building non-ASan replay target for the controlled exploit..."
"$AFL_COMPILER" -g -O0 -fno-stack-protector -no-pie \
    -o vuln_hard vuln_hard.c

echo "[+] Built ./vuln_hard_asan and ./vuln_hard"

mkdir -p seeds
if [[ ! -e seeds/seed1 ]]; then
    printf '\x08ABCDEFGH' > seeds/seed1
fi
if [[ ! -e seeds/seed2 ]]; then
    printf '\x02XY' > seeds/seed2
fi
# Keep one seed long enough to exercise the unchecked length immediately.
# AFL++ records this ASan finding on the first cycle, while the shorter seeds
# still let students observe the normal path and mutate toward the bug.
if [[ ! -e seeds/seed3 ]]; then
    printf '\x11' > seeds/seed3
    printf 'A%.0s' {1..17} >> seeds/seed3
fi

echo ""
echo "Next steps:"
echo "  AFL_USE_ASAN=1 afl-fuzz -i seeds -o out -- ./vuln_hard_asan @@"
