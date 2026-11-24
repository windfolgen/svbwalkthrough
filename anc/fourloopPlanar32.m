(* The planar correlator in diagram order. Each BasisFunction takes [z,zz]
   in the original basis ordering; multiply by Multiplier to obtain the row.
   Keep u,v,z,zz and the package's word and period symbols unassigned on load. *)
Module[{directory=DirectoryName[$InputFileName], ext=FileExtension[$InputFileName],
        filename, read, basisFunction, rows},
  filename[i_] := "fourloopI"<>ToString[i]<>"."<>ext;
  read[i_] := Get[FileNameJoin[{directory,filename[i]}]];
  basisFunction[212] = With[{native=read[212]}, Function[{q,qb},native[1-q,1-qb]]];
  basisFunction[i : (168|260)] := basisFunction[i] = read[i];
  basisFunction[i_Integer] := basisFunction[i] =
    Function @@ {read[i] /. {z -> Slot[1], zz -> Slot[2]}};
  rows = {
    {1,175,1,"Known"},
    {2,173,1,"Bootstrap"},
    {3,208,1,"Known"},
    {4,181,1,"Bootstrap"},
    {5,174,1,"Known"},
    {6,176,1,"Bootstrap"},
    {7,233,1/u,"Bootstrap"},
    {8,140,v,"Product"},
    {9,187,1,"Known"},
    {10,214,1/v,"Bootstrap"},
    {11,246,1,"Bootstrap"},
    {12,212,1,"Bootstrap"},
    {13,144,u,"Bootstrap"},
    {14,260,u/v,"Bootstrap"},
    {15,49,v^2/u,"Product"},
    {16,3,1,"Known"},
    {17,5,1,"Known"},
    {18,39,1,"Product"},
    {19,38,v,"Known"},
    {20,21,1,"Known"},
    {21,37,1,"Known"},
    {22,27,v/u,"Known"},
    {23,49,v/u,"Product"},
    {24,160,1,"Known"},
    {25,167,1,"Bootstrap"},
    {26,162,1,"Known"},
    {27,163,1,"Bootstrap"},
    {28,164,1,"Known"},
    {29,133,u/v,"Product"},
    {30,168,1,"Bootstrap"},
    {31,169,u,"Bootstrap"},
    {32,126,u/v,"Product"}
  };
  Map[Function[row, With[{i=row[[2]]},
    <|"Row"->row[[1]], "Basis"->i, "Multiplier"->row[[3]], "Status"->row[[4]],
      "BasisFile"->filename[i], "BasisFunction"->basisFunction[i]|>
  ]], rows]
]
