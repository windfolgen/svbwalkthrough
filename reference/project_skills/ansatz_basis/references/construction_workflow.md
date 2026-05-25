# Construction Workflow

Use this order when constructing a candidate parity basis.

1. Fix the target parity.
2. Fix the maximum weight.
3. Load the grouped benchmark file for that parity.
4. Identify the expected bucket count and bucket sizes by weight.
5. Build or propose candidate elements weight by weight.
6. Flatten only after the grouped structure is stable.
7. Validate with `AuditAnsatzBenchmark`.

## Why grouped first

Weight-by-weight comparison is the least ambiguous way to review a candidate basis:

- it shows where extra or missing elements first appear
- it avoids hiding mistakes inside a large flattened list
- it matches how the benchmark data is stored

## Validation pattern

For grouped candidates:

```mathematica
AuditAnsatzBenchmark[root, candidateGrouped,
  "Parity" -> "odd",
  "MaxWeight" -> 6
]
```

For flat candidates:

```mathematica
AuditAnsatzBenchmark[root, candidateFlat,
  "Parity" -> "odd",
  "CandidateFlat" -> candidateFlat
]
```
