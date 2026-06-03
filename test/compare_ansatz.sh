#!/bin/bash
FILES=(
  "threeloophard1_svliste0uv.m"
  "threeloophard1_svliste0uvp.m"
  "threeloophard1_svliste1uv.m"
  "threeloophard1_svliste1uvp.m"
  "threeloophard1_svlisteinfuv.m"
  "threeloophard1_svlisteinfuvp.m"
  "threeloophard1_svlistmple0uv.m"
  "threeloophard1_svlistmple0uvp.m"
  "threeloophard1_svlistmple1uv.m"
  "threeloophard1_svlistmple1uvp.m"
  "threeloophard1_svlistmpleinfuv.m"
  "threeloophard1_svlistmpleinfuvp.m"
)

AETHER_DIR="/Users/windfolgen/Documents/aether/svbwalkthrough/series_agent"
LOCAL_DIR="series_agent"

for f in "${FILES[@]}"; do
  echo "Comparing $f..."
  if [ ! -f "$LOCAL_DIR/$f" ]; then
    echo "  Local file missing: $LOCAL_DIR/$f"
  elif [ ! -f "$AETHER_DIR/$f" ]; then
    echo "  Aether file missing: $AETHER_DIR/$f"
  else
    # Ignore whitespace and empty lines for robustness
    diff -wB "$AETHER_DIR/$f" "$LOCAL_DIR/$f" > test/diff_$f.txt
    if [ -s test/diff_$f.txt ]; then
      echo "  [DIFFERENCE FOUND] see test/diff_$f.txt"
    else
      echo "  [MATCH]"
      rm test/diff_$f.txt
    fi
  fi
done
