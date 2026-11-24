"""Verify the two-numerator rank, signed graph comparisons and explicit-period minors."""
from fractions import Fraction
from pathlib import Path
import json

import numpy as np
from flint import nmod_mat

HERE = Path(__file__).resolve().parent
WEIGHT = HERE.parent / "weight_eight"


def multiply(a, b, prime):
    # Integer inputs lie in [0,p). Every product and partial sum is exactly
    # representable as binary64 at the matrix widths used here.
    assert a.shape[1] * (prime - 1)**2 < 2**53
    return (a.astype(float) @ b.astype(float)).astype(np.int64) % prime


def null_basis(reduced, pivots, prime):
    assert np.array_equal(reduced[:, pivots], np.eye(len(pivots), dtype=int))
    free = np.setdiff1d(np.arange(reduced.shape[1]), pivots)
    basis = np.zeros((reduced.shape[1], len(free)), np.int64)
    basis[free] = np.eye(len(free), dtype=int)
    basis[pivots] = -reduced[:, free] % prime
    return basis


def published_reference(prime):
    names = json.loads((WEIGHT / "generators.json").read_text())["labels"]
    lookup = {tuple(name): i for i, name in enumerate(names)}
    rel = np.load(WEIGHT / "change_of_basis.npz")
    piv, free = rel["pivots"], rel["free"]
    denominator = np.array([pow(int(q), -1, prime) for q in rel["denominators"]])
    out = []
    first = json.loads((WEIGHT / "fit.json").read_text())["coefficients"]
    for terms in (first, [(["1", "known", "Pv"], "2")]):
        x = np.zeros(len(names), np.int64)
        for key, value in terms:
            q = Fraction(value)
            x[lookup[tuple(key)]] = q.numerator * pow(q.denominator, -1, prime) % prime
        out.append((x[piv] + rel["numerators"].astype(np.int64) @ (x[free]*denominator % prime)) % prime)
    return np.concatenate(out)


def verify(prime, data):
    q = np.load(HERE / f"joint-light-echelon-{prime}.npz")
    rows, piv = q["rows"].astype(np.int64), q["pivots"].astype(int)
    assert rows.shape == (2996, 3296)
    V = null_basis(rows, piv, prime)
    circle = np.load(HERE / f"circle-{prime}.npz")
    C = circle["G"].astype(np.int64)
    reference = published_reference(prime)
    assert np.array_equal(reference[1648:], circle["G_reference"])
    assert not np.any(C @ reference[1648:] % prime)
    R, rank = nmod_mat(multiply(C, V[1648:], prime).tolist(), prime).rref()
    assert rank == 137
    red = np.array(R.tolist()[:rank], np.int64)
    T = null_basis(red, red.astype(bool).argmax(axis=1), prime)
    variations = multiply(V, T, prime)
    raw = np.load(HERE / f"graph-{prime}.npz")
    assert np.array_equal(reference, raw["reference"])
    observations = data["observations"]
    A = raw["rows"].astype(np.int64)
    predicted = (A @ reference + raw["H_minus_M"]) % prime
    measured = 0
    for i, (val, obs) in enumerate(zip(predicted, observations, strict=True)):
        rec = obs["primes"][str(prime)]
        assert val == rec["prediction"]
        if obs["label"][0] == "graph":
            assert raw["H_minus_M"][i] == 0
        if rec["graph"] is not None:
            assert val == rec["graph"]
            measured += 1
    selected = data["selected"]
    minor = multiply(A[selected], variations, prime)
    determinant = int(nmod_mat(minor.tolist(), prime).det())
    assert minor.shape == (163, 163)
    assert determinant == int(raw["determinant"]) == data["primes"][str(prime)]["determinant"] != 0
    assert measured == data["primes"][str(prime)]["graph_rows_available"]
    assembly = data["high_spin_assembly"]
    for row in assembly["records"]:
        total = sum(c*q for c,q in zip(assembly["signs"], row["coefficients"], strict=True))
        assert total % assembly["prime"] == row["signed_graph"] == row["candidate"]
    for grade, width in [("3", 618), ("5", 138), ("33", 18)]:
        period = np.load(HERE / f"minor-{grade}-{prime}.npz")
        A = period["rows"]
        assert A.shape == (width, width+1) and not np.any(A[:,-1])
        assert int(nmod_mat(A[:,:-1].astype(int).tolist(),prime).det()) == int(period["determinant"]) != 0
    print(f"p={prime}: rank 3296/3296, {measured}/{len(observations)} independent graph values available and matched, explicit-period ranks 618, 138 and 18.")


if __name__ == "__main__":
    info = json.loads((HERE / "independent_graph_rows.json").read_text())
    for modulus in (1000003, 1000033):
        verify(modulus, info)
