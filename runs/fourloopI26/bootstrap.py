"""Direct svMPL coefficients from graph OPE data and exact function symmetries."""

from collections import defaultdict, Counter
from pathlib import Path
from functools import cache
import re, json, os
import sympy as s
from flint import fmpq as Q, nmod_mat, fmpq_mat

import argparse
import subprocess
from itertools import product
from shutil import which

from tempfile import TemporaryDirectory
from zipfile import ZipFile

package = Path(__file__).resolve().parent
inputs = package / "inputs"


def make_words():
    basis = []
    for weight, period in [
        (7, "1"),
        (4, "f[3]"),
        (2, "f[5]"),
        (1, "f[3]^2"),
        (0, "f[7]"),
    ]:
        for letters in product("01", repeat=weight):
            basis.append([period, "".join(letters)])
        if weight == 7:
            for position in range(3):
                for ends in product("01", repeat=weight - 1):
                    letters = list(ends)
                    letters.insert(position, "B")
                    basis.append([period, "".join(letters)])
    # Exhaust all 0,1,zbar assignments in the last two positions, also in
    # the lower-weight period sectors. The previous family occurs first.
    for period, weight in [("1", 7), ("f[3]", 4), ("f[5]", 2), ("f[3]^2", 1)]:
        for prefix in product("01B", repeat=min(2, weight)):
            n = prefix.count("B")
            if n == 0 or (weight == 7 and n < 2):
                continue
            for suffix in product("01", repeat=max(0, weight - 2)):
                basis.append([period, "".join(prefix + suffix)])
    terms = []
    for period, word in basis:
        indices = ",".join("zz" if k == "B" else k for k in word)
        terms.append("(" + period + ")*I[z," + indices + ",0]" if indices else period)
    return basis, "words:=[" + ",\n".join(terms) + "]:\n"


sizes = {"native": 5, "cross": 3}


def mon(d):
    """Canonical exponent tuple for a word, period, or power-log coefficient."""
    return tuple(sorted((k, v) for k, v in d.items() if v))


@cache
def monparse(term):
    atoms = Counter()
    c = Q(1)
    for operator, base, pwr in re.findall(
        r"([*/]?)([a-zA-Z]+(?:\[[^\]]+\])?|\d+)(?:\^(\d+))?", term
    ):
        n = int(pwr or "1") * (-1 if operator == "/" else 1)
        if base.isdigit():
            c *= Q(base) ** n
        elif base == "f[3,3]":
            atoms["f[3]"] += 2 * n
            c /= 2**n
        else:
            atoms[base] += n
    return mon(atoms), c


def parse(text):
    out = defaultdict(Q)
    if "(" in text:
        syms = {}

        def safe(m):
            k = m.group(0)
            if k not in syms:
                syms[k] = "A" + str(len(syms))
            return syms[k]

        raw = re.sub(r"[A-Za-z]+\[[^\]]*\]", safe, text)
        inner = (
            str(s.expand(s.sympify(raw.replace("^", "**"))))
            .replace(" ", "")
            .replace("**", "^")
        )
        inv = {v: k for k, v in syms.items()}
        text = re.sub(r"A\d+", lambda m: inv[m.group()], inner)
    for sign, term in re.findall(r"([+-]?)([^+-]+)", text):
        assert re.fullmatch(
            r"(?:[*/]?(?:[a-zA-Z]+(?:\[[^\]]+\])?|\d+)(?:\^\d+)?)+", term
        ), term
        key, c = monparse(term)
        if c:
            out[key] += -c if sign == "-" else c
    return {k: c for k, c in out.items() if c}


