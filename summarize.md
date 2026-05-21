# Summary of SVB Walkthrough Calculation Procedures

## Overview
This Mathematica notebook implements a **bootstrap method for computing multi-loop Feynman integrals** via leading singularities. The core workflow is: (1) compute leading singularities of an integrand, (2) construct an ansatz from a basis of transcendental functions, (3) fix the ansatz coefficients by matching to the leading singularities.

---

## 1. Basic Algebraic Infrastructure

### 1.1 Position Coordinates
- Define coordinates `x[a, b]` with properties:
  - `x[a, a] = 0`
  - `x[a] - x[b] := x[a, b]`
  - Antisymmetry: if `!OrderedQ[{a,b}]`, then `x[a,b] = -x[b,a]`
  - Additivity: `x[a,b] + x[b,c] = x[a,c]`

### 1.2 Vector Algebra (V, V2, VD, SD)
- `V[a]` represents a vector
- `VD[a, b] := V[a] * V[b]` (orderless)
- `V2[a] := V[a]^2` (squared norm)
- Special rules for dot products when differences are position coordinates:
  - If `a - b == x[__]`, then `VD[a,b] = -1/2*(V2[a-b] - V2[a] - V2[b])`
  - If `a + b == x[__]`, then similar rule with `+1/2`
- `SD[a,b]` is the fallback symbol for generic scalar products

### 1.3 Utility Functions
- **`ShowV2[exp]`**: Display `V2[x[a,b]]` as `Subscript[x, a,b]^2`
- **`PerfectSquareOut[expr]`**: Factor out perfect squares from square roots, returns `{square_part, remaining_radical}`
- **`Jacob[list, var]`**: Compute the Jacobian determinant for cutting 4 conditions on a loop variable `var`
- **`AdmissibleCutQ[cut, var, replambda]`**: Check if a cut set provides at least 4 independent conditions
- **`ResolveCondition[list, var]`**: Handle quadratic polynomials by replacing with derivative + discriminant
- **`ReOrganize[tem2]`**: Reorganize square roots from multiple cut cases

---

## 2. Leading Singularity Computation (`LeadingSingularities`)

### 2.1 Input
- An integrand as a rational function with denominator being a product of propagators `x[a,b]`
- Optional: external vertices (default `{1,2,3,4}`)

### 2.2 Graph Construction
- Build graph from denominator edges (solid) and numerator edges (dashed)
- Identify loop variables as non-external vertices
- Check vertex degree: each loop must have degree >= 4

### 2.3 Step 1: Direct Integration ("Easy" Loops)
- Find loops with exactly degree 4 (directly integrable)
- If multiple such loops exist, order them by connectivity in the subgraph without external points
- For each directly integrable loop:
  - Cut its 4 propagators (set to zero)
  - Compute Jacobian factor
  - Add Jacobian to `replambda` abbreviation rules
  - Remove cut propagators from the cutlist
  - Factor and flatten remaining propagators

### 2.4 Step k (k >= 2): Iterative Cutting
- For each remaining branch in the cutlist:
  - Count how many propagators involve each remaining loop variable
  - If a loop has exactly 4 propagators: cut that loop
  - If no loop has 4 propagators: use `ResolveOrder` to determine best loop to cut next
- **`CutOneLoop[cutlist, numlist, var, replambda, remain]`**: Main cutting engine
  - Select propagators involving `var`
  - Find all 4-element subsets that are admissible cuts
  - For each subset case:
    1. Separate integer propagators from square-root-related ones (`lambda`)
    2. Solve the linear system of 4 cut conditions
    3. If solution has < 4 variables, iterate by substituting into square roots
    4. Check for double poles and record `checksol` for numerator cancellation
    5. Handle higher poles by requiring numerator cancellation
    6. If quadratic conditions exist, resolve via `ResolveCondition`
    7. Further split the 4 conditions into all 4-element subsets
    8. Compute Jacobian for each subset
    9. Build remaining denominator and numerator
    10. Sow `{den1, num1, replam, remain}` for next iteration

### 2.5 Final Step: Express in Cross-Ratios (u, v)
- After all loops are cut, express the result using:
  - `u = V2[x[1,2]]*V2[x[3,4]] / (V2[x[1,3]]*V2[x[2,4]])`
  - `v = V2[x[1,4]]*V2[x[2,3]] / (V2[x[1,3]]*V2[x[2,4]])`
- Apply `PerfectSquareOut` to all lambda replacements
- Return the list of leading singularities as rational functions in `u`, `v`, and lambda symbols

### 2.6 Output Levels
- `outputlevel == 1`: Return `{cutlist, numlist, replambda}`
- `outputlevel == 2`: Return leading singularities list
- `outputlevel == 3`: Return `{ls, cutlist[[All,3]]}` with lambda replacements

---

