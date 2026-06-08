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
  {{m[1]}, {m[2]}, {m[3], m[4], m[5], m[6]}}, (* {1, 1, 4} *)
  {{m[1]}, {m[2], m[3]}, {m[4], m[5], m[6]}}, (* {1, 2, 3} *)
  {{m[1], m[2]}, {m[3]}, {m[4], m[5], m[6]}}, (* {2, 1, 3} *)
  {{m[1]}, {m[2], m[3], m[4]}, {m[5], m[6]}}, (* {1, 3, 2} *)
  {{m[1], m[2]}, {m[3], m[4]}, {m[5], m[6]}}, (* {2, 2, 2} *)
  {{m[1], m[2], m[3]}, {m[1]}, {m[5], m[6]}}  (* {3, 1, 2} *)
};

Do[
  t0 = SessionTime[];
  tensor = MPartition[shapes[[i]], p];
  l = Length[tensor];
  Print["Shape ", i, ": basis length = ", l];
  
  tSolve = SessionTime[];
  bv = b /@ Range[l];
  cv = c /@ Range[l];
  sys = Table[
    ((tensor[[i]]*(cv . tensor) // Expand) /. {d2[1, p] -> u}) == bv[[i]], 
    {i, 1, l}
  ];
  sol = Solve[sys, cv];
  Print["  Solving took: ", SessionTime[] - tSolve, "s"];
, {i, 1, Length[shapes]}];
