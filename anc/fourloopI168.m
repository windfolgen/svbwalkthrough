(* I168 = 2 v I26 + R168. Get this file and apply it to [q,qb]. *)
Module[{file, scalar, remainder},
  file[name_] := FileNameJoin[{DirectoryName[$InputFileName],
    "fourloop"<>name<>"."<>FileExtension[$InputFileName]}];
  scalar = Get[file["I26"]];
  remainder = Function @@ {Get[file["R168"]] /. {z -> Slot[1], zz -> Slot[2]}};
  Function[{q,qb}, 2*(1-q)*(1-qb)*scalar[q,qb] + remainder[q,qb]]
]
