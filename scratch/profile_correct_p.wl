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
Print["=== Profiling Term ", k, " with correct vector p and optimized method ==="];
t0 = SessionTime[];
vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};

temlistOpt = Take[result[[k]], 3];
Do[
  If[vclist[[i]] === {}, Continue[]];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  
  tGen0 = SessionTime[];
  (* FindTensor using optimized method *)
  flag = Module[{temIndex, pos, rep},
    If[record === {}, Return[{False, {}, {}}]];
    temIndex = Length /@ tem;
    pos = Position[record[[All, 1]], temIndex, 1] // Flatten;
    If[pos === {},
      {False, {}, {}}
    ,
      rep = Thread@Rule[
        record[[pos[[1]], 2]] /. {vc[a_, b_] :> b} // Flatten,
        tem /. {vc[a_, b_] :> b} // Flatten
      ];
      {True, rep, record[[pos[[1]], 3]]}
    ]
  ];
  
  If[flag[[1]],
    rep = flag[[2]];
    tpRaw = flag[[3]];
    Print["  FindTensor found match in ", SessionTime[] - tGen0, "s"];
  ,
    tGen = SessionTime[];
    tpRaw = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
    Print["  GenTensorProjection took ", SessionTime[] - tGen, "s"];
    AppendTo[record, {Length /@ tem, tem, tpRaw}];
    flag = Module[{temIndex, pos, rep},
      temIndex = Length /@ tem;
      pos = Position[record[[All, 1]], temIndex, 1] // Flatten;
      rep = Thread@Rule[
        record[[pos[[1]], 2]] /. {vc[a_, b_] :> b} // Flatten,
        tem /. {vc[a_, b_] :> b} // Flatten
      ];
      {True, rep, record[[pos[[1]], 3]]}
    ];
    rep = flag[[2]];
    tpRaw = flag[[3]];
  ];
  
  If[i == 2, tpRaw = tpRaw /. {u -> 1, p -> 3}, tpRaw = tpRaw /. {p -> 2}];
  tp2Replaced = tpRaw[[2]] /. rep;
  
  tExp = SessionTime[];
  temExpr = (result[[k, i + 1]]*tp2Replaced /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
  Print["  Expansion of term took ", SessionTime[] - tExp, "s. Terms count: ", Length[temExpr]];
  
  tClass = SessionTime[];
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
  Print["  ClassifyTopology of all subterms took ", SessionTime[] - tClass, "s"];
  
  tensor = Variables[tpRaw[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
  tensorActual = tensor /. rep;
  
  revRep = Map[Reverse, rep];
  tempDummy = temp /. revRep;
  resDummy = tempDummy . tpRaw[[1]];
  resActual = resDummy /. rep;
  
  temlistOpt[[i + 1]] = resActual // MonomialList[#, tensorActual] &;
, {i, 1, 2}];

Print["Total time: ", SessionTime[] - t0, "s"];
