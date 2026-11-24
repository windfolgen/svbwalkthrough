"""Degree-two cubic and quartic OPE logarithms of M by ordered radial integration."""

from collections import Counter
from fractions import Fraction as Q
from functools import cache
from itertools import combinations, permutations, product
from math import comb, prod
import gzip
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
LOOPS = (5, 6, 7, 8)


@cache
def contractions(vertices):
    """Pair the indices of one unit vector, with multiplicities of equivalent pairs."""
    if not vertices:
        return {(): 1}
    first, *tail = vertices
    out = Counter()
    for second, multiplicity in Counter(tail).items():
        rest = tail.copy()
        rest.remove(second)
        extra = () if first == second else (tuple(sorted((first, second))),)
        for pairs, count in contractions(tuple(rest)).items():
            out[tuple(sorted(extra + pairs))] += multiplicity * count
    return out


@cache
def angular(pairs):
    """Exact S^3 moment as a polynomial in the cosine between external unit vectors."""
    for i in LOOPS:
        incident = tuple(q for edge in pairs if i in edge for q in edge if q != i)
        if not incident:
            continue
        if len(incident) % 2:
            return {}
        denominator = prod(range(4, 4 + len(incident), 2))
        rest = tuple(e for e in pairs if i not in e)
        out = Counter()
        for extra, count in contractions(incident).items():
            for power, coefficient in angular(tuple(sorted(rest + extra))).items():
                out[power] += Q(count, denominator) * coefficient
        return out
    return {len(pairs): Q(1)}


@cache
def angular_poly(exponent, order):
    """Coefficient of s^order in (1-2 s cos(theta)+s^2)^exponent."""
    result = {}
    for j in range((order + 1) // 2, order + 1):
        choose = comb(exponent, j) if exponent >= 0 else (-1) ** j * comb(j - exponent - 1, j)
        power = 2 * j - order
        value = choose * comb(j, order - j) * (-2) ** power
        if value:
            result[power] = value
    return result


def flag(graph, vertices, free, quartic):
    inner, outer = vertices.index(2), vertices.index(3)
    gaps = [j for j in range(inner, outer) if j != free]

    def exponent(i, j):
        return graph.get(tuple(sorted((i, j))), 0)

    beta = [
        4 * int(v in LOOPS) + 2 * (exponent(1, v) + sum(exponent(v, w) for w in vertices[:j]))
        for j, v in enumerate(vertices)
    ]
    base = [sum(beta[: j + 1]) for j in range(5)]
    target = [2 - base[j] for j in gaps]
    if min(target) < 0:
        return {}
    edges = []
    for i, j in combinations(range(6), 2):
        a, b = vertices[i], vertices[j]
        e = exponent(a, b)
        if not e:
            continue
        mask = [k for k, g in enumerate(gaps) if i <= g < j]
        cap = min([target[k] for k in mask] + ([2 * e] if e > 0 else []), default=None)
        edges.append([i, j, e, mask, cap, tuple(sorted((a, b)))])
    for item in edges:
        if item[4] is not None:
            continue
        # Haar orthogonality bounds the harmonic on the only unconstrained edge.
        bounds = []
        for v in item[:2]:
            if vertices[v] in LOOPS:
                others = [b[4] for b in edges if b is not item and v in b[:2]]
                if None not in others:
                    bounds.append(sum(others))
        item[4] = min(bounds)
    edges.sort(key=lambda e: (-len(e[3]), e[4]))
    last = [
        max((i for i, e in enumerate(edges) if k in e[3]), default=-1) for k in range(len(target))
    ]
    loose = free if free is not None else (0 if inner else 4)
    out = Counter()

    def visit(idx, crossing, factors):
        if idx == len(edges):
            if any(target):
                return
            weight = Q(1, 24)
            if not quartic:
                divisor = crossing + (
                    base[loose] - 2 if free is not None else (base[0] if inner else -beta[-1])
                )
                if divisor == 0:
                    return
                weight = Q(-1, 3 * divisor)
            for powers in product(*(tuple(poly.items()) for _, poly in factors)):
                pairs = tuple(
                    sorted(edge for (edge, _), (n, _) in zip(factors, powers) for _ in range(n))
                )
                c = weight * prod(value for _, value in powers)
                for degree, value in angular(pairs).items():
                    out[degree] += c * value
            return
        i, j, e, mask, cap, pair = edges[idx]
        maximum = min([cap] + [target[k] for k in mask])
        forced = {target[k] for k in mask if idx == last[k]}
        if len(forced) > 1:
            return
        for n in forced or range(maximum + 1):
            if n > maximum:
                continue
            for k in mask:
                target[k] -= n
            visit(
                idx + 1,
                crossing + (n if i <= loose < j else 0),
                factors + [(pair, angular_poly(e, n))] if n else factors,
            )
            for k in mask:
                target[k] += n

    visit(0, 0, [])
    return out


def graph_coefficients():
    data = json.loads(gzip.decompress((HERE.parent / "independent/exterior.json.gz").read_bytes()))[
        "graphs"
    ]["M"]
    terms = Counter()
    for weight, monomial in data:
        variants = []
        for perm in permutations(LOOPS):
            v = dict(zip(LOOPS, perm))
            edges = (
                (*sorted((v.get(i, i), v.get(j, j))), n) for i, j, n in monomial if 4 not in (i, j)
            )
            variants.append(tuple(sorted(edges)))
        terms[min(variants)] += Q(weight, 96)
    result = {}
    for log in (4, 3):
        out = Counter()
        for monomial, c in terms.items():
            graph = {(i, j): e for i, j, e in monomial}
            for perm in permutations(LOOPS):
                chain = (2, *perm, 3)
                orders = (
                    [(chain, None)]
                    if log == 4
                    else (
                        [(chain, j) for j in range(5)]
                        + [((perm[0], 2, *perm[1:], 3), None), ((2, *perm[:3], 3, perm[3]), None)]
                    )
                )
                for vertices, free in orders:
                    for k, value in flag(graph, vertices, free, log == 4).items():
                        out[k] += c * value
        result[log] = {k: v for k, v in out.items() if v}
    return result


if __name__ == "__main__":
    print(graph_coefficients())
