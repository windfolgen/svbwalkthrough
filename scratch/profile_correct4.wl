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
Print["Performing RegionExpand..."];
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> False];
{topOverall, top1, top2} = exp[[1]];
topArray = {top1, top2};

Print["Performing ToTensorProduct..."];
result = Flatten[ToTensorProduct[#, topOverall, top1, top2, "check" -> False] & /@ (exp[[2]]), 1];
Print["Total terms: ", Length[result]];

(* Load record *)
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];
Print["Loaded record of length: ", Length[record]];

(* Profile term 4030 *)
k = 4030;
Print["=== Profiling Term ", k, " ==="];
t0 = SessionTime[];

vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
Print["vclist: ", InputForm[vclist]];

Do[
  If[vclist[[i]] === {}, Continue[]];
  tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
  Print["Gathered loop indices top ", i, ": ", InputForm[tem]];
  
  tGen0 = SessionTime[];
  flag = FindTensor[tem, record];
  If[flag[[1]],
    tp = flag[[3]];
    Print["  FindTensor found match in ", SessionTime[] - tGen0, "s"];
  ,
    tGen = SessionTime[];
    tp = GenTensorProjection[tem, vecP, "krep" -> {d2[1, vecP] -> u}];
    Print["  GenTensorProjection took ", SessionTime[] - tGen, "s"];
    AppendTo[record, {Length /@ tem, tem, tp}];
  ];
  
  If[i == 2, tp = tp /. {u -> 1, vecP -> 3}, tp = tp /. {vecP -> 2}];
  
  tExp = SessionTime[];
  temExpr = (result[[k, i + 1]]*tp[[2]] /. {vecP -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
  Print["  Expansion of term took ", SessionTime[] - tExp, "s. Terms count: ", Length[temExpr]];
  
  tClass = SessionTime[];
  Do[
    tem1 = temExpr[[j]] // Expand;
    If[Head[tem1] === Plus, tem1List = List @@ tem1, tem1List = {tem1}];
    Do[
      tem2 = ClassifyTopology[tem1List[[l]], topArray[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
    , {l, 1, Length[tem1List]}];
  , {j, 1, Length[temExpr]}];
  Print["  ClassifyTopology of all subterms took ", SessionTime[] - tClass, "s"];
  
, {i, 1, 2}];

dtTotal = SessionTime[] - t0;
Print["Total time for term ", k, ": ", dtTotal, "s"];
