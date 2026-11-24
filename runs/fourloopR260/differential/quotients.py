"""Generate sector-quotient jobs or combine their Kira reductions for the fixed-u derivative."""

import argparse
import gzip
import json
import re
from functools import lru_cache
from pathlib import Path

from flint import fmpz_mpoly_ctx, fmpz_mpoly
import sympy as sp

from source import D, EDGES, HERE, aligned_graphs, compact, differentiated, scaled_direct

ONE_PINCH = [(i,) for i in range(1, 14)]
TWO_PINCH = [(2, 3), (2, 5), (2, 6), (2, 8), (2, 9), (5, 6)]
RING = fmpz_mpoly_ctx.get(("u", "v", "D"))
MASTER = (1,) * 13 + (0,) * 5


def tag(missing):
    return "omit-" + "-".join(map(str, missing))


def survives(indices, missing):
    return all(indices[i - 1] > 0 for i in range(1, 14) if i not in missing)


def as_integral(indices):
    return "T[" + ",".join(map(str, indices)) + "]"


def indices(text):
    return tuple(map(int, text.split(",")))


def case_files(folder):
    return {k: (folder / "results" / "T" / k).read_text() for k in ("masters", "kira_target.m")}


def read_rules(files):
    rules = {
        indices(t): {indices(t): sp.Integer(1)}
        for t in re.findall(r"T\[([^\]]+)\]", files["masters"])
    }
    for part in files["kira_target.m"].strip().strip("{}").split("\n,"):
        if "->" not in part:
            continue
        left, right = part.split("->")
        source = indices(re.search(r"T\[([^\]]+)\]", left)[1])
        rules[source] = {
            indices(t): sp.sympify(c.replace("^", "**"), locals={"d": D})
            for t, c in re.findall(r"T\[([^\]]+)\]\*([^\n]+)", right)
        }
    return rules


def reduced(num, den):
    if not num:
        return RING.constant(0), RING.constant(1)
    g = num.gcd(den)
    return num // g, den // g


@lru_cache(None)
def fraction(expr):
    return reduced(*(fmpz_mpoly(str(p).replace("**", "^"), RING) for p in expr.as_numer_denom()))


def project(terms, rules, missing):
    answer = {}
    for a, coeff in terms.items():
        if not survives(a, missing):
            continue
        n, d = fraction(coeff)
        for m, c in rules[a].items():
            p, q = fraction(c)
            x, y = answer.get(m, (RING.constant(0), RING.constant(1)))
            answer[m] = reduced(x * d * q + y * n * p, y * d * q)
    return {m: t for m, t in answer.items() if t[0]}


def write_job(root, missing, inputs):
    folder = root / tag(missing)
    config = folder / "config"
    config.mkdir(parents=True, exist_ok=True)
    loop_names = {1: "", 2: "p", 3: "k", 5: "l1", 6: "l2", 7: "l3", 8: "l4"}
    propagators = ["-".join(filter(None, (loop_names[j], loop_names[i]))) for i, j in EDGES]
    cuts = [i for i in range(1, 14) if i not in missing]
    (config / "integralfamilies.yaml").write_text(
        "integralfamilies:\n  - name: T\n    loop_momenta: [l1,l2,l3,l4]\n"
        f"    top_level_sectors: [8191]\n    cut_propagators: {cuts}\n    propagators:\n"
        + "".join(f'      - ["{p}", 0]\n' for p in propagators)
    )
    (config / "kinematics.yaml").write_text(
        "kinematics:\n  incoming_momenta: [p,k]\n  outgoing_momenta: []\n"
        "  kinematic_invariants: [[u,2],[v,2],[s,2]]\n  scalarproduct_rules:\n"
        "    - [[p,p],u]\n    - [[k,k],s]\n    - [[p-k,p-k],v]\n  symbol_to_replace_by_one: s\n"
    )
    (folder / "target").write_text(
        "".join(as_integral(a) + "\n" for a in inputs if survives(a, missing))
    )
    (folder / "job.yaml").write_text(
        "jobs:\n  - reduce_sectors:\n      reduce:\n        - {sectors: [8191], r: 14, s: 4}\n"
        "      select_integrals:\n        select_mandatory_list:\n          - [T,target]\n"
        "      run_initiate: true\n      run_triangular: true\n      run_back_substitution: true\n"
        "  - kira2math:\n      target:\n        - [T,target]\n"
    )


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    opts = cli.add_mutually_exclusive_group()
    opts.add_argument("--write-jobs", type=Path)
    opts.add_argument("--from-jobs", type=Path)
    args = cli.parse_args()
    graphs = aligned_graphs()
    deriv = {name: compact(differentiated(t, scaled_direct)) for name, t in graphs.items()}
    archive = json.loads(gzip.decompress((HERE / "quotients.json.gz").read_bytes()))
    inputs = sorted(set().union(*graphs.values(), *deriv.values()))
    for missing in ONE_PINCH + TWO_PINCH:
        name = tag(missing)
        if args.write_jobs:
            write_job(args.write_jobs, missing, inputs)
            continue
        saved = archive[name]
        rules = read_rules(case_files(args.from_jobs / name) if args.from_jobs else saved["files"])
        results = {label: project(row, rules, missing) for label, row in deriv.items()}
        for label, terms in results.items():
            assert MASTER not in terms
            assert sorted(map(as_integral, terms)) == saved["support"][label]
        print(name, "M", len(results["M"]), "Y0", len(results["Y0"]))


if __name__ == "__main__":
    main()
