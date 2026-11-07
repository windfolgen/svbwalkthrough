# Weighted function series and analytic constraints

`catalog.m` registers profiles 169 (735 reference functions) and 246 (756),
the reference bases, prefactors, period rings, boundary block names, and
SHA-256 hashes. Reference functions use the original physical `z,zz` variables.

Each compressed packet evaluates to an association with `Matrix` and `Keys`.
Boundary-series packets contain function expansions only: no target vector or
solution. Their keys identify coefficients in the appropriate period ring.
Constraint packets encode the stated crossing, logarithmic or regularity
conditions. They apply only where those analytic assumptions are established.

The series agent projects these matrices onto the supplied ansatz and obtains
right-hand sides from the separate [boundary expressions](../../boundaries/fourloop_hard/README.md).
The initial export rebuilt the packets from research series and verified them
exactly against every archived equation block. Earlier research integration checks regenerated N6 expansions for five
directions, including the two mixed odd functions used by I167/I246. The current
review reruns the equation construction and exact solves against the packaged data.

See [the package procedure and regeneration guide](../../../series_agent/WEIGHTED_BOOTSTRAP.md).
