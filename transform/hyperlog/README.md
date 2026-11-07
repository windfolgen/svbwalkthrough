# Hyperlog procedures for the weighted bootstrap

These are the additional Maple procedures promoted into the package:
`OrderedHyperlogJet`, `DiagonalJet`, `ForbiddenDiagonalJet`, `CircleJet`, and
`ForbiddenCircleJet`. They use the installed HyperlogProcedures library.

The configurable `build_jets.mpl` produces ordered function expansions or
local/crossing transformations. It has no hard-coded installation paths.
Create the output directory first, then set:

```sh
export SVB_PACKAGE_ROOT=/path/to/svbwalkthrough
export SVB_HYPERLOG_DIR=/path/to/HyperlogProcedures08
export SVB_BASIS_FILE=/absolute/path/to/atoms.txt
export SVB_OUTPUT_DIRECTORY=/absolute/path/to/output
export SVB_MODE=e0
/path/to/maple -q "$SVB_PACKAGE_ROOT/transform/hyperlog/build_jets.mpl"
```

The Hyperlog directory must expose its required cache/data files, as for the
original Maple workflow. `atoms.txt` is a Maple list of svMPL expressions with
symbolic `z,zz`. Modes are `e0`, `e1`, `einf`, `diagonal`, `circle`, and
`inversion`. Optional `SVB_ATOM_INDICES='[1,4,16]'` selects a subset;
`SVB_ATOM_TIMEOUT` defaults to 180 seconds.

Ordered series use depths `(8,3)` and keep the holomorphic and antiholomorphic
logarithms separate; local series use order three. Each successful atom is
written to `atom_<index>.txt`. **Check `status.json`: its `failed` list must be
empty.** Maple's process exit code alone does not certify success. The output
is deliberately regenerated for the requested atoms, avoiding stale reuse
when the input list changes.

The ordinary examples do not invoke Maple during each coefficient solve:
function expansions are precomputed data, as in the original package. This
producer is the route for rebuilding/extending those data. Fresh ordinary,
moving-letter and mixed-letter e0 controls were compared exactly with the
previously certified expansions during integration.
