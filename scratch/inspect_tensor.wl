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

tGen0 = SessionTime[];
flag = Module[{temIndex, pos, rep},
  If[record === {},
    {False, {}, {}}
  ,
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

Print["=== tpRaw properties ==="];
Print["Length[tpRaw]: ", Length[tpRaw]];
Print["Head[tpRaw[[1]]]: ", Head[tpRaw[[1]]]];
Print["Dimensions[tpRaw[[1]]]: ", Dimensions[tpRaw[[1]]]];
Print["Length[tpRaw[[1]]]: ", Length[tpRaw[[1]]]];
Print["Short[tpRaw[[1]], 5]:"];
Print[Short[tpRaw[[1]], 5]];

Print["Head[tpRaw[[2]]]: ", Head[tpRaw[[2]]]];
Print["Length[tpRaw[[2]]]: ", Length[tpRaw[[2]]]];
Print["Short[tpRaw[[2]], 5]:"];
Print[Short[tpRaw[[2]], 5]];

tp2Replaced = tpRaw[[2]] /. rep;
temExpr = (result[[k, i + 1]]*tp2Replaced /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;

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

Print["=== temp properties ==="];
Print["Length[temp]: ", Length[temp]];
Print["Short[temp, 5]:"];
Print[Short[temp, 5]];

glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
repG = AssociationMap[h[Hash[#]] &, glist];
tempHashed = temp /. repG;

Print["=== tempHashed properties ==="];
Print["Length[tempHashed]: ", Length[tempHashed]];
Print["Short[tempHashed, 5]:"];
Print[Short[tempHashed, 5]];

revRep = Map[Reverse, rep];
tempDummy = tempHashed /. revRep;
resDummy = tempDummy . tpRaw[[1]];

Print["=== resDummy properties ==="];
Print["Head[resDummy]: ", Head[resDummy]];
Print["Short[resDummy, 5]:"];
Print[Short[resDummy, 5]];

resActual = resDummy /. rep;
Print["=== resActual properties ==="];
Print["Head[resActual]: ", Head[resActual]];
Print["Short[resActual, 5]:"];
Print[Short[resActual, 5]];

tensor = Variables[tpRaw[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
tensorActual = tensor /. rep;
Print["=== tensorActual properties ==="];
Print["Length[tensorActual]: ", Length[tensorActual]];
Print[tensorActual];
