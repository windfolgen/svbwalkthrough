"""Exact fixed-u differential of the signed graphs M and Y0 in one integral family."""

import argparse
from collections import defaultdict, Counter
import gzip
from itertools import combinations, permutations
import json
from pathlib import Path

import sympy as sp

HERE = Path(__file__).resolve().parent
U, V, D = sp.symbols("u v D")
W = (1 + U - V) / 2
DELTA = U - W**2
LAMBDA = -4 * DELTA
BETA = (2 * D - 7) / V + (3 - D) * sp.diff(LAMBDA, V) / (2 * LAMBDA)
EDGES = (
    (1, 5),
    (1, 6),
    (1, 7),
    (2, 5),
    (2, 6),
    (2, 8),
    (3, 5),
    (3, 7),
    (3, 8),
    (5, 6),
    (5, 7),
    (6, 8),
    (7, 8),
    (1, 8),
    (2, 7),
    (3, 6),
    (5, 8),
    (6, 7),
)
PARENT = (1,) * 13 + (0, 0, 0, -1, -1)
VERTICES = (1, 2, 3, 5, 6, 7, 8)


def shifted(indices, position, amount):
    powers = list(indices)
    powers[position] += amount
    return tuple(powers)


def square(out, indices, i, j, coefficient):
    """Multiply an indexed integral by a squared distance in the numerator."""
    if i == j:
        return
    edge = tuple(sorted((i, j)))
    if edge in EDGES:
        out[shifted(indices, EDGES.index(edge), -1)] += coefficient
    else:
        out[indices] += coefficient * {(1, 2): U, (2, 3): V, (1, 3): 1}[edge]


def compact(out):
    factored = {key: sp.factor(value) for key, value in out.items() if value != 0}
    return {key: value for key, value in factored.items() if value != 0}


def aligned_graphs():
    data = json.loads(
        gzip.decompress((HERE.parent / "independent" / "exterior.json.gz").read_bytes())
    )
    rotations = [dict(zip(range(1, 9), (1, 2, 3, 4, *p))) for p in permutations(range(5, 9))]
    packets = {}
    for name, graph in data["graphs"].items():
        terms = defaultdict(int)
        for weight, monomial in graph:
            # Degree zero at each external vertex allows x4 -> infinity with no leftover power.
            assert all(sum(e for i, j, e in monomial if a in (i, j)) == 0 for a in range(1, 5))
            distances = {(i, j): e for i, j, e in monomial if 4 not in (i, j)}
            external = U ** distances.get((1, 2), 0) * V ** distances.get((2, 3), 0)
            embedded = []
            for mapping in rotations:
                powers = {
                    tuple(sorted((mapping[i], mapping[j]))): -e
                    for (i, j), e in distances.items()
                    if j >= 5
                }
                if all(edge in EDGES[:13] for edge, e in powers.items() if e > 0):
                    embedded.append(tuple(powers.get(edge, 0) for edge in EDGES))
            assert embedded
            terms[min(embedded)] += sp.Rational(weight, 96) * external
        packets[name] = compact(terms)
        assert packets[name][PARENT] == U * V
    assert {name: len(terms) for name, terms in packets.items()} == {"M": 12, "Y0": 8}
    return packets


def convergent_at_separated_points(indices):
    """Power count all internal clusters, fixed vertices and the point at infinity in D=4."""
    powers = {edge: n for edge, n in zip(EDGES, indices) if n}
    towards_infinity = {
        (4, i): 4 - sum(n for edge, n in powers.items() if i in edge) for i in range(5, 9)
    }
    powers.update(towards_infinity)

    def degree(vertices):
        return sum(n for (a, b), n in powers.items() if a in vertices and b in vertices)

    for size in range(1, 5):
        for cluster in combinations(range(5, 9), size):
            if size > 1 and degree(cluster) >= 2 * (size - 1):
                return False
            if any(degree((*cluster, i)) >= 2 * size for i in range(1, 5)):
                return False
    return True


