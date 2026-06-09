(* ::Package:: *)

integrand=(x[1,2] x[1,3] x[1,4] x[5,6])/(x[1,5] x[1,6] x[1,7] x[1,8] x[2,6] x[2,8] x[3,5] x[3,7] x[4,5] x[4,6] x[5,7] x[5,8] x[6,7] x[6,8]);


leadingsingularity=1/(z-zz);


ansatz=Import[FileNameJoin[{DirectoryName[$InputFileName], "allsvlistoddans.m"}]];

OrderY=4;
