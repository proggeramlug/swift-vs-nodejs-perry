#!/bin/sh
# Usage: ./run.sh [runs] [outdir]   — after ./build.sh
# Optional on shared machines: MAXLOAD=3 (wait for 1-min load below it before each case)
# and WRAP='taskset -c 6,7,14,15 nice -n -10' (prefix for hyperfine).
set -e
cd "$(dirname "$0")"
RUNS=${1:-5}; OUT=${2:-results/local}; MAXLOAD=${MAXLOAD:-999}
CASES="collatz particles words trees"
mkdir -p "$OUT"; cp bin/versions.txt "$OUT/"; rm -f "$OUT/load.txt"
if [ "$(uname)" = Darwin ]; then TIME="/usr/bin/time -l"; else TIME="/usr/bin/time -v"; fi
echo "| case | impl | output | peak RSS |" > "$OUT/rss.md"; echo "|---|---|---|---|" >> "$OUT/rss.md"
for c in $CASES; do
  node $c.ts > "$OUT/expected-$c.txt" 2>/dev/null
  for impl in node perry swift; do
    if [ $impl = node ]; then cmd="node $c.ts"; else cmd="./bin/$c-$impl"; fi
    $TIME $cmd > out.txt 2> time.txt
    ok=$(cmp -s out.txt "$OUT/expected-$c.txt" && echo match || echo DIFF)
    rss=$(awk '/maximum resident set size/{printf "%.0f MB", $1/1048576} /Maximum resident set size/{printf "%.0f MB", $NF/1024}' time.txt)
    echo "| $c | $impl | $ok | $rss |" >> "$OUT/rss.md"
  done
  load() { if [ "$(uname)" = Darwin ]; then sysctl -n vm.loadavg | awk '{print $2}'; else cut -d" " -f1 /proc/loadavg; fi; }
  while [ "$(load | cut -d. -f1)" -ge "$MAXLOAD" ]; do sleep 30; done
  l0=$(load)
  $WRAP hyperfine --runs "$RUNS" --warmup 1 --export-json "$OUT/time-$c.json" \
    -n node "node $c.ts" -n perry "./bin/$c-perry" -n swift "./bin/$c-swift"
  echo "$c $l0 $(load)" >> "$OUT/load.txt"
done
rm -f out.txt time.txt
cat "$OUT/rss.md"
