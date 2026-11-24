"""Numerical Euclidean evaluation of the R168 bootstrap in its native tangential chart."""

from pathlib import Path
from fractions import Fraction
from functools import cache
from math import acos, sqrt, log
import gzip, json, sys
import numpy as np
from scipy.integrate import solve_ivp
from scipy.sparse import csr_matrix
from scipy.special import zeta

HERE = Path(__file__).resolve().parent
TYPES = ("even", "odd", "odd_plus", "odd_minus")


def read(file):
    return json.load(gzip.open(HERE / file, "rt"))


@cache
def system():
    return compile_system(read("R168_bootstrap_function.json.gz")["systems"])


def compile_system(systems):
    edges = [[] for j in range(8)]
    size = 1
    ends = {}
    for t, stages in systems.items():
        old = [0]
        for layer in stages:
            new = list(range(size, size + len(layer)))
            size += len(layer)
            for j, row in enumerate(layer):
                for i, h, c in row:
                    edges[h].append((new[j], old[i], float(Fraction(c))))
            old = new
        ends[t] = old

    def one(ls):
        if not ls:
            return csr_matrix((size, size))
        j, i, c = zip(*ls)
        return csr_matrix((c, (j, i)), shape=(size, size))

    a, b, c, d, e, f, g, h = map(one, edges)
    return [
        2 * a - 2 * b - 2 * f - g + h,
        2 * b + 2 * d,
        2 * b - 2 * d,
        2 * f,
        2 * f,
        g + h,
        g - h,
    ], ends


def initial(radius, poles, ms):
    n = ms[0].shape[0]
    f = np.zeros((n, 9), complex)
    f[0, 0] = 1
    for k in range(1, 9):
        f[:, k] = ms[0] @ f[:, k - 1] / k
    L = np.array([log(radius) ** j for j in range(9)])
    ans = f @ L
    accum = [np.zeros_like(f) for k in poles]
    for j in range(1, 25):
        force = np.zeros_like(f)
        for k, (a, m) in enumerate(zip(poles, ms[1:])):
            accum[k] = (radius / a) * (accum[k] + f)
            force -= m @ accum[k]
        f = np.zeros_like(force)
        for k in range(8, -1, -1):
            g = force[:, k].copy()
            if k < 8:
                g -= (k + 1) * f[:, k + 1]
            t = g / j
            x = t.copy()
            for _ in range(8):
                t = ms[0] @ t / j
                x += t
            f[:, k] = x
        ans += f @ L
    return ans


def native_states(u, v, tol, compiled):
    if u <= 0 or v <= 0:
        raise ValueError("positive Euclidean ratios required")
    radial = sqrt(u)
    c = (1 + u - v) / (2 * radial)
    if abs(c) >= 1:
        raise ValueError("use a limit on the Euclidean diagonal")
    angle = acos(c)
    a = np.exp(1j * angle)
    ell = 2 * c
    if abs(ell) < 1e-12:
        raise ValueError("use a continuous limit at z+bar(z)=0")
    poles = [1 / a, a, 1.0, -1.0, ell, 1 / ell]
    ms, outputs = compiled
    start = min([radial * 0.6, 0.05] + [abs(q) * 0.05 for q in poles])
    init = initial(start, poles, ms)
    special = sorted(set(float(x) for x in (1.0, ell, 1 / ell) if start < x < radial))
    # Continue through apparent singularities with a single smooth path in the radius.
    bend = min(0.18 * min(radial, 1.0), 0.20 * abs(a.imag)) if special else 0

    def rhs(t, F):
        x = start + (radial - start) * t + 1j * bend * 4 * t * (1 - t)
        dx = radial - start + 1j * bend * 4 * (1 - 2 * t)
        out = ms[0] @ F / x
        for m, p in zip(ms[1:], poles):
            out += (m @ F) / (x - p)
        return dx * out

    result = solve_ivp(rhs, (0, 1), init, method="DOP853", rtol=tol, atol=tol * 0.025)
    if not result.success:
        raise ArithmeticError(result.message)
    q = radial * a
    return result.y[:, -1], outputs, q - q.conjugate()


def _native_value(u, v, tol):
    f, outputs, d = native_states(u, v, tol, system())
    pref = np.array(
        [
            v / d**2,
            1 / d,
            v / d * (1 / (u - v) + 1 / (1 - v)),
            v / d * (1 / (u - v) - 1 / (1 - v)),
        ]
    )
    scal = {
        "bare": 1,
        "zeta3": zeta(3, 1),
        "zeta5": zeta(5, 1),
        "zeta3_squared": zeta(3, 1) ** 2,
        "zeta7": zeta(7, 1),
    }
    vals = {k: pref @ f[ids] * scal[k] for k, ids in outputs.items()}
    return sum(vals.values()), vals


def value(u, v, tol=8e-12):
    """R168 and its period contributions on the Euclidean sheet, including removable divisors."""
    if u <= 0 or v <= 0:
        raise ValueError("positive Euclidean ratios required")
    radial = sqrt(u)
    c = (1 + u - v) / (2 * radial)
    if abs(c) > 1 + 1e-13:
        raise ValueError("cross ratios outside the Euclidean region")
    if u > 1 + 3e-6:
        w, parts = value(1 / u, v / u, tol)
        return w / u, {k: x / u for k, x in parts.items()}
    near_diagonal = 1 - abs(c) < 2e-6
    if near_diagonal or min(abs(1 - v), abs(u - v), abs(c), abs(u - 1)) < 3e-6:
        # At a divisor individual cut prefactors may diverge. Extrapolate the physical
        # sum across nearby regular points, using one-sided angles at a collinear endpoint.
        import math

        h = 1.5e-3
        if abs(u - 1) < 3e-6:
            # A change of radius at fixed angle preserves the Euclidean domain.
            ts = (-3, -2, -1, 1, 2, 3)
            points = [
                (
                    (radial + h * j) ** 2,
                    1 + (radial + h * j) ** 2 - 2 * (radial + h * j) * c,
                )
                for j in ts
            ]
        elif near_diagonal:
            h = 0.005
            sign = 1 if c > 0 else -1
            ts = (1, 2, 3, 4, 5, 6)
            points = [(u, 1 + u - 2 * radial * (c - sign * h * j)) for j in ts]
        else:
            h = min(h, (1 - abs(c)) / 8)
            ts = (-3, -2, -1, 1, 2, 3)
            points = [(u, 1 + u - 2 * radial * (c + h * j)) for j in ts]
        weights = [math.prod(-k / (j - k) for k in ts if k != j) for j in ts]
        ys = [value(U, V, min(tol, 6e-13))[1] for U, V in points]
        parts = {key: sum(w * q[key] for w, q in zip(weights, ys)) for key in ys[0]}
        return sum(parts.values()), parts
    return _native_value(u, v, tol)


if __name__ == "__main__":
    u, v = map(float, sys.argv[1:3])
    print(value(u, v, float(sys.argv[3]) if len(sys.argv) > 3 else 8e-12))
