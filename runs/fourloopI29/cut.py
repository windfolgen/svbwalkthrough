"""Check the discriminant and Legendre modulus on the iterated I29 cut."""
import sympy as sp

a, b, x, y, t = sp.symbols("a b x y t")
identity = sp.eye(2)
first = identity.col_join(sp.zeros(2))
second = sp.zeros(2).col_join(identity)
third = identity.col_join(identity)
fourth = identity.col_join(sp.diag(a, b))


def bracket(line, other):
    return line.row_join(other).det()


def transversal(p, q):
    return sp.Matrix([[1, 0], [p, 0], [0, 1], [0, q]])


def main():
    seven, eight = transversal(x, y), transversal(1, t)
    for line in (seven, eight):
        assert bracket(first, line) == bracket(second, line) == 0
    normal = bracket(first, third)*bracket(second, fourth)
    u = sp.factor(bracket(first, second)*bracket(third, fourth)/normal)
    v = sp.factor(bracket(first, fourth)*bracket(second, third)/normal)
    assert sp.expand(u-(1-a)*(1-b)) == 0 and v == a*b
    A = bracket(third, fourth)*bracket(seven, eight)
    B = bracket(third, seven)*bracket(fourth, eight)
    C = bracket(third, eight)*bracket(fourth, seven)
    discriminant = sp.discriminant((A-B-C)**2-4*B*C, x)
    expected = 16*u*(y-t)**2*(t-1)*(a*t-b)*((a-1)*y-(b-1))*(a*(b-1)*y-b*(a-1))
    assert sp.expand(discriminant-expected) == 0
    r, s, m, n = 1, b/a, (b-1)/(a-1), b*(a-1)/(a*(b-1))
    assert sp.factor((r-m)*(s-n)/((r-n)*(s-m))) == v
    assert sp.factor(a**2*u*(r-n)*(s-m)) == -(a-b)**2
    print("Two equal box cuts; the diagonal residue has Legendre parameter v and prefactor proportional to 1/(sqrt(u)*(z-zbar)) for I29/u.")


if __name__ == "__main__":
    main()
