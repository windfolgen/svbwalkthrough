res = Get["runs/threeloophard1/result.m"];
benchmarkAll = Get["resulthard3L.m"];
(* Extract the numerator of the double pole term in benchmark *)
(* The double pole term is at (z-zz)^2 *)
(* Let's find the coefficient of 1/(z-zz)^2 *)
coeffBenchmark = Coefficient[benchmarkAll, 1/(z - zz)^2];

Print["Calculated result is list: ", ListQ[res]];
Print["Length of calculated result: ", Length[res]];

calculatedExpr = res[[1]];
diff = Expand[calculatedExpr - coeffBenchmark];

Print["Algebraic difference (should be 0): ", diff];
