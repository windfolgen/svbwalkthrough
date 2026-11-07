(* Pure function basis, one list per leading singularity. *)
Get[FileNameJoin[{ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]],
  "data", "constraints", "reciprocal_s3_w8", "orbit.m"}]]["LeadingSingularities"][[All, 3]]
