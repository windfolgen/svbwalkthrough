(* ::Package:: *)

integrand=(x[4,7]* x[5,6]-x[4,5]x[6,7]-x[4,6]x[5,7])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);


leadingsingularity=1/(z-zz)/(1-u);


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/fourloopI41/fourloopI41ansatz.m"];
