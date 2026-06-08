#!/bin/bash
set -e

echo "=== STARTING THREELOOPHARD1 ==="
wolfram -script runs/threeloophard1/run.wl

echo "=== STARTING THREELOOPHARD2 ==="
wolfram -script runs/threeloophard2/run.wl

echo "=== STARTING THREELOOPI5 ==="
wolfram -script runs/threeloopI5/run.wl

echo "=== STARTING THREELOOPI8 ==="
wolfram -script runs/threeloopI8/run.wl

echo "=== ALL THREELOOP RUNS COMPLETED SUCCESSFULLY ==="
