bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
diff = Expand[bm - new];
nonZero = Select[diff, # =!= 0 &];
getMinYPower[expr_] := Exponent[expr /. {Log[u] -> 1, Zeta[_] -> 1, Pi -> 1}, Y, Min];
minPowers = Map[getMinYPower, nonZero];
Print["Min powers of Y in differences: ", Tally[minPowers]];
