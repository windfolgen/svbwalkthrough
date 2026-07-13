(* ::Package:: *)

integrand = x[3,7]/(x[1,5] x[1,7] x[2,6] x[2,7] x[3,5] x[3,6] x[3,8] x[4,5] x[4,7] x[5,8] x[6,7] x[6,8] x[7,8]);

leadingsingularity = 1/(z-zz)/(1-u);

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI41ansatz.m"}]];

OrderY = 4;
