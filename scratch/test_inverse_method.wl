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

(* Original method *)
tpA = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> 1}];
tpA = tpA /. {p -> 2};
matA = tpA[[1]];

(* New direct Inverse method *)
tensor = MPartition[tem, p];
l = Length[tensor];
bv = b /@ Range[l];
cv = c /@ Range[l];
sys = Table[
  ((tensor[[i]]*(cv . tensor) // Expand) /. {d2[1, p] -> 1}) == bv[[i]], 
  {i, 1, l}
];
{rhs, lhsMat} = CoefficientArrays[sys[[All, 1]], cv];
matDirect = Inverse[Normal[lhsMat]];
matDirect = matDirect /. {p -> 2};

Print["Are the two matrices identical? ", Expand[matDirect - matA] === Table[0, {l}, {l}]];
