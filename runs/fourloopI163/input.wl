(* Ancillary I163; original physical z,zz coordinates. *)
integrand = Get[FileNameJoin[{rootDir, "data", "constraints", "reciprocal_s3_w8", "integrand.m"}]];
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI163ansatz.m"}]];
lsConfigList = MapThread[Append, {
  {{"simple",1}, {"simple",1/(u-1)}, {"simple",u/(u-v)}, {"simple",1/(v-1)},
   {"double",1}, {"double",u}, {"double",v}}, ansatzlist}];
OrderY = 6;
bootstrapOptions = <|"BootstrapMethod" -> "Constrained",
  "ConstraintProfile" -> "data/constraints/reciprocal_s3_w8/profile.wl"|>;
