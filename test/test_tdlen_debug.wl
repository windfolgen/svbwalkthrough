$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym"}];

Print["Loading config..."];
Get[FileNameJoin[{rootDir, "config.wl"}]];

Print["Loading LiteRed2..."];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

Print["Loading bases..."];
Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

Print["Loading asym_new.wl..."];
Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

(* Load input for threeloophard1 *)
Print["Loading input..."];
inputPath = FileNameJoin[{rootDir, "runs", "threeloophard1", "input.wl"}];
Block[{integrand, leadingsingularity, ansatz, OrderY},
  Get[inputPath];
  testIntegrand = integrand;
];

perm = {1, 2, 3, 4};
Print["Applying permutation ", perm, " to integrand..."];
testIntegrandPermuted = testIntegrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};

Print["Running RegionExpand..."];
exp = RegionExpand[testIntegrandPermuted, {5, 6, 7}, "order" -> 3, "check" -> False];
{top, top1, top2} = exp[[1]];
result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];

Print["Result length: ", Length[result]];

(* Let's inspect all terms to find if any term produces a list-of-lists *)
cachePath = FileNameJoin[{asymDir, "tmp", "cache_tensor_record_noremove.mx"}];
recordGlobal = If[FileExistsQ[cachePath], Import[cachePath], {}];
Print["Loaded cache record length: ", Length[recordGlobal]];

Do[
  term = result[[k]];
  vclist = {
    Cases[{term[[2]]}, vc[__], Infinity] // DeleteDuplicates, 
    Cases[{term[[3]]}, vc[__], Infinity] // DeleteDuplicates
  };
  
  (* Run ProjectTensor logic on this single term *)
  Block[{temlist = Take[term, 3], record = recordGlobal, glist = {}, gtotal = {}, rep = Association[{}], tp, flag, tem, temp, tensor, hasNested = False},
    Do[
      If[vclist[[i]] === {},
        glist = Complement[Cases[{term[[i + 1]]}, _G, Infinity] // DeleteDuplicates, gtotal];
        If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
        gtotal = Join[gtotal, glist];
        temlist[[i + 1]] = {term[[i + 1]] /. rep};
        Continue[]
      ];
      
      tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;
      flag = FindTensor[tem, record];
      If[flag[[1]],
        tp = flag[[3]],
        tp = GenTensorProjection[tem, p, "krep" -> {d2[1, p] -> u}];
        AppendTo[record, {Length /@ tem, tem, tp}]
      ];
      If[i == 2, tp = tp /. {u -> 1, p -> 3}, tp = tp /. {p -> 2}];
      
      Block[{topLocal = {top1, top2}},
        tem = (term[[i + 1]] * tp[[2]] /. {p -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[topLocal[[i]], -a])} // Expand;
        
        temp = Reap[
          Do[
            tem1 = tem[[j]] // Expand;
            If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
            Sow[Plus @@ Reap[
              Do[
                tem2 = ClassifyTopology[tem1[[l]], topLocal[[i]], i, "loops" -> term[[-1, i]], "ClassifySub" -> False];
                If[tem2 === {0, 0, 0, $Failed}, Continue[]];
                Sow[Times @@ Take[tem2, 3]]
              , {l, 1, Length[tem1]}]
            ][[2, 1]]]
          , {j, 1, Length[tem]}]
        ][[2, 1]];
      ];
      
      glist = Complement[Cases[{temp}, _G, Infinity] // DeleteDuplicates, gtotal];
      If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
      gtotal = Join[gtotal, glist];
      
      tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
      
      dotProduct = (temp /. rep) . tp[[1]];
      If[k == 279,
        Print["[Term 279 top ", i, " debug]"];
        Print["  temp: ", InputForm[temp]];
        Print["  tp[[1]]: ", InputForm[tp[[1]]]];
        Print["  dotProduct: ", InputForm[dotProduct]];
        Print["  tensor: ", InputForm[tensor]];
      ];
      temlist[[i + 1]] = dotProduct // MonomialList[#, tensor] &;
      
      If[Depth[temlist[[i + 1]]] > 2,
        hasNested = True;
      ];
    , {i, 1, 2}];
    
    If[hasNested,
      Print["\n[NESTED LIST FOUND] Term: ", k];
      Print["vclist: ", vclist];
      Print["temlist[[2]] head: ", Head[temlist[[2]]], ", Depth: ", Depth[temlist[[2]]], ", Length: ", Length[temlist[[2]]]];
      Print["temlist[[2]] InputForm: ", InputForm[temlist[[2]]]];
      Print["temlist[[3]] head: ", Head[temlist[[3]]], ", Depth: ", Depth[temlist[[3]]], ", Length: ", Length[temlist[[3]]]];
      Print["temlist[[3]] InputForm: ", InputForm[temlist[[3]]]];
      
      (* Check if calling SpecialMultiply causes Thread::tdlen *)
      Print["Testing SpecialMultiply on this term..."];
      Quiet[
        Check[
          res = SpecialMultiply[temlist, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}];
          Print["SpecialMultiply succeeded: ", Short[InputForm[res], 5]];
        ,
          Print["SpecialMultiply FAILED with message!"];
        ]
      ];
    ];
  ];
, {k, 1, Length[result]}];

Print["Done scanning!"];
