bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
diff1 = bm[[1]] - new[[1]] // Expand;
Print["Difference in first element: ", diff1];
