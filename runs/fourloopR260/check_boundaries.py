"""Check the withheld angular coefficients and the independent signed graph comparisons."""

import json
from collections import defaultdict
from math import isclose, sqrt
from pathlib import Path
from statistics import mean, stdev

HERE = Path(__file__).resolve().parent


def close(a, b):
    if not isclose(a, b, rel_tol=1e-12, abs_tol=1e-11):
        raise ValueError(f"{a} differs from {b}")


def check_angular(data):
    harmonics = defaultdict(set)
    for key, degrees in data["OPE_checks"].items():
        chart, prime, log_power, period = key.split("/")
        for degree, row in degrees.items():
            if row["assembled"].keys() != row["graph"].keys():
                raise ValueError(f"Different angular supports in {key} at {degree}")
            for spin, graph in row["graph"].items():
                if (row["assembled"][spin] - graph) % int(prime):
                    raise ValueError(
                        f"Angular residual in {key} at degree {degree}, spin {spin}"
                    )
                harmonics[prime].add((chart, log_power, period, degree, spin))
    if {p: len(rows) for p, rows in harmonics.items()} != data["by_modulus"]:
        raise ValueError("Angular counts disagree")
    if (
        not harmonics["1000033"] <= harmonics["1000003"]
        or len(harmonics["1000003"]) != 182
    ):
        raise ValueError("Inconsistent repeated angular projections")
    print("182 withheld harmonics agree, including 102 repeated at the second prime.")


def check_graph(graph):
    for row in graph["points"]:
        u, v = row["u"], row["v"]
        crossed = row["crossed_I168"] + row["v_times_swapped_I168"]
        close(u * row["analytic_I260"], row["analytic_R260"] + crossed)
        scrambles = row["scrambles_R260_and_I260"]
        if len(scrambles) != graph["scrambles"]:
            raise ValueError("Missing scramble")
        signed, raw = zip(*scrambles)
        assembled = [(x + crossed) / u for x in signed]
        for sample, key in (
            (signed, "R260_graph"),
            (raw, "I260_graph"),
            (assembled, "I260_from_R260_graph_and_analytic_I168"),
        ):
            close(mean(sample), row[key]["mean"])
            close(stdev(sample) / sqrt(len(sample)), row[key]["standard_error"])
        for obs, key in (("R260", "R260_graph"), ("I260", "I260_graph")):
            pull = (row["analytic_" + obs] - row[key]["mean"]) / row[key][
                "standard_error"
            ]
            print(f"({u}, {v})  {obs}: residual {pull:+.3f} standard errors")


if __name__ == "__main__":
    data = json.loads((HERE / "boundary.json").read_text())
    graph = json.loads((HERE / "euclidean/graph.json").read_text())
    check_angular(data)
    check_graph(graph)
