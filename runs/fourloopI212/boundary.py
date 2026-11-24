"""Compare the native leading-power double logarithm of I212 with its frozen expansion."""
from fractions import Fraction
from functools import cache
from pathlib import Path
import json

from hard_moments import moments


@cache
def soft_moment(r, s):
    return sum(Fraction(1, r + k + 1) for k in range(s + 1)) / (2 * (s + 1))


def graph_moment(n, hard):
    """Expand (1-Z)(1-aX)/[(1-X)(1-bX)(1-aZ)] and integrate a^r b^s."""
    result = [Fraction(0), Fraction(0)]
    for i in range(n + 1):
        j = n - i
        def x_coefficient(r):
            return (sum(soft_moment(r, k) for k in range(i + 1))
                    - sum(soft_moment(r + 1, k) for k in range(i)))
        weight = x_coefficient(j)
        if j:
            weight -= x_coefficient(j - 1)
        for grade, value in enumerate(hard[i, j]):
            result[grade] += weight * value
    return result


@cache
def taylor(word, n):
    if not word:
        return Fraction(n == 0)
    if n <= 0:
        return Fraction(0)
    if word[0] == 0:
        return taylor(word[1:], n) / n
    return -sum(taylor(word[1:], k) for k in range(n)) / n


def bootstrap_moment(n, terms):
    result = [Fraction(0), Fraction(0)]
    for chart, pi_grade, tag, power, word, coefficient in terms:
        if chart == 0:
            assert pi_grade == 0 and tag in (0, 4)
            factor = 1 if tag == 0 else Fraction(-3, 4)
            result[int(tag == 4)] += factor * Fraction(coefficient) * taylor(tuple(word), n + 2 - power)
    return result


if __name__ == "__main__":
    terms = json.loads(Path(__file__).with_name("double_log_boundary.json").read_text())["terms"]
    hard = moments(23)
    for n in range(24):
        graph = graph_moment(n, hard)
        assert graph == bootstrap_moment(n, terms), (n, graph)
        if n in (22, 23):
            print(f"N={n}: {graph[0]} + ({graph[1]})*zeta(3)")
