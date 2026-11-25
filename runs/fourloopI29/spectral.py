"""Native Euclidean series of I29/u and its fixed-v derivative.

The OPE residue is expanded in delta = Delta - (4 + spin + 2*level).
A monomial key (i,j,l) denotes z**i * zbar**j * log(u)**l.
Through delta**4 the only transcendental constant is zeta(3); use
zeta3=0 and 1 to recover the rational and zeta(3) parts separately.
"""
from collections import defaultdict
from functools import cache
from math import factorial
from flint import fmpq as Q, fmpq_series as Series


def series(*coeffs):
    return Series(list(coeffs), prec=5)


@cache
def gamma_product(n, half):
    result = series(1)
    for j in range(1, n + 1):
        result *= series(j, Q(1, 2) if half else 1)
    return result


def residue_weight(spin, level, zeta3, layers):
    """Regular part of the spectral weight after extracting its pole."""
    n, s = level, spin
    gap = series(2 + s + 2*n, 1)
    measure = (s+1)*gap/8 * gamma_product(s+n+1, True)**2 / gamma_product(2*s+2*n+2, False)
    measure *= gamma_product(n, True)**2 / gamma_product(2*n, False)
    measure *= series(1, 0, 0, Q(zeta3, 2))
    # Separate the double pole in the alternating series for the eigenvalue.
    regular = [Q((-1)**n), Q(0)]
    for j in range(3):
        p = j + 2
        partial = sum(Q((-1)**k, k**p) for k in range(1, n+1))
        partial += sum(Q((-1)**k, k**p) for k in range(1, n+s+2))
        if j == 1:
            partial += Q(3*zeta3, 2)
        regular.append(Q((-1)**(n+j)*(j+1), 2**p)*partial)
    eigenvalue = 16*series(*regular)/((s+1)*gap)
    return measure * eigenvalue**layers


@cache
def hypergeometric(h, degree):
    """Coefficients of 2F1(h+delta/2,h+delta/2;2h+delta;x)."""
    result = [series(1)]
    for j in range(degree):
        result.append(result[-1]*series(h+j, Q(1,2))**2 / ((j+1)*series(2*h+j, 1)))
    return result


def graph_series(degree, zeta3, layers=3):
    """Return the reduced fishnet correlator divided by u**2.

    Layers 1, 2 and 3 give 1/v, the square of the one-loop box, and I29/u.
    """
    if layers not in (1, 2, 3):
        raise ValueError("layers must be 1, 2, or 3")
    maxlog = 2*layers - 2
    result = defaultdict(Q)
    for n in range(degree//2+1):
        for s in range(0, degree-2*n+1, 2):
            extra = degree-2*n-s
            high = hypergeometric(s+n+2, extra)
            low = hypergeometric(n+1, extra)
            weight = residue_weight(s, n, zeta3, layers)
            for a in range(extra+1):
                for b in range(extra-a+1):
                    i, j = s+1+a, b
                    if i == j:
                        continue
                    sign = 1 if i > j else -1
                    coeff = weight*high[a]*low[b]
                    for log in range(maxlog+1):
                        value = sign*coeff[maxlog-log]/(2**log*factorial(log))
                        for k in range(min(i,j), max(i,j)):
                            result[n+k, n+i+j-1-k, log] += value
    return {k:v for k,v in result.items() if v}


def kernel_series(graph, degree):
    """Apply sqrt(u)*d*d/du at fixed v to sqrt(u)*d*(I29/u)."""
    result = defaultdict(Q)
    for (a,b,l), c in graph.items():
        # u*d*((z-1)*d_z-(zbar-1)*d_zbar), acting on the monomial.
        terms = [(2,1,a-b), (1,2,b-a),
                 (1,1,-a-b), (0,2,a), (2,0,b)]
        # (d**2+2*u*(z+zbar-2))/2 multiplies the undifferentiated graph.
        terms += [(2,0,Q(1,2)), (0,2,Q(1,2)), (1,1,-3), (2,1,1), (1,2,1)]
        for i,j,w in terms:
            if a+b+i+j <= degree:
                result[a+i,b+j,l] += c*w
        if l and a+b+2 <= degree:
            for i,j,w in ((2,0,1),(1,1,-2),(0,2,1)):
                result[a+i,b+j,l-1] += c*l*w
    return {k:v for k,v in result.items() if v}
