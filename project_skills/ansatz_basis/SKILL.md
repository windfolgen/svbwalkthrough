# Skill: Constructing Parity-Odd and Parity-Even SVMPL Ansatz

## Purpose

This skill describes how to construct parity-odd and parity-even single-valued multiple polylogarithm (SVMPL) ansatz basis files of the form `I[z, w1, ..., wn, 0]`, where the new letter (`zz` or `1/zz`) is allowed to appear only in the **last N entries** of the word — counted from the front (`w1` is the last-integrated singularity).

The reference implementation is in [data/reference_notebook/svbwalkthrough.wl](../../data/reference_notebook/svbwalkthrough.wl), Section 3 (lines 918–1145). This skill generalises that example, which fixes N=2 with the new letter `zz`, to the three cases that arise in practice:

| Case | New letter L | N (new-letter slots) | Example |
|------|-------------|----------------------|---------|
| 1 (reference) | `zz` | 2 | 3-loop, weight 6 |
| 2 | `1/zz` | 2 | structurally identical, just `$Letter = 1/zz` |
| 3 | `zz` | 4 | 4-loop hard, weight 8 |

## Conventions

- `I[z, w1, ..., wn, 0]` is an iterated integral over the interval `[z, 0]`. The word entries `w1, ..., wn` are drawn from the alphabet `{0, 1, zz}` (or `{0, 1, 1/zz}`).
- **"Last entries" are counted from the front.** `w1` is the last entry, `w2` is the second-last, etc. So "last two entries" means `{w1, w2}` and "last four entries" means `{w1, w2, w3, w4}`. `z` and the final `0` are the integration endpoints, not word entries.
- `f[k]` denotes the single-valued zeta value `ζ_k` for odd `k`. `f[a, b]` is a depth-2 single-valued multiple zeta value. The identity `f[3, 5] = f[3] f[5] - f[5, 3]` holds, so `f[3, 5]` is **not independent**.
- Total weight = (prefactor weight) + (word length `n`).

## Step 1 — List the zeta prefactors and constants at the target weight

For each target weight `W`, enumerate every **independent** zeta monomial `Z` with weight `≤ W`:

- `1` (weight 0)
- single odd zetas: `f[3]`, `f[5]`, `f[7]`, ... (all odd)
- independent products / depth-2 values whose weight is `≤ W`:
  - weight 6: `f[3, 3]` (note: `f[3, 3] = f[3]^2 / 2`)
  - weight 8: `f[5, 3]` and `f[3] f[5]` (note: `f[3, 5] = f[3] f[5] - f[5, 3]` is dependent)

For each `Z` with weight `w_Z`:
- If `w_Z < W`: `Z` is a **prefactor**; it pairs with an SVMPL of word length `W - w_Z`.
- If `w_Z == W`: `Z` is a **constant** (no `I[z, ..., 0]` factor). Constants are even under parity, so they enter **only** the even ansatz as standalone elements.

### Weight 6 (3-loop) zeta inventory

| Role | Prefactor | Weight | Paired word length |
|------|-----------|--------|--------------------|
| Prefactor | `f[5]` | 5 | 1 |
| Prefactor | `f[3]` | 3 | 3 |
| Prefactor | `1` | 0 | 6 |
| Constant (even only) | `f[3, 3]` | 6 | — |

### Weight 8 (4-loop) zeta inventory

| Role | Prefactor | Weight | Paired word length |
|------|-----------|--------|--------------------|
| Prefactor | `f[7]` | 7 | 1 |
| Prefactor | `f[3, 3]` | 6 | 2 |
| Prefactor | `f[5]` | 5 | 3 |
| Prefactor | `f[3]` | 3 | 5 |
| Prefactor | `1` | 0 | 8 |
| Constant (even only) | `f[5, 3]` | 8 | — |
| Constant (even only) | `f[3] f[5]` | 8 | — |

## Step 2 — Build the raw SVMPL list for a given N

For each prefactor `Z` (weight `w_Z`, paired word length `L = W - w_Z`):

1. Compute `nNew = Min[L, N]` (number of new-letter slots) and `nOld = L - nNew`.
2. Generate the new-letter part: `Tuples[{$Letter, 0, 1}, nNew]` (each slot independently takes the new letter, `0`, or `1`).
3. Generate the old-letter part: `Tuples[{0, 1}, nOld]` (no new letter allowed here).
4. Concatenate via `Outer[Join, newTuples, oldTuples, 1] // Flatten[#, 1] &`.
5. Form the SVMPL: `Z * I[z, Sequence @@ #, 0] & /@ combinedTuples`.

Special case: if `L == 0` (the constant case), the element is just `Z` itself (no `I[z, ..., 0]`).

