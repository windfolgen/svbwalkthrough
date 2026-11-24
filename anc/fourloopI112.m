(* I112 = I26 + J112. Get this file and apply it to [q,qb]. *)
Module[{file, scalar, finite},
  file[name_] := FileNameJoin[{DirectoryName[$InputFileName],
    "fourloop"<>name<>"."<>FileExtension[$InputFileName]}];
  scalar = Get[file["I26"]];
  finite = Function @@ {Get[file["J112"]] /. {z -> Slot[1], zz -> Slot[2]}};
  Function[{q,qb}, scalar[q,qb] + finite[q,qb]]
]
