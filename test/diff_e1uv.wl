new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
old = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
diff = Expand[new - old];
Print["Non-zero elements in diff: ", Count[diff, x_ /; x =!= 0]];
