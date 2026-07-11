# Init Instructions

Before working in this workspace, read the following skill files in this order:

1. **System Rules** — [project_skills/system/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/system/SKILL.md)
   Operational rules for file management, workspace cleanliness, process safety, and git safety. Always read this first.

2. **Summary** — [summary.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/summary.md)
   High-level overview of the project, directory structure, pipeline stages, and proven runs.

3. **Workflow Orchestration** — [project_skills/workflow/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/workflow/SKILL.md)
   How to invoke each skill in the correct order, manage multi-leading-singularity runs, and interpret audit gates.

4. **Per-skill details:**
   - [project_skills/boundary_calculation/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/boundary_calculation/SKILL.md) — Skill 2: boundary condition calculation
   - [project_skills/series_expansion/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL.md) — Skill 1: ansatz series expansion (Mathematica)
   - [project_skills/series_expansion/SKILL_hyperlog_series_expansion.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/series_expansion/SKILL_hyperlog_series_expansion.md) — Hyperlog series expansion via Maple
   - [project_skills/coefficient_solving/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/coefficient_solving/SKILL.md) — Skill 3: coefficient solving
   - [project_skills/ansatz_basis/SKILL.md](file:///Users/windfolgen/Documents/AntiGravity/svbwalkthrough/project_skills/ansatz_basis/SKILL.md) — How to construct parity-even/odd ansatz bases

The actual agent source code lives in:
- `workflow_engine.wl` — Main orchestration engine
- `input_parser.wl` — Input config parser
- `asym/boundary_agent/boundary_agent.wl` — Skill 2
- `series_agent/series_agent.wl` — Skill 1
- `solve_agent/solve_agent.wl` — Skill 3
- `audit_agent/audit_agent.wl` — Skill 4
- `review_agent.wl` — Audit facade
- `config.wl` — Fixed global configuration
- `ConformalWeight.m` — Conformal weight calculator

Mirror series expansion and mirror solving are under development in `series_agent/series_agent_mirror.wl` and `solve_agent/solve_agent_mirror.wl`.
