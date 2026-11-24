"""Independent graph boundaries and tests of the normalization of the fifth numerator."""

import argparse
import json
from concurrent.futures import ProcessPoolExecutor
from itertools import repeat
from math import prod, sqrt
import os
from pathlib import Path
import sys
from tempfile import TemporaryDirectory

import numpy as np

HERE = Path(__file__).resolve().parent


def extrapolate(values, steps):
    return sum(
        np.asarray(values[i - 1]) * prod(-j / (i - j) for j in steps if j != i) for i in steps
    )


def analytic(row, root):
    import verify as evaluator

    u, v0 = row["u"], row["v"]
    values = []
    for i in range(1, 7):
        v = v0 + i * row["step"]
        r, w = sqrt(u), (1 + u - v) / 2
        h = (w + 1j * sqrt(u - w * w)) / r
        os.environ["SV_DETOUR"] = "1"
        result = evaluator.evaluate(root, (u, v, h))[0]["R260"]
        if row["boundary"] == "circle":
            path = root / "M"
            vals = evaluator.component_matrix(
                path, [("id", "Pv"), ("inverse", "Pv")]
            ) @ evaluator.run(path, h, r, 24, 0.25, 1)
            d = r * (h - 1 / h)
            native, crossed = vals * [v / (d * (v - 1)), u * v / (d * (u - v))]
            assert max(abs(native.imag), abs(crossed.imag)) < 1e-7
            values.append([result, native.real, crossed.real])
        else:
            values.append([result])
    return values


def regenerate_analytic(rows):
    sys.path.insert(0, str(HERE.parent / "euclidean"))
    import verify

    with TemporaryDirectory() as folder, np.load(
        verify.HERE / "ordinary_data.npz", allow_pickle=False
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
        with ProcessPoolExecutor(max_workers=min(4, len(rows))) as pool:
            for row, values in zip(rows, pool.map(analytic, rows, repeat(root))):
                np.testing.assert_allclose(values, row["analytic"], rtol=0, atol=1e-6)


def regenerate_graph(rows):
    from scipy.stats import qmc
    from boundary_graph import signed_graph

    for row in rows:
        samples = []
        for seed in row["seeds"]:
            net = qmc.Sobol(8, scramble=True, seed=seed).random_base2(row["power"])
            samples.append(signed_graph(row["u"], row["v"], net))
        np.testing.assert_allclose(samples, row["graph"], rtol=0, atol=1e-7)


def report(rows):
    native_crossed, errors = [], []
    circle_seeds = None
    for row in rows:
        # Compare a fourth-order extrapolation at three stencil choices.
        limit = extrapolate(row["analytic"], (1, 2, 3, 4))
        for steps in [(2, 3, 4, 5), (2, 3, 4, 5, 6)]:
            np.testing.assert_allclose(
                limit, extrapolate(row["analytic"], steps), rtol=0, atol=3e-6
            )
        draws = np.asarray(row["graph"])
        sem = draws.std(ddof=1) / sqrt(len(draws))
        print(
            f"({row['u']}, {row['v']}):  svMPL {limit[0]:.7f}, graph {draws.mean():.7f} +/- {sem:.7f}"
        )
        if row["boundary"] == "circle":
            if circle_seeds is None:
                circle_seeds = row["seeds"]
            assert circle_seeds == row["seeds"]
            native_crossed.append(limit[1:])
            residuals = draws - limit[0]
            errors.append(residuals)
            response = sum(limit[1:])
            print(f"  G=a Pv: a = {2+residuals.mean()/response:.7f} +/- {sem/abs(response):.7f}")
    # Pair corresponding scrambles when estimating the covariance between kinematics.
    draws = 2 + np.linalg.solve(native_crossed, errors)
    print(
        "Independent native and crossed normalizations:",
        draws.mean(axis=1),
        "+/-",
        draws.std(axis=1, ddof=1) / sqrt(draws.shape[1]),
    )


if __name__ == "__main__":
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument(
        "--analytic",
        action="store_true",
        help="recompute the physical svMPL limits on both detours",
    )
    cli.add_argument(
        "--graph", action="store_true", help="recompute the signed graph at each exact boundary"
    )
    args = cli.parse_args()
    rows = json.loads((HERE / "boundaries.json").read_text())
    if args.analytic:
        regenerate_analytic(rows)
    if args.graph:
        regenerate_graph(rows)
    report(rows)
