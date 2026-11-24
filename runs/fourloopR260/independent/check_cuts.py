"""Reconstruct the signed exterior-cut forms from the stored logarithmic decompositions."""
import argparse
import gzip
import json
from concurrent.futures import ProcessPoolExecutor
from functools import cache
from itertools import combinations, permutations, product
from math import prod
from pathlib import Path

import sympy as sp
from flint import fmpq_mpoly, fmpq_mpoly_ctx

HERE = Path(__file__).resolve().parent
with gzip.open(HERE / "exterior.json.gz", "rt") as stream:
    data = json.load(stream)
C = fmpq_mpoly_ctx.get(("z", "b", *("t" + str(i) for i in range(7))))
one, zero = C.constant(1), C.constant(0)
ext = (1, 2, 3, 4)
chords = list(combinations(range(8), 2))


def wedge(a, b):
    return [a[i] * b[j] - a[j] * b[i] for i, j in combinations(range(4), 2)]


def chord(a, b):
    return -sum(x * y for x, y in zip(a, (b[5], -b[4], b[3], b[2], -b[1], b[0])))


def line(a, r, b):
    return [u + r * v for u, v in zip(a, b)]


def normalize(a, b):
    if not a:
        return zero, one
    common = a.gcd(b)
    a, b = a // common, b // common
    lc = b.leading_coefficient()
    return a / lc, b / lc


def graph_form(info, graph_terms=None):
    z, b, *t = C.gens()
    hs = iter([one, *t])
    def external(v):
        return ((one, zero), (one, v), (one, one), (zero, one))
    pairs = [([*a, zero, zero], [zero, zero, *c]) for a, c in zip(external(z), external(b))]
    lines = [wedge(*ab) for ab in pairs]
    scales, cuts, jac = [], set(), one
    choices = iter(info["choices"])
    for j, group in enumerate(info["shape"], 5):
        cuts.update((e, j) for e in group)
        if len(group) == 3:
            missing, = set(ext) - set(group)
            h = next(hs)
            ab = [[fmpq_mpoly(q.replace("h", f"({h})"), C) for q in row]
                  for row in data["triple"][str(missing)]]
            scales.append((missing, j, h))
        elif len(group) == 2:
            ab = [line(a, next(hs), c) for a, c in (pairs[e-1] for e in group)]
        else:
            e, = group
            f = next(choices)
            a, c = pairs[e-1]
            u, v = pairs[f-1]
            x, y, s = next(hs), next(hs), next(hs)
            ab = [line(a, x, c), line(line(u, y, c), s, v)]
            jac *= chord(lines[e-1], lines[f-1])
        lines.append(wedge(*ab))
    assert next(hs, None) is None
    ds = {(i+1, j+1): chord(lines[i], lines[j]) for i, j in chords}
    assert cuts == {k for k, v in ds.items() if not v}
    if graph_terms is None:
        graph_terms = data["graphs"][info["graph"]]
    terms = [(a, {(i, j): k for i, j, k in row}) for a, row in graph_terms]
    terms = [(a, graph) for a, graph in terms if all(graph.get(k) == -1 for k in cuts)]
    if not terms:
        return zero, one
    low = {k: max(0, *(-g.get(k, 0) for _, g in terms)) for k in ds if k not in cuts}
    num = sum(a * prod(ds[k] ** (v + g.get(k, 0)) for k, v in low.items() if v + g.get(k, 0)) for a, g in terms)
    den = prod(ds[k] ** v for k, v in low.items() if v)
    return normalize(num * jac * prod(ds[m, j] for m, j, h in scales),
                     den * 96 * (z-b) ** len(scales) * prod(h for m, j, h in scales))


