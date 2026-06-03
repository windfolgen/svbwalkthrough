bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"];
new = Get["series_agent/fourloopI41_svlistmple1uv.m"];
Print["Length of benchmark: ", Length[bm]];
Print["Length of new: ", Length[new]];
Print["Is element 1 identical? ", Expand[bm[[1]] - new[[1]]] === 0];
Print["Is element 2 identical? ", Expand[bm[[2]] - new[[2]]] === 0];
