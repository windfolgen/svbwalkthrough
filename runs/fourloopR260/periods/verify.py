"""Recombine the period-bearing ordinary GPL products of the public native svMPL seed."""

import gzip
import hashlib
import json
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
with gzip.open(ROOT / "ordinary_period_columns.json.gz", "rt") as src:
    charts = json.load(src)
records = json.loads((ROOT.parent / "fit.json").read_text())
grades = records["lower_native_word_coefficients"]
allowed = {"f2[3]", "f2[5]", "f2[3,3]", "f2[7]"}
for chart, data in charts.items():
    table = defaultdict(Fraction)

    def add(rows, multiplier):
        for left, right, period, coefficient in rows:
            table[left, tuple(right), tuple(period)] += multiplier * Fraction(
                coefficient
            )

    add(data["F8_induced_periods"], 1)
    for words in grades.values():
        for word, coefficient in words:
            add(data["lower_word_columns"][word], Fraction(coefficient))
    terms = [
        [a, list(b), list(p), str(c)] for (a, b, p), c in sorted(table.items()) if c
    ]
    assert all(len(p) == 1 and p[0] in allowed for _, _, p, _ in terms)
    encoded = json.dumps(terms, separators=(",", ":")).encode()
    assert hashlib.sha256(encoded).hexdigest() == data["sum_sha256"]
    print(
        chart,
        len(terms),
        "nonzero period-bearing ordinary coefficients, exact agreement",
    )
