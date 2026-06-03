bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
diff = Expand[bm - new];
indices = Select[Range[Length[diff]], diff[[#]] =!= 0 &];
Print["First differing indices: ", Take[indices, UpTo[5]]];
Print["Difference at index ", indices[[1]], ": ", diff[[indices[[1]]]]];
