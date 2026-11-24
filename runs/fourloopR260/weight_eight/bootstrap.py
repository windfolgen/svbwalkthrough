"""Recover the weight-eight Gram numerator from two-channel function and OPE constraints."""

import gzip
import json
from fractions import Fraction
from math import isqrt, lcm
from pathlib import Path

import numpy as np
from flint import nmod_mat
from scipy.sparse import load_npz

HERE = Path(__file__).resolve().parent
PRIMES = (1_000_003, 1_000_033)


def fit(prime):
    with np.load(HERE / f"ope_{prime}.npz", allow_pickle=False) as data:
        radial = data["radial"].astype(np.int64)
        independent = radial[data["selected"]]
        basis = data["generators"]
        coeff = nmod_mat(independent[:, :-1].tolist(), prime).solve(
            nmod_mat(independent[:, -1:].tolist(), prime)
        )
        x = np.array(coeff.tolist(), dtype=np.int64).ravel()
        if np.any((radial[:, :-1] @ x - radial[:, -1]) % prime):
            raise ValueError(f"Nonzero radial residual modulo {prime}")
        solution = np.zeros(4609, dtype=np.int64)
        solution[basis[data["free"]]] = x
        solution[basis[data["pivots"]]] = (
            data["kinematic_rhs"] - data["coupling"] @ x
        ) % prime
        print(
            f"p={prime}: {len(basis)-len(x)} kinematic pivots and {len(x)} independent radial constraints"
        )
    return solution


def rational_lift(a, b):
    p, q = PRIMES
    modulus = p * q
    residue = a + p * ((b - a) * pow(p, -1, q) % q)
    bound = isqrt(modulus // 2)
    old, num, old_den, den = modulus, residue, 0, 1
    while abs(num) > bound:
        d, rem = divmod(old, num)
        old, num = num, rem
        old_den, den = den, old_den - d * den
    value = Fraction(num, den)
    if (
        value.denominator > bound
        or (value.denominator * residue - value.numerator) % modulus
    ):
        raise ValueError("Ambiguous rational reconstruction")
    return value


if __name__ == "__main__":
    names = json.loads((HERE / "generators.json").read_text())["labels"]
    a, b = map(fit, PRIMES)
    solution = [rational_lift(int(x), int(y)) for x, y in zip(a, b, strict=True)]
    with gzip.open(HERE / "lightcone.json.gz", "rt") as stream:
        lightcone = json.load(stream)
    for label, target, terms in lightcone:
        if sum(
            (solution[j] * Fraction(c) for j, c in terms if solution[j]), Fraction(0)
        ) != Fraction(target):
            raise ValueError(f"Exact light-cone residual in {label}")
    reference = {
        tuple(name): Fraction(c)
        for name, c in json.loads((HERE / "fit.json").read_text())["coefficients"]
    }
    # The OPE pivots and the archived fit use different independent generators.
    differences = [
        c - reference.get(tuple(name), 0)
        for name, c in zip(names, solution, strict=True)
    ]
    common_denominator = lcm(*(q.denominator for q in differences))
    integer_vector = [int(q * common_denominator) for q in differences]
    ordinary = load_npz(HERE / "ordinary_matrix.npz").astype(np.int64)
    bound = int(abs(ordinary).sum(axis=1).max()) * max(map(abs, integer_vector))
    if bound >= 2**63:
        raise OverflowError("Integer comparison exceeds int64")
    if np.any(ordinary @ np.array(integer_vector, dtype=np.int64)):
        raise ValueError("Reconstructed function differs from the published fit")
    print(
        f"Verified {len(lightcone)} rational light-cone coordinates; all {ordinary.shape[0]:,} ordinary function coordinates agree with the archived fit."
    )
