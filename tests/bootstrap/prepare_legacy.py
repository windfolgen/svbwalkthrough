"""Prepare isolated legacy outputs using an existing boundary/series cache."""
import argparse
from pathlib import Path
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("--cache-root", type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
isolated = root / "scratch" / "bootstrap_validation"
(isolated / "runs").mkdir(parents=True, exist_ok=True)
for name in ("ConformalWeight.m", "config.wl", "input_parser.wl", "workflow_engine.wl",
             "review_agent.wl", "audit_agent", "asym", "data", "series_agent",
             "solve_agent", "constraint_agent"):
    target = isolated / name
    if not target.exists():
        target.symlink_to(root / name, target_is_directory=(root / name).is_dir())
for label in ("threeloopI5", "threeloopI8", "threeloophard1", "threeloophard2",
              "fourloopI41", "fourloopI42"):
    for folder, pattern in (("asym/boundary_agent", label + "*_asyexp.m"),
                            ("series_agent", label + "*_svlist*.m")):
        files = list((args.cache_root / folder).glob(pattern))
        if not files:
            raise SystemExit(f"Missing {folder} caches for {label}")
        for source in files:
            dest = root / folder / source.name
            if source.resolve() != dest.resolve():
                shutil.copy2(source, dest)
    shutil.copytree(root / "runs" / label, isolated / "runs" / label, dirs_exist_ok=True)
print(isolated)
