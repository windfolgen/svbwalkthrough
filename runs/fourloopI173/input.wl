(* ::Package:: *)

integrand=(x[1,8]x[3,7]x[2,4])/(x[2,5]x[3,5]x[5,7]x[5,8]x[1,6]x[4,6]x[6,7]x[6,8]x[1,7]x[2,7]x[3,8]x[4,8]x[7,8]);


leadingsingularity={1/(z-zz),(u-v-1)/(z-zz)^2};


ansatz={Import[FileNameJoin[{DirectoryName[$InputFileName], "svlistoddansatz_w8.m"}]],Import[FileNameJoin[{DirectoryName[$InputFileName], "svlistevenansatz_w8.m"}]]};

OrderY=4;
