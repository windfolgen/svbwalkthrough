"""Replay the three full Euclidean R260 values from the ordinary expansions of the svMPLs.

Run with Python, NumPy, SciPy, SymPy, a C++17 compiler and OPENBLAS_NUM_THREADS=1.
The scalar R168 evaluations use the repository's independently cross-checked radial function.
The rational coefficients in ordinary_data.npz contain no fitted numerical constants.
"""

import json
import os
from math import sqrt
from pathlib import Path
from tempfile import TemporaryDirectory
import numpy as np
from scipy.integrate import solve_ivp
from scipy.sparse import csr_matrix
from radial import factors, run

HERE = Path(__file__).resolve().parent
from R168_bootstrap import value as remainder168
import mpmath as mp


def component_matrix(path, names):
    labels = json.loads((path / "encoding.json").read_text())["columns"]
    periods = dict(
        (p, float(v))
        for p, v in (
            line.split("\t")
            for line in (path / "constants.tsv").read_text().splitlines()
        )
    )
    idx = np.load(path / "in-ref.npy")
    offsets = np.load(path / "in-offset.npy")
    coeff = np.load(path / "in-num.npy") / np.load(path / "in-den.npy")
    mat = np.zeros((len(names), len(np.load(path / "offsets.npy")) - 1))
    for label, a, b in zip(labels, offsets, offsets[1:]):
        key = tuple(label[:-1])
        if key in names:
            j = names.index(key)
        elif len(key) == 1 and key[0] in names:
            j = names.index(key[0])
        else:
            continue
        np.add.at(mat[j], idx[a:b], coeff[a:b] * periods[label[-1]])
    return mat


def kernel_weights(t, h):
    """Rational numerators of dlog A and dlog M along z=t*h, zz=t/h."""
    ih = 1 / h
    z, b, u = t * h, t * ih, t * t
    a = -(u - 2 * b + 1) * h / (z - 1) - (u - 2 * z + 1) * ih / (b - 1)
    m = (u + 2 * b - 3) * h / (z - 1) - (u + 2 * z - 3) * ih / (b - 1)
    return a, m


def initial(K, weights, h, r, degree):
    ih = 1 / h
    tan = h + ih
    delta = lambda t: t**4 - 6 * t**2 + 4 * t * tan - 3
    py = 0j
    for w, wt in zip(*np.polynomial.legendre.leggauss(degree)):
        x = (w + 1) / 2
        t = float(r * x**6)
        if t < 1e-27:
            continue
        aa, mm = kernel_weights(t, h)
        ca, cm = weights @ run(K, h, t, 24, 0.24, 1)
        py += wt * 3 * r * x**5 * (aa * ca + mm * cm) / (1j * sqrt(-delta(t).real))
    return py / (1j * sqrt(-delta(r).real))


def elliptic_on_ray(K, kinematics):
    enc = json.loads((K / "encoding.json").read_text())
    off, ch, kr, wt = [
        np.load(K / (k + ".npy")) for k in ("offsets", "children", "kernels", "weights")
    ]
    n = len(off) - 1
    ir = np.repeat(np.arange(n), np.diff(off))
    u, v, h = kinematics
    ih = 1 / h
    r = sqrt(u)
    end = 1 / r
    tan = h + ih
    ca_cm = component_matrix(K, ["CA", "CM"])
    s0 = run(K, h, r, 24, 0.25, 1)
    yhs = [initial(K, ca_cm, h, r, k) for k in [26, 42]]
    assert abs(yhs[-1] - yhs[0]) < 1e-8
    mats = {}
    for k, (a, b) in enumerate(enc["keys"]):
        mask = kr == k
        for fn, power in factors(a, b):
            pole = complex(fn(h))
            pole = complex(round(pole.real, 13), round(pole.imag, 13))
            m = csr_matrix(
                (power * wt[mask].astype(float), (ir[mask], ch[mask])), shape=(n, n)
            )
            mats[pole] = mats[pole] + m if pole in mats else m
    # Both detours must be homologous to an infinitesimal detour of the real ray.
    # As the diagonal approaches, the conjugate poles at h and 1/h approach the ray.
    discriminant_roots = np.roots([1., 0., -6., 4 * tan.real, -3.])
    poles = [*mats, h, ih, *discriminant_roots]
    height = min([0.21] + [abs(p.imag) / 2 for p in poles
                           if r <= p.real <= end and abs(p.imag) > 1e-10])
    getH = {}
    for sense in [1, -1]:

        def rhs(x, vec):
            t = r + (end - r) * x + 1j * sense * height * np.sin(np.pi * x)
            dt = end - r + 1j * sense * height * np.pi * np.cos(np.pi * x)
            zs = vec[:-1]
            u = t * t
            aa, mm = kernel_weights(t, h)
            sy = t**4 - 6 * u + 4 * t * tan - 3
            ds = 4 * t**3 - 12 * t + 4 * tan
            ca, cm = ca_cm @ zs
            dy = (aa * ca + mm * cm - 0.5 * ds * vec[-1]) / sy
            return np.r_[
                dt * sum(mat @ zs / (t - pole) for pole, mat in mats.items()), dt * dy
            ]

        sol = solve_ivp(
            rhs, (0, 1), np.r_[s0, yhs[-1]], method="DOP853", rtol=3e-13, atol=1e-14
        )
        assert sol.success
        val = sol.y[-1, -1]
        getH[sense] = val
    return yhs[-1], getH


