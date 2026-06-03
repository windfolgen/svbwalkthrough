$HistoryLength = 0;
Get["config.wl"];
ansatz = Import["runs/fourloopI41/fourloopI41ansatz.m"];
basisElements = DeleteDuplicates @ Cases[ansatz, _I | _f, {1, Infinity}];
fullBasisSV = Import[FileNameJoin[{$DataDir, $SVTextPrefix <> "e0_uptow8_inuv.txt"}]];
If[Head[fullBasisSV] === String,
  Get["series_agent/series_agent.wl"]; (* for ParseListString *)
  fullBasisSV = ParseListString[fullBasisSV];
];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
Print["Length svIndices: ", Length[svIndices]];
