(* Affine period ansatz at fixed symbol. Components 4 and 5 multiply dlog A and dlog M. *)
Module[{data, sectors, odd, periods, words, origin, kernels, column},
  data = Import[FileNameJoin[{DirectoryName[$InputFileName], "fit", "period_basis.json"}], "RawJSON"];
  sectors = <|"P0" -> 1, "Pu" -> 2, "Pv" -> 3|>;
  odd[expr_] := (expr - (expr /. {z -> zz, zz -> z}))/2;
  periods = <|"z3" -> f[3], "z5" -> f[5], "z7" -> f[7], "z33" -> f[3]^2,
               "p2z3" -> Pi^2 f[3], "p2z5" -> Pi^2 f[5], "p4z3" -> Pi^4 f[3]|>;
  words = Map[odd[ToExpression[#]] &, data["words"]];
  origin = ToExpression /@ Lookup[data["particular"], {"P0", "Pu", "Pv", "A", "M"}];
  origin[[1 ;; 3]] = odd /@ origin[[1 ;; 3]];
  kernels = Map[ToExpression, data["closed_forms"], {2}];
  column[label_] := Module[{parts = StringSplit[label, ":"], k},
    Which[
      Length[parts] == 3, {{sectors[parts[[2]]], periods[parts[[1]]] words[parts[[3]]]}},
      First[parts] == "M", {{5, periods[Last[parts]]}},
      StringStartsQ[label, "projkernel"],
        k = 1 + FromDigits[StringDrop[label, StringLength["projkernel"]]];
        {{4, kernels[[k, 1]]}, {5, kernels[[k, 2]]}}
    ]
  ];
  <|"particular" -> origin, "columns" -> (column /@ data["columns"])|>
]
