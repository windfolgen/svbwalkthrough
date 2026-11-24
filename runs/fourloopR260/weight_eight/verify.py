"""Replay the rational function-space rank and the native four-cut numerator.

ordinary_matrix.npz stores twice each coefficient of G_a(z) G_b(zz).
Rows follow coordinates.json.gz. Columns follow generators.json. Each free
column in change_of_basis.npz has its own integral numerator vector and
positive denominator relative to the pivot columns.
"""

from fractions import Fraction
from pathlib import Path
import gzip
import json
import re
import numpy as np
from flint import nmod_mat
from scipy.sparse import load_npz


def read_seed(source, name):
    indices = {
        "0": "0",
        "1": "1",
        "zz": "B",
        "1/zz": "R",
        "1-zz": "C",
        "zz/(zz-1)": "D",
    }
    expression = source.split(name + " :=", 1)[1].split(":", 1)[0].strip()
    values = {}
    for term in re.split(r"\s*\+\s*", expression):
        match = re.fullmatch(r"\(([-\d/]+)\)\*I\[z,([^\]]+),0\]", term)
        if match is None:
            raise ValueError(f"Unrecognized {name} term: {term}")
        coefficient, letters = match.groups()
        word = "".join(indices[a] for a in letters.split(","))
        if word in values:
            raise ValueError(f"Duplicate {name} word {word}")
        values[word] = Fraction(coefficient)
    return values


def verify(directory):
    words = json.loads((directory / "generators.json").read_text())["labels"]
    indices = {tuple(name): i for i, name in enumerate(words)}
    matrix = load_npz(directory / "ordinary_matrix.npz").astype(np.int64).tocsr()
    with gzip.open(directory / "coordinates.json.gz", "rt") as stream:
        coordinates = json.load(stream)
    assert matrix.shape == (len(coordinates), len(words)) == (92885, 4609)

    relations = np.load(directory / "change_of_basis.npz")
    pivot = relations["pivots"]
    free = relations["free"]
    assert sorted(np.r_[pivot, free]) == list(range(len(words)))
    left, right = matrix[:, pivot].tocsr(), matrix[:, free].tocsr()
    numerator = relations["numerators"].astype(np.int64)
    denominator = relations["denominators"].astype(np.int64)
    assert np.all(denominator > 0)
    bound = int(abs(left).sum(axis=1).max()) * int(np.abs(numerator).max())
    assert bound < 2**52
    floating = numerator.astype(float)
    for i in range(0, len(coordinates), 192):
        # Every product and partial sum is an exactly representable integer.
        actual = (left[i : i + 192].astype(float) @ floating).astype(np.int64)
        expected = right[i : i + 192].toarray() * denominator
        assert np.array_equal(actual, expected)
    selected = json.loads((directory / "independent_coordinates.json").read_text())
    minor = left[selected].toarray().tolist()
    assert nmod_mat(minor, 1000003).rank() == len(selected) == len(pivot) == 1648

    fit = json.loads((directory / "fit.json").read_text())["coefficients"]
    weights = np.zeros(len(words), dtype=np.int64)
    for name, value in fit:
        value = 18 * Fraction(value)
        assert value.denominator == 1
        weights[indices[tuple(name)]] = int(value)
    local = matrix @ weights
    assert np.count_nonzero(local) == 8352
    assert int(np.abs(local).max()) == 36 * 256
    source = (directory.parents[2] / "anc/fourloopR260.mpl").read_text()
    # In this native chart the holomorphic length-eight entries are the seed.
    bare = {
        w: Fraction(int(c), 36)
        for (w, other), c in zip(coordinates, local, strict=True)
        if len(w) == 8 and not other and c
    }
    if bare != read_seed(source, "R260GramWeightEightSeed") or len(bare) != 1162:
        raise ValueError("Weight-eight reduction differs from the ancillary formula")
    periods = json.loads((directory.parent / "fit.json").read_text())[
        "lower_native_word_coefficients"
    ]
    for grade, words in periods.items():
        if words and {w: Fraction(c) for w, c in words} != read_seed(
            source, f"R260GramPeriodSeed[{grade}]"
        ):
            raise ValueError(f"Period seed {grade} differs from the ancillary formula")
    print(
        "All 1,162 weight-eight seed coefficients and the period seeds agree with anc/fourloopR260.mpl."
    )
    print(
        "Verified all 2,961 rational dependencies, a rank-1,648 minor, and 8,352 native numerator coordinates."
    )


if __name__ == "__main__":
    verify(Path(__file__).resolve().parent)