def ladder(z, n):
    zb = z.conjugate()
    return float(
        mp.re(
            sum(
                (-1) ** j
                * mp.factorial(2 * n - j)
                * mp.log(abs(z) ** 2) ** j
                * (mp.polylog(2 * n - j, z) - mp.polylog(2 * n - j, zb))
                / (mp.factorial(j) * mp.factorial(n - j) * mp.factorial(n))
                for j in range(n + 1)
            )
            / (z - zb)
        )
    )


def evaluate(root, kinematics):
    """Evaluate a native origin ray where the starting root is imaginary."""
    u, v, h = kinematics
    r = sqrt(u)
    d = r * (h - 1 / h)
    z = r * h
    pref = [
        v / (d * (u - 1)),
        u * v / (d * (u - 1)),
        2 * v / (d * (v - 1)),
        2 * u * v / (d * (u - v)),
    ]
    mdir = root / "M"
    keys = [("id", "F"), ("inverse", "F"), ("id", "Pv"), ("inverse", "Pv")]
    M = np.dot(pref, component_matrix(mdir, keys) @ run(mdir, h, r, 24, 0.25, 1))
    H0, branch = elliptic_on_ray(root / "kernel", kinematics)
    source = root / "I214"
    nums = component_matrix(source, ["P0", "Pu", "Pv"])

    def algebraic(t, H):
        t2 = t * t
        v2 = (1 - t * h) * (1 - t / h)
        p0, pu, pv = nums @ run(source, h, t, 24, 0.25, 1)
        return v2 / (t * (h - 1 / h)) * (p0 + pu / (t2 - 1) + pv / (v2 - 1) + t2 * H)

    J = algebraic(r, H0)
    rows = []
    S = z / (z - 1)
    W = 1 - z
    sub = (
        -remainder168(u / v, 1 / v)[0]
        - v * remainder168(v, u)[0]
        + u / v * ladder(S, 2) ** 2
        + v * ladder(W, 2) ** 2
    )
    sub -= v * (1 + u - v) * (ladder(z, 1) * ladder(z, 3) - ladder(z, 2) ** 2 / 3)
    for s, H in branch.items():
        os.environ["SV_DETOUR"] = str(s)
        JC = algebraic(1 / r, H)
        result = M - 2 * (J + JC) + sub
        assert abs(result.imag) < 2e-8
        rows.append(
            dict(
                detour=s,
                M=float(M.real),
                I214=float(J.real),
                CI214=float(JC.real),
                R260=float(result.real),
                imaginary_residual=float(result.imag),
            )
        )
    assert abs(rows[0]["R260"] - rows[1]["R260"]) < 2e-8
    return rows


def verify(root, benchmark):
    u, v = benchmark["u"], benchmark["v"]
    real = (1 + u - v) / 2
    h = (real + 1j * sqrt(u - real**2)) / sqrt(u)
    os.environ["SV_DETOUR"] = "1"
    rows = evaluate(root, (u, v, h))
    expected = benchmark["analytic_R260"]
    for row in rows:
        if abs(row["R260"] - expected) > 2e-8:
            raise ValueError(f"R260 differs from the benchmark at {(u,v)}")
    print(
        f"(u,v)=({u},{v})  R260={rows[0]['R260']:.10f}  graph={benchmark['R260_graph']['mean']:.6f}",
        flush=True,
    )


if __name__ == "__main__":
    with TemporaryDirectory() as folder, np.load(
        HERE / "ordinary_data.npz", allow_pickle=False
    ) as data:
        root = Path(folder)
        for label in data:
            tag, key = label.split("_", 1)
            path = root / tag
            path.mkdir(exist_ok=True)
            if key.endswith((".tsv", ".json")):
                (path / key).write_text(str(data[label]))
            else:
                np.save(path / (key + ".npy"), data[label])
        for benchmark in json.loads((HERE / "graph.json").read_text())["points"]:
            verify(root, benchmark)
        r168 = json.loads(
            (HERE.parents[1] / "fourloopR168/validation.json").read_text()
        )
        for row in r168["Euclidean_points"]:
            value = remainder168(row["u"], row["v"])[0]
            if abs(value - row["bootstrap"]) > 2e-8:
                raise ValueError(
                    "Independent R168 radial evaluation differs from the benchmark"
                )
            print(f"(u,v)=({row['u']},{row['v']})  R168={value.real:.10f}", flush=True)
