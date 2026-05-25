(* ::Package:: *)

integrand=(x[1,4] x[2,3] )/(x[1,5] x[1,6] x[1,7] x[2,5] x[2,6] x[2,7] x[3,5] x[3,6] x[3,7] x[4,5] x[4,6] x[4,7]);
(*the integrand used*)


leadingsingularity=(v)/(z-zz)^3;(*the leading singularity*)


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/threeloopI8/threeloopoddansatz.m"];
