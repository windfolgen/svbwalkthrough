---
name: ansatz_basis
description: >
  Construct parity-even (or parity-odd) ansatz bases from SVHPL/MPL
  basis elements.  Produces both weight-grouped and flat forms,
  validates against benchmark files, and optionally calls
  AuditAnsatzBenchmark to confirm correctness.
---

## Inputs expected from the user or calling context
- `letters` (list) — basis letters (usually `{0,1}`).
- `maxWeight` (integer) — maximum transcendental weight.
- `parity` — `"even"` or `"odd"`.
- Optionally `loopOrder`, `lastEntry`, `lastTwoEntries`, grouping
  preference.

## Primary references
- [`benchmark_files.md`](references/benchmark_files.md) — local
  benchmark file paths and roles.
- [`construction_workflow.md`](references/construction_workflow.md) —
  step-by-step build order.
- [`parity_rules.md`](references/parity_rules.md) — conservative
  labelling rules for parity.

## Workflow
1. Load the grouped-by-weight benchmark (`allsvlistevenans.m` or
   `allsvlistoddans.m`) as your primary structural reference.
2. Identify how many weight buckets the benchmark has and how many
   elements are in each.
3. Build your candidate basis one weight at a time, matching the
   bucket sizes and element order from the benchmark.
4. Use the flat benchmark (`svmplevenansatz_threeloop.m` or
   `svmploddansatz_threeloop.m`) only when you must produce a
   flattened form — the grouped form is the canonical reference.
5. Produce both forms: a weight-grouped basis (list of lists) and a
   flat basis (single list).
6. When available, call `AuditAnsatzBenchmark[rootDir, label, basis, flatBasis]`
   to validate.

## Output contract — your final answer MUST include
- `parity` — the parity you built.
- `maxWeight` — the maximum weight.
- `groupedBasis` — weight-grouped list of lists.
- `flatBasis` — single flat list.
- Optionally a diff report if `AuditAnsatzBenchmark` ran.

## Notes
- Do not claim that the basis is complete without running the
  benchmark comparison; always mark it as "candidate" when unvalidated.
- Keep the weight-grouped organisation stable — it matches the
  benchmark data format and enables weight-by-weight comparison.
- The notebook `svbwalkthrough.nb` Section 3 describes how the
  original author constructed the even/odd ansatz — use it for
  narrative context but not as the sole structural reference.
