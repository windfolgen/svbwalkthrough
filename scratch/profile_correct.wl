(* ::Package:: *)

$HistoryLength = 0;
runDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/fourloopI42";
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];

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
exp = RegionExpand[intCase, loops, "order" -> order, "check" -> True];
{top, top1, top2} = exp[[1]];
Print["Performing ToTensorProduct..."];
result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];
Print["Total terms: ", Length[result]];

(* Load record *)
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], {}];
If[Not[ListQ[record]], record = {}];
Print["Loaded record of length: ", Length[record]];

(* Profile terms 4030 to 4040 *)
Do[
  t0 = SessionTime[];
  
  vclist = {Cases[{result[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{result[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  Do[
    If[vclist[[i]] === {}, Continue[]];
    tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    
    (* Find or generate tensor projection *)
    flag = FindTensor[tem, record];
    If[flag[[1]],
      tp = flag[[3]];
    ,
      tGen = SessionTime[];
      tp = GenTensorProjection[tem, vecP, "krep" -> {d2[1, vecP] -> u}];
      Print["    [GEN TENSOR] term ", k, " top ", i, " took ", SessionTime[] - tGen, "s"];
      AppendTo[record, {Length /@ tem, tem, tp}];
    ];
    
    If[i == 2, tp = tp /. {u -> 1, vecP -> 3}, tp = tp /. {vecP -> 2}];
    
    temExpr = (result[[k, i + 1]]*tp[[2]] /. {vecP -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])} // Expand;
    
    If[Head[temExpr] === Plus, temList = List @@ temExpr, temList = {temExpr}];
    
    Do[
      tem1 = temList[[j]] // Expand;
      If[Head[tem1] === Plus, tem1List = List @@ tem1, tem1List = {tem1}];
      Do[
        t1 = SessionTime[];
        tem2 = ClassifyTopology[tem1List[[l]], top[[i]], i, "loops" -> result[[k, -1, i]], "ClassifySub" -> False];
        dtClass = SessionTime[] - t1;
        
        t2 = SessionTime[];
        checkVal = Times @@ Take[tem2, 3];
        dtCheck = 0.0;
        If[checkVal =!= 0,
          checkVal = (checkVal /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])}) - tem1List[[l]] // Factor;
          dtCheck = SessionTime[] - t2;
        ];
        
        If[dtClass > 0.01 || dtCheck > 0.01,
          Print["      [SLOW] term ", k, " top ", i, " subterm ", l, " Classify: ", dtClass, "s, Check: ", dtCheck, "s"];
        ];
      , {l, 1, Length[tem1List]}];
    , {j, 1, Length[temList]}];
  , {i, 1, 2}];
  
  dtTotal = SessionTime[] - t0;
  If[dtTotal > 0.1,
    Print["  Term ", k, " total time: ", dtTotal, "s"];
  ];
, {k, 4030, 4040}];

Print["Done profiling."];
