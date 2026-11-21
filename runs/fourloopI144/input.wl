(* Ancillary graph 144, in the original physical z,zz coordinates. *)
integrand = (x[1, 2]*x[1, 3]*x[1, 4]*x[2, 4]*x[5, 6])/(x[1, 5]*x[1, 6]*x[1, 7]*x[1, 8]*x[2, 5]*x[2, 6]*x[2, 8]*x[3, 6]*x[3, 8]*x[4, 5]*x[4, 6]*x[4, 7]*x[5, 7]*x[5, 8]*x[6, 7]);
leadingsingularitylist = {1/((1-u)*(z-zz)), 1/((1-u+v)*(z-zz)), 1/(z-zz)^2};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI144ansatz.m"}]];
