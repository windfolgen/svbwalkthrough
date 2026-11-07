# Independent weighted graph boundaries

These Wolfram expressions are physical N4/N6 graph-boundary data, independent
of the svMPL ansatz and its coefficient solution. Their hashes and graph
normalizations are registered in `data/series/fourloop_hard/catalog.m`.

I169 has all six N4 channels and N6 channel 1. I246 has N4 channels 1 and 5,
N6 channel 1, and N6 channel 5 transferred from the independently calculated
channel 3 with `B5 = u/(1-Y) B3`. I167 uses the established ancillary identity
I167 = I246; this is not an independent N6 reduction of the I167 graph.

Orders are weighted, with channel-dependent leading powers. They are not
ordinary rectangular truncations in `u,Y`. The workflow checks the actual
integrand and applies any rational normalization before forming equations.
An unmatched graph needs independently supplied boundary expressions.

See [the native reconstruction API and limitations](../../../series_agent/WEIGHTED_BOOTSTRAP.md).
