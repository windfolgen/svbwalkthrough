(* Ancillary graph 233, in the original physical z,zz coordinates. *)
integrand = (x[1, 2]*x[1, 6]*x[2, 3]*x[3, 4]*x[5, 7])/(x[1, 5]*x[1, 7]*x[1, 8]*x[2, 6]*x[2, 7]*x[2, 8]*x[3, 5]*x[3, 6]*x[3, 7]*x[4, 5]*x[4, 7]*x[5, 6]*x[5, 8]*x[6, 7]*x[6, 8]);
leadingsingularitylist = {u/((1-u)*(zz-z)), u/((1-u-v)*(zz-z)), u/((1-v)*(zz-z)), u/(zz-z)^2};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI233ansatz.m"}]];
