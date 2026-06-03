SetDirectory["/Users/windfolgen/Documents/AntiGravity/svbwalkthrough"];
svlisteinf = Import["allsvlistmpl_threeloope0.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
zPows = Cases[svlisteinf, Power[z, a_Integer] :> a, Infinity];
zzPows = Cases[svlisteinf, Power[zz, a_Integer] :> a, Infinity];
Print["Z powers: ", MinMax[zPows]];
Print["ZZ powers: ", MinMax[zzPows]];
