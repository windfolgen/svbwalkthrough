"""Full-word tangential restrictions using the archived ordinary iterated-integral differential."""

from collections import defaultdict
from functools import cache
import json
from math import lcm
from fractions import Fraction
from pathlib import Path

import numpy as np
import sympy as sp

HERE = Path(__file__).resolve().parent
T, H = sp.symbols("t h")


def residues(keys, curve, generic):
    """Restrict dlog(a-b) only after differentiating the transversely displaced path."""
    if curve == "circle":
        b = T
        end = b / (b - 1) + H * T
        specialization = 0
        factors = [T, T - 1, T + 1, T - 2, 2 * T - 1, T**2 - T + 1]
    else:
        b = T / H
        end = T * H
        specialization = 1 if curve == "positive diagonal" else -1
        factors = [T, T - 1, T + 1, T - 2 * specialization, 2 * T - specialization]
    letters = {
        "E": end,
        "B": b,
        "D": b / (b - 1),
        "R": 1 / b,
        "C": 1 - b,
        "0": 0,
        "1": 1,
        "m": -1,
        "T": 2,
        "A": sp.Rational(1, 2),
    }
    coefficients = sp.symbols("c:" + str(len(factors)))
    ansatz = sum(n * sp.diff(p, T) / p for n, p in zip(coefficients, factors))
    result = []
    generic_factors = []
    for a, c in keys:
        difference = letters[a] - letters[c]
        differential = sp.cancel(sp.diff(difference, T) / difference)
        denom = differential.as_numer_denom()[1]
        while denom.subs(T, 0) == 0:
            denom = sp.cancel(denom / T)
        # No nonzero radial pole coalesces with the tangential origin.
        assert denom.subs({H: specialization, T: 0}) != 0
        if generic:
            split = []
            for sign, polynomial in zip((1, -1), sp.cancel(difference).as_numer_denom()):
                for factor, power in sp.factor_list(polynomial, T)[1]:
                    monic = sp.Poly(factor, T).monic().as_expr()
                    if monic not in generic_factors:
                        generic_factors.append(monic)
                    split.append((generic_factors.index(monic), sign * power))
            result.append(split)
            continue
        restricted = sp.cancel(differential.subs(H, specialization))
        equations = sp.Poly(sp.together(restricted - ansatz).as_numer_denom()[0], T).all_coeffs()
        (solution,) = sp.linsolve(equations, coefficients)
        assert all(x.is_Integer for x in solution)
        result.append([(j, int(x)) for j, x in enumerate(solution) if x])
    return result, len(generic_factors) if generic else len(factors)


def counts(data, curve, generic=False):
    enc = json.loads(str(data["M_encoding.json"]))
    kernels, alphabet_size = residues(enc["keys"], curve, generic)
    offsets, children, indices, weights = [
        data["M_" + k].tolist() for k in ("offsets", "children", "kernels", "weights")
    ]
    start = set(map(int, enc["constants"]))
    offsets_in, refs, nums, dens = [
        data["M_" + k].tolist() for k in ("in-offset", "in-ref", "in-num", "in-den")
    ]
    assert len(start) == 213 and len(offsets) - 1 == 21581

    if generic:
        # These are the only angular HPL initial states with a possible
        # singularity at endpoint +1 or -1. The other words contain only zeros.
        start = {int(k) for k, (word, j) in enc["constants"].items() if "B" in word or "D" in word}
        assert start

    @cache
    def edges(node):
        out = defaultdict(int)
        for i in range(offsets[node], offsets[node + 1]):
            child = children[i]
            assert child < node
            for symbol, multiplicity in kernels[indices[i]]:
                out[symbol, child] += weights[i] * multiplicity
        return [(s, c, n) for (s, c), n in out.items() if n]

    def nonzero_words(vector):
        # Every tangential initial state is an independent formal constant here.
        total = int(any(node in start and c for node, c in vector.items()))
        branches = [defaultdict(int) for _ in range(alphabet_size)]
        for node, c in vector.items():
            for symbol, child, n in edges(node):
                branches[symbol][child] += c * n
        for branch in branches:
            child = {k: n for k, n in branch.items() if n}
            if child:
                total += nonzero_words(child)
        return total

    vectors = {}
    for i, (chart, name, period) in enumerate(enc["columns"]):
        low, high = offsets_in[i : i + 2]
        row = defaultdict(Fraction)
        for k, n, q in zip(refs[low:high], nums[low:high], dens[low:high]):
            row[k] += Fraction(n, q)
        vectors[chart, name, period] = row
    if curve == "circle" and not generic:
        # In x=1-z coordinates the same circle is the original u=1.
        # Its only putative pole is proportional to F(1-x)+F(1/(1-x)).
        for chart, name, period in list(vectors):
            if chart == "swap" and name == "F":
                a, b = vectors[chart, name, period], vectors["is", name, period]
                vectors["sum", "F", period] = {
                    k: a.get(k, 0) + b.get(k, 0) for k in a.keys() | b.keys()
                }
    output = {}
    for (chart, name, period), row in vectors.items():
        if curve != "circle" and chart not in ("id", "inverse"):
            continue
        if curve == "circle" and not generic and (chart not in ("id", "sum")):
            continue
        denom = lcm(*(c.denominator for c in row.values()))
        output[chart, name, period] = nonzero_words(
            {k: int(n * denom) for k, n in row.items() if n}
        )
    return output


def main():
    with np.load(HERE.parent / "euclidean" / "ordinary_data.npz", allow_pickle=False) as data:
        for chart in ("positive diagonal", "negative diagonal", "circle"):
            result = counts(data, chart)
            if chart == "circle":
                assert len(result) == 12 and all(
                    v == 0 for (c, n, p), v in result.items() if n == "Pv" or c == "sum"
                )
                control = [result["id", "F", p] for p in ("1", "f2[3,3]", "f2[3]", "f2[5]")]
                assert control == [1375, 4, 75, 11]
                print("v=1: Pv vanishes; u=1: F+CF vanishes; surviving F controls", control)
            else:
                assert len(result) == 14 and not any(result.values())
                print(chart + ": all 14 native and inverse F and Pv period columns vanish")
        for chart in ("positive diagonal", "circle"):
            result = counts(data, chart, generic=True)
            assert not any(result.values())
            print(
                chart + ": all",
                len(result),
                "columns annihilate the singular angular initial states off the divisor",
            )


if __name__ == "__main__":
    main()
