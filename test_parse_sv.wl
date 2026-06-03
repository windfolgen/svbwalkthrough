Get["workflow_engine.wl"];
ansatz = Import["runs/fourloopI41/fourloopI41ansatz.m"];
basisElements = DeleteDuplicates @ Cases[ansatz, _I | _f, {1, Infinity}];
fullBasisSV = ParseListString[Import["data/allsvliste0_uptow8_inuv.txt", "String"]];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
Print["Length svIndices: ", Length[svIndices]];
