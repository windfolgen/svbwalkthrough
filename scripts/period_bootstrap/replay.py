"""Recover the physical GPL coefficients from the two finite-field boundary systems."""
import argparse
from collections import Counter
import json
from math import gcd, isqrt
from pathlib import Path

from flint import nmod_mat
import numpy as np

PRIMES = (1000003, 1000033)


def solve_field(folder, prime):
    with np.load(folder / f"p{prime}.npz", allow_pickle=False) as fit:
        lhs, rhs = fit["lhs"], fit["rhs"]
        dimension = lhs.shape[1]
        matrix = nmod_mat(lhs[:dimension].tolist(), prime)
        values = nmod_mat([[int(q)] for q in rhs[:dimension]], prime)
        seed = np.asarray(matrix.solve(values).tolist(), dtype=np.int64).ravel()
        if np.any((lhs @ seed - rhs) % prime):
            raise ValueError(f"Fitted boundary discrepancy modulo {prime}")
        weights = fit["v"].astype(np.int64) * seed[fit["cols"]]
        words = np.add.reduceat(weights, fit["ptr"][:-1]) % prime
    with np.load(folder / f"holdout{prime}.npz", allow_pickle=False) as checks:
        prediction = checks["lhs"] @ seed % prime
        if not np.array_equal(prediction, checks["rhs"]):
            raise ValueError(f"Independent boundary discrepancy modulo {prime}")
    return words, dict(prime=prime, independent_seed_columns=dimension, fitted_rows=len(rhs),
                       fitted_discrepancies=0, check_rows=len(prediction),
                       nonzero_check_rows=int(np.count_nonzero(prediction)), check_discrepancies=0)


def reconstruct(a, b):
    p, q = PRIMES
    modulus = p * q
    bound = isqrt(modulus // 2)
    residue = a + p * ((b - a) * pow(p, -1, q) % q)
    previous, current = modulus, residue
    old_denominator, denominator = 0, 1
    while current > bound:
        quotient, remainder = divmod(previous, current)
        previous, current = current, remainder
        old_denominator, denominator = denominator, old_denominator - quotient * denominator
    if denominator < 0:
        current, denominator = -current, -denominator
    if not (0 < denominator <= bound and gcd(current, denominator) == 1
            and (residue * denominator - current) % modulus == 0):
        raise ValueError(f"No bounded rational reconstruction for {a}, {b}")
    return [current, denominator]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()
    folder = args.run_directory / "fit"
    labels = json.loads((folder / "words.json").read_text())
    outputs, checks = zip(*(solve_field(folder, prime) for prime in PRIMES))
    if any(len(vec) != len(labels) for vec in outputs):
        raise ValueError("Word table and field map sizes differ")
    coefficients = [reconstruct(int(a), int(b)) for a, b in zip(*outputs)]
    support = Counter(label[0] for label, (num, _) in zip(labels, coefficients) if num)
    report = dict(finite_fields=checks, word_coordinates=len(labels), nonzero_terms=dict(support))
    print(json.dumps(report, indent=2))
    args.output_json.write_text(json.dumps(dict(coefficients=coefficients, validation=report)) + "\n")


if __name__ == "__main__":
    main()
