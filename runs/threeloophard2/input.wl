(* ::Package:: *)

integrand=(x[3,6] x[4,5]+x[3,5] x[4,6])/(x[1,5] x[1,6] x[2,5] x[2,6] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7] x[5,7] x[6,7]);


leadingsingularity=1/(z-zz)/(1-v);


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/threeloophard2/threeloophard2_ans.m"];
