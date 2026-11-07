"""Run public examples and regression scripts in separate Wolfram kernels.

The four examples start without generated results, so stale files cannot make
the comparison pass. IBP and certified series/boundary inputs are reused.
Optional legacy regression caches come from an existing repository checkout.
"""
import argparse
import datetime
import json
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--cache-root", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
logs = root / "scratch" / "bootstrap_logs"
logs.mkdir(parents=True, exist_ok=True)
report_path = root / "tests" / "bootstrap" / "run_all_validation.json"
report = {"started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
          "certified_inputs_reused": True, "runs": [], "passed": False}

def run(command):
    name = Path(command[-1]).stem if command[0] == "wolframscript" else "prepare_legacy"
    if name == "run":
        name = Path(command[-1]).parent.name
    start = time.monotonic()
    print("Running " + name, flush=True)
    with (logs / (name + ".log")).open("w") as output:
        completed = subprocess.run(command, cwd=root, stdout=output, stderr=subprocess.STDOUT)
    row = {"name": name, "exit_code": completed.returncode,
           "wall_seconds": time.monotonic() - start}
    report["runs"].append(row)
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(row), flush=True)
    if completed.returncode:
        raise SystemExit(f"Failed: {name}; see {logs / (name + '.log')}")

for label in ("fourloopI163", "fourloopI167", "fourloopI169", "fourloopI246"):
    directory = root / "runs" / label
    for name in ("coeff_sol.m", "result.m", "generator_coeff_sol.m",
                 label + ".txt", "workflow_validation.json"):
        (directory / name).unlink(missing_ok=True)
    run(["wolframscript", "-file", f"runs/{label}/run.wl"])

for script in ("checks", "assembly", "weighted_jets"):
    run(["wolframscript", "-file", f"tests/bootstrap/{script}.wl"])

if args.cache_root:
    run(["python3", "tests/bootstrap/prepare_legacy.py", "--cache-root", str(args.cache_root.resolve())])
    for script in ("legacy", "extension"):
        run(["wolframscript", "-file", f"tests/bootstrap/{script}.wl"])

report["passed"] = True
report["finished_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
report_path.write_text(json.dumps(report, indent=2) + "\n")
print("All bootstrap checks passed.", flush=True)
