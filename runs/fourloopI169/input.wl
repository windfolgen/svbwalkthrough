(* Ancillary index 169; original physical z,zz coordinates. *)
integrand = (x[1, 3]*x[1, 4]*x[2, 3]*x[2, 4]*x[5, 6]^2)/(x[1, 5]*x[1, 6]*x[1, 8]*x[2, 5]*x[2, 6]*x[2, 8]*x[3, 5]*x[3, 6]*x[3, 7]*x[4, 5]*x[4, 6]*x[4, 7]*x[5, 7]*x[5, 8]*x[6, 7]*x[6, 8]);

leadingsingularitylist = {v/(u*(-1 + v)*(z - zz)), v/(u*(z - zz)^2)};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI169ansatz.m"}]];
OrderY = 6;

bootstrapOptions = <|"BootstrapMethod" -> "Weighted"|>;
