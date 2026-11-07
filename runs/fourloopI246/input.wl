(* Ancillary index 246; original physical z,zz coordinates. *)
integrand = (x[1, 2]^2*x[1, 4]*x[2, 3]*x[5, 7])/(x[1, 5]*x[1, 6]*x[1, 7]*x[1, 8]*x[2, 5]*x[2, 6]*x[2, 7]*x[2, 8]*x[3, 5]*x[3, 7]*x[4, 5]*x[4, 7]*x[5, 8]*x[6, 7]*x[6, 8]);

leadingsingularitylist = {v/((-1 + v)*(z - zz)), v/(z - zz)^2};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI246ansatz.m"}]];
OrderY = 6;

bootstrapOptions = <|"BootstrapMethod" -> "Weighted"|>;
