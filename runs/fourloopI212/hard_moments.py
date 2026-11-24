"""Null-spin moments of the finite two-loop propagator graph by triangle IBP."""
from collections import Counter
from fractions import Fraction
from functools import cache
from math import comb, factorial

# (integer part, coefficient of epsilon) for a propagator power or gamma argument.
HALF_DIMENSION = (2, -1)
DIMENSION = (4, -2)
ONE, TWO, SHIFTED = (1, 0), (2, 0), (1, 1)


def add(a, b):
    return a[0] + b[0], a[1] + b[1]


def subtract(a, b):
    return a[0] - b[0], a[1] - b[1]


@cache
def bubble(a, b, spin, ell):
    """Gamma ratio for the beta integral at fixed tensor power ell."""
    arguments = Counter([subtract(add(a, b), HALF_DIMENSION),
                         add(subtract(HALF_DIMENSION, a), (ell, 0)),
                         add(subtract(HALF_DIMENSION, b), (spin - ell, 0))])
    arguments.subtract([a, b, add(subtract(DIMENSION, add(a, b)), (spin, 0))])
    return tuple((arg, count) for arg, count in sorted(arguments.items()) if count)


@cache
def bubble_product(left, right):
    """Laurent coefficients in the rational, zeta(2) and zeta(3) grades."""
    power, prefactor = 0, Fraction(1)
    log_series = [Fraction(0)] * 4
    zeta2 = zeta3 = Fraction(0)
    for (integer, slope), count in left + right:
        if integer == 0:
            assert slope
            prefactor *= Fraction(slope) ** (-count)
            power -= count
        else:
            assert integer > 0
            prefactor *= Fraction(factorial(integer - 1)) ** count
            for k in range(1, integer):
                for j in (1, 2, 3):
                    log_series[j] += count * Fraction((-1) ** (j - 1), j) * Fraction(slope, k) ** j
        zeta2 += count * Fraction(slope**2, 2)
        zeta3 -= count * Fraction(slope**3, 3)
    assert power >= -2
    _, r1, r2, r3 = log_series
    series = [(1, 0, 0), (r1, 0, 0), (r2 + r1**2 / 2, zeta2, 0),
              (r3 + r1*r2 + r1**3 / 6, r1*zeta2, zeta3)]
    return {power + k: tuple(prefactor * value for value in row) for k, row in enumerate(series)}


def triangle(i, j, order):
    """Right-hand side of the x-y total derivative after canceling propagators."""
    outer = bubble(ONE, ONE, j, j)
    products = [(1, bubble(TWO, ONE, i, i), outer),
                (1, bubble(ONE, TWO, i, i), outer),
                (-1, outer, bubble(SHIFTED, TWO, i+j, i+j))]
    for ell in range(j + 1):
        products.append((-comb(j, ell), bubble(ONE, ONE, j, ell),
                         bubble(TWO, SHIFTED, i+ell, i+ell)))
    totals = {p: [Fraction(0)] * 3 for p in range(-2, order + 1)}
    for coefficient, left, right in products:
        expansion = bubble_product(left, right)
        for p, grades in totals.items():
            for k, value in enumerate(expansion.get(p, ())):
                grades[k] += coefficient * value
    assert all(not any(values) for p, values in totals.items() if p < order)
    return totals[order]


def moments(max_spin):
    hard = {}
    for spin in range(max_spin + 1):
        rhs = triangle(0, spin, 1)
        current = [-value / 2 for value in rhs]
        assert not current[1]
        hard[0, spin] = tuple(current[::2])
        for i in range(1, spin + 1):
            j = spin - i
            rhs = triangle(i, j, 0)
            assert not rhs[1]
            current = [value + delta / i for value, delta in zip(current, rhs)]
            hard[i, j] = tuple(current[::2])
        assert all(hard[i, spin-i] == hard[spin-i, i] for i in range(spin + 1))
    assert hard[0, 0] == (0, 6)
    return hard
