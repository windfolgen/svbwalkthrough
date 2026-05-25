# Construction Workflow

Step-by-step order for building a candidate parity basis:

1. **Fix target parity** — `"even"` or `"odd"`.
2. **Fix maximum weight** (e.g., 6 for "threeloop").
3. **Load the grouped benchmark** (`allsvlistevenans.m` or
   `allsvlistoddans.m`).
4. **Identify expected bucket count and sizes**: count how many
   weight buckets the benchmark has and how many elements are in each.
5. **Build candidate weight-by-weight**:
   - For each weight `w` from 1 to `maxWeight`, collect SVHPL
     basis elements `I[z, a1, …, an]` with total weight = `w`.
   - Match the element count and order from the benchmark.
6. **Flatten** only after the grouped structure is stable — do not
   flatten prematurely.
7. **Validate** with `AuditAnsatzBenchmark[rootDir, label, groupedBasis, flatBasis]`
   (when the audit agent is available).

## Why grouped first?
- Weight-by-weight comparison is the least ambiguous — it shows
  exactly where errors first appear.
- It avoids hiding mistakes that flattening might obscure.
- The benchmark data format is itself weight-grouped, so direct
  comparison is natural.

## Validation snippet (if `AuditAnsatzBenchmark` is not available)
```mathematica
(* grouped comparison *)
groupedBenchmark = Import[FileNameJoin[{dir, "allsvlistevenans.m"}]];
If[groupedBenchmark === groupedBasis,
   Print["Grouped match PASS"],
   Print["Grouped mismatch at weights: ",
     Position[MapThread[SameQ, {groupedBenchmark, groupedBasis}], False]]
];

(* flat comparison *)
flatBenchmark = Import[FileNameJoin[{dir, "svmplevenansatz_threeloop.m"}]];
If[Sort[flatBenchmark] === Sort[flatBasis],
   Print["Flat match PASS"],
   Print["Flat mismatch."]
];
```
