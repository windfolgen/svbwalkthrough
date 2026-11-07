(* Ancillary index 167; original physical z,zz coordinates. *)
integrand = (x[1, 2]*x[1, 4]*x[2, 3]*x[5, 6]^2)/(x[1, 5]*x[1, 6]*x[1, 8]*x[2, 5]*x[2, 6]*x[2, 7]*x[3, 5]*x[3, 6]*x[4, 5]*x[4, 6]*x[5, 7]*x[5, 8]*x[6, 7]*x[6, 8]*x[7, 8]);

leadingsingularitylist = {v/((-1 + v)*(z - zz)), v/(z - zz)^2};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI167ansatz.m"}]];
OrderY = 6;

bootstrapOptions = <|"BootstrapMethod" -> "Weighted"|>;
