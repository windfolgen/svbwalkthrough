$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];
Do[
  Get[FileNameJoin[{rootDir, "asym", "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, $LiteRedBases}];

Get[FileNameJoin[{rootDir, "asym", "asym_new.wl"}]];

shapes = {
  {{m[1], m[2]}, {m[3], m[4]}, {m[5], m[6]}}  (* {2, 2, 2} *)
};

i = 1;
tensor = MPartition[shapes[[i]], p];
l = Length[tensor];

bv = b /@ Range[l];
cv = c /@ Range[l];

sys = Table[
  ((tensor[[i]]*(cv . tensor) // Expand) /. {d2[1, p] -> u}) == bv[[i]], 
  {i, 1, l}
];

tLS = SessionTime[];
{rhs, lhsMat} = CoefficientArrays[sys[[All, 1]], cv];
cvSol = LinearSolve[Normal[lhsMat], bv];
solLS = Thread[Rule[cv, cvSol]];
Print["LinearSolve took ", SessionTime[] - tLS, "s"];

tSolve = SessionTime[];
solSolve = Flatten[Solve[sys, cv]];
Print["Solve took ", SessionTime[] - tSolve, "s"];

Print["Are the solutions identical? ", (cv /. solLS) === (cv /. solSolve)];
