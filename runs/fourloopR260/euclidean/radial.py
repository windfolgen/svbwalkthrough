"""Continue the ordinary GPLs on a Euclidean ray with exact rational dlog kernels and Taylor transport."""

from pathlib import Path
from functools import cache
from math import factorial, log, sqrt
import json, ctypes as ct, sys, cmath
import numpy as np
import sympy as s
import subprocess
from tempfile import TemporaryDirectory

LIBDIR = TemporaryDirectory()
so = Path(LIBDIR.name) / "radial.so"
subprocess.run(
    [
        "c++",
        "-O3",
        "-std=c++17",
        "-shared",
        "-fPIC",
        str(Path(__file__).with_name("radial.cpp")),
        "-o",
        str(so),
    ],
    check=True,
)
lib = ct.CDLL(str(so))
ip = np.ctypeslib.ndpointer(np.int32, flags="C_CONTIGUOUS")
cp = np.ctypeslib.ndpointer(np.complex128, flags="C_CONTIGUOUS")
lib.advance.argtypes = [ct.c_int, ct.c_int, ct.c_int, ct.c_double] + [ip] * 4 + [cp] * 3
T, H = s.symbols("t h")
b = T / H
expr = {
    "E": T * H,
    "0": 0,
    "1": 1,
    "B": b,
    "R": 1 / b,
    "C": 1 - b,
    "D": b / (b - 1),
    "m": -1,
    "T": 2,
    "A": s.Rational(1, 2),
}


@cache
def factors(a, b):
    n, d = s.cancel(expr[a] - expr[b]).as_numer_denom()
    residues = {}
    for sign, pol in ((1, n), (-1, d)):
        roots = s.roots(pol, T)
        assert sum(roots.values()) == s.degree(pol, T), (a, b, pol)
        for root, j in roots.items():
            residues[root] = residues.get(root, 0) + sign * j
    return [(s.lambdify(H, v, "numpy"), j) for v, j in residues.items() if j]


def flow(arr, roots, start, end, order, shrink):
    off, ch, kr, wt = arr
    allroots = {r for ks in roots for r, c in ks}
    import os

    sign = int(os.environ.get("SV_DETOUR", "1"))
    xs = sorted(
        {
            round(r.real, 13)
            for r in allroots
            if abs(r.imag) < 1e-11 and 1e-10 < r.real < end - 1e-10
        }
    )
    route = []
    for j, xc in enumerate(xs):
        before = xs[j - 1] if j else 0
        after = xs[j + 1] if j + 1 < len(xs) else end
        eps = min(0.055, (xc - before) / 4, (after - xc) / 4)
        route.extend([xc - eps, xc + 1j * sign * eps, xc + eps])
    route.append(end)
    t = 0.0
    v = np.asarray(start, np.complex128)
    for target in route:
        while abs(target - t) > 1e-14:
            radius = min(abs(t - r) for r in allroots if t != r)
            dist = abs(target - t)
            length = min(dist, shrink * radius)
            assert length > 1e-13, (end, t, radius)
            delta = (target - t) * length / dist
            poles = np.zeros((len(roots), order + 1), complex)
            for j, singular in enumerate(roots):
                for r, c in singular:
                    if t == r:
                        assert not t
                        poles[j, 0] += c
                        continue
                    u = delta / (t - r)
                    vec = u
                    for k in range(1, order + 1):
                        poles[j, k] += c * vec
                        vec *= -u
            o = np.zeros_like(v)
            lib.advance(
                len(v),
                order,
                t == 0,
                log(abs(delta)) if not t else 0,
                off,
                ch,
                kr,
                wt,
                poles,
                v,
                o,
            )
            t = target if length == dist else t + delta
            v = o
    return v


def angle(wds, h, order, shrink):
    words = {""}
    for w in wds:
        words.update(w[i:] for i in range(len(w) + 1))
    words = sorted(words, key=lambda a: (len(a), a))
    idx = {w: i for i, w in enumerate(words)}
    keys = "01m"
    off = [0]
    child = []
    kr = []
    for w in words:
        if w:
            child.append(idx[w[1:]])
            kr.append(keys.index(w[0]))
        off.append(len(child))
    arr = [np.array(v, np.int32) for v in (off, child, kr, [1] * len(kr))]
    roots = [[(v / h**2, 1)] for v in (0, 1, -1)]
    logs = cmath.log(h * h)
    start = [
        logs ** len(w) / factorial(len(w)) if not w.strip("0") else 0 for w in words
    ]
    return dict(zip(words, flow(arr, roots, start, 1.0, order, shrink)))


def run(src, h, tmax, order, shrink, physical):
    enc = json.loads((src / "encoding.json").read_text())
    arr = [
        np.load(src / (k + ".npy"))
        for k in ("offsets", "children", "kernels", "weights")
    ]
    constants = enc["constants"]
    start = np.zeros(len(arr[0]) - 1, dtype=complex)
    ell = -cmath.log(h)
    if physical:
        ws = {""}
        for w, j in constants.values():
            w = w.translate(str.maketrans("BD", "1m"))
            ws.update(w[: len(w) - k] for k in range(len(w) - len(w.rstrip("0")) + 1))
        av = angle(ws, h, order, shrink)
        for i, (w, j) in constants.items():
            w = w.translate(str.maketrans("BD", "1m"))
            val = sum(
                av[w[: len(w) - k]] * ell**k / factorial(k)
                for k in range(len(w) - len(w.rstrip("0")) + 1)
            )
            start[int(i)] = val * ell**j / factorial(j)
    else:
        start[0] = 1
    roots = [[(complex(f(h)), j) for f, j in factors(a, b)] for a, b in enc["keys"]]
    out = flow(arr, roots, start, tmax, order, shrink)
    return out
