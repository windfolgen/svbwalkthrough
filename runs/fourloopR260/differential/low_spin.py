"""Fix the two P_v normalizations using exact degree-two OPE moments."""

from collections import defaultdict
from pathlib import Path
import json

import numpy as np
import sympy as sp
from flint import fmpq, fmpq_poly
from sympy.polys.fields import field

from low_spin_graph import graph_coefficients

HERE = Path(__file__).resolve().parent
RING, H = field("h", sp.QQ)
T, h = sp.symbols("t h")
MAX_ORDER = 4
COSINE = (H + 1 / H) / 2


def rational(numerator=0, denominator=1):
    return RING.ground_new(sp.QQ(numerator, denominator))


def taylor(function):
    """Truncated power series in t with exact coefficients in Q(h)."""
    numerator, denominator = [sp.Poly(p, T) for p in sp.cancel(function).as_numer_denom()]
    a = [RING.from_expr(numerator.nth(i)) for i in range(MAX_ORDER + 1)]
    b = [RING.from_expr(denominator.nth(i)) for i in range(MAX_ORDER + 1)]
    assert b[0]
    values = []
    for n in range(MAX_ORDER + 1):
        values.append((a[n] - sum(b[j] * values[n - j] for j in range(1, n + 1))) / b[0])
    return values


def radial_data():
    z, b = T * h, T / h
    u, v, d = T**2, (1 - z) * (1 - b), z - b
    marks = {
        "E": z,
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
    prefactors = {
        ("id", "F"): v / (d * (u - 1)),
        ("inverse", "F"): u * v / (d * (u - 1)),
        ("id", "Pv"): v / (d * (v - 1)),
        ("inverse", "Pv"): u * v / (d * (u - v)),
    }
    with np.load(HERE.parent / "euclidean/ordinary_data.npz", allow_pickle=False) as data:
        enc = json.loads(str(data["M_encoding.json"]))
        arrays = [
            data["M_" + k].tolist()
            for k in (
                "offsets",
                "children",
                "kernels",
                "weights",
                "in-offset",
                "in-ref",
                "in-num",
                "in-den",
            )
        ]
    kernels = []
    for a, c in enc["keys"]:
        difference = marks[a] - marks[c]
        kernels.append(taylor(T * sp.diff(difference, T) / difference))
    # [t^2] p(t) f(t) needs [t^n] f for 0<=n<=4 since p starts at t^-2.
    pref = {k: taylor(T**2 * p)[::-1] for k, p in prefactors.items()}
    return enc, arrays, kernels, pref


def to_flint(poly):
    if not poly:
        return fmpq_poly()
    coefficients = [poly.get((k,), sp.QQ.zero) for k in range(int(poly.degree()) + 1)]
    return fmpq_poly([fmpq(int(c.numerator), int(c.denominator)) for c in coefficients])


def polynomial_data(kernels, pref, arrays):
    # Every edge removes exactly one letter. A common denominator per letter
    # makes the entire dual recurrence a polynomial computation.
    common = RING.ring.one
    for row in [*kernels, *pref.values()]:
        for value in row:
            common = common.lcm(value.denom)

    def clear(value):
        return to_flint(value.numer * common.exquo(value.denom))

    offsets, children = arrays[:2]
    weights = []
    for i in range(len(offsets) - 1):
        depths = {weights[j] + 1 for j in children[offsets[i] : offsets[i + 1]]}
        assert len(depths) <= 1
        weights.append(next(iter(depths), 0))
    base = to_flint(common)
    powers = [base**i for i in range(max(weights) + 2)]
    return (
        [[clear(c) for c in row] for row in kernels],
        {k: [clear(c) for c in row] for k, row in pref.items()},
        weights,
        powers,
    )


def project(column, log, enc, arrays, kernels, pref, depth, powers):
    """Apply the dual of the ordinary hyperlog differential to one OPE coefficient."""
    offsets, children, indices, weights, in_offsets, refs, nums, dens = arrays
    chart, name, period = enc["columns"][column]
    rows = [defaultdict(fmpq_poly) for _ in range(len(offsets) - 1)]
    for j in range(in_offsets[column], in_offsets[column + 1]):
        for n, weight in enumerate(pref[chart, name]):
            if weight:
                rows[refs[j]][n, log] += (
                    fmpq(nums[j], dens[j] * 2**log)
                    * weight
                    * powers[len(powers) - 2 - depth[refs[j]]]
                )
    constants = defaultdict(fmpq_poly)
    for i in reversed(range(len(rows))):
        row = rows[i]
        if not row:
            continue
        for n in range(MAX_ORDER + 1):
            for k in range(9):
                weight = row.get((n, k))
                if not weight:
                    continue
                if n == k == 0:
                    if str(i) in enc["constants"]:
                        constants[tuple(enc["constants"][str(i)])] += weight * powers[depth[i]]
                    continue
                if n:
                    weight /= n
                    if k < 8:
                        row[n, k + 1] -= (k + 1) * weight
                else:
                    weight /= k
                for j in range(offsets[i], offsets[i + 1]):
                    child = rows[children[j]]
                    coefficient = weight * weights[j]
                    kernel = kernels[indices[j]]
                    if not n:
                        if kernel[0]:
                            child[0, k - 1] += coefficient * kernel[0]
                    else:
                        for m in range(n + 1):
                            if kernel[m]:
                                child[n - m, k] += coefficient * kernel[m]
    # Angular states ("0",0) and ("",1) are respectively log(h) and -log(h).
    # They arise separately in the ordinary radial system before cancellation.
    assert constants.pop(("0", 0), 0) == constants.pop(("", 1), 0)
    result = constants.pop(("", 0), 0)
    assert not any(constants.values())
    assert period == "1" or not result
    if not result:
        return rational()

    def from_flint(poly):
        return RING.ring.from_dict(
            {(k,): sp.QQ(int(c.p), int(c.q)) for k, c in enumerate(poly) if c}
        )

    return RING.new(from_flint(result), from_flint(powers[-1]))


def main():
    enc, arrays, kernels, pref = radial_data()
    kernel_polys, pref_polys, depth, powers = polynomial_data(kernels, pref, arrays)
    observed = graph_coefficients()
    for log, expected in [(4, (0, rational(1, 24))), (3, (-rational(1, 12), -rational(5, 6)))]:
        values = defaultdict(rational)
        for i, (chart, name, _) in enumerate(enc["columns"]):
            if (chart, name) in pref:
                values[chart, name] += project(
                    i, log, enc, arrays, kernel_polys, pref_polys, depth, powers
                )
        direct = sum(
            rational(c.numerator, c.denominator) * COSINE**m for m, c in observed[log].items()
        )
        fixed = values["id", "F"] + values["inverse", "F"]
        native, crossed = values["id", "Pv"], values["inverse", "Pv"]
        assert (native, crossed) == expected
        assert direct - fixed == 2 * (native + crossed)
        print(
            f"log^{log}: graph minus F and CF = {direct-fixed}, coefficients of native and crossed Pv = {native}, {crossed}",
            flush=True,
        )
    print("The two independent equations give native = crossed = 2.")


if __name__ == "__main__":
    main()
