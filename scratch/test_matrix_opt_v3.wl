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

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
perm = {2, 1, 3, 4};
loops = {5, 6, 7, 8};
order = 4;

intCase = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
{topOverall, top1, top2} = exp[[1]];
topArray = {top1, top2};
result = Flatten[ToTensorProduct[#, topOverall, top1, top2, "check" -> False] & /@ (exp[[2]]), 1];

commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];

k = 4034;
i = 2; (* Topology 2 *)

vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;

(* Let's run GenTensorProjection manually to get the mat and basis_monomials *)
tensorBasis = MPartition[tem, p];
l = Length[tensorBasis];
bv = b /@ Range[l];
cv = c /@ Range[l];
sys = Table[
  ((tensorBasis[[i]]*(cv . tensorBasis) // Expand) /. {d2[1, p] -> u}) == bv[[i]], 
  {i, 1, l}
];
sol = Flatten[Solve[sys, cv]];

tMat = SessionTime[];
(* mat is cv /. sol as a coefficient array with respect to bv *)
mat = Normal[CoefficientArrays[cv /. sol, bv]][[2]];
Print["Matrix extraction took ", SessionTime[] - tMat, "s"];
Print["Matrix dimensions: ", Dimensions[mat]];

(* Original tpRaw[[1]] is Transpose[mat] . tensorBasis *)
tpRaw1 = Transpose[mat] . tensorBasis;

(* Check if tpRaw1 matches what we get from cache or original GenTensorProjection *)
tpRawFromGen = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
Print["Does manual Transpose[mat].tensorBasis match GenTensorProjection output? ", tpRaw1 === tpRawFromGen[[1]]];
Print["If False, check difference at D->4: ", (tpRaw1 /. D -> 4) === (tpRawFromGen[[1]] /. D -> 4)];

(* Let's run the contraction using the new optimized method *)
If[i == 2, 
  mat = mat /. {u -> 1, p -> 3};
  tensorBasis = tensorBasis /. {p -> 3};
, 
  mat = mat /. {p -> 2};
  tensorBasis = tensorBasis /. {p -> 2};
];

flag = FindTensor[tem, record];
If[flag[[1]],
  rep = flag[[2]];
  tp = flag[[3]];
,
  rep = {};
  tp = tpRawFromGen;
];

temExpr = (result[[k, i + 1]]*(tp[[2]]) /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;

temp = Reap[
  Do[
    tem1 = temExpr[[j]] // Expand;
    If[Head[tem1] === Plus, tem1List = List @@ tem1, tem1List = {tem1}];
    Sow[Plus @@ Reap[
      Do[
        tem2 = ClassifyTopology[tem1List[[l]], topArray[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
        Sow[Times @@ Take[tem2, 3]]
      , {l, 1, Length[tem1List]}]
    ][[2, 1]]]
  , {j, 1, Length[temExpr]}]
][[2, 1]];

glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
repG = AssociationMap[h[Hash[#]] &, glist];
tempHashed = temp /. repG;

tOpt = SessionTime[];
(* Optimized contraction: coeffHashed = tempHashed . Transpose[mat] *)
(* Wait! Is it tempHashed . Transpose[mat] or mat . tempHashed? *)
(* Let's test both and compare. *)
coeffHashed = tempHashed . Transpose[mat];
(* Multiply by tensorBasis *)
temlistOpt = Table[coeffHashed[[j]] * tensorBasis[[j]], {j, 1, Length[tensorBasis]}];
(* Replace dummy indices with actual indices *)
temlistOptActual = temlistOpt /. rep;
Print["Optimized contraction took ", SessionTime[] - tOpt, "s"];

(* Compare with the original slow method *)
tSlow = SessionTime[];
tpRaw1Replaced = tp[[1]] /. {u -> 1, p -> 3};
resDummy = (tempHashed) . tpRaw1Replaced;
resActual = resDummy /. rep;
tensor = Variables[tpRaw1Replaced] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
tensorActual = tensor /. rep;
temlistSlow = resActual // MonomialList[#, tensorActual] &;
Print["Original slow contraction (with G-hashing) took ", SessionTime[] - tSlow, "s"];

Print["Are the two lists of monomials identical? ", temlistOptActual === temlistSlow];
Print["If not identical, is the Total identical? ", Expand[Total[temlistOptActual] - Total[temlistSlow]] === 0];
Print["Optimized list: ", Short[temlistOptActual, 5]];
Print["Slow list:      ", Short[temlistSlow, 5]];
