bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
diff = Expand[bm - new];
getMinYPower[expr_] := Exponent[expr /. {Log[u] -> 1, Zeta[_] -> 1, Pi -> 1}, Y, Min];
minPowers = Map[getMinYPower, diff];
idx = Position[minPowers, -2, 1, 1][[1, 1]];
Print["First index with 1/Y^2 difference: ", idx];
Print["Difference at index ", idx, ": ", diff[[idx]]];
