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
  {{m[1]}, {m[2]}, {m[3]}, {m[4]}} (* shape {4}, rank 4 *)
};

tem = shapes[[1]];

(* Method A: u symbolic in GenTensorProjection *)
tpA = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
tpA = tpA /. {p -> 2};
matA = tpA[[1]];

(* Method B: u -> 1 in GenTensorProjection *)
tpB = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> 1}];
tpB = tpB /. {p -> 2};
matB = tpB[[1]];

(* Reconstruct matA from matB using the matrix formula:
   matA[[j, i]] = matB[[j, i]] * u^(-(n_i + n_j)/2)
*)
tensorBasis = tpB[[2]];
L = Length[tensorBasis];
ranks = Table[Count[tensorBasis[[jj]], _vc, Infinity], {jj, 1, L}];
scalingMat = Table[u^(-(ranks[[row]] + ranks[[col]])/2), {row, 1, L}, {col, 1, L}];
matReconstructed = matB * scalingMat;

Print["Are the reconstructed matrix and original symbolic matrix identical? ", Expand[matReconstructed - matA] === Table[0, {L}, {L}]];
Print["Matrix A: ", matA // Short[#, 5] &];
Print["Reconstructed: ", matReconstructed // Short[#, 5] &];
