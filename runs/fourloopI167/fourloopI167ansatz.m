(* Per-leading-singularity basis lists, in original z,zz coordinates. *)
Module[{basisDir = FileNameJoin[{ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]], "data", "ansatz", "fourloop_hard"}]},
  {
    Join[Get[FileNameJoin[{basisDir, "two_family_odd_w8.m"}]], Get[FileNameJoin[{basisDir, "mixed_odd_extension_w8.m"}]]],
    Join[Get[FileNameJoin[{basisDir, "two_family_even_w8.m"}]], Get[FileNameJoin[{basisDir, "mixed_even_extension_w8.m"}]]]
  } /. {w -> 1-z, ww -> 1-zz}
]
