(* scratch/profile_chunk5.wl *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/";
asymDir = FileNameJoin[{rootDir, "asym"}];
Get[FileNameJoin[{rootDir, "config.wl"}]];
If[!MemberQ[$Packages, "LiteRed`"], Get["LiteRed2`"]];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression["LiteRed2`" <> b]]];
, {b, $LiteRedBases}];
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

integrand = (x[1,7] x[2,4] x[3,4] x[5,6])/(x[1,5] x[1,6] x[2,5] x[2,7] x[3,6] x[3,7] x[4,5] x[4,6] x[4,8] x[5,7] x[5,8] x[6,7] x[6,8] x[7,8]);
loops = {5, 6, 7, 8};
order = 4;

perm = {2, 1, 3, 4}; (* permutation 2134 *)
int1 = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};
exp1 = RegionExpand[int1, loops, "order" -> order, "check" -> True];
{topVal, top1, top2} = exp1[[1]];
result1 = Flatten[ToTensorProduct[#, topVal, top1, top2, "check" -> True] & /@ (exp1[[2]]), 1];

list = result1[[4001;;5000]];
top = {top1, top2};
tagp = p;
gtotal = {};
rep = Association[{}];

(* We will also load the MX cache to simulate the real run *)
commonDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/tmp/";
commonCache = FileNameJoin[{commonDir, "cache_tensor_record_noremove.mx"}];
record = If[FileExistsQ[commonCache], Import[commonCache], <||>];
record = toAssoc[record];

mrep = {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y};

Print["=== Profiling Chunk 5 (Terms 4001-5000) ==="];
slowTermsCount = 0;

Do[
  k = 4000 + idx;
  tTerm = SessionTime[];
  
  temlist = Take[list[[idx]], 3];
  vclist = {Cases[{list[[idx, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{list[[idx, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  Do[
    If[vclist[[i]] === {}, Continue[]];
    tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    
    flag = FindTensor[tem, record];
    If[flag[[1]],
      tp = flag[[3]],
      tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];
      AssociateTo[record, Length /@ tem -> {tem, tp}]
    ];
    
    If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
    
    temVal = (list[[idx, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])} // Expand;
    
    temp = Reap[
       Do[
        tem1 = temVal[[j]] // Expand;
        If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
        Sow[Total @ Reap[
            Do[
             tem2 = ClassifyTopology[tem1[[l]], top[[i]], i, "loops" -> list[[idx, -1, i]], "ClassifySub" -> False];
             If[tem2 === {0, 0, 0, $Failed}, Sow[0]; Continue[]];
             Sow[Times @@ Take[tem2, 3]]
            , {l, 1, Length[tem1]}]
           ][[2, 1]]]
       , {j, 1, Length[temVal]}]
    ][[2, 1]];
    
    glist = Complement[Cases[{temp}, _G, Infinity] // DeleteDuplicates, gtotal];
    If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
    gtotal = Join[gtotal, glist];
    
    dist = Distribute[(temp /. rep) . tp[[1]], Plus];
    temlist[[i + 1]] = If[Head[dist] === Plus, List @@ dist, {dist}];
  , {i, 1, 2}];
  
  res = SpecialMultiply[temlist, h, mrep];
  
  dt = SessionTime[] - tTerm;
  If[dt > 1.0,
    Print["[SLOW] Term ", k, " took ", dt, "s"];
    slowTermsCount++;
  ];
  If[Mod[idx, 100] == 0,
    Print["Progress: ", idx, "/1000 terms done. Cumulative slow terms: ", slowTermsCount];
  ];
, {idx, 1, Length[list]}];

Print["Done profiling! Total slow terms (>1s): ", slowTermsCount];
