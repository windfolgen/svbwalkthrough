---
name: ansatz_basis
description: Construct parity-even or parity-odd ansatz bases for this SVB workspace from the local benchmark files, organize the result by weight, and validate it against the hard benchmark references.
---

# Ansatz Basis

Use this skill when the task is to build or check a parity-even or parity-odd ansatz basis inside this workspace.

This is a project-local skill. It is benchmark-driven, not a general proof system.

## Inputs

Expect the user or caller to provide:

- `letters`
- `maxWeight`
- `parity`: `even`, `odd`, or `both`

Optional constraints:

- `loopOrder`
- `lastEntry` or `lastTwoEntries`
- whether the output should remain grouped by weight

## Primary references

Read only the files you need:

- [references/benchmark_files.md](references/benchmark_files.md): which local files define the parity benchmarks
- [references/construction_workflow.md](references/construction_workflow.md): the recommended build order
- [references/parity_rules.md](references/parity_rules.md): what to preserve when labeling even and odd sectors

## Workflow

1. Load the grouped benchmark for the requested parity.
2. Use the grouped benchmark as the primary reference for weight-by-weight structure.
3. Use the flat benchmark only when a flattened ansatz list is required.
4. Produce output in two forms:
   - grouped by weight
   - flattened list
5. If a candidate basis is generated, validate it with:

```mathematica
Get[FileNameJoin[{root, "audit_agent", "audit_agent.wl"}]];
AuditAnsatzBenchmark[root, candidate,
  "Parity" -> "even" (* or "odd" *),
  "MaxWeight" -> 6
]
```

## Output contract

When constructing a candidate basis, return:

- the requested parity
- the maximum weight covered
- the grouped basis by weight
- the flattened basis
- a short diff summary against the benchmark if validation was requested

## Notes

- Do not claim completeness without benchmark support.
- Keep the grouped-by-weight organization stable. That is the easiest shape for later review.
- If the benchmark and the generated basis differ, report missing and extra items explicitly instead of silently normalizing them away.