## 3. Canonical DCI Integrals (`CanonicalDCI`)

### 3.1 Binary Word to Integrand
- Input: a binary word (list of 0s and 1s, or string)
- Output: a DCI (Dual Conformal Invariant) integrand
- Rules:
  - Start with `1/(x[1,5]*x[2,5]*x[3,5]*x[4,5])`
  - For each subsequent bit (starting from position 2):
    - If `0`: replace one external leg pattern, multiply by `x[2,4]/(x[count,2]*x[count,4])/x[1,count]`
    - If `1`: multiply by `x[1,2]/x[2,4]`, then replace `4 -> count`, divide by `x[4,count]*x[1,count]`
  - Increment `count` each step

### 3.2 Graph Drawing (`drawGraph`)
- Visualize the integrand as a graph
- Options: `withoutnum`, `planar`, `output`, `id`

---

## 4. Ansatz Construction

### 4.1 Basis Elements
- Multiple polylogarithms denoted `I[z, a1, a2, ..., an]` with weights up to some maximum
- Even/odd classification under parity
- Building blocks:
  - `f[3]`, `f[5]`, etc. (presumably certain prefactors or form factors)
  - `I[z, zz, ...]` terms with `zz` as a special symbol

### 4.2 Ansatz Files
- `allsvlistmpl_threeloop.m`: List of all MPL basis elements for 3-loop
- `svmplevenansatz_threeloop.m`: Even parity ansatz (linear combinations of basis)
- `svmploddansatz_threeloop.m`: Odd parity ansatz
- `allsvlistevenans.m`, `allsvlistoddans.m`: Even/odd singular value lists

### 4.3 Ansatz Structure
Each ansatz element is a linear combination:
```
c[1]*basis[1] + c[2]*basis[2] + ... + c[n]*basis[n]
```
where coefficients are rational numbers determined by matching.

---

## 5. Solution Fitting and Result

### 5.1 Coefficient Solving
- Given leading singularities computed from integrands
- Match against ansatz evaluated at singular points
- Solve linear system for coefficients `c[i]`

### 5.2 Solution Files
- `threeloophard1_ans.m`, `threeloophard2_ans.m`: Ansatz with symbolic coefficients
- `threeloophard1_sol.m`, `threeloophard2_sol.m`: Solved coefficient values
- `resulthard3L.m`: Final combined result expressed in terms of basis functions

### 5.3 Final Result Format
- Rational function in `(z - zz)` and `(1 - v)` denominators
- Numerator: linear combination of `I[z, ...]` and `f[...]` terms with integer/rational coefficients

---

## 6. Key Data Files

| File | Purpose |
|------|---------|
| `svbwalkthrough.nb` | Main notebook with all algorithms |
| `allsvlistmpl_threeloop.m` | Complete MPL basis for 3-loop |
| `svmplevenansatz_threeloop.m` | Even parity ansatz |
| `svmploddansatz_threeloop.m` | Odd parity ansatz |
| `threeloophard1_ans.m`, `threeloophard2_ans.m` | Hard topology ansatz |
| `threeloophard1_sol.m`, `threeloophard2_sol.m` | Solved coefficients |
| `resulthard3L.m` | Final 3-loop hard result |
| `threeloophard_svliste*uv*.m` | Singular value lists at various limits (e0, e1, eInf, u, v, up, vp) |

---

## 7. Workflow Diagram

```
Input: Integrand (denominator + numerator)
  |
  v
Graph Analysis --> Identify loop variables
  |
  v
Step 1: Cut "easy" loops (degree == 4)
  |
  v
Step k: Iteratively cut remaining loops
  |         - Select 4 conditions
  |         - Solve linear system
  |         - Handle square roots
  |         - Compute Jacobians
  |         - Branch on cases
  |
  v
Last Step: Express in u, v cross-ratios
  |
  v
Output: Leading singularities (list of rational functions)
  |
  v
Match against Ansatz (I[z,...] + f[...] basis)
  |
  v
Solve for coefficients c[i]
  |
  v
Output: Fitted result (linear combination of basis)
```

---

## 8. Skill Prototype Requirements

To automate this workflow, a skill would need:

1. **Input Parser**: Accept integrand as product of `x[a,b]` propagators
2. **Graph Analyzer**: Build graph, identify loops, check degrees
3. **Cut Engine**: Implement `CutOneLoop` logic with case branching
4. **Jacobian Calculator**: Compute determinant of cut conditions
5. **Square Root Handler**: `PerfectSquareOut`, `ReOrganize`, discriminant resolution
6. **Cross-Ratio Converter**: Express final result in `u`, `v`
7. **Ansatz Manager**: Load basis, construct ansatz, evaluate at singular points
8. **Solver**: Linear algebra to fit coefficients
9. **Output Formatter**: Write result in standard notation
