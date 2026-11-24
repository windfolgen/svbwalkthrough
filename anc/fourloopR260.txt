(* Conditional four-cut candidate for R260. Get this file and apply it to
   [q,qb]. Use the Euclidean continuation of both I214 primitives. For
   separately continued primitives see GramAuxiliaries["R260FromI214"]. *)
Module[{file, i214, fromI214},
  file[name_] := FileNameJoin[{DirectoryName[$InputFileName],
    "fourloop"<>name<>"."<>FileExtension[$InputFileName]}];
  i214 = Function @@ {Get[file["I214"]] /. {z -> Slot[1], zz -> Slot[2]}};
  fromI214 = Get[file["GramAuxiliaries"]]["R260FromI214"];
  Function[{q,qb}, fromI214[q,qb,i214[q,qb],i214[1/qb,1/q]]]
]
