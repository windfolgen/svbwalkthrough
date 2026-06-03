(* Test Script *)
svlisteinf = Import["../allsvlisteinf_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svlisteinf[[1]];
Print[Variables[expr]];
