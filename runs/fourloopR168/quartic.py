"""Fit the R168 leading fourth logarithm to eight individual svMPL boundary columns."""

from fractions import Fraction as Q
from functools import cache
from itertools import product
import sympy as s
import json



@cache
def h1(n):
    return sum((Q(1, j) for j in range(1, n + 1)), Q(0))


@cache
def graph(n):
    return sum(((h1(n) - h1(n - j)) / j) ** 2 for j in range(1, n + 1))


@cache
def multiple(a, n):
    if not a:
        return int(n == 0)
    if n <= 0:
        return 0
    return sum(multiple(a[1:], j) for j in range(n)) / Q(n ** a[0])


def graph_projection():
    words = ["".join((*w, "1")) for w in product("01", repeat=3)]

    # HyperlogProcedures gives G_w / 4! in the native leading fourth logarithm
    # of I[z,w,0,0,0,0,0]. The rational prefactor 1/d tends to 1/Y.
    def col(w, n):
        a = tuple(len(q) + 1 for q in w[:-1].split("1"))
        return (-1) ** w.count("1") * multiple(a, n) / 24

    def target(n):
        return -(graph(n) - graph(n - 1)) / 12

    A = s.Matrix([[col(w, n) for w in words] for n in range(1, 9)])
    sol = A.inv() * s.Matrix([target(n) for n in range(1, 9)])
    assert all(
        sum(col(w, n) * a for w, a in zip(words, sol)) == target(n)
        for n in range(9, 65)
    )
    return dict(
        rank=A.rank(),
        fit_moments=8,
        held_out_moments=56,
        coefficients={w: str(a) for w, a in zip(words, sol) if a},
        minor=str(A.det()),
    )


if __name__ == "__main__":
    print(json.dumps(graph_projection(), indent=2))