When `L < N`, **all** `L` slots are new-letter slots (`nNew = L`, `nOld = 0`); the part is **not** dropped.

### Mathematica construction (general template)

```mathematica
$Letter = zz;  (* or 1/zz *)
Nslots = 2;    (* or 4 *)

buildPart[prefactor_, wordLen_] := Module[{nNew, nOld, newT, oldT, combined},
  If[wordLen === 0, Return[{prefactor}]];   (* constant *)
  nNew = Min[wordLen, Nslots];
  nOld = wordLen - nNew;
  newT = Tuples[{$Letter, 0, 1}, nNew];
  oldT = Tuples[{0, 1}, nOld];
  combined = If[nOld === 0, newT,
    Flatten[Outer[Join, newT, oldT, 1], 1]];
  prefactor * (I[z, Sequence @@ #, 0] & /@ combined)
];

(* Example: weight 6, N = 2 *)
svlistmplans = Join[
  buildPart[f[5], 1],
  buildPart[f[3], 3],
  buildPart[1,    6]
];

(* Example: weight 8, N = 4 *)
svlistmplans = Join[
  buildPart[f[7],   1],
  buildPart[f[3,3], 2],
  buildPart[f[5],   3],
  buildPart[f[3],   5],
  buildPart[1,      8]
];
```

This reproduces line 947 of [svbwalkthrough.wl](../../data/reference_notebook/svbwalkthrough.wl) when `N = 2`, `W = 6`, and the prefactor list is `{f[5]@1, f[3]@3, 1@6}`.

## Step 3 — Compute the complex conjugate of each SVMPL

The conjugate is computed in Maple via **Hyperlogprocedures**. See [project_skills/series_expansion/SKILL_hyperlog_conjugate.md](../series_expansion/SKILL_hyperlog_conjugate.md) for the procedure, or use pre-computed conjugate files.

After conjugation, the new letter `zz` (or `1/zz`) typically moves to an arbitrary position in the word. **The ansatz restricts the new letter to the last N entries**, which is what makes the SVMPL constraints so strong (see line 984 of svbwalkthrough.wl).

```mathematica
svlistmpln    = Cases[svlistmplans, _I, Infinity] // DeleteDuplicates;
(* export svlistmpln to Maple, compute conjugates, import back *)
svlistmplnconj = Import[...];
conjrep = Thread @ Rule[svlistmpln, svlistmplnconj];
svlistall = Cases[conjrep, _I, Infinity] // DeleteDuplicates;
```

## Step 4 — Impose the parity constraint

Form a linear system over the coefficients `c[1] .. c[$LENG]` (where `$LENG = Length[svlistmplans]`).

- **Odd ansatz** (purely imaginary under conjugation): `c . (svlistmplans /. conjrep) + c . svlistmplans = 0`
- **Even ansatz** (real under conjugation): `c . (svlistmplans /. conjrep) - c . svlistmplans = 0`

Extract the coefficient matrix with respect to the independent SVMPL list `svlistall`, expand each row in the transcendental basis `{f[3], π, f[5], f[7], f[3,3], f[5,3]}` (use `f[3,3] -> f[3]^2/2`), set each monomial independent, then solve:

```mathematica
presys = Last @ Normal @ CoefficientArrays[
  c[Range[$LENG]] . (svlistmplans /. conjrep) + c[Range[$LENG]] . svlistmplans,
  svlistall];  (* use "-" for even *)
presys1 = Table[
  (presys[[i]] /. {Pi -> pi, f[3,3] -> f[3]^2/2} //
     MonomialList[#, {f[3], pi, f[5], f[7], f[3,3], f[5,3]}] &) /.
   {pi -> 1, f[3] -> 1, f[5] -> 1, f[7] -> 1},
  {i, 1, Length[presys]}] // Flatten;
sys = CoefficientArrays[presys1, c /@ Range[$LENG]][[2]];
ns = NullSpace[sys] // RowReduce;
```

The `MonomialList` step treats every monomial in the transcendental basis as an independent equation, so that coefficients of `f[3]`, `f[5]`, `f[3]^2`, `f[5,3]`, etc. are all separately required to vanish. After `NullSpace`, `ns` is the list of allowed linear combinations of `svlistmplans`.

## Step 5 — Remove redundancy with the pure SVHPL ansatz

Some directions in `ns` are already spanned by the pure SVHPL odd/even ansatz (which has no `zz` at all). Remove them with partial row reduction against the SVHPL basis.