@cache
def verify_terminal(graph, n, den, variables, coordinates):
    z, b = sp.symbols("z b")
    u, v, d = z*b, (1-z)*(1-b), z-b
    pref = (v/(d*(u-1)), u*v/(d*(u-1)), v/(d*(v-1)), u*v/(d*(u-v)))
    rows = {tuple(map(sp.Rational, row)) for row in coordinates}
    if graph == "M":
        assert not variables and len(rows) == 1
        assert sp.cancel(sp.sympify(n)/sp.sympify(den)-sum(c*f for c, f in zip(next(iter(rows)), pref))) == 0
        return
    var, = map(sp.Symbol, variables)
    a, h = [sp.Poly(q, var, domain=sp.QQ.frac_field(z, b)) for q in (n, den)]
    assert a.degree() < h.degree()
    radical_squares = ((u*v/d)**2/((1-u)**2-4*v), (v/d)**2/((1-u)**2-4*u*v))
    found = set()
    for factor, mult in h.factor_list()[1]:
        assert mult == 1 and factor.degree() in (1, 2)
        res = (a * (h.exquo(factor)*factor.diff()).invert(factor)) % factor
        mean, square = res.nth(0), 0
        if factor.degree() == 2:
            f2, f1, f0 = (factor.nth(j) for j in (2, 1, 0))
            slope = res.nth(1)
            mean -= slope*f1/(2*f2)
            square = (f1*f1-4*f2*f0)*(slope/(2*f2))**2
        matches = set()
        for row in rows:
            c, e, r, s = row
            if r*s or sp.cancel(mean - c*pref[0] - e*pref[1]):
                continue
            if sp.cancel(square - r*r*radical_squares[0] - s*s*radical_squares[1]) == 0:
                matches.add(row)
        assert matches and all((c,e,-r,-s) in matches for c,e,r,s in matches)
        found.update(matches)
    assert found == rows


def restrict(poly, var, a, h):
    """Evaluate a polynomial at variable a/h and return its reduced fraction."""
    degree = int(poly.degrees()[var])
    if not degree:
        return poly, one
    return normalize((h*C.gen(var)-a).resultant(poly, var), h**degree)


def replay(info):
    numerator, denominator = graph_form(info)
    dag = info["decomposition"]
    if not numerator:
        assert not dag and not info["nodes"]
        return
    seen = {}
    def check(index, n, d, remaining):
        key = str(n), str(d), remaining
        if index in seen:
            assert seen[index] == key
            return
        seen[index] = key
        node = dag["nodes"][index]
        if "terminal" in node:
            assert list(key[:2]) == node["terminal"]
            assert list(remaining) == node["variables"]
            verify_terminal(info["graph"], *key[:2], remaining, tuple(map(tuple, node["coordinates"])))
            return
        name = node["variable"]
        assert name in remaining
        j = C.names().index(name)
        assert n.degrees()[j] < d.degrees()[j]
        expected = dict(node["children"])
        assert len(expected) == len(node["children"])
        seen_poles = set()
        for fac, power in d.factor()[1]:
            degree = fac.degrees()[j]
            if not degree:
                continue
            assert degree == power == 1
            h = fac.derivative(j)
            a = -fac.subs({j:0})
            pn, pd = restrict(n, j, a, h)
            if not pn:
                continue
            qn, qd = restrict((d//fac)*h, j, a, h)
            residue = normalize(pn*qd, pd*qn)
            pole = str(a) + " / " + str(h)
            seen_poles.add(pole)
            check(expected[pole], *residue, tuple(t for t in remaining if t != name))
        assert seen_poles == set(expected)
    check(dag["root"], numerator, denominator, tuple(C.names()[2:]))
    assert len(seen) == len(dag["nodes"]) == info["nodes"]


def check_coverage():
    def canonical(groups):
        return min(tuple(sorted((tuple(sorted(perm[e-1] for e in g)) for g in groups),
                                key=lambda g: (-len(g),g))) for perm in data["stabilizer"])
    patterns = set(permutations((3,2,2,1))) | set(permutations((3,3,1,1)))
    graphs = {canonical([tuple(i for i, j, k in terms if i in ext and j == a and k == -1)
                         for a in range(5,9)]) for _, terms in data["graphs"]["M"]}
    actual = {canonical(subset) for graph in graphs for shape in patterns
              for subset in product(*(combinations(g,k) for g,k in zip(graph, shape)))}
    for name in ("M","Y0"):
        recorded = [tuple(map(tuple, case["shape"])) for case in data["charts"] if case["graph"] == name]
        assert len(recorded) == len(actual) == 42 and set(recorded) == actual


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--orbit", type=int)
    parser.add_argument("--workers", type=int, default=2)
    args = parser.parse_args()
    check_coverage()
    cases = [c for c in data["charts"] if args.orbit is None or c["orbit"] == args.orbit]
    assert cases
    with ProcessPoolExecutor(args.workers) as pool:
        list(pool.map(replay, cases))
    print(f"Reconstructed {len(cases)} meromorphic cut forms from their logarithmic decompositions.")
