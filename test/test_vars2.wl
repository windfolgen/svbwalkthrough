(* test_vars.wl *)
rootDir = "../";
svliste0 = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
Print[InputForm[svliste0[[1]]]];