def ibp(indices, i, j):
    """Divergence in x_i of (x_j-x_i) times the seed integrand."""
    out = defaultdict(int)
    out[indices] = -D
    for pos, edge in enumerate(EDGES):
        a = indices[pos]
        if i not in edge or a == 0:
            continue
        other = edge[0] if edge[1] == i else edge[1]
        out[indices] += a
        raised = shifted(indices, pos, 1)
        square(out, raised, i, j, a)
        square(out, raised, other, j, -a)
    return out


def scaled_ward(indices):
    """2 delta times the derivative with respect to v at fixed u, after a conformal change of variables."""
    out = defaultdict(int)
    bp = bk = 1 / (2 * V)
    ap, ak = bp - W * bk, U * bk - W * bp
    for i in VERTICES:
        weight = sum(n for edge, n in zip(EDGES, indices) if i in edge)
        c = D - weight if i >= 5 else -weight
        out[indices] -= 2 * c * DELTA * bk
        if i in (2, 3):
            out[indices] += 4 * c * DELTA * bp
        if i >= 5:
            out[indices] += 2 * c * (ap * U + ak)
            square(out, indices, 1, i, 2 * c * (ap + ak))
            square(out, indices, 2, i, -2 * c * ap)
            square(out, indices, 3, i, -2 * c * ak)
    return out


def scaled_direct(indices):
    """Same external derivative before changing any loop variable."""
    out = defaultdict(int)
    for i in range(5, 9):
        pos = EDGES.index((2, i))
        a = indices[pos]
        if a == 0:
            continue
        raised = shifted(indices, pos, 1)
        out[raised] -= a * (W * U - U * (2 * W - 1))
        square(out, raised, 1, i, a * (W - U))
        square(out, raised, 2, i, -a * W)
        square(out, raised, 3, i, a * U)
    return out


def differentiated(terms, derivative):
    out = defaultdict(int)
    for indices, c in terms.items():
        out[indices] += 2 * DELTA * (sp.diff(c, V) - BETA * c)
        for target, coefficient in derivative(indices).items():
            out[target] += c * coefficient
    return out


def source(terms):
    out = differentiated(terms, scaled_ward)
    t, r = (1 - W) / V, (U - W) / V
    # Each row gives (additional numerator distance, divergence vertex, anchor, multiplier).
    identities = [
        ((1, 8), 8, 5, -1),
        ((2, 7), 7, 5, t),
        ((3, 6), 6, 5, r),
        ((5, 8), 8, 1, 1),
        ((5, 8), 8, 2, -t),
        ((5, 8), 8, 3, -r),
        (None, 6, 5, W),
        (None, 7, 5, W),
        (None, 8, 5, W),
    ]
    for edge, i, j, coefficient in identities:
        seed = PARENT if edge is None else shifted(PARENT, EDGES.index(edge), -1)
        for key, c in ibp(seed, i, j).items():
            out[key] -= terms[PARENT] * coefficient * c
    return compact(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--export", type=Path, help="write both exact pinched source functions as JSON"
    )
    args = parser.parse_args()
    export = {"edges": EDGES, "dimension": "D", "graphs": {}}
    for name, terms in aligned_graphs().items():
        assert all(convergent_at_separated_points(a) for a in terms)
        result = source(terms)
        histogram = Counter(sum(n > 0 for n in a[:13]) for a in result)
        expected = (
            {12: 65, 11: 44, 10: 53, 9: 28} if name == "M" else {12: 49, 11: 8, 10: 53, 9: 28}
        )
        assert histogram == expected
        print(
            f"{name}: {len(terms)} aligned terms; exact source counts {dict(sorted(histogram.items()))}"
        )
        export["graphs"][name] = [
            {"indices": a, "coefficient": str(c)} for a, c in sorted(result.items())
        ]
    if args.export:
        args.export.write_text(json.dumps(export, indent=1) + "\n")


if __name__ == "__main__":
    main()
