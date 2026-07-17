---
name: system
description: >
  Operational rules for working in the svbwalkthrough workspace. Covers file management,
  workspace cleanliness, testing conventions, Mathematica process safety, git safety,
  and the core rule to never mutate agent algorithms without approval. Always loaded first.
---

# System Rules for svbwalkthrough

## File & Workspace Management

### Temporary Scripts
If you generate temporary scripts to test something, they must be under `test/`. Every `run.wl` script must have a log file in the same folder. If the test fails, fix the script and update it or totally remove it. Do not directly generate scripts under the root directory — keep the workspace clean.

### Cached Files — Never Delete
- `asym/tmp/targetIntegrals_reduced.m` — shared across all runs, contains pre-reduced target integrals
- `asym/tmp/cache_tensor_record_noremove.mx` — persistent global tensor caching
- External `"IBPDir"` — IBP reduction tables, reusable across runs

### Stale File Management
After each job, check whether something is stale or broken but not removed. Manage files carefully — do not mess up the workspace by putting similar scripts in different folders randomly.

### External Data Source — Cloud Share Folder (user-configurable)
Pre-computed series expansion files (`svansatzw8_*.txt`, `allsvlist_fourloop_*.txt`, `svlistoddansatz_w8.m`, `svlistevenansatz_w8.m`) are too large to track in git and are shared via a cloud drive (e.g. Nutstore, Dropbox, iCloud).

**Path placeholder:** `<YOUR_CLOUD_SHARE_PATH>/series_expansion/test`

> **Note:** Each user should connect their own cloud share folder and substitute the placeholder above with their local mount path. The coding assistant keeps the actual local path in `local_overrides/system_local.md` (gitignored, machine-local). When the user says "check the share folder" or "new files copied", the assistant looks there. The order of list elements in these files matches the order of the ansatz (`svlistoddansatz_w8.m` + `svlistevenansatz_w8.m`).

## Agent Algorithm Safety

**Do not change the algorithms in the agents without informing me or my approval.** If you think some algorithms are not correct or need improvement, ask for suggestion first before proceeding. If no definite order is given to let you solve it yourself, you must always report first before acting.

## Mathematica Process Management — CRITICAL

NEVER kill or terminate Mathematica/WolframKernel processes with a blanket `kill -9` command that targets ALL processes (e.g., `ps aux | grep MathKernel | awk '{print $2}' | xargs kill -9`). The user may have their own Mathematica notebooks or kernels running independently.

When you need to clean up processes:
1. Always save the PID of any process you launch (e.g., `MY_PID=$!`)
2. Only kill specific PIDs that you launched yourself
3. Use a project-scoped PID file (e.g. `/tmp/svbwalkthrough_<label>_pid.txt`) to retrieve the PID of your background job

Safe cleanup example:
```bash
MY_PID=$!
echo "my_pid=$MY_PID" > /tmp/svbwalkthrough_${label}_pid.txt

# Kill only your own processes later
kill -9 $(cat /tmp/svbwalkthrough_${label}_pid.txt) 2>/dev/null
# Also kill subkernels spawned by your job (they will be children of your PID)
pkill -P $(cat /tmp/svbwalkthrough_${label}_pid.txt) 2>/dev/null
```

## Git Safety — PERMANENT

NEVER use `git stash` or any other operation that modifies the working tree without immediately verifying all source files are intact. `git stash` was used for a branch comparison and `git stash pop` was forgotten, causing fixes to silently disappear.

After ANY git operation that modifies the working tree (stash, checkout, switch, reset), immediately verify:
```bash
git diff HEAD -- series_agent/ solve_agent/ workflow_engine.wl audit_agent/
```

For comparisons with another branch, use `git show <branch>:<path>` (read-only, no tree mutation):
```bash
git show main:runs/fourloopI41/coeff_sol.m > /tmp/old.m
```

## Pre-Task Checklist
Before a task, check twice that your scripts will work and are consistent. Once finished, remove stale files that are proven wrong or not consistent.
