(* ::Package:: *)

integrand=1/(x[1,6] x[1,7] x[2,6] x[2,7] x[3,5] x[3,7] x[4,5] x[4,6] x[5,6] x[5,7]);
(*the integrand used*)


leadingsingularity=(1)/(z-zz)/(1-v);(*the leading singularity*)


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/threeloopI5/threeloopoddansatz.m"];