def graph_jet(frame):
    """Apply the cut derivative to the graph series and expand at the local cusp."""
    cross = frame == "cross"
    cap = sizes[frame]
    path = inputs / (frame + ".m")
    U, Y, L = s.symbols("u Y lg")
    z, b = s.symbols("z zz")
    f = {i: s.Symbol("zeta" + str(i)) for i in (3, 5, 7)}
    a = path.read_text().replace("^", "**").replace("Log[u]", "lg")
    for i in f:
        a = a.replace("Zeta[" + str(i) + "]", str(f[i]))
    g = s.sympify(a)
    delta = Y**2 - 2 * U * (2 - Y) + U**2
    aa, hh = (1, 2) if cross else (2, 1)
    D = lambda q: aa * (U * s.diff(q, U) + s.diff(q, L)) - hh * (1 - Y) * s.diff(q, Y)
    num = (
        s.expand((delta * D(g) + D(delta) * g / 2) / U)
        if cross
        else s.expand(
            (delta * D(g) + D(delta) * g / 2) * sum(Y**j for j in range(cap + 1))
        )
    )
    pred = 0
    for (i, j), c in s.Poly(num, U, Y).terms():
        if 2 * i + j <= cap:
            pred += c * (z * b) ** i * (z + b - z * b) ** j
    out = {}
    for power, q in s.Poly(pred, z, b, L, *f.values()).terms():
        i, j = power[:2]
        if i + j > cap:
            continue
        key = mon(dict(zip(["z", "zz", "lg", "f[3]", "f[5]", "f[7]"], power)))
        out[key] = Q(str(q))
    return out


def light_target():
    # Native graph DIS coefficients in conventional HPLs at Y, with H_1=-G_1.
    g = {
        4: {"001": Q(-1, 24), "011": Q(-1, 12), "101": Q(1, 12)},
        3: {"0001": Q(5, 6), "0011": Q(2, 3), "0101": Q(1, 3), "1001": Q(-2, 3)},
    }
    return {
        mon({"lg": k, "LL[" + ",".join(w) + "]": 1}): c * (-1) ** w.count("1")
        for k, a in g.items()
        for w, c in a.items()
    }


sections = ["mirror", "inv", "light", "crosslight", "native", "cross"]


def equations(basis, projections):
    """Join the six function projections with the independent graph right-hand sides."""
    rows = defaultdict(dict)
    for tag in sections:
        lines = projections[tag].splitlines()
        if len(lines) != len(basis):
            raise ValueError(f"Incomplete {tag} projection")
        for i, ln in enumerate(lines):
            idx, expr = ln.split("\t")
            if int(idx) != i + 1:
                raise ValueError(f"Misordered {tag} projection")
            parsed = parse(expr)
            for key, c in parsed.items():
                d = dict(key)
                if tag in sizes and d.get("z", 0) + d.get("zz", 0) > sizes[tag]:
                    continue
                rows[tag, key][i] = c
    targets = {"light": light_target(), **{k: graph_jet(k) for k in sizes}}
    for tag, ts in targets.items():
        for k, c in ts.items():
            rows[tag, k][len(basis)] = c
    return rows


def matrix(rows, ids, p):
    lookup = {i: j for j, i in enumerate(ids)}
    n = len(ids)
    out = []
    for k, row in rows.items():
        vec = [0] * n
        for i, c in row.items():
            if i in lookup:
                vec[lookup[i]] = int(c.numerator) * pow(int(c.denominator), -1, p) % p
        out.append(vec)
    return nmod_mat(out, p)


