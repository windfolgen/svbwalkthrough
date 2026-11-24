---
name: svmpl-graph-boundaries
description: Test proposed svMPL numerators against low-order Euclidean OPE coefficients derived from a conformal graph, and select independent boundary measurements for the remaining freedom.
---

# Test svMPL numerators with graph boundaries

Use this workflow when a cut or a subtraction suggests a known numerator, an overall multiple, or a small number of functions. Start by writing the complete prefactors and specifying which functions are held fixed. If a term and its crossed image are predicted to have the same normalization, temporarily give them independent coefficients. This makes crossing itself testable.

1. Choose a boundary on which the unknowns have different responses. For a four-dimensional Euclidean short-distance expansion set $z=th$, $\bar z=t/h$. Then $u=t^2$, $Y=1-v=t(h+h^{-1})-t^2$ and $c=(h+h^{-1})/2$. A factor singular at $t=0$ can move a higher numerator coefficient into the desired order.
2. Calculate the graph side independently. For a maximal radial logarithm, use the ordered radii between the short and unit external distances. For the logarithm one power below it, account also for a free radial gap and a loop outside the interval. Average each monomial of internal unit vectors on $S^3$. Escalate radial order or spin only if the proposed probes leave the coefficients underdetermined. For other dimensions or log powers derive the corresponding sector weights.
3. Expand the candidate directly in the HyperlogProcedures svMPL convention. A triangular ordinary hyperlog differential can evaluate these functions exactly. Record the explicit periods, independent angular initial states and the conversion $\log t=\tfrac12\log u$. Compare rows over the rationals or $\mathbb Q(h)$ when feasible.
4. Subtract the fixed sectors, then report the response matrix, its rank and the exact solution. State whether it fixes normalizations, selects a full function in a specified basis, or verifies a graph differential equation. Reserve independent graph kinematics or boundary coefficients for a check and identify which data entered the solve.

For $R_{260}$ a single radial degree supplies two rows which fix the native and crossed coefficients of $P_v$ separately. Both residuals have spin zero. The graph algorithm, exact svMPL projection and four held-out physical boundary comparisons run from the repository root. [Worked test, inputs and reproduction commands](../../runs/fourloopR260/differential/README.md)
