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
Print["Shape 5 basis length: ", l];

bv = b /@ Range[l];
cv = c /@ Range[l];

tSys = SessionTime[];
sys = Table[
  ((tensor[[i]]*(cv . tensor) // Expand) /. {d2[1, p] -> u}) == bv[[i]], 
  {i, 1, l}
];
Print["Constructed sys in ", SessionTime[] - tSys, "s"];

(* Check if the system has any non-linear terms or strange symbols *)
Print["Variables in sys: ", Variables[sys]];
Print["Coefficient matrix dimensions: ", Dimensions[CoefficientArrays[sys[[All, 1]], cv][[2]]]];

tSolve = SessionTime[];
sol = Solve[sys, cv];
Print["Solve took ", SessionTime[] - tSolve, "s"];
