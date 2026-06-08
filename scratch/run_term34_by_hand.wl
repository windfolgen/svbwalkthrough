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
record = Import[commonCache];

k = 4034;
tagp = p;
list = {result[[k]]};
len = Length[list];

Print["Starting ProjectTensor by hand..."];
Do[
  Print["Term 1/1 started"];
  temlist = Take[list[[kk]], 3];
  vclist = {Cases[{list[[kk, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{list[[kk, 3]]}, vc[__], Infinity] // DeleteDuplicates};
  
  Do[
    Print["  Topology ", i, " started"];
    If[vclist[[i]] === {},
      Print["    No tensor structure"];
      Continue[]
    ];
    
    tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
    
    tFind = SessionTime[];
    flag = FindTensor[tem, record];
    Print["    FindTensor took ", SessionTime[] - tFind, "s. Found? ", flag[[1]]];
    
    If[flag[[1]],
      tp = flag[[3]],
      
      tGen = SessionTime[];
      tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];
      Print["    GenTensorProjection took ", SessionTime[] - tGen, "s"];
      AppendTo[record, {Length /@ tem, tem, tp}];
    ];
    
    tRep = SessionTime[];
    If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
    Print["    Replacement in tp took ", SessionTime[] - tRep, "s"];
    
    tExpr = SessionTime[];
    temExpr = (list[[kk, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topArray[[i]], -a])} // Expand;
    Print["    temExpr expansion took ", SessionTime[] - tExpr, "s. Terms: ", Length[temExpr]];
    
    tClass = SessionTime[];
    temp = Reap[
      Do[
        tem1 = temExpr[[j]] // Expand;
        If[Head[tem1] === Plus, tem1List = List @@ tem1, tem1List = {tem1}];
        Sow[Plus @@ Reap[
          Do[
            tem2 = ClassifyTopology[tem1List[[l]], topArray[[i]], i, "loops" -> list[[kk, -1, i]], "ClassifySub" -> False];
            Sow[Times @@ Take[tem2, 3]]
          , {l, 1, Length[tem1List]}]
        ][[2, 1]]]
      , {j, 1, Length[temExpr]}]
    ][[2, 1]];
    Print["    ClassifyTopology loop took ", SessionTime[] - tClass, "s"];
    
    tCont = SessionTime[];
    glist = Cases[{temp}, _G, Infinity] // DeleteDuplicates;
    (* Wait! Is glist or rep definition correct here? *)
    (* In ProjectTensor, glist/rep/gtotal are global to ProjectTensor. *)
    (* Here we just use a local rep for simplicity. *)
    repLocal = AssociationMap[h[Hash[#]] &, glist];
    
    If[MatrixQ[tp[[1]]],
      Print["    MatrixQ is True. Performing mat . temp"];
      coeff = tp[[1]] . (temp /. repLocal);
      temlist[[i + 1]] = Table[coeff[[jj]] * tp[[2]][[jj]], {jj, 1, Length[tp[[2]]]}],
      
      Print["    MatrixQ is False. Performing MonomialList"];
      tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
      temlist[[i + 1]] = (temp /. repLocal) . tp[[1]] // MonomialList[#, tensor] &
    ];
    Print["    Contraction took ", SessionTime[] - tCont, "s"];
    
  , {i, 1, 2}];
  
  tMult = SessionTime[];
  resSpecial = SpecialMultiply[temlist, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}];
  Print["  SpecialMultiply took ", SessionTime[] - tMult, "s"];
  
, {kk, 1, len}];
Print["All done! Total time: ", SessionTime[] - t0, "s"];
