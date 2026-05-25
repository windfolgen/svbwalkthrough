(* ::Package:: *)

integrand=((x[5,6]*x[3,4]-x[3,6]x[4,5]-x[3,5]x[4,6])/(x[5,1]x[5,2]x[5,3]x[5,4]x[6,1]x[6,2]x[6,3]x[6,4]x[6,7]x[5,7]x[7,3]x[7,4]));


leadingsingularity=1/(z-zz)^2;


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/threeloophard1/threeloophard1_ans.m"];
