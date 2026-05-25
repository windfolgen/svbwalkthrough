(* ::Package:: *)

integrand=-((x[1,2] x[1,4] x[3,7] x[1,3] x[2,4] (-x[1,7] x[5,4]+x[1,4] x[5,7]-x[1,5] x[7,4]))/(x[1,5]^2 x[1,7]^2 x[2,6] x[2,7] x[3,5] x[3,6] x[4,5] x[4,7] x[4,8] x[5,8] x[6,7] x[6,8] x[7,8]));


leadingsingularity=u*v/(z-zz);


ansatz=Import["/Users/windfolgen/Documents/aether/svbwalkthrough/runs/fourloopI6boxing/threeloopoddansatz.m"];
