(* ::Package:: *)

integrandlist={(x[3,6] x[4,5])/(x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7]),(x[3,5] x[4,6])/(x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7])};
coeff={1,1};


leadingsingularity=1/(z-zz)/(1-v);


ansatz=Import[FileNameJoin[{DirectoryName[$InputFileName], "threeloophard2_ans.m"}]];

OrderY=3;
