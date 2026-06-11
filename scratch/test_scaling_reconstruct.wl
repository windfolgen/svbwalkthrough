(* scratch/test_scaling_reconstruct.wl *)
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

idxList = {{m[1], m[2]}, {m[3], m[4]}};
tag = 2;

(* Solve with u *)
tpU = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> u}];

(* Solve with u -> 1 using GenTensorProjection *)
tp1 = GenTensorProjection[idxList, tag, "krep" -> {d2[1, tag] -> 1}];

tensor = tpU[[2]];
l = Length[tensor];

(* Count vector occurrences *)
kList = Table[
  Module[{expanded = Expand[tensor[[i]]], firstTerm},
    firstTerm = If[Head[expanded] === Plus, expanded[[1]], expanded];
    Length[Cases[{firstTerm}, vc[tag, _], Infinity]]
  ],
  {i, 1, l}
];

(* Retrieve the coefficient matrix for u -> 1 *)
(* We know cv . tensor /. sol = sum_j bv[[j]] * tp[[1]][[j]] *)
(* So the coefficient of bv[[j]] and tensor[[i]] is the matrix elements of tp_coeff *)
sys1 = Table[
  ((tensor[[i]]*(c /@ Range[l] . tensor) // Expand) /. {d2[1, tag] -> 1}) == b[i],
  {i, 1, l}
];
sol1 = Flatten[Solve[sys1, c /@ Range[l]]];
sol1 = Together[sol1];
mat1 = Normal[CoefficientArrays[c /@ Range[l] /. sol1, b /@ Range[l]]][[2]];

(* Scale the coefficient matrix *)
matUScaled = Table[
  mat1[[i, j]] * u^(-(kList[[i]] + kList[[j]])/2),
  {i, 1, l}, {j, 1, l}
];

(* Reconstruct cvU *)
cvUReconstructed = matUScaled . (b /@ Range[l]);
solUReconstructed = Thread[Rule[c /@ Range[l], cvUReconstructed]];

(* Compare the final projection tensors *)
projUOrig = tpU[[1]];
projURecon = Normal[CoefficientArrays[cvUReconstructed . tensor, b /@ Range[l]]][[2]];

diff = projUOrig - projURecon // Expand // Simplify;
Print["Max difference: ", Max[Abs[diff /. {d -> 4, u -> 2}]]];
Print["Are the reconstructed projection tensors algebraically identical? ", diff === Table[0, {l}]];
