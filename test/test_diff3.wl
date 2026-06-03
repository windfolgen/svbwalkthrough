new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
old = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
diff = Expand[new[[3]] - old[[3]]];
Print["Difference in element 3:"];
Print[InputForm[diff]];
