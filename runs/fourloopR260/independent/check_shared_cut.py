"""Compare the signed graph and the two I214 images on one oriented p5 contour."""
from collections import Counter
from itertools import permutations

from check_cuts import C, data, graph_form, normalize, one, restrict, zero


def symmetrize(numerator, denominator, external=(1, 2, 3, 4)):
    """Return the 96 labeled terms, with multiplicity, in the exterior chart convention."""
    powers = Counter(numerator.split())
    powers.subtract(denominator.split())
    klein = [(1, 2, 3, 4), (2, 1, 4, 3), (3, 4, 1, 2), (4, 3, 2, 1)]
    monomials = Counter()
    for perm in klein:
        frame = tuple(external[i - 1] for i in perm)
        for loops in permutations((5, 6, 7, 8)):
            labels = (0, *frame, *loops)
            relabeled = []
            for edge, exponent in powers.items():
                i, j = sorted(labels[int(k)] for k in edge)
                relabeled.append((i, j, exponent))
            monomials[tuple(sorted(relabeled))] += 1
    return [(count, graph) for graph, count in monomials.items()]


def cut_residue(chart, route, graph_terms):
    n, den = graph_form(chart, graph_terms)
    for name, a, h in route:
        if not n:
            return zero, one
        var = C.names().index(name)
        linear = h * C.gen(var) - a
        quotient, remainder = divmod(den, linear)
        if remainder:
            return zero, one
        pn, pd = restrict(n, var, a, h)
        qn, qd = restrict(h * quotient, var, a, h)
        assert qn, f"Expected a simple pole in {name}"
        n, den = normalize(pn * qd, pd * qn)
    return n, den


def main():
    z, b, *parameters = C.gens()
    t4, t6 = parameters[4], parameters[6]
    route = [
        ("t5", t6 - t4, one), ("t0", t6, one), ("t1", t4, one),
        ("t2", t6, one), ("t3", t4, one), ("t4", b * t6, z),
        ("t6", b * (1 - z), one),
    ]
    chart = next(row for row in data["charts"] if row["orbit"] == 41 and row["graph"] == "M")
    assert chart["shape"] == [[1, 2, 3], [2, 4], [3, 4], [4]]
    v = (1 - z) * (1 - b)
    denominator = (z - b) * (v - 1)
    # Dimensionless graph seeds, including the common s13*s24 normalization.
    i214 = ("13 24 14 16 23 25 34", "15 17 18 26 27 28 35 36 38 45 46 47 56 58 67")
    graphs = [
        ("M", data["graphs"]["M"], 2),
        ("I214", symmetrize(*i214), 1),
        ("C(I214)", symmetrize(*i214, external=(1, 3, 2, 4)), 0),
        ("Y0", data["graphs"]["Y0"], 0),
        ("uI260", symmetrize(
            "12 13 14 23 24 34 58 67", "16 17 18 25 27 28 35 36 38 45 46 47 56 57 68 78",
        ), 0),
        ("I168(u/v,1/v)", symmetrize(
            "12 13 14 14 23 24 56 56", "15 16 17 18 25 26 28 35 36 45 46 47 57 58 67 68",
        ), 0),
        ("v I168(v,u)", symmetrize(
            "12 13 14 14 23 34 56 56", "15 16 17 18 25 26 35 36 37 45 46 48 57 58 67 68",
        ), 0),
    ]
    for name, terms, units in graphs:
        num, den = cut_residue(chart, route, terms)
        assert 48 * num * denominator == units * v * den, name
        print(f"{name}: {units} in units of p5/48")


if __name__ == "__main__":
    main()
