(* scratch/test_inverse_method.wl *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

idxList = {{m[1], m[3]}, {m[2], m[5]}, {m[7], m[9]}};
tag = 2;
krep = {d2[1, tag] -> u};

tensor = MPartition[idxList, tag];
l = Length[tensor];

M = Table[
  ((tensor[[i]] * tensor[[j]] // Expand) /. krep),
  {i, 1, l}, {j, 1, l}
];

Print["Basis size (L): ", l];

t0 = SessionTime[];
Print["Trying Inverse[M]..."];
invM = Inverse[M];
Print["Inverse[M] took: ", SessionTime[] - t0, "s"];

t0 = SessionTime[];
Print["Trying LinearSolve[M, IdentityMatrix[L]]..."];
invM2 = LinearSolve[M, IdentityMatrix[l]];
Print["LinearSolve took: ", SessionTime[] - t0, "s"];

t0 = SessionTime[];
Print["Computing sol = invM . tensor..."];
sol = invM . tensor;
Print["Multiplication took: ", SessionTime[] - t0, "s"];

t0 = SessionTime[];
Print["Factoring sol..."];
solFactored = Factor /@ sol;
Print["Factoring took: ", SessionTime[] - t0, "s"];
