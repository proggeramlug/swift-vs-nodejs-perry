#!/bin/sh
# Builds every case for Swift and Perry. Env: PERRY, SWIFTC (defaults: perry, swiftc).
# For a source-built Perry also set PERRY_SRC and PERRY_RUNTIME_DIR (see README).
set -e
cd "$(dirname "$0")"
PERRY=${PERRY:-perry}; SWIFTC=${SWIFTC:-swiftc}
CASES="collatz particles words trees"
mkdir -p bin
for c in $CASES; do
  "$SWIFTC" -O $c.swift -o bin/$c-swift
  "$PERRY" compile $c.ts -o bin/$c-perry > /dev/null
done
{
  echo "date: $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "os: $(uname -srm)"
  if [ "$(uname)" = Darwin ]; then echo "cpu: $(sysctl -n machdep.cpu.brand_string)"; else echo "cpu: $(lscpu | sed -n 's/^Model name: *//p' | head -1)"; fi
  echo "node: $(node --version)"
  echo "perry: $("$PERRY" --version)"
  [ -n "$PERRY_SRC" ] && echo "perry-commit: $(git -C "$PERRY_SRC" log -1 --format='%H (%cd)' --date=iso)"
  [ -n "$PERRY_RUNTIME_DIR" ] && echo "perry-runtime: $(ls -l "$PERRY_RUNTIME_DIR/libperry_runtime.a" | awk '{print $6, $7, $8}')"
  echo "swift: $("$SWIFTC" --version 2>&1 | grep -m1 -oE 'Swift version [^ ]+( \([^)]*\))?') (-O)"
  echo "hyperfine: $(hyperfine --version)"
} > bin/versions.txt
cat bin/versions.txt
