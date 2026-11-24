---
name: elliptic-svmpl-onefold
description: Bootstrap a conformal integral whose cut admits a final elliptic integration with an svMPL numerator, including the characteristic, period sectors and physical endpoint.
---

# Bootstrap the svMPL kernel of an elliptic onefold

Identify the characteristic of the graph cut and the external derivative tangent to it. Display the polynomial defining the elliptic curve, its square-root convention, the rational prefactor and the variable held fixed. Derive the numerator that this derivative isolates. Determine the boundary of the integrated function from the graph, including any homogeneous term allowed there.

Build the unknown numerator directly from svMPL words of the required weight and parity. Include lower-weight words multiplied by allowed periods. State the order of the indices used by the paper and by HyperlogProcedures when restricting a moving letter to particular slots. Trial word sets can be compared using the coefficient and augmented ranks; an inconsistent augmented system is evidence that the support or the imposed constraints need rechecking.

Apply the characteristic derivative to independent graph expansions in their own channels. Check crossing and endpoint exchange at function level. After solving, substitute in the graph equations, compare an unused boundary or an independent differentiated graph value, and integrate the onefold on its prescribed sheet. An earlier symbol result can supply a separate comparison after the periods have been included.

For $I_{26}$ the characteristic is $\rho=u/v^2$ and regularity fixes the primitive at a root of the quartic. The repository contains the graph inputs, Maple word projections, rational solver and branch convention. Reproduce the kernel from the root with the following command. [Worked derivation](../../runs/fourloopI26/README.md) · [Ancillary onefold](../../anc/fourloopI26.mpl)

~~~sh
python runs/fourloopI26/bootstrap.py --output /tmp/I26-kernel.json
~~~
