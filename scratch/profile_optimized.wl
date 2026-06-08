$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, vecP}, Vector, {u}, Number];
SetConstraints[{vecP}, sp[vecP, vecP] = u];
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
recordOrig = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[recordOrig]], recordOrig = {}];
recordOpt = recordOrig;

k = 4034; (* This is a slow term *)
Print["=== Profiling Term ", k, " (Original Method) ==="];
t0 = SessionTime[];
vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};

temlistOrig = Take[result[[k]], 3];
Do[
  If[vclist[[i]] === {}, Continue[]];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  flag = FindTensor[tem, recordOrig];
  If[flag[[1]],
    tp = flag[[3]];
  ,
    tp = GenTensorProjection[tem, vecP, "krep" -> {d2[1, vecP] -> u}];
    AppendTo[recordOrig, {Length /@ tem, tem, tp}];
    (* re-retrieve with FindTensor to simulate exact logic *)
    tp = FindTensor[tem, recordOrig][[3]];
  ];
  
  If[i == 2, tp = tp /. {u -> 1, vecP -> 3}, tp = tp /. {vecP -> 2}];
  
  temExpr = (result[[k, i + 1]]*tp[[2]] /. {vecP -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
  
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
  
  tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
  temlistOrig[[i + 1]] = temp . tp[[1]] // MonomialList[#, tensor] &;
, {i, 1, 2}];
Print["Original method took: ", SessionTime[] - t0, "s"];


Print["=== Profiling Term ", k, " (Optimized Method) ==="];
t1 = SessionTime[];

(* Optimized FindTensor that does NOT apply /. rep to matrix *)
FindTensorOpt[tensor_, rec_] := Module[
  {temIndex, pos, rep},
  If[rec === {}, Return[{False, {}, {}}]];
  temIndex = Length /@ tensor;
  pos = Position[rec[[All, 1]], temIndex, 1] // Flatten;
  If[pos === {}, Return[{False, {}, {}}]];
  rep = Thread@Rule[
    rec[[pos[[1]], 2]] /. {vc[a_, b_] :> b} // Flatten,
    tensor /. {vc[a_, b_] :> b} // Flatten
  ];
  Return[{True, rep, rec[[pos[[1]], 3]]}] (* Return raw tp without /. rep *)
];

temlistOpt = Take[result[[k]], 3];
Do[
  If[vclist[[i]] === {}, Continue[]];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  flag = FindTensorOpt[tem, recordOpt];
  If[flag[[1]],
    rep = flag[[2]];
    tpRaw = flag[[3]];
  ,
    tpRaw = GenTensorProjection[tem, vecP, "krep" -> {d2[1, vecP] -> u}];
    AppendTo[recordOpt, {Length /@ tem, tem, tpRaw}];
    (* retrieve again *)
    flag = FindTensorOpt[tem, recordOpt];
    rep = flag[[2]];
    tpRaw = flag[[3]];
  ];
  
  (* Apply vecP replacement to tpRaw (very fast symbol replacement) *)
  If[i == 2, tpRaw = tpRaw /. {u -> 1, vecP -> 3}, tpRaw = tpRaw /. {vecP -> 2}];
  
  (* Apply rep to tpRaw[[2]] (monomials only, very fast) *)
  tp2Replaced = tpRaw[[2]] /. rep;
  
  temExpr = (result[[k, i + 1]]*tp2Replaced /. {vecP -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
  
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
  
  tensor = Variables[tpRaw[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
  tensorActual = tensor /. rep;
  
  revRep = Map[Reverse, rep];
  tempDummy = temp /. revRep;
  resDummy = tempDummy . tpRaw[[1]];
  resActual = resDummy /. rep;
  
  temlistOpt[[i + 1]] = resActual // MonomialList[#, tensorActual] &;
, {i, 1, 2}];
Print["Optimized method took: ", SessionTime[] - t1, "s"];

Print["Are results identical? ", temlistOrig === temlistOpt];
