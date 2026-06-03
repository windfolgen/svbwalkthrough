bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
diff = Expand[bm - new];
nonZero = Select[diff, # =!= 0 &];
Print["Number of non-zero differences: ", Length[nonZero]];
If[Length[nonZero] > 0, Print["First non-zero difference: ", nonZero[[1]]]];
