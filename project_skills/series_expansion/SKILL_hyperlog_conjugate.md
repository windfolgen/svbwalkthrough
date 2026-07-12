# Hyperlog Conjugate Transformation Skill

Apply complex conjugation (`CConjugate`) to a list of single-valued integrals using Oliver Schnetz's HyperlogProcedures.

## Overview

Given a list of hyperlog expressions (e.g., from ansatz files or series expansion outputs), compute their complex conjugates element-wise. The result is a new list where each integral `el` is replaced by `CConjugate(el, [z, zz])`.

## Prerequisites

- Maple 2023+ with HyperlogProcedures loaded
- `HyperlogProcedures` and `cachedatamine.m` in the working directory (typically `/home/ana/maple/HyperlogProcedures08/`)
- Input file containing a **Maple list** of expressions

## Input

A text file containing a Maple list, e.g.:

```maple
[f[0, 1, 0] + I*Pi^2, f[1, 0, 1] - 2*zeta[3], ...]
```

Or from Mathematica `.m` format (requires `{ } → [ ]` conversion).

## Minimal Script

```maple
read "/home/ana/maple/HyperlogProcedures08/HyperlogProcedures":
kernelopts(numcpus = 1):
LargeCache(f):

# --- Read input list ---
# If the file is a plain Maple list:
intList := parse(FileTools[Text][ReadFile]("input_list.txt")):

# If the file came from Mathematica / Wolfram Language:
# str := StringTools[SubstituteAll](
#          StringTools[SubstituteAll](
#            FileTools[Text][ReadFile]("input_from_wolfram.m"), "{", "["), "}", "]"):
# intList := parse(str):

printf("Loaded %a elements to conjugate\n", nops(intList)):

# --- Compute conjugates ---
Lconj := []:
for idx from 1 to nops(intList) do
    el := intList[idx]:
    conjResult := CConjugate(el, [z, zz]):
    Lconj := [op(Lconj), conjResult]:
    if idx mod 50 = 0 then
        printf("Processed %d / %d\n", idx, nops(intList)):
    end if:
end do:

# --- Export result ---
Export("output_conj.txt", convert(Lconj, string)):
printf("Done. Output written to output_conj.txt\n"):
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `input_file` | Path to the text file containing the input list |
| `output_file` | Path for the conjugated output list |
| `vars` | Conjugate variable pair, default `[z, zz]` |

## Key Procedure: `CConjugate`

```maple
CConjugate(x, [z, zz])
```

Performs:
1. Swaps conjugate variables (`z ↔ zz`)
2. Replaces `I → -I`
3. Re-expands in the proper basis via `shuffleexpand` / `lyndonize`

## Important Notes

1. **Run from HyperlogProcedures directory**: Execute the script from the directory containing `HyperlogProcedures` and `cachedatamine.m`, otherwise cache files are not found.

2. **Mathematica input fix**: If the list was exported from Mathematica, `{` and `}` must be replaced by `[` and `]` before `parse()`, because Maple treats `{ }` as an unordered **set**.

3. **Progress tracking**: For large lists (e.g., 300+ elements), print progress every 50 iterations. Conjugation can take significant CPU time.

4. **Memory**: `LargeCache(f)` loads precomputed cache data. Ensure sufficient RAM.

## Batch Conjugation: Multiple Lists

If you have several lists to process (e.g. `svlistmplfourloophard`, `svlistmplfourloopinvz`, `svlistmpln`), create one script per list or loop over them:

```maple
read "/home/ana/maple/HyperlogProcedures08/HyperlogProcedures":
kernelopts(numcpus = 1):
LargeCache(f):

tasks := [
    ["svlistmplfourloophard.txt", "svlistmplfourloophard_conj.txt"],
    ["svlistmplfourloopinvz.txt", "svlistmplfourloopinvz_conj.txt"]
]:

for task in tasks do
    infile  := task[1]:
    outfile := task[2]:

    intList := parse(FileTools[Text][ReadFile](infile)):
    Lconj := []:
    for el in intList do
        Lconj := [op(Lconj), CConjugate(el, [z, zz])]:
    end do:
    Export(outfile, convert(Lconj, string)):
    printf("Done: %a -> %a\n", infile, outfile):
end do:
```

## Bash Runner

```bash
#!/bin/bash
HP_DIR="/home/ana/maple/HyperlogProcedures08"
MAPLE="/home/ana/maple2023/bin/maple"
SCRIPT="/path/to/conjugate_list.mpl"

cd ${HP_DIR} && ${MAPLE} ${SCRIPT} > conjugate.log 2>&1 &
```

## Existing Examples

Reference scripts in `HyperlogProcedures08/conjugations/scripts/`:

- `conjugate_svlistmplfourloophard.mpl`
- `conjugate_svlistmplfourloopinvz.mpl`
- `conjugate_svlistmpln.mpl`

All follow the same pattern: `read HyperlogProcedures` → `LargeCache(f)` → loop `CConjugate(el, [z, zz])` → `Export`.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `could not open cachedatamine.m` | Run the script from the directory containing `HyperlogProcedures` |
| Input parsed as set (order lost) | Replace `{` → `[` and `}` → `]` before `parse()` |
| Very slow / hangs | Normal for large expressions; ensure `LargeCache(f)` was called |
| `CConjugate` undefined | Check that `HyperlogProcedures` was read successfully |
