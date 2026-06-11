(* ::Package:: *)

integrand=(x[1,2] x[1,4] x[3,5])/(x[1,5] x[1,7] x[1,8] x[2,7] x[2,8] x[3,6] x[3,8] x[4,5] x[4,6] x[5,6] x[5,7] x[5,8] x[6,7]);


leadingsingularity=1/(z-zz);


ansatz=Import[FileNameJoin[{DirectoryName[$InputFileName], "svlistoddansatz_w8.m"}]];

OrderY=4;
