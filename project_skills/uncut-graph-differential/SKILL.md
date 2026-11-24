---
name: uncut-graph-differential
description: Audit a cut-based conformal-integral ansatz by deriving an uncut differential equation with pinched source graphs and an independently determined boundary condition.
---

# Derive an uncut graph differential equation

Use this workflow when the objective is equality to a proposed function outside an assumed word or prefactor space. Specify the physical graph and any signed subtractions before analyzing individual sectors.

1. Choose a conformal frame at the physical dimension, align loop labels, and combine identical graph terms. State the family, measure and irreducible scalar products. If using dimensional regularization, define the continued packet in this frame.
2. Differentiate with respect to a kinematic variable that keeps an accessible boundary. Reduce the sector with all parent propagators to identify its homogeneous differential when that sector is small. Search for an identity on uncut integrals using external differentiation and explicit total derivatives. Verify cancellation of every parent-sector coefficient symbolically. A second derivative implementation and sector quotients provide cross-checks.
3. Compute the source terms with fewer propagators. Inspect three-point conformal subgraphs, known periods and existing functional results before attempting a full reduction. Apply the regulator limit after summing any terms that can have poles. A cut quotient discards subgraphs and retains only a projection of this source.
4. Apply the same differential to the candidate, including period terms. Determine the homogeneous integration freedom and fix it on the graph and candidate at the same physical boundary. To conclude global equality, establish equality of the resulting sources on an open domain and specify how the physical sheet is reached.

For $R_{260}$ the aligned graph $M$ has a single thirteen-propagator term. Nine elementary integration-by-parts identities give a fixed-$u$ equation, and the regular diagonal fixes the homogeneous constant. The comparison of the complete integrated source with the svMPL derivative remains open. [Exact graph identity, evaluated subintegrals and scope](../../runs/fourloopR260/differential/README.md)
