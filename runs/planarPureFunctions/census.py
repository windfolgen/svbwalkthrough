"""Compare the full svMPL coefficients, then add the normalized onefold primitives."""
import argparse
import hashlib
import json
import re
from zipfile import ZipFile, Path as ZipPath
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

# Maps are left-composed as maps of the arguments. The distinct values at 3
# identify the six anharmonic transformations without a symbolic dependency.
MAPS = (
    lambda x: x, lambda x: 1-x, lambda x: 1/x, lambda x: x/(x-1),
    lambda x: 1/(1-x), lambda x: (x-1)/x,
)
NAMES = ("1", "W", "C", "S", "CW", "WC")
PROBE = Fraction(3)
VALUES = [m(PROBE) for m in MAPS]
def compose(i, j):
    return VALUES.index(MAPS[i](VALUES[j]))


def load_vector(path):
    vec = {}
    for line in path.read_text().splitlines():
        mon, coeff = line.split("\t")
        # Factor order may differ between Maple kernels. Keep each word intact.
        factors = re.split(r"\*(?![^\[]*\])", mon)
        key = "*".join(sorted(factors))
        if key in vec:
            raise ValueError(f"Duplicate monomial in {path}: {key}")
        vec[key] = Fraction(coeff)
    if not vec:
        raise ValueError(f"Empty vector in {path}")
    return vec


def combination(*terms):
    result = defaultdict(Fraction)
    for coeff, vec in terms:
        for word, value in vec.items():
            result[word] += coeff * value
    return {k: v for k, v in result.items() if v}


def fingerprint(vec):
    """The first nonzero rational fixes scale. Keep and compare the full tuple."""
    items = sorted(vec.items())
    scale = items[0][1]
    return tuple((k, v/scale) for k, v in items), scale


def signature(key):
    data = "\n".join(f"{k}\t{v}" for k, v in key)
    return hashlib.sha256(data.encode()).hexdigest()


def add_scaled(target, scale, source):
    for word, value in source.items():
        new = target.get(word, 0) + scale * value
        if new:
            target[word] = new
        else:
            target.pop(word, None)


def independent_basis(vectors, slots):
    # Choose a short function first, then its earliest occurrence in Table 4.
    # Store a normalized echelon row together with its exact expansion in the
    # selected original functions. Each pivot is an explicit svMPL/period word.
    echelon = []
    representatives = []
    expansion = {}
    for slot in sorted(slots, key=lambda s: (len(vectors[s+(0,)]), s)):
        row = vectors[slot+(0,)].copy()
        used = {}
        for pivot, reduced, origin in echelon:
            lead = row.get(pivot)
            if lead:
                add_scaled(row, -lead, reduced)
                add_scaled(used, lead, origin)
        if row:
            pivot = min(row)
            scale = row[pivot]
            origin = {s: -v/scale for s,v in used.items()}
            origin[slot] = 1/scale
            echelon.append((pivot,{w:v/scale for w,v in row.items()},origin))
            representatives.append(slot)
            used = {slot:Fraction(1)}
        expansion[slot] = used
    representatives.sort()
    for slot, terms in expansion.items():
        factors = [(v,vectors[s+(0,)]) for s,v in terms.items()]
        assert combination(*factors) == vectors[slot+(0,)]
    return representatives, expansion, [pivot for pivot,_,_ in echelon]


def modular_minor(matrix, prime):
    mat = [[value.numerator*pow(value.denominator,-1,prime)%prime for value in row]
           for row in matrix]
    determinant = 1
    for col in range(len(mat)):
        pivot = next(i for i in range(col,len(mat)) if mat[i][col])
        if pivot != col:
            mat[pivot], mat[col] = mat[col], mat[pivot]
            determinant = -determinant
        lead = mat[col][col]
        determinant = determinant*lead % prime
        for i in range(col+1,len(mat)):
            coeff = mat[i][col]*pow(lead,-1,prime)%prime
            if coeff:
                mat[i] = [(a-coeff*b)%prime for a,b in zip(mat[i],mat[col])]
    return determinant