def run(basis, projections):
    """Test the nested ansätze and solve independent rows over the rationals."""
    rows = equations(basis, projections)
    nb = len(basis)
    ids = list(range(nb))
    rhs = nb
    reports = {}
    for label, idx in [
        ("binary", [i for i, (p, w) in enumerate(basis) if "B" not in w]),
        ("last_two", [i for i, (p, w) in enumerate(basis) if "B" not in w[2:]]),
        ("last_three", ids),
    ]:
        reports[label] = {}
        for prime in (1000003, 1000033):
            a = matrix(rows, idx, prime).rank()
            aug = matrix(rows, idx + [rhs], prime).rank()
            reports[label][str(prime)] = [len(idx), a, aug]
        print(label, reports[label], flush=True)
    m = matrix(rows, ids, 1000003)
    rr, rank = m.transpose().rref()
    selected = [next(j for j in range(rr.ncols()) if rr[k, j]) for k in range(rank)]
    del rr, m
    D = list(rows.items())
    cs = [D[j][1] for j in selected]
    A = fmpq_mat([[v.get(i, Q(0)) for i in ids] for v in cs])
    b = fmpq_mat([[v.get(rhs, Q(0))] for v in cs])
    if rank != nb:
        raise ValueError("The expanded word ansatz is underdetermined")
    solution = A.solve(b, algorithm="dixon")
    for (channel, monomial), row in D:
        residual = sum(
            (solution[i, 0] * c for i, c in row.items() if i != rhs), Q(0)
        ) - row.get(rhs, 0)
        if residual:
            raise ValueError(f"Nonzero residual in {channel} at {monomial}")
    terms = {(p, w): solution[i, 0] for i, (p, w) in enumerate(basis) if solution[i, 0]}
    return terms, reports, len(rows)


def published_kernel():
    source = (package.parents[1] / "anc/fourloopI26.mpl").read_text()
    formula = source.split("I26P7SV :=", 1)[1].split(":", 1)[0]
    coefficients = {}
    for term in formula.split():
        match = re.fullmatch(r"([+-]?)(?:(\d+)\*)?(f\[3\]\*)?I\[z,([01z,]+),0\]", term)
        if not match:
            raise ValueError(f"Unrecognized ancillary term {term}")
        sign, factor, period, indices = match.groups()
        word = "".join("B" if k == "zz" else k for k in indices.split(","))
        key = ("f[3]" if period else "1", word)
        if key in coefficients:
            raise ValueError(f"Repeated ancillary word {word}")
        coefficients[key] = Q((-1 if sign == "-" else 1) * int(factor or "1"))
    return coefficients


def load_projections(words, library, maple):
    if library is None:
        with ZipFile(inputs / "word_projections.zip") as archive:
            if archive.read("words.mpl").decode() != words:
                raise ValueError("The tabulated word ordering differs from the ansatz")
            return {tag: archive.read(tag + ".tsv").decode() for tag in sections}
    with TemporaryDirectory() as temp:
        folder = Path(temp)
        (folder / "words.mpl").write_text(words)
        subprocess.run(
            [maple, "-q", str(package / "function_constraints.mpl")],
            cwd=folder,
            env={
                **os.environ,
                "I26_SV_LIBRARY": str(library.resolve()),
                "I26_SV_WORK": temp,
            },
            check=True,
        )
        return {tag: (folder / (tag + ".tsv")).read_text() for tag in sections}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--library",
        type=Path,
        help="Regenerate the word projections with this HyperlogProcedures 0.8 installation",
    )
    parser.add_argument("--maple", default=which("maple") or "maple")
    parser.add_argument(
        "--output", type=Path, help="Write the recovered nonzero coefficients as JSON"
    )
    args = parser.parse_args()
    basis, words = make_words()
    projections = load_projections(words, args.library, args.maple)
    fitted, ranks, row_count = run(basis, projections)
    validation = json.loads((package / "validation.json").read_text())[
        "repeated_last_two_extension"
    ]
    if ranks != validation["ranks"] or row_count != validation["equation_count"]:
        raise ValueError("The constraint counts or ranks differ from the benchmark")
    if fitted != published_kernel():
        raise ValueError("The fitted coefficients differ from anc/fourloopI26.mpl")
    if args.output:
        args.output.write_text(
            json.dumps(
                [
                    dict(period=p, maple_word=w, coefficient=str(c))
                    for (p, w), c in fitted.items()
                ],
                indent=2,
            )
            + "\n"
        )
    print(
        f"{len(fitted)} recovered terms agree with anc/fourloopI26.mpl; all {row_count} rational residuals vanish."
    )
