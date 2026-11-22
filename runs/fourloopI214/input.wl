(* Ancillary graph 214 in the original physical z,zz coordinates. *)
integrand = (x[1,4]*x[1,6]*x[2,3]*x[2,5]*x[3,4])/
  (x[1,5]*x[1,7]*x[1,8]*x[2,6]*x[2,7]*x[2,8]*x[3,5]*x[3,6]*x[3,8]*
   x[4,5]*x[4,6]*x[4,7]*x[5,6]*x[5,8]*x[6,7]);
leadingsingularitylist = {v/(z-zz), v/((z-zz)*(u-1)), v/((z-zz)*(v-1)), u*v/((z-zz)*y)};
ansatzlist = Get[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI214ansatz.m"}]];
