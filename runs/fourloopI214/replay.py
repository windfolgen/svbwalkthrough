"""Recover the two I214 fits exactly and test the unused period ordering."""
import gzip
import json
import sys
from collections import defaultdict
from fractions import Fraction
from math import lcm
from pathlib import Path

from flint import fmpz_mat, nmod_mat


ROOT = Path(__file__).resolve().parent
FIT = ROOT / "fit"
PRIME = 1_000_003


def records(files):
    for path in files:
        with gzip.open(path, "rt") as stream:
            for line in stream:
                yield json.loads(line)


def solve(files, columns, width):
    """Find independent equations mod p, then solve their integer minor over Q."""
    count = 0
    for file in files:
        with gzip.open(file, "rb") as stream:
            count += sum(1 for _ in stream)
    transpose = nmod_mat(len(columns), count, PRIME)
    for i, (_, row) in enumerate(records(files)):
        if len(row) != width + 1:
            raise ValueError("Unexpected fit width")
        for k, j in enumerate(columns):
            if row[j]:
                transpose[k, i] = row[j] % PRIME
    reduced, rank = transpose.rref()
    if rank != len(columns):
        raise ValueError(f"Only {rank} of {len(columns)} directions fixed")
    selected = {}
    i = 0
    for k in range(rank):
        while not reduced[k, i]:
            i += 1
        selected[i] = k
        i += 1
    del reduced, transpose
    minor, rhs = fmpz_mat(rank, rank), fmpz_mat(rank, 1)
    for i, (_, row) in enumerate(records(files)):
        if i in selected:
            k = selected[i]
            rhs[k, 0] = row[-1]
            for h, j in enumerate(columns):
                minor[k, h] = row[j]
    answer = minor.solve(rhs)
    values = [Fraction(0)] * width
    for k, j in enumerate(columns):
        values[j] = Fraction(str(answer[k, 0]))
    return values


def check(files, values):
    scale = lcm(*(v.denominator for v in values))
    entries = [(j, int(v * scale)) for j, v in enumerate(values) if v]
    count = 0
    for key, row in records(files):
        if len(row) != len(values) + 1 or sum(c * row[j] for j, c in entries) != scale * row[-1]:
            raise ValueError(f"Exact residual at {key}")
        count += 1
    return count


def tensor_branch(stages, vectors):
    """Keep the coproduct nodes reached by the fitted weight-eight tensors."""
    top = []
    for vector in vectors:
        terms = defaultdict(Fraction)
        for j, coefficient in enumerate(vector):
            if coefficient:
                for i, letter, weight in stages[-1][j]:
                    terms[i, letter] += coefficient * Fraction(weight)
        top.append([[i, a, str(v)] for (i, a), v in sorted(terms.items()) if v])
    levels = [top]
    for stage in reversed(stages[:-1]):
        used = sorted({i for node in levels[-1] for i, a, v in node})
        indices = {j: k for k, j in enumerate(used)}
        levels[-1] = [[[indices[i], a, v] for i, a, v in node] for node in levels[-1]]
        levels.append([stage[i] for i in used])
    return levels[::-1]


def run():
    with gzip.open(ROOT / "symbol.json.gz", "rt") as f:
        published = json.load(f)
    bases = []
    for character in (1, 3):
        with gzip.open(FIT / f"symbol_basis_{character}.json.gz", "rt") as f:
            bases.append(json.load(f))
    size, root_size = (len(b["stages"][-1]) for b in bases)
    width = 3 * size + root_size
    symbol_files = [FIT / "symbol_rows.jsonl.gz"]
    symbol = solve(symbol_files, range(width), width)
    symbol_rows = check(symbol_files, symbol)
    position = 0
    for basis, branch, names in zip(bases, published["branches"], (["P0", "Pu", "Pv"], ["Py"])):
        size = len(basis["stages"][-1])
        vectors = [symbol[position + j * size:position + (j + 1) * size] for j in range(len(names))]
        position += len(names) * size
        if (names != branch["numerators"] or basis["letters"] != published["letters"]
                or tensor_branch(basis["stages"], vectors) != branch["stages"]):
            raise ValueError("Reconstructed tensor differs from symbol.json.gz")
    print(f"Verified all four tensors from {symbol_rows} equations.", file=sys.stderr, flush=True)

    labels = json.loads((FIT / "period_basis.json").read_text())["columns"]
    independent = json.loads((ROOT / "validation/function_rank.json").read_text())["formal_independent_columns"]
    training = [FIT / f"period_{frame}.jsonl.gz" for frame in ("1234", "4132")]
    periods = solve(training, independent, len(labels))
    fitted = check(training, periods)
    withheld = check([FIT / "period_1324.jsonl.gz"], periods)
    report = dict(symbol_columns=width, symbol_equations=symbol_rows, verified_symbol_tensors=4,
                  period_columns=len(labels), period_rank=len(independent), nonzero_period_coefficients=sum(map(bool, periods)),
                  fitted_orderings=["1234", "4132"], fitted_period_equations=fitted,
                  withheld_ordering="1324", withheld_period_equations=withheld, exact_residuals_nonzero=0)
    return dict(symbol=[str(v) for v in symbol], periods=[str(v) for v in periods], validation=report)


if __name__ == "__main__":
    data = run()
    Path(sys.argv[1]).write_text(json.dumps(data) + "\n")
    print(json.dumps(data["validation"], indent=2))
