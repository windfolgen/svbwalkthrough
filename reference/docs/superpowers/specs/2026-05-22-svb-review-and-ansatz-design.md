# SVB Review Gate And Ansatz Skill Design

## Goal

Upgrade the existing SVB audit layer into a stage-oriented review gate, and add a workspace-local skill that teaches an agent how to construct parity-even and parity-odd ansatz bases from benchmark files already present in this repository.

## Scope

This first version covers:

- a unified review entrypoint for `preflight`, `boundary`, `series`, `solve`, and `pipeline`
- hard benchmark profiles for the existing three hard boundary cases and two hard series/solve cases
- a reusable `AuditAnsatzBenchmark` entrypoint for future parity-basis checks
- a workspace-local skill under `project_skills/ansatz_basis/`

This version does not attempt to:

- infer the leading singularity from the integrand
- infer the alphabet from first principles
- prove basis completeness without benchmark support

## Review Architecture

The review layer remains in `audit_agent/audit_agent.wl`, but it is promoted from a collection of stage-specific checks into a unified review gate.

New public entrypoints:

- `RunReviewGate[rootDir, label, stage, opts___]`
- `AuditAnsatzBenchmark[rootDir, ansatzData, opts___]`
- `AuditHardBenchmarkWorkspace[rootDir, opts___]`
- `audit_agent/run_hard_benchmark_review.wl` as a one-shot runner

The gate reuses the existing stage checks:

- `AuditSourceContracts`
- `AuditPipelineInput`
- `AuditBoundaryStep`
- `AuditSeriesStep`
- `AuditSolveStep`
- `AuditFullPipeline`

## Review Categories

Checks are annotated into four review categories:

- `contract`: file paths, labels, required inputs, benchmark profile attachment
- `stale`: freshness and reuse suspicion
- `format`: import shape, list lengths, variable cleanup, output schema
- `logic`: residuals, coefficient coverage, conformal-weight consistency, benchmark diffs

## Benchmark Profiles

The gate uses explicit benchmark profiles instead of burying hard-coded assumptions in stage logic.

Profiles in version 1:

- `hard-boundary`: labels `I3Lhard`, `I3Lhardr`, `I3Lhardt`
- `hard-series`: labels `threeloophard1`, `threeloophard2`
- `hard-solve`: labels `threeloophard1`, `threeloophard2`
- `hard-ansatz`: parity `even`, `odd`

## Stage Behavior

### Preflight

Validates:

- root directory
- required files
- pole type
- conformal-weight consistency
- ansatz and basis list shape

### Boundary

Validates:

- permutation order
- six expected files
- file freshness
- import success
- `SeriesData` or zero output shape

### Series

Validates:

- all six SV and MPL outputs
- basis-length agreement
- freshness
- residual `z`-like variable leakage
- requested truncation order

### Solve

Validates:

- `c[i] -> value` rule shape
- duplicate coefficient protection
- full coefficient coverage
- bad numeric or symbolic values
- optional residual substitution against target data

### Ansatz

Validates:

- grouped parity benchmark file presence and importability
- flat parity benchmark file presence and importability
- grouped benchmark bucket count up to the requested weight
- optional exact comparison against a candidate grouped or flat ansatz

## Workspace Skill

The project-local skill lives at:

- `project_skills/ansatz_basis/SKILL.md`

Supporting references:

- `project_skills/ansatz_basis/references/benchmark_files.md`
- `project_skills/ansatz_basis/references/construction_workflow.md`
- `project_skills/ansatz_basis/references/parity_rules.md`

The skill teaches an agent to:

1. load the benchmark parity files
2. treat `allsvlist...ans.m` as grouped benchmark data
3. treat `svmpl...ansatz_threeloop.m` as flat benchmark data
4. organize outputs by weight first, then as a flattened list
5. validate generated candidates with `AuditAnsatzBenchmark`

## Integration Notes

- `master_agent.wl` should call `RunReviewGate` after each stage instead of directly calling the lower-level audit functions.
- benchmark attachment is advisory for generic labels and strict for known hard benchmark labels.
- the hard benchmark workspace summary can be regenerated through `AuditHardBenchmarkWorkspace`.
