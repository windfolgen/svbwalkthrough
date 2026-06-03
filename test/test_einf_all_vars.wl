(* Print variables of allsvlisteinf *)
svlisteinf = Import["../allsvlisteinf_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
vars = Union[Flatten[Variables /@ svlisteinf]];
Print[InputForm[vars]];
