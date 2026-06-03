(* Print svlisteinf[[1]] *)
svlisteinf = Import["../allsvlisteinf_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
Print[InputForm[svlisteinf[[1]]]];
