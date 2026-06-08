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

k = 4074;
i = 1; (* Topology 1 *)

vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;

(* Method A: u symbolic in GenTensorProjection *)
tpA = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
tpA = tpA /. {p -> 2};
matA = tpA[[1]];

(* Method B: u -> 1 in GenTensorProjection *)
tpB = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> 1}];
tpB = tpB /. {p -> 2};
matB = tpB[[1]];

(* Reconstruct matA from matB *)
tensorBasis = tpB[[2]];
L = Length[tensorBasis];
ranks = Table[Count[tensorBasis[[jj]], _vc, Infinity], {jj, 1, L}];
scalingMat = Table[u^((ranks[[col]] - ranks[[row]])/2), {row, 1, L}, {col, 1, L}];
matReconstructed = matB * scalingMat;

Print["Are the reconstructed matrix and original symbolic matrix identical? ", Expand[matReconstructed - matA] === Table[0, {L}, {L}]];
Print["Matrix A: ", matA // Short[#, 5] &];
Print["Reconstructed: ", matReconstructed // Short[#, 5] &];
