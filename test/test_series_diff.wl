f1 = ToExpression["{" <> StringTake[StringTrim[Import["allsvlistmpl_threeloope1_inuv.txt", "String"]], {2, -2}] <> "}"];
f2 = ToExpression["{" <> StringTake[StringTrim[Import["allsvlistmpl_threeloope1_inuv_old.txt", "String"]], {2, -2}] <> "}"];

diff = Expand[Normal[f1] - Normal[f2]];
maxDiff = Max[Abs[Flatten[diff /. {Log[u]->1, Zeta[_]->1, Y->1, Pi->1}]]];
Print["Max diff for e1uv SV: ", maxDiff];

f1P = ToExpression["{" <> StringTake[StringTrim[Import["allsvlistmpl_threeloope1_inuvp.txt", "String"]], {2, -2}] <> "}"];
f2P = ToExpression["{" <> StringTake[StringTrim[Import["allsvlistmpl_threeloope1_inuvp_old.txt", "String"]], {2, -2}] <> "}"];

diffP = Expand[Normal[f1P] - Normal[f2P]];
maxDiffP = Max[Abs[Flatten[diffP /. {Log[u]->1, Zeta[_]->1, Y->1, Pi->1}]]];
Print["Max diff for e1uvp SV: ", maxDiffP];
