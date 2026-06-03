$HistoryLength = 0;
Get["config.wl"];
Get["workflow_engine.wl"];
Get["input_parser.wl"];
Get["series_agent/series_agent.wl"];
parsed = ParseInput["runs/fourloopI41/"];
ansatz = parsed["LeadingSingularities"][[1,3]];
basisElements = DeleteDuplicates @ Cases[ansatz, _I | _f, {1, Infinity}];
fullBasisMPL = Import["data/allsvlistmpl_fourloop_invzz.m"];
mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisMPL, e, {1}]] /@ basisElements;
mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
Print["Length mplIndices: ", Length[mplIndices]];
mplListRaw = ParseListString[Import["data/allsvlistmpl_fourloop_invzze1_inuv.txt", "String"]];
mplList = mplListRaw[[mplIndices]];
Print["Length mplList selected: ", Length[mplList]];

(* We test the manual expansion logic for e1uv (ptr=1, OddQ[i]=True, i=5) *)
poleType = "simple"; weightN = 2; poleOrder = 1; yOrder = 4;
add = 1; (* simplifying for test *)
radical = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)]; expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

ExpandInuvListLocal[basisList_, sqrtSer_, expT_] := ParallelTable[
  Module[{test, test2, seriesY},
    test = If[poleType === "simple",
      basisList[[j]] * add * (-sqrtSer) / expT,
      basisList[[j]] * add / expT
    ];
    test2 = (test /. {Log[u] -> logU});
    seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {Y > 0}] // Normal;
    (seriesY /. {logU -> Log[u]}) // Expand
  ],
  {j, 1, Length[basisList]}
];

res = ExpandInuvListLocal[mplList, sqrtSeries, expTerm];
Print["Length res: ", Length[res]];
Print["Is empty? ", res === {}];
