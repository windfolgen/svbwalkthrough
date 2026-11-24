(* Basis integral assembled from the four-cut bootstrap of R260. Get this file and
   apply it to [q,qb]. The correlator multiplier u/v is external. *)
Module[{file, r260, i168},
  file[name_] := FileNameJoin[{DirectoryName[$InputFileName],
    "fourloop"<>name<>"."<>FileExtension[$InputFileName]}];
  r260 = Get[file["R260"]];
  i168 = Get[file["I168"]];
  Function[{q,qb}, With[{u=q*qb, v=(1-q)*(1-qb)},
    (r260[q,qb]+i168[q/(q-1),qb/(qb-1)]+v*i168[1-q,1-qb])/u
  ]]
]
