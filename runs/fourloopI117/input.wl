(* ::Package:: *)

integrand = (x[1,6])/(x[1,5] x[1,7] x[1,8] x[2,6] x[2,8] x[3,6] x[3,8] x[4,6] x[4,7] x[5,6] x[5,7] x[5,8] x[6,7]);

leadingsingularity = 1/(z-zz)/(1-u);

ansatz = Import[FileNameJoin[{DirectoryName[$InputFileName], "fourloopI41ansatz.m"}]];

OrderY = 4;
