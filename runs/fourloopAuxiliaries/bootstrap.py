"""Refit the four finite auxiliary functions on their published word supports."""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1]))
from runs.fourloopR168.bootstrap import verify_fit


if __name__ == "__main__":
    for name, rows, rank, maple_name in [
        ("I110", 540, 2, "I110"), ("I113", 585, 112, "I113"),
        ("I142", 546, 98, "I142"), ("J112", 828, 93, "I112m26"),
    ]:
        formula = HERE.parents[1] / "anc" / f"fourloop{name}.mpl"
        verify_fit(HERE / name, (rows, rank), formula, maple_name)