```mathematica
(* Load SVHPL basis at the target weight *)
allsvlistoddans = Import[FileNameJoin[{dir, "allsvlistoddans.m"}]];
allsvlistevenans = Import[FileNameJoin[{dir, "allsvlistevenans.m"}]];

oddansatz  = Join[allsvlistoddans[[6]],  f[5] allsvlistoddans[[1]], f[3] allsvlistoddans[[3]]];
evenansatz = Join[allsvlistevenans[[6]], f[5] allsvlistevenans[[1]], f[3] allsvlistevenans[[3]],
                  {f[3,3]}];  (* include the weight-6 constant in the even SVHPL basis *)
(* For weight 8, also include f[5,3], f[3] f[5] in the even SVHPL basis *)

MatchAnsatz[exp_, ansatz_] := Module[{svlistall2, sys2, sys1, len, sol},
  svlistall2 = Cases[ansatz, _I, Infinity] // DeleteDuplicates;
  len = Length[ansatz];
  sys2 = CoefficientArrays[-exp + c[Range[len]] . ansatz, svlistall2][[2]] // Normal;
  sys1 = Table[(sys2[[i]] /. {Pi -> pi, f[3,3] -> f[3]^2/2} //
       MonomialList[#, {f[3], pi, f[5], f[7], f[3,3], f[5,3]}] &) /.
     {pi -> 1, f[3] -> 1, f[5] -> 1, f[7] -> 1}, {i, 1, Length[sys2]}] // Flatten;
  sol = Solve[Thread @ Equal[sys1, 0], c /@ Range[len]][[1]];
  c /@ Range[len] /. sol
];

presyst = Table[MatchAnsatz[oddansatz[[i]], svlistmplans], {i, 1, Length[oddansatz]}];
(* For even ansatz, use evenansatz instead. *)

PartialRowReduce[mat1_, mat2_] := Module[{tem, temmat, temmat1, rank},
  tem = SortBy[mat1, LeafCount];
  temmat = mat2;
  rank = MatrixRank[temmat];
  Do[
    temmat1 = Append[temmat, tem[[i]]];
    If[MatrixRank[temmat1] - rank == 1, temmat = temmat1; rank = rank + 1;],
    {i, 1, Length[tem]}];
  temmat
];

ns1 = PartialRowReduce[ns, presyst];
```

`PartialRowReduce` sorts null-space vectors by leaf count and greedily keeps only those linearly independent from `presyst` (the SVHPL directions). The result `ns1` is the final reduced basis; `Drop[ns1, k]` removes the first `k` redundant entries (the SVHPL-matched ones), and `Drop[ns1, k] . svlistmplans` is the parity-odd/even SVMPL ansatz.

## Step 6 — Export

```mathematica
Export[FileNameJoin[{dir, "svmploddansatz_threeloop.m"}],  Drop[ns1, 30] . svlistmplans];
Export[FileNameJoin[{dir, "svmplevenansatz_threeloop.m"}], Drop[ns1, 44] . svlistmplans];
```

The drop count depends on how many directions `PartialRowReduce` matched against the SVHPL basis (13 remain for odd, 12 for even in the 3-loop N=2 example).

## Rules and constraints

- **Only independent zeta monomials.** Never use `f[3, 5]` as a prefactor or constant — it equals `f[3] f[5] - f[5, 3]`. Use `f[5, 3]` and `f[3] f[5]` instead.
- **Constants are even.** Products of odd zetas are even under `z ↔ zz`, so constants (`f[3,3]`, `f[5,3]`, `f[3] f[5]`) appear only in the even ansatz.
- **The new letter is restricted to the last N entries of the word.** This restriction is what makes the SVMPL ansatz small. After conjugation the new letter may appear anywhere, but the ansatz only keeps it in the first N word slots (positions `w1 .. wN`).
- **Word length < N is allowed.** When `L < N`, every slot is a new-letter slot (`nNew = L`, `nOld = 0`); the part is kept, not dropped.
- **`f[3, 3]` can be a prefactor at weight 8.** At weight 6 it is a constant; at weight 8 it pairs with an SVMPL of word length 2.

## Existing ansatz files (under `data/ansatz/`)

| File | Parity | Weight | N | New letter | Source |
|------|--------|--------|---|------------|--------|
| `svmploddansatz_threeloop.m` | odd | 6 | 2 | `zz` | svbwalkthrough.wl Section 3 |
| `svmplevenansatz_threeloop.m` | even | 6 | 2 | `zz` | svbwalkthrough.wl Section 3 |
| `svmploddansatz_fourloophard_small.m` | odd | 8 | 4 | `zz` | generalised construction |
| `svmplevenansatz_fourloophard_small.m` | even | 8 | 4 | `zz` | generalised construction |
| `allsvlistoddans.m`, `allsvlistevenans.m` | odd/even | up to 8 | — | none (pure SVHPL) | prior construction |
| `svlistoddansatz_w8.m`, `svlistevenansatz_w8.m` | odd/even | 8 | — | none (pure SVHPL) | prior construction |
