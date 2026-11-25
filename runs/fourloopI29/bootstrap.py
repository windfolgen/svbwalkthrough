"""Solve the I29 weight-seven ansatz over the rationals, then compare the ancillary."""
import argparse
from collections import defaultdict
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import re
from zipfile import ZipFile

from flint import fmpq as Q, fmpq_mat
from spectral import graph_series, kernel_series

HERE = Path(__file__).resolve().parent
I26 = HERE.parent / "fourloopI26"
spec = spec_from_file_location("i26_word_projections", I26 / "bootstrap.py")
common = module_from_spec(spec)
spec.loader.exec_module(common)
TAGS = ("mirror", "crossing", "native")


def basis_words():
    inherited, _ = common.make_words()
    extra = [(p, w.replace("B", "C")) for p, w in inherited if w.startswith("B") and w.count("B") == 1]
    return [tuple(w) for w in inherited] + extra


def word_expression(period, word):
    indices = ",".join({"B": "zz", "C": "zz/(zz-1)"}.get(c, c) for c in word)
    return period + ("*I[z," + indices + ",0]" if indices else "")


def read_columns(folder):
    if folder:
        return {tag:(folder/(tag+".tsv")).read_text().splitlines() for tag in TAGS}
    with ZipFile(I26/"inputs/word_projections.zip") as old, ZipFile(HERE/"word_projections.zip") as new:
        def lines(archive, tag):
            return archive.read(tag+".tsv").decode().splitlines()
        return {tag:([] if tag=="crossing" else lines(old,tag))+lines(new,tag) for tag in TAGS}


def kernel_target(cap):
    jets = [kernel_series(graph_series(2*cap-2, z), 2*cap) for z in (0, 1)]
    target = {}
    for key in jets[0].keys() | jets[1].keys():
        a,b,l = key
        if max(a,b)>cap:
            continue
        rational = jets[0].get(key,Q(0))
        period = jets[1].get(key,Q(0))-rational
        for c,p in ((rational,0), (period,1)):
            if c:
                target[common.mon({"z":a, "zz":b, "lg":l, "f[3]":p})] = c
    return target


def equations(basis, folder):
    count = len(basis)
    rows = defaultdict(dict)
    for tag, lines in read_columns(folder).items():
        if len(lines)!=count:
            raise ValueError(f"Expected {count} columns in {tag}")
        for j,line in enumerate(lines):
            index,expr = line.split("\t")
            if int(index)!=j+1:
                raise ValueError(f"Misordered {tag} projection")
            for key,c in common.parse(expr.replace("zz/(zz-1)", "C")).items():
                powers = dict(key)
                if tag=="native" and max(powers.get("z",0), powers.get("zz",0))>5:
                    continue
                rows[tag,key][j] = c
    for key,c in kernel_target(5).items():
        rows["native",key][count] = c
    return rows


def solve(basis, rows):
    n = len(basis)
    cols = list(range(n))
    for prime in (1000003, 1000033):
        matrix = common.matrix(rows,cols,prime)
        ranks = matrix.rank(), common.matrix(rows,cols+[n],prime).rank()
        if ranks != (n,n):
            raise ValueError(f"Nonunique or inconsistent at {prime}: {ranks}")
        print(f"{prime}: rank {ranks[0]}, augmented rank {ranks[1]}")
    reduced, rank = matrix.transpose().rref()
    selected = [next(j for j in range(reduced.ncols()) if reduced[i,j]) for i in range(rank)]
    records = list(rows.values())
    sub = [records[i] for i in selected]
    coeff = fmpq_mat([[row.get(j,Q(0)) for j in cols] for row in sub])
    rhs = fmpq_mat([[row.get(n,Q(0))] for row in sub])
    sol = coeff.solve(rhs, algorithm="dixon")
    for key,row in rows.items():
        if sum((c*sol[j,0] for j,c in row.items() if j!=n),Q(0)) != row.get(n,0):
            raise ValueError(f"Rational residual at {key}")
    return {word:sol[j,0] for j,word in enumerate(basis) if sol[j,0]}


def ancillary():
    source = (HERE.parents[1]/"anc/fourloopI29.mpl").read_text()
    formula = source.split("I29K7SV :=",1)[1].split(":",1)[0]
    terms = {}
    for item in formula.split():
        m = re.fullmatch(r"([+-]?\d+)\*(f\[3\]\*)?I\[z,(.*),0\]", item)
        if not m:
            raise ValueError(f"Unrecognized ancillary term {item}")
        c,p,w = m.groups()
        word = "".join({"zz":"B","zz/(zz-1)":"C"}.get(x,x) for x in w.split(","))
        key = "f[3]" if p else "1",word
        if key in terms:
            raise ValueError(f"Repeated ancillary term {key}")
        terms[key] = Q(int(c))
    return terms


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--words",type=Path,help="Write the ordered Maple ansatz and exit")
    parser.add_argument("--projections",type=Path,help="Read independently regenerated TSVs")
    args = parser.parse_args()
    basis = basis_words()
    if args.words:
        args.words.write_text("words:=["+ ",\n".join(word_expression(*w) for w in basis) + "]:\n")
    else:
        rows = equations(basis, args.projections)
        result = solve(basis, rows)
        if result != ancillary():
            raise ValueError("The solved kernel differs from the ancillary")
        print(f"{len(rows)} rational equations, {len(result)} nonzero terms; ancillary matched.")
