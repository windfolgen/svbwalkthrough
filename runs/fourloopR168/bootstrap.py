"""Fit the four svMPL functions to the symmetry-reduced OPE equations at two primes."""

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


def solve(prime, directory=HERE, shape=(591, 105), sectors=4):
    with np.load(directory / f"graph_{prime}.npz", allow_pickle=False) as data:
        graph = data["graph"].astype(np.int64)
        target = data["rhs"].reshape(-1)
        rows, unknowns = graph.shape
        if (rows, unknowns) != shape:
            raise ValueError("Incomplete graph system")
        augmented = np.column_stack((graph, target))
        reduced, rank = nmod_mat(augmented.tolist(), prime).rref()
        if rank != unknowns or any(reduced[j, j] != 1 for j in range(rank)):
            raise ValueError(f"No unique fit modulo {prime}")
        fitted = np.array([int(reduced[j, unknowns]) for j in range(rank)])
        if np.any(graph @ fitted % prime != target):
            raise ValueError(f"Graph residual modulo {prime}")
        fitted_sectors = []
        start = 0
        for j in range(1, sectors + 1):
            basis = data[f"sector_{j}"].astype(np.int64)
            end = start + basis.shape[1]
            fitted_sectors.append(basis @ fitted[start:end] % prime)
            start = end
        if start != unknowns:
            raise ValueError("Incomplete symmetry basis")
    return fitted_sectors


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


def verify_fit(directory, shape, ancillary_file, maple_name):
    support = json.loads((directory / "support.json").read_text())
    first, second = [solve(p, directory, shape, len(support)) for p in PRIMES]
    ancillary = ancillary_file.read_text()
    word_count = 0
    for j, (sector, left, right) in enumerate(zip(support, first, second, strict=True), 1):
        fitted = (reconstruct(int(a), int(b)) for a, b in zip(left, right, strict=True))
        result = maple_numerator(sector, fitted)
        published = ancillary.split(f"{maple_name}SVNumerator[{j}] :=", 1)[1].split(":", 1)[0]
        if result != "".join(published.split()):
            raise ValueError(f"Sector {j} differs from {ancillary_file.name}")
        word_count += len(left)
    print(f"{directory.name}: rank {shape[1]} for {shape[0]} OPE equations at both primes. "
          f"All {word_count} rational coefficients agree with {ancillary_file.name}.")


if __name__ == "__main__":
    verify_fit(HERE, (591, 105), HERE.parents[1] / "anc/fourloopR168.mpl", "R168")
