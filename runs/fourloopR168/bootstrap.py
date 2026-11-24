"""Fit the four svMPL numerators to the symmetry-reduced OPE equations at two primes."""

import json
from fractions import Fraction
from math import isqrt
from pathlib import Path

import numpy as np
from flint import nmod_mat

HERE = Path(__file__).resolve().parent
PRIMES = (1_000_003, 1_000_033)
INDICES = {"0": "0", "1": "1", "B": "zz", "R": "1/zz", "C": "1-zz", "D": "zz/(zz-1)"}
PERIODS = {
    "bare": "1",
    "zeta3": "f[3]",
    "zeta5": "f[5]",
    "zeta3_squared": "f[3]^2",
    "zeta7": "f[7]",
}


def solve(prime):
    with np.load(HERE / f"graph_{prime}.npz", allow_pickle=False) as data:
        graph = data["graph"].astype(np.int64)
        target = data["rhs"].reshape(-1)
        rows, unknowns = graph.shape
        if (rows, unknowns) != (591, 105):
            raise ValueError("Incomplete graph system")
        augmented = np.column_stack((graph, target))
        reduced, rank = nmod_mat(augmented.tolist(), prime).rref()
        if rank != unknowns or any(reduced[j, j] != 1 for j in range(rank)):
            raise ValueError(f"No unique fit modulo {prime}")
        fitted = np.array([int(reduced[j, unknowns]) for j in range(rank)])
        if np.any(graph @ fitted % prime != target):
            raise ValueError(f"Graph residual modulo {prime}")
        sectors = []
        start = 0
        for j in range(1, 5):
            basis = data[f"sector_{j}"].astype(np.int64)
            end = start + basis.shape[1]
            sectors.append(basis @ fitted[start:end] % prime)
            start = end
        if start != unknowns:
            raise ValueError("Incomplete symmetry basis")
    return sectors


def reconstruct(a, b):
    p, q = PRIMES
    modulus = p * q
    residue = a + p * ((b - a) * pow(p, -1, q) % q)
    bound = isqrt(modulus // 2)
    previous, n = modulus, residue
    old_den, den = 0, 1
    while abs(n) > bound:
        quotient, remainder = divmod(previous, n)
        previous, n = n, remainder
        old_den, den = den, old_den - quotient * den
    result = Fraction(n, den)
    if (
        result.denominator > bound
        or (residue * result.denominator - result.numerator) % modulus
    ):
        raise ValueError("Ambiguous rational reconstruction")
    return result


def maple_numerator(support, coefficients):
    groups = []
    for grade, words in support.items():
        fitted = {word: next(coefficients) for word in words}
        terms = []
        for word, value in sorted(fitted.items()):
            indices = ",".join(INDICES[letter] for letter in word)
            terms.append(f"({value})*I[z,{indices},0]")
        groups.append(f"({PERIODS[grade]})*(" + "+".join(terms) + ")")
    if next(coefficients, None) is not None:
        raise ValueError("Word count differs from the trial support")
    return "+".join(groups)


if __name__ == "__main__":
    support = json.loads((HERE / "support.json").read_text())
    first, second = map(solve, PRIMES)
    ancillary = (HERE.parents[1] / "anc/fourloopR168.mpl").read_text()
    for j, (sector, left, right) in enumerate(
        zip(support, first, second, strict=True), 1
    ):
        fitted = (reconstruct(int(a), int(b)) for a, b in zip(left, right, strict=True))
        result = maple_numerator(sector, fitted)
        published = ancillary.split(f"R168SVNumerator[{j}] :=", 1)[1].split(":", 1)[0]
        if result != "".join(published.split()):
            raise ValueError(f"Sector {j} differs from the ancillary result")
    print(
        "Rank 105 for 591 OPE equations at each prime. All 3,032 rational coefficients agree with anc/fourloopR168.mpl."
    )