def census(work, basis_vectors=None):
    # Number of ordinary components extracted from each ancillary integral before
    # the five row-14 components are assembled below. Row 30 supplies R168.
    widths = (1, 2, 1, 2, 1, 2, 4, 1, 2, 3, 2, 3, 3, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 7, 1, 1, 4, 2, 1)
    indices = [(r, j) for r, width in enumerate(widths, 1) for j in range(1, width+1)]
    indices.append((0, 1))  # Gram F
    raw = {(r,j,t): load_vector(work/f"v_{t+1}_{r}_{j}.tsv")
           for r,j in indices+[(0,2)] for t in range(6)}
    assert all(raw[0,2,t] == raw[15,1,t] for t in range(6))
    assert all(raw[0,2,compose(1,t)] == raw[32,1,t] for t in range(6))

    vectors = {k:v for k,v in raw.items() if k[0] != 0}
    def a(t):
        return combination((1,raw[0,1,t]),(-2,raw[10,2,t]),
                           (2,raw[10,1,t]),(-2,raw[10,1,compose(2,t)]))
    for t in range(6):
        h = raw[19,1,t]
        vectors[14,1,t] = combination((1,raw[0,2,compose(1,t)]),(-1,h))
        vectors[14,2,t] = combination((1,raw[0,2,compose(3,t)]),(-1,h))
        vectors[14,3,t] = h
        vectors[14,4,t] = a(t)
        vectors[14,5,t] = a(compose(2,t))
    slots = sorted((r,j) for r,j,t in vectors if t==0)
    # Formal tuples, not their digests, decide all matches.
    tags = {k:fingerprint(v) for k,v in vectors.items()}
    assert all(len({tags[r,j,t][0] for t in range(6)}) in (1,2,3,6) for r,j in slots)
    groups = []
    remaining = set(slots)
    while remaining:
        r,j = rep = min(remaining)
        members = []
        for s,k in sorted(remaining):
            native, scale = tags[s,k,0]
            matches = [(NAMES[t],str(scale/tags[r,j,t][1])) for t in range(6)
                       if native == tags[r,j,t][0]]
            if matches:
                members.append({"slot":[s,k],"maps":matches})
        groups.append({"representative":rep,"members":members})
        remaining.difference_update(tuple(m["slot"]) for m in members)
    # A match in one frame must transport with the same scale in all six.
    for group in groups:
        r,j = group["representative"]
        for member in group["members"]:
            s,k = member["slot"]
            for mapping, ratio in member["maps"]:
                for t in range(6):
                    left, ls = tags[s,k,t]
                    right, rs = tags[r,j,compose(NAMES.index(mapping),t)]
                    assert left == right and ls == Fraction(ratio)*rs, (r,j,s,k,mapping,t)
    exact = defaultdict(list)
    fixed = defaultdict(list)
    for r,j in slots:
        key,scale = tags[r,j,0]
        exact[key,scale].append([r,j])
        fixed[key].append(([r,j],scale))
    exact_groups = [g for g in exact.values() if len(g)>1]
    fixed_groups = [[(slot,str(scale/v[0][1])) for slot,scale in v]
                    for v in fixed.values() if len(v)>1]
    data = {"svmpl_slots":len(slots),"exact":len(exact),"up_to_scale":len(fixed),
            "up_to_scale_and_crossing":len(groups),
            "exact_groups":exact_groups,"fixed_groups":fixed_groups,"orbits":groups,
            "svmpl_signatures":{f"{r}.{j}":[signature(tags[r,j,0][0]),str(tags[r,j,0][1]),
                                             len(vectors[r,j,0])] for r,j in slots},
            "onefold_slots":{"10.4":"Py","14.6":"Py","14.7":"C(Py)",
                             "14.8":"S(Q)","14.9":"W(Q)","30.5":"Q"}}
    # Each primitive has its own definition and sheet. The argument in the
    # appendix distinguishes the three Q images and the two Py images.
    data["including_onefolds"] = {
        "slots":len(slots)+6,"exact":len(exact)+5,"up_to_scale":len(fixed)+5,
        "up_to_scale_and_crossing":len(groups)+2}
    representatives, expansion, pivots = independent_basis(vectors, slots)
    index = {slot:i for i,slot in enumerate(representatives,1)}
    def fmt(slot): return ".".join(map(str,slot))
    if basis_vectors is not None:
        basis_vectors.extend(vectors[s+(0,)] for s in representatives)
    minor = [[vectors[s+(0,)].get(w,Fraction(0)) for w in pivots] for s in representatives]
    data["fixed_basis"] = {
        "svmpl_rank": len(representatives),
        "representatives": [fmt(s) for s in representatives],
        "elimination_pivots": pivots,
        "minor_mod_primes": {str(p):modular_minor(minor,p) for p in (1000003,1000033)},
        "coefficients": {fmt(s):{str(index[k]):str(c) for k,c in sorted(expansion[s].items())}
                         for s in slots}}
    return data


if __name__ == "__main__":
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("work",type=Path,nargs="?",
                    default=Path(__file__).with_name("canonical_words.zip"))
    ap.add_argument("--output",type=Path)
    args=ap.parse_args()
    if args.work.is_dir():
        result = census(args.work)
    else:
        with ZipFile(args.work) as archive:
            result = census(ZipPath(archive))
    if args.output:
        args.output.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps({k:v for k,v in result.items() if k in
        ("svmpl_slots","exact","up_to_scale","up_to_scale_and_crossing","including_onefolds")},indent=2))
