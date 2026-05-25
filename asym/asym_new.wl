filepath = DirectoryName[$InputFileName];

(*the functions for asymptotic expansion*)
ClearAll[d, d2, invd2];
SetAttributes[{d, d2, invd2}, {Orderless}];
d2[a_, a_] := 0;
d[a_, a_] := d2[a, 1];

ClearAll[vc, g];
SetAttributes[{g}, {Orderless}];
vc /: vc[a_, m_]*vc[b_, m_] := d[a, b];
vc /: Power[vc[a_, m_], 2] := d2[a, 1];
g /: g[m_, n_]*vc[a_, m_] := vc[a, n];
g /: g[m_, n_]*g[n_, l_] := g[m, l];
g /: Power[g[m_, n_], 2] := D;
g[a_, a_] := D;


Options[ClassifyTopology] = {"loops" -> {}, "ClassifySub" -> True, "subloops" -> {}, "resetconst" -> False, "deBug" -> False};
(*the loop momenta in subloops specify one of the factorized 2-point integral family*)
ClassifyTopology[exp_, list_, tag_, OptionsPattern[]] := 
  Module[{const, den, num, init, pos, tem, tem1, tensor, i, l, loops, subloops, mask},
   loops = OptionValue["loops"];
   subloops = If[OptionValue["ClassifySub"], OptionValue["subloops"], OptionValue["loops"]];
   If[loops === {}, Return[{1, 1, 1}]];
   If[OptionValue["ClassifySub"] && subloops === {}, Return[{1, 1, 1}]];
   mask = Table[If[IntersectingQ[List@@list[[i]],subloops],1,0],{i,1,Length[list]}];
   {num, den} = NumeratorDenominator[exp // Factor];
   tem = CoefficientRules[num,list];
   If[tem === {}, Return[{0, 0, 0, $Failed}]];
   tem1 = CoefficientRules[den,list];
   If[Length[tem]>1 || Length[tem1]>1,Print["numerator or denominator expected to be monomial!"];Return[$Failed]];
   init = tem1[[1,1]]-tem[[1,1]];
   init = init * mask; (*mask will keep those relevant to subloops*)
   const = tem[[1,2]]/tem1[[1,2]];(*remaining terms that can not be described by scalar integrals*)
   
   If[Union[init] === {0}, Return[{0, 0, 0, $Failed}]];
   pos = Position[init, _?(# > 0 &), 1] // Flatten;
   If[OptionValue["deBug"], Print["pos: ", pos]];
   If[AnyTrue[subloops, (Count[Table[FreeQ[list[[pos[[i]]]], #], {i, 1, Length[pos]}], False] < 2) &], Return[{0, 0, 0, 0}]];(*scaleless integrals*)
   
   If[const === 0, Return[{0, 0, 0, $Failed}]];
   tensor = const/(const/.{d[__]->1})//Cancel; (*extract the d[,] structures in the numerator*)
   const = const/tensor//Cancel;(*the remaining constant term*)
 
   If[OptionValue["resetconst"],(*if we need to reset the constant term*)
    (*If[(const) =!= 1, Print["Warning: the constant in topology ", tag, " has been reset to 1! The original expression is ", const]];*)
    Return[{1, G[tag, init], tensor, {OptionValue["subloops"], Complement[OptionValue["loops"], OptionValue["subloops"]]}}],
    Return[{const, G[tag, init], tensor, {OptionValue["subloops"], Complement[OptionValue["loops"], OptionValue["subloops"]]}}]];
   ];


Options[RegionExpand] = {"order" -> 4, "deBug" -> False, "check" -> False, "keepr" -> False};
RegionExpand[oint_, loops_, OptionsPattern[]] := 
  Module[{int, intl, den, num, subset = {}, rep, result = 0, pos, com, tem, tem1, tem2, top, top1, top2, check, start, i, j},
   Print["set 1 to 0, 4 to infinity."];
   Print["performing region expansion..."];
   start = SessionTime[];
   intl=oint//Expand;
   If[Head[intl]===Plus, intl = List@@intl, intl = {intl}];
   top = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 2], d2[loops[[i]], 3]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   top1 = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 2]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   top2 = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 3]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   kinRep = {invd2[a_, b_] :> 1/d2[a, b], d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v};
   Print["topology: ", top, " can be split into"];(*Print["topology 2: ",top2];*)
   Print["topo1: ", top1]; Print["topo2: ", top2];
   subset = Tuples[{0, 1}, Length[loops]];
   result = Reap[
        Do[
            int = intl[[k]]//Factor;
            den = Denominator[int] /. {x -> invd2};
            num = Numerator[int] /. {x -> d2};
            If[Head[num] === Times, num = List @@ num, num = {num}];
            If[Head[den] === Times, den = List @@ den, den = {den}];
            num = DeleteCases[num, _?(! FreeQ[#, d2[_,4]] &)];
            den = DeleteCases[den, _?(! FreeQ[#, invd2[_,4]] &)];
            If[OptionValue["deBug"], Print["den: ", den]; Print["num: ", num]];
            Print["Loops: ", Subscript[x, #] & /@ loops, ". There are totally ", Power[2, Length[loops]], " regions."];
            Print["classifying topologies: "];
            Do[
                pos = Position[subset[[i]], 0, 1] // Flatten;
                com = Complement[loops, loops[[pos]]];
                rep = {
                    invd2[a_ /; (MemberQ[loops[[pos]], a]), 3] :> Sum[Power[r (2 d[3, a] - d2[a, 1]), n]/Power[d2[3, 1], n + 1], {n, 0, OptionValue["order"]}],
                    invd2[a_ /; (MemberQ[com, a]), 2] :> Sum[Power[r (2 d[2, a] - d2[2, 1]), n]/Power[d2[a, 1], n + 1], {n, 0, OptionValue["order"]}],
                    invd2[a_ /; (MemberQ[loops[[pos]], a]), b_ /; (MemberQ[com, b])] :> Sum[Power[r (2 d[b, a] - d2[a, 1]), n]/Power[d2[b, 1], n + 1], {n, 0, OptionValue["order"]}]
                };
                tem = (Normal[Series[(((Times @@ den)*(Times @@ num) /. rep) //. kinRep), {r, 0, OptionValue["order"]}]] // Expand);
                If[Head[tem] === Plus, 
                    tem = List @@ tem // Factor,
                    tem = {tem} // Factor;
                ];
                If[OptionValue["deBug"], Print["tem: ", tem]];
                If[Not@OptionValue["keepr"], tem = tem /. {r -> 1}];
                Print["region ", i, ": total terms ", Length[tem]];
                
                Do[
                    tem1 = ClassifyTopology[tem[[j]], top, 1, "loops" -> loops, "subloops" -> loops[[pos]], "ClassifySub" -> False];
                    If[tem1 === {0, 0, 0, $Failed}, Print["this term cannot be classified: ", {tem[[j]], loops[[pos]], com}]; Continue[]];
                    If[tem1[[1]] === 0, Continue[]];
                    If[OptionValue["check"],
                        (*self consistency check*)
                        check = (Times @@ Take[tem1, 3] /. {G[_, a_] :> Times @@ (Thread@Power[top, -a])}) - tem[[j]] // Factor;
                        If[check =!= 0, Print["Not consistent! check the result: ", tem[[j]]]; Sow[$Failed]; Continue[]];
                    ];
                    Sow[tem1]
                , {j, 1, Length[tem]}]
            , {i, 1, Length[subset]}]
        ,{k,1,Length[intl]}];
    ][[2]];
   
   Return[{{top,top1,top2},result[[1]]}];
];

(*this function is used to split the tensor structure out of numerator*)
Options[NumToTensor] = {"deBug" -> False, "check" -> False};
NumToTensor[num_, tag_, {loops1_List,loops2_List}, OptionsPattern[]] := 
  Module[{list, counter = 1, const, t1 = {}, t2 = {}, t0 = {}, tem, tem1, k, listi, pow, result},
   If[Head[num] === Times, list = List @@ num, list = {num}];
   const = Times @@ DeleteCases[list, _?(Not@FreeQ[#, d | d2] &)];
   t0 = {const};(*constant term*)
   list = Cases[list, _?(Not@FreeQ[#, d | d2] &)];(*related to loop momenta*)
   If[OptionValue["deBug"], Print["list: ", list]];
   Do[
    If[Head[list[[i]]] === d2 || MatchQ[list[[i]], Power[d2[__], _]],
     If[Head[list[[i]]] === d2, listi = list[[i]]; pow = 1, listi = list[[i, 1]]; pow = list[[i, 2]]];
     If[OptionValue["deBug"], Print["d2 detected: ", {listi, pow}]];
     tem = Intersection[List @@ listi, #] & /@ {loops1, loops2};
     tem1 = Complement[List @@ listi, Join[loops1, loops2]];
     If[OptionValue["deBug"], Print["tem,tem1 ", {tem, tem1}]];
     If[tem1 =!= {1}, Print[" warning: there is one term in numerator that is ", list[[i]]]];(*there can only be d2[_,1] in the numerator due to the expansion we take*)
     If[tem[[1]] =!= {},
      k = 1;
      While[k <= pow,
       t1 = Join[t1, {vc[tem[[1, 1]], tag[counter]], vc[tem[[1, 1]], tag[counter + 1]]}];
       AppendTo[t0, g[tag[counter], tag[counter + 1]]];
       counter += 2;
       k = k + 1;
       ],
      If[tem[[2]] =!= {},
       k = 1;
       While[k <= pow,
        t2 = Join[t2, {vc[tem[[2, 1]], tag[counter]], vc[tem[[2, 1]], tag[counter + 1]]}];
        AppendTo[t0, g[tag[counter], tag[counter + 1]]];
        counter += 2;
        k = k + 1;
        ],
       AppendTo[t0, list[[i]]]
       ]
      ],
     If[Head[list[[i]]] === d || MatchQ[list[[i]], Power[d[__], _]],
      If[Head[list[[i]]] === d, listi = list[[i]]; pow = 1, listi = list[[i, 1]]; pow = list[[i, 2]]];
      If[OptionValue["deBug"], Print["d detected: ", {listi, pow}]];
      tem = Intersection[List @@ listi, #] & /@ {loops1, loops2};
      tem1 = Complement[List @@ listi, Join[loops1, loops2]];
      If[OptionValue["deBug"], Print["tem,tem1 ", {tem, tem1}]];
      If[tem[[1]] === {} && tem[[2]] === {},
       AppendTo[t0, list[[i]]],
       If[tem[[1]] === {} && tem1 === {},
        k = 1;
        While[k <= pow,
         t2 = Join[t2, {vc[tem[[2, 1]], tag[counter]], vc[tem[[2, 2]], tag[counter + 1]]}];
         AppendTo[t0, g[tag[counter], tag[counter + 1]]];
         counter += 2;
         k = k + 1;
        ],
        If[tem[[2]] === {} && tem1 === {},
         k = 1;
         While[k <= pow,
          t1 = Join[t1, {vc[tem[[1, 1]], tag[counter]], vc[tem[[1, 2]], tag[counter + 1]]}];
          AppendTo[t0, g[tag[counter], tag[counter + 1]]];
          counter += 2;
          k = k + 1;
         ],
         If[tem1 === {},
          k = 1;
          While[k <= pow,
           t1 = Join[t1, {vc[tem[[1, 1]], tag[counter]]}];
           t2 = Join[t2, {vc[tem[[2, 1]], tag[counter + 1]]}];
           AppendTo[t0, g[tag[counter], tag[counter + 1]]];
           counter += 2;
           k = k + 1;
          ],
          If[tem[[1]] === {},
           k = 1;
           While[k <= pow,
            t2 = Join[t2, {vc[tem[[2, 1]], tag[counter]]}];
            AppendTo[t0, vc[tem1[[1]], tag[counter]]];
            counter += 1;
            k = k + 1;
           ],
           k = 1;
           While[k <= pow,
            t1 = Join[t1, {vc[tem[[1, 1]], tag[counter]]}];
            AppendTo[t0, vc[tem1[[1]], tag[counter]]];
            counter += 1;
            k = k + 1;
           ]
          ]
         ]
        ]
       ]
      ];
     ]
    ]
   , {i, 1, Length[list]}];
   result = {Times @@ t0, Times @@ t1, Times @@ t2};
   If[OptionValue["check"],
    If[((Times @@ result // Expand) - num // Factor) =!= 0, Print["the numerator is not right!: ", {num, result}]]
   ];
   result
  ];

(*tranform the scalar integrand to two topologies*)
Options[ToTensorProduct] = {"deBug" -> False, "check" -> False};
ToTensorProduct[list_, top_, top1_, top2_, OptionsPattern[]] := 
  Module[{loops, loop1, loop2, exp, tem, tem1, temden, temnum, result,
     check, zeroterm = {}},
   loops = list[[-1]] // Flatten // Sort;
   loop1 = list[[-1, 1]];
   loop2 = list[[-1, 2]];
   If[OptionValue["deBug"], Print["loops: ", loops]];
   exp = list[[3]]*Product[Power[top[[i]], -list[[2, 2, i]]], {i, 1, Length[top]}] // Factor;(*the expression to be reduced*)
   If[OptionValue["deBug"], Print["exp: ", exp]];
   tem = (Numerator[exp] /. {d2[a_ /; (MemberQ[Join[loop1, {2}], a]), b_ /; (MemberQ[Join[loop2, {3}], b])] :> d2[a, 1] + d2[b, 1] - 2 d[a, b]} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0})/Denominator[exp] // Expand;
   If[Head[tem] === Plus, tem = (List @@ tem) // Factor, tem = {tem}];
   result = Reap[
      Do[
       temden = 1/Denominator[tem[[i]]];
       temnum = Numerator[tem[[i]]];
       If[Head[temnum] === Times, temnum = List @@ temnum, temnum = {temnum}];
       tem1 = Times @@ Cases[temnum, _?(Not@FreeQ[#, d2] &)];(*d2 in numerator*)
       temden = tem1*temden;(*temden will only contain terms relevant to loop momenta*)
       temnum = Numerator[tem[[i]]]/tem1 // Factor;(*remaining terms in numerator*)
       temnum = NumToTensor[temnum, m, {loop1,loop2}];
       temden = {list[[1]], Times @@ (ClassifyTopology[temden, top1, 1, "loops" -> loops,"subloops" -> loop1, "resetconst" -> True][[{1, 2, 3}]]), Times @@ (ClassifyTopology[temden, top2, 2, "loops" -> loops,"subloops" -> loop2, "resetconst" -> True][[{1, 2, 3}]])};
       (*self consistency check*)
       check = (Times @@ (temden*temnum) /. {G[1, a_] :> Times @@ (Thread@Power[top1, -a])} /. {G[2, a_] :> Times @@ (Thread@Power[top2, -a])});
       If[check === 0, (*AppendTo[zeroterm, list[[1]]*tem[[i]]];*)Continue[]];(*cases where the integral vanishes due to scalelessness*)
       If[OptionValue["check"],
        check = check - list[[1]]*tem[[i]] // Factor;
        If[check =!= 0, Print["Not consistent! check the reason: ", list]; Sow[$Failed]; Continue[]];
        ];
       Sow[Append[temden*temnum, list[[-1]]]]
       , {i, 1, Length[tem]}]
      ][[2]];
   If[result =!= {}, result = result[[1]]];
   If[OptionValue["deBug"], Return[{result, zeroterm}], Return[result]];
  ];


DressTensor[list_, elem_, tag_] := Module[
  {ppart, remain, l, k = 1, start},
  ppart = vc[tag, #] & /@ elem;
  remain = Complement[list, elem];
  If[remain === {}, Return[{ppart}]];
  start = {#} & /@ Subsets[remain, {2}];
  l = Length[remain];
  While[Length[start[[1]] // Flatten] < l && k < 10,
    start = Table[
      Sort[Append[start[[i]], #]] & /@ Subsets[Complement[remain, start[[i]] // Flatten], {2}],
      {i, 1, Length[start]}
    ] // Flatten[#, 1] & // DeleteDuplicates;
    k = k + 1;
  ];
  Return[Table[Join[g @@@ start[[i]], ppart], {i, 1, Length[start]}]]
];

MPartition[olist_, tag_] := Module[
  {list, l, start, k, tem, perm, tem1},
  list = Flatten[olist];
  l = Length[list];
  If[OddQ[l],
    start = (Table[Subsets[list, {i}], {i, 1, l, 2}] // Flatten[#, 1] &),
    start = (Table[Subsets[list, {i}], {i, 0, l, 2}] // Flatten[#, 1] &)
  ];
  tem = Times @@@ Sort /@ ((DressTensor[list, #, tag] & /@ start) // Flatten[#, 1] &) // DeleteDuplicates;
  (* symmetrize the tensor *)
  tem1 = tem;
  Do[
    If[Length[olist[[k]]] > 1,
      perm = Thread@Rule[olist[[k]], #] & /@ Permutations[olist[[k]]];
      tem1 = Table[
        Sum[tem1[[i]] /. perm[[j]], {j, 1, Length[perm]}]/Length[perm] // Factor,
        {i, 1, Length[tem1]}
      ] // DeleteDuplicates;
    ],
    {k, 1, Length[olist]}
  ];
  Return[tem1]
];

Options[GenTensorProjection] = {"krep" -> {}, "outputrank" -> 0};
GenTensorProjection[indexlist_, tagp_, OptionsPattern[]] := Module[
  {tensor, l, b, bv, rep, c, cv, sys, sol, start},
  start = SessionTime[];
  tensor = MPartition[indexlist, tagp];
  l = Length[tensor];
  If[l > OptionValue["outputrank"], 
    Print["dimensions: ", l];
    Print["indexlist: ", indexlist]
  ];
  bv = b /@ Range[l];
  cv = c /@ Range[l];
  rep = Thread@Rule[bv, tensor];
  sys = Table[
    ((tensor[[i]]*(cv . tensor) // Expand) /. OptionValue["krep"]) == bv[[i]], 
    {i, 1, l}
  ];
  sol = Flatten[Solve[sys, cv]];
  If[l > OptionValue["outputrank"], 
    Print["time consuming: ", SessionTime[] - start]
  ];
  Return[{Normal[CoefficientArrays[cv . tensor /. sol, bv]][[2]] // Factor, tensor}]
];

FindTensor::usage = "FindTensor[tensor,record] finds a tensor structure in the list record.";
FindTensor[tensor_, record_] := Module[
  {tem, pos, rep},
  If[record === {}, Return[{False, {}}]];
  tem = Length /@ tensor;
  pos = Position[record[[All, 1]], tem, 1] // Flatten;
  If[pos === {}, Return[{False, {}}]];
  rep = Thread@Rule[
    record[[pos[[1]], 2]] /. {vc[a_, b_] :> b} // Flatten,
    tensor /. {vc[a_, b_] :> b} // Flatten
  ];
  Return[{True, rep, record[[pos[[1]], 3]] /. rep}]
];

(*SpecialMultiply[temlist_, h_, rep_] := Module[
  {i},
  If[Length[temlist[[2]]] > Length[temlist[[3]]],
    Return[Total[Reap[
      Do[
        Sow[(temlist[[1]]*temlist[[2, i]]*temlist[[3]] // Total // Expand) /. rep // Collect[#, _h, Together] &],
        {i, 1, Length[temlist[[2]]]}
      ]
    ][[2, 1]]] // Collect[#, h, Factor] &],
    Return[Total[Reap[
      Do[
        Sow[(temlist[[1]]*temlist[[3, i]]*temlist[[2]] // Total // Expand) /. rep // Collect[#, _h, Together] &],
        {i, 1, Length[temlist[[3]]]}
      ]
    ][[2, 1]]] // Collect[#, _h, Factor] &]
  ]
];*)
SpecialMultiply[temlist_, h_, rep_] := Module[
  {scalar, listA, listB, totalB},
  
  scalar = temlist[[1]];
  
  (* 1. Determine which list to iterate over to minimize loop overhead *)
  If[Length[temlist[[2]]] > Length[temlist[[3]]],
    listA = temlist[[2]]; 
    listB = temlist[[3]],
    
    listA = temlist[[3]]; 
    listB = temlist[[2]]
  ];
  
  (* 2. PRECOMPUTE the sum of the smaller list ONCE outside the loop *)
  totalB = Total[listB];
  
  (* 3. Map functionally instead of using Reap/Sow *)
  Total @ Map[
    (* Consider applying /. rep before Expand if your replacements reduce term size *)
    Collect[Expand[scalar * # * totalB] /. rep, _h, Together] &, 
    listA
  ] // Collect[#, _h, Factor] &
];


Options[ProjectTensor] = {"krep" -> {}, deBug -> False, "check" -> False, "chunksize" -> 1000, "dir" -> filepath<>"tmp/", "profile" -> False};
ProjectTensor[list_, tagp_, top1_, top2_, OptionsPattern[]] := 
  Module[{vclist, tem1, tem2, tp, record, flag, top, k, check, start, end, len, fresult, glist = {}, gtotal = {}, rep = Association[{}], revrep, tensor, t0, tGen, tExp, tClass, tCont, tMult},
   Print["projecting the tensor structure and performing the contraction..."];
   top = {top1, top2};
   record = {};(*record known tensor reduction*)
   (*we further split the results into smaller size*)
   len = Length[list];
   Print["total length: ",len," split into number of chunks: ",Quotient[len, OptionValue["chunksize"]] + 1];
   Do[
    start = 1 + (mm - 1)*OptionValue["chunksize"];
    end = Min[start + OptionValue["chunksize"] - 1, len];
    Print["--- ProjectTensor Chunk ", mm, "/", Quotient[len, OptionValue["chunksize"]] + 1, " (Terms ", start, "-", end, ") Time: ", SessionTime[] - 0., " ---"];
    Block[{result, tem, temp, temlist, t0, dt},
     result = Reap[
        Do[
          If[Mod[k, 100] == 0, Print["    Working on Term ", k, "/", len]];
          temlist = Take[list[[k]], 3];(*each element is {const,top1,top2}*)
          
          vclist = {Cases[{list[[k, 2]]}, vc[__], Infinity] // DeleteDuplicates, Cases[{list[[k, 3]]}, vc[__], Infinity] // DeleteDuplicates};(*extract tensor in two topologies*)
          
          If[OptionValue[deBug], Print["tensor structure: ", vclist]];
          Do[(*for every topology*)
           t0 = SessionTime[];
           If[vclist[[i]] === {},
            
            glist = Complement[Cases[{list[[k, i + 1]]}, _G, Infinity] // DeleteDuplicates, gtotal];
            
            If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
            gtotal = Join[gtotal, glist];
            temlist[[i + 1]] = {temlist[[i + 1]] /. rep};
            If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] NoTensor Setup took ", dt, "s on term ", k, " top ", i]];
            Continue[]
            ];(*no tensor to reduce*)
           
           tem = GatherBy[vclist[[i]], First] /. {vc[a_, b_] :> b} // SortBy[#, Length] &;(*Lorentz index structure*)
           
           flag = FindTensor[tem, record];(*find the tensor reduction results in record*)
           If[flag[[1]],
            tp = flag[[3]](*if it is known in record*),
            
            tp = GenTensorProjection[tem, tagp, "krep" -> {d2[1, tagp] -> u}];(*if it is not known in record, generate it*)
            AppendTo[record, {Length /@ tem, tem, tp}]];
           
           If[i == 2, tp = tp /. {u -> 1, tagp -> 3}, tp = tp /. {tagp -> 2}];
           
           If[OptionValue[deBug], Print["tp: ", tp]];(*in the second topology, the external legs are set to x13^2=1*)
           If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] GenTensor took ", dt, "s on term ", k, " top ", i]];
           
           t0 = SessionTime[];
           tem = (list[[k, i + 1]]*tp[[2]] /. {tagp -> (i + 1)} // Expand) /. {d[a_, b_] :> (d2[1, a] + d2[1, b] - d2[a, b])/2} /. {d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v, d[a_, 1] :> 0} /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])} // Expand;
           (*classify topology for every term*)
           
           If[Not@FreeQ[tem, vc | d], Print["something is wrong in the reduction!", list[[k, i + 1]], " tensor: ", tp[[2]]]];(*check the result*)
           If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] Expansion took ", dt, "s on term ", k, " top ", i]];
           
           t0 = SessionTime[];
           temp = Reap[
              Do[
               tem1 = tem[[j]] // Expand;
               
               If[Head[tem1] === Plus, tem1 = List @@ tem1, tem1 = {tem1}];
               Sow[Plus @@ Reap[
                   Do[
                    
                    tem2 = ClassifyTopology[tem1[[l]], top[[i]], i, "loops" -> list[[k, -1, i]], "ClassifySub" -> False];
                    
                    If[tem2 === {0, 0, 0, $Failed},(*Print["Check the reason!: this term has not been classified ",tem1[[l]]];*)Continue[]];
                    
                    If[OptionValue[deBug] && tem2 === {0, 0, 0, 0}, Print["This term is 0: ", tem1[[l]], " topology :", i]];
                    (*check the result*)
                    If[OptionValue["check"],
                        check = Times @@ Take[tem2, 3];
                    
                        If[check === 0, Sow[0];(*Print[
                        "the term is 0",{tem1[[l]],list[[k,-1,i]]}];*)
                        Continue[]];(*the scaleless case*)
                    
                        check = (check /. {G[i, a_] :> Times @@ (Thread@Power[top[[i]], -a])}) - tem1[[l]] // Factor;
                    
                        If[check =!= 0, Print["classification not consistent: ", {tem1[[l]], tem2}]];
                    ];
                    (*check the result*)
                    Sow[Times @@ Take[tem2, 3]]
                    , {l, 1, Length[tem1]}]
                   ][[2, 1]]]
               , {j, 1, Length[tem]}]
            ][[2, 1]];
           
           If[OptionValue[deBug], Print["tensor projection temp: ", temp]];
           If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] ClassifyTopology took ", dt, "s on term ", k, " top ", i]];
           
           t0 = SessionTime[];
           glist = Complement[Cases[{temp}, _G, Infinity] // DeleteDuplicates, gtotal];
           
           If[glist =!= {}, rep = Join[rep, AssociationMap[h[Hash[#]] &, glist]]];
           gtotal = Join[gtotal, glist];
           
           tensor = Variables[tp[[1]]] // DeleteCases[#, _?((Head[#] =!= vc && Head[#] =!= g) &)] &;
           
           temlist[[i + 1]] = (temp /. rep) . tp[[1]] // MonomialList[#, tensor] &;(*tensor reduction finished for one topology, replace G in order to reduce the memory consuming*)
           If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] Contraction took ", dt, "s on term ", k, " top ", i]];
           , {i, 1, 2}];
          
          If[OptionValue[deBug], Print["tensor projection result: ", temlist]];
          (*the multiplication between two topologies may involve huge terms of tensor products, we tackle it in a specific way*)
          
          t0 = SessionTime[];
          Sow[(SpecialMultiply[temlist, h, {d2[1, 3] -> 1, d2[2, 1] -> u, d2[2, 3] -> 1 - Y, d[a_, 1] :> 0, d[2, 3] -> (u + Y)/2, v -> 1 - Y}])]
          If[OptionValue["profile"] && (dt = SessionTime[] - t0) > 0.5, Print["    [SLOW] SpecialMultiply took ", dt, "s on term ", k]];
          , {k, start, end}]
        ][[2]];
        
     If[result =!= {}, result = result[[1]] // Total // Collect[#, _h, Factor] &];
     If[DirectoryQ[OptionValue["dir"]],
      Export[OptionValue["dir"] <> "tensor_" <> ToString[mm] <> ".mx", result],
      CreateDirectory[OptionValue["dir"]];
      Export[OptionValue["dir"] <> "tensor_" <> ToString[mm] <> ".mx", result]
      ];
    ];
    , {mm, 1, Quotient[len, OptionValue["chunksize"]] + 1}];
   revrep = AssociationMap[Reverse, rep];
   fresult = Table[Import[OptionValue["dir"] <> "tensor_" <> ToString[mm] <> ".mx"], {mm, 1, Quotient[len, OptionValue["chunksize"]] + 1}] /. revrep // Flatten;
   If[OptionValue[deBug], Return[{fresult, record}]];
   Return[fresult];
];


ClassifyGs::usage = "ClassifyGs[exp,topology] classify the integrals according to their involved loops.";
ClassifyGs[exp_, top_] := 
  Module[{glist, pos, loops, tem, len, result, loop1, loop2, rep = {}},
   glist = Cases[exp, G[_, {a__}] | G[a__] :> G[a], Infinity] // DeleteDuplicates;
   result = Reap[
       Do[
        pos = Position[glist[[i]], _?(# > 0 &), 1] // Flatten;
        loops = Complement[(List @@@ top) // Flatten // DeleteDuplicates, {1, 2, 3, 4}];
        loop1 = Complement[(List @@@ top[[pos]]) // Flatten // DeleteDuplicates // DeleteCases[#, _?(MemberQ[{1, 2, 3, 4}, #] &)] &, {1, 2, 3, 4}];
        loop2 = Complement[loops, loop1];(*irrelevant loop momenta*)
        pos = Position[IntersectingQ[#, loop2] & /@ (List @@@ top), True, 1];
        len = Length[pos];
        tem = Delete[glist[[i]], pos];
        Sow[tem, len];
        AppendTo[rep, Rule[glist[[i]], tem]];
        , {i, 1, Length[glist]}]
       ][[2]] // SortBy[#, Length[First[#]] &] &;
   Return[{rep // DeleteDuplicates, DeleteDuplicates /@ result}];
  ];
Options[CheckEpsOrder] = {"kernelnum" -> 4};
CheckEpsOrder[olist_, gtransform_, Grep_, basischange_, masterrep_, order_, OptionsPattern[]] := Module[{tem, result, pos},
   tem = olist[[1]] /. olist[[2]];
   LaunchKernels[OptionValue["kernelnum"]];
   result = ParallelTable[
     Block[{aexp},
      aexp = Series[(tem[[i]] /. gtransform /. {D -> 4 - 2 ep} /. Grep // Collect[#, _G] &) /. basischange /. masterrep, {ep, 0, 0}];
      If[Head[aexp] === SeriesData, 
       If[aexp[[-2]] > 0, Series[(aexp // Normal), {u, 0, 0}, {Y, 0, order}] // Normal, Null], aexp]
      ], {i, 1, Length[tem]}];
   CloseKernels[];(*close kernels to avoid memory consuming*)
    If[Not@FreeQ[result, Null],
     Print[Style["the order of epsilon is not enough!", Red]];
     pos = Position[result, Null, 1] // Flatten;
     Print["the following terms require higher order of epsilon: ", Short[tem[[pos]], 40]];
     Return[{}],
     Print[Style["SUCCESS: The epsilon order is completely sufficient for all regions!", Green]];
     Return[result];
     ]
];

(* RunAsymExpansion[intname, integrand, perm, order, loops]
   intname  : String, e.g. "I6tb", "d2"
   integrand: the integrand expression in terms of x[i,j] with external labels {1,2,3,4}
   perm     : List, e.g. {1,2,3,4}, {1,3,2,4}, ...
   order    : Integer, the expansion order (default 3)
   loops    : List of loop indices (default {5,6,7,8})
*)
RunAsymExpansion[intname_String, integrand_, perm_List, order_Integer:3, loops_List:{5, 6, 7, 8}] := Module[
    {name, int, starttime, exp, top, top1, top2, result, test,
     grep, glist, gtransform, basischange,
     trep, reducedg, target4L, target3L, target2L, target1L,
     trep4L, trep3L, trep2L, trep1L, trep1, trep2, Grep,
     Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L, Gmasterrep,
     fresult, fresults},

    name = intname <> StringJoin[ToString /@ perm];
    Print["=== Running ", name, " ==="];

    (* Apply the permutation to the integrand *)
    int = integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, perm])};

    (* Step 1: Tensor reduction (with caching) *)
    starttime = SessionTime[];
    If[FileExistsQ[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"],
        test = Import[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"];
        {top, top1, top2} = test[[1]];
        test = test[[2]];
        Print["tensor reduction results loaded! ", "time: ", SessionTime[] - starttime],
        Print["no tensor reduced results found ", "time: ", SessionTime[] - starttime];
        exp = RegionExpand[int, loops, "order" -> order, "check" -> True];
        Print["region expansion of integrand finished! ", "time: ", SessionTime[] - starttime];
        {top, top1, top2} = exp[[1]];
        result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];
        test = ProjectTensor[result, p, top1, top2, "check" -> True, "profile" -> True];
        Export[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m", {{top, top1, top2}, test}];
        Print["tensor reduction finished! ", "time: ", SessionTime[] - starttime];
    ];

    (* Step 2: Classify topologies *)
    {grep, glist} = ClassifyGs[test, top1];
    gtransform = Join[grep /. {G[a__] :> G[1, {a}]}, grep /. {G[a__] :> G[2, {a}]}] // Dispatch;
    basischange = Import[filepath <> "asym4LbasisChange.m"] // Dispatch;
    Print["basischange loaded!"];

    (* Step 3: IBP reduction (with caching) *)
    If[FileExistsQ[filepath <> "tmp/targetIntegrals_reduced.m"],
        trep = Import[filepath <> "tmp/targetIntegrals_reduced.m"];
        Print["reduced results loaded! ", "time: ", SessionTime[] - starttime];
        reducedg = Keys[trep],
        Print["no IBP reduced results found! ", "time: ", SessionTime[] - starttime];
        trep = {};
        reducedg = {};
    ];
    target4L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 14, {}] /. {G[a__] :> j[asym, a]};
    target3L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 9,  {}] /. {G[a__] :> j[asym3L, a]};
    target2L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 5,  {}] /. {G[a__] :> j[asym2L, a]};
    target1L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 2,  {}] /. {G[a__] :> j[asym1L, a]};

    trep4L = Thread@Rule[#, IBPReduce[#]] &[Complement[target4L, reducedg]];
    trep3L = Thread@Rule[#, IBPReduce[#]] &[Complement[target3L, reducedg]];
    trep2L = Thread@Rule[#, IBPReduce[#]] &[Complement[target2L, reducedg]];
    trep1L = Thread@Rule[#, IBPReduce[#]] &[Complement[target1L, reducedg]];
    trep = Join[trep, trep4L, trep3L, trep2L, trep1L];
    Export[filepath <> "tmp/targetIntegrals_reduced.m", trep];
    trep1 = trep /. {j[_, a__] :> G[1, {a}]} /. {d -> 4 - 2 ep};
    trep2 = trep /. {j[_, a__] :> G[2, {a}]} /. {u -> 1} /. {d -> 4 - 2 ep};
    Grep = Join[trep1, trep2] // Dispatch;
    Print["target integrals reduced! ", "time: ", SessionTime[] - starttime];

    (* Step 4: Series expansion *)
    Gmasterrep4L = Import[filepath <> "Gmaterrep4L.m"];
    Gmasterrep3L = Import[filepath <> "Gmaterrep3L.m"];
    Gmasterrep2L = Import[filepath <> "Gmaterrep2L.m"];
    Gmasterrep1L = Import[filepath <> "Gmaterrep1L.m"];
    Gmasterrep = Join[Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L] // Dispatch;
    fresult = Series[(test /. gtransform /. {D -> 4 - 2 ep} /. Grep // Collect[#, _G] &) /. basischange /. Gmasterrep, {u, 0, 0}];
    fresults = Series[((fresult // Total) + O[ep]) // Normal // Expand, {Y, 0, order}] // ExpandAll;

    Export[filepath <> "check" <> name <> "_order" <> ToString[order] <> "_asyexp.m", fresults];
    Print["series expansion finished ", "time: ", SessionTime[] - starttime];
    Print["=== Done ", name, " ==="];

    fresults
];

(* RunAsymExpansionParallel[intname, integrand, perms, order, loops]
   Performs asymptotic expansion for multiple permutations safely in parallel.
*)
RunAsymExpansionParallel[intname_String, integrand_, perms_List, order_Integer:3, loops_List:{5, 6, 7, 8}] := Module[
    {names, ints, starttime, testAll, topAll, top1All, top2All,
     greps = {}, grep, glist, gtransformAll, basischange,
     trep, reducedg, target4LAll = {}, target3LAll = {}, target2LAll = {}, target1LAll = {},
     trep4L, trep3L, trep2L, trep1L, trep1, trep2, Grep,
     Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L, Gmasterrep,
     fresults},

    names = (intname <> StringJoin[ToString /@ #]) & /@ perms;
    ints = (integrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, #])}) & /@ perms;

    Print["=== Running Parallel Expansion for ", intname, " with ", Length[perms], " permutations ==="];
    starttime = SessionTime[];

    (* Step 1: Parallel Tensor Reduction *)
    testAll = ParallelTable[
        Module[{exp, result, test, top, top1, top2, permDir},
            permDir = filepath <> "tmp/tensor_" <> names[[i]] <> "/";
            If[Not[DirectoryQ[permDir]], CreateDirectory[permDir]];
            
            If[FileExistsQ[filepath <> "tmp/tensor_" <> names[[i]] <> "_order" <> ToString[order] <> "_results.m"],
                test = Import[filepath <> "tmp/tensor_" <> names[[i]] <> "_order" <> ToString[order] <> "_results.m"];
                Print[names[[i]], ": tensor reduction results loaded!"];
                test
                ,
                Print[names[[i]], ": no tensor reduced results found. Starting reduction..."];
                exp = RegionExpand[ints[[i]], loops, "order" -> order, "check" -> True];
                {top, top1, top2} = exp[[1]];
                result = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ (exp[[2]]), 1];
                
                (* CRITICAL: pass unique dir to ProjectTensor so parallel workers do not overwrite each other's tmp chunks *)
                test = ProjectTensor[result, p, top1, top2, "check" -> True, "dir" -> permDir];
                Export[filepath <> "tmp/tensor_" <> names[[i]] <> "_order" <> ToString[order] <> "_results.m", {{top, top1, top2}, test}];
                Print[names[[i]], ": tensor reduction finished!"];
                {{top, top1, top2}, test}
            ]
        ], {i, 1, Length[perms]}
    ];
    
    top1All = testAll[[All, 1, 2]];
    testAll = testAll[[All, 2]];

    (* Step 2: Sequentially collect all target integrals via ClassifyGs *)
    Do[
        {grep, glist} = ClassifyGs[testAll[[i]], top1All[[i]]];
        AppendTo[greps, grep];
        
        target4LAll = Join[target4LAll, FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 14, {}] /. {G[a__] :> j[asym, a]}];
        target3LAll = Join[target3LAll, FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 9,  {}] /. {G[a__] :> j[asym3L, a]}];
        target2LAll = Join[target2LAll, FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 5,  {}] /. {G[a__] :> j[asym2L, a]}];
        target1LAll = Join[target1LAll, FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 2,  {}] /. {G[a__] :> j[asym1L, a]}];
    , {i, 1, Length[perms]}];

    target4LAll = DeleteDuplicates[target4LAll];
    target3LAll = DeleteDuplicates[target3LAll];
    target2LAll = DeleteDuplicates[target2LAll];
    target1LAll = DeleteDuplicates[target1LAll];

    gtransformAll = Table[
       Join[greps[[i]] /. {G[a__] :> G[1, {a}]}, greps[[i]] /. {G[a__] :> G[2, {a}]}] // Dispatch
    , {i, 1, Length[perms]}];
    
    basischange = Import[filepath <> "asym4LbasisChange.m"] // Dispatch;
    Print["basischange loaded!"];

    (* Step 3: Sequentially IBP reduce collected unique target integrals to protect cache bounds *)
    If[FileExistsQ[filepath <> "tmp/targetIntegrals_reduced.m"],
        trep = Import[filepath <> "tmp/targetIntegrals_reduced.m"];
        reducedg = Keys[trep];
        Print["reduced results loaded!"];
        ,
        Print["no IBP reduced results found!"];
        trep = {};
        reducedg = {};
    ];

    trep4L = Thread@Rule[#, IBPReduce[#]] &[Complement[target4LAll, reducedg]];
    trep3L = Thread@Rule[#, IBPReduce[#]] &[Complement[target3LAll, reducedg]];
    trep2L = Thread@Rule[#, IBPReduce[#]] &[Complement[target2LAll, reducedg]];
    trep1L = Thread@Rule[#, IBPReduce[#]] &[Complement[target1LAll, reducedg]];
    trep = Join[trep, trep4L, trep3L, trep2L, trep1L];
    Export[filepath <> "tmp/targetIntegrals_reduced.m", trep];
    
    trep1 = trep /. {j[_, a__] :> G[1, {a}]} /. {d -> 4 - 2 ep};
    trep2 = trep /. {j[_, a__] :> G[2, {a}]} /. {u -> 1} /. {d -> 4 - 2 ep};
    Grep = Join[trep1, trep2] // Dispatch;
    Print["target integrals reduced! time: ", SessionTime[] - starttime];

    (* Step 4: Parallelize the Series expansions *)
    Gmasterrep4L = Import[filepath <> "Gmaterrep4L.m"];
    Gmasterrep3L = Import[filepath <> "Gmaterrep3L.m"];
    Gmasterrep2L = Import[filepath <> "Gmaterrep2L.m"];
    Gmasterrep1L = Import[filepath <> "Gmaterrep1L.m"];
    Gmasterrep = Join[Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L] // Dispatch;

    (* Distribute mapping rules dynamically down to local environments. 
       Note: We aggressively DO NOT broadcast `testAll` here to prevent massive RAM/WSTP failures. *)
    DistributeDefinitions[gtransformAll, Grep, basischange, Gmasterrep, names, order];

    (* Completely release master kernel memory lock on the heavy tensor chunks *)
    Clear[testAll, topAll, top1All, top2All];

    fresults = ParallelTable[
       Block[{fresult, fres, localTest},
           
           (* Load the uniquely solved tensor results straight off local storage to bypass parallel link congestion *)
           localTest = Import[filepath <> "tmp/tensor_" <> names[[i]] <> "_order" <> ToString[order] <> "_results.m"][[2]];

           fresult = Series[(localTest /. gtransformAll[[i]] /. {D -> 4 - 2 ep} /. Grep // Collect[#, _G] &) /. basischange /. Gmasterrep, {u, 0, 0}];
           fres = Series[((fresult // Total) + O[ep]) // Normal // Expand, {Y, 0, order}] // ExpandAll;
           
           Export[filepath <> "check" <> names[[i]] <> "_order" <> ToString[order] <> "_asyexp.m", fres];
           Print[names[[i]], ": series expansion finished!"];
           fres
       ]
    , {i, 1, Length[perms]}];

    CloseKernels[];
    
    Print["=== Done Parallel Expansion! time: ", SessionTime[] - starttime, " ==="];
    fresults
];

(* RunAsymExpansionTest[intname, integrand, perm, order, loops]
   Tests whether the epsilon expansion order is sufficient for the given integral.
*)
RunAsymExpansionTest[intname_String, integrand_, perm_List, order_Integer:3, loops_List:{5, 6, 7, 8}] := Module[
    {name, int, starttime, test, top, top1, top2, grep, glist, gtransform, basischange,
     trep, reducedg, target4L, target3L, target2L, target1L,
     trep4L, trep3L, trep2L, trep1L, trep1, trep2, Grep,
     Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L, Gmasterrep},

    name = intname <> StringJoin[ToString /@ perm];
    Print["=== Running Eps Order Test for ", name, " ==="];

    If[FileExistsQ[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"],
        test = Import[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"];
        {top, top1, top2} = test[[1]];
        test = test[[2]];
        Print["tensor reduction results loaded! "],
        Print["no tensor reduced results found. Please run RunAsymExpansion first!"];
        Return[$Failed];
    ];

    {grep, glist} = ClassifyGs[test, top1];
    gtransform = Join[grep /. {G[a__] :> G[1, {a}]}, grep /. {G[a__] :> G[2, {a}]}] // Dispatch;
    basischange = Import[filepath <> "asym4LbasisChange.m"] // Dispatch;

    If[FileExistsQ[filepath <> "tmp/targetIntegrals_reduced.m"],
        trep = Import[filepath <> "tmp/targetIntegrals_reduced.m"];
        reducedg = Keys[trep],
        trep = {};
        reducedg = {};
    ];
    target4L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 14, {}] /. {G[a__] :> j[asym, a]};
    target3L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 9,  {}] /. {G[a__] :> j[asym3L, a]};
    target2L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 5,  {}] /. {G[a__] :> j[asym2L, a]};
    target1L = FirstCase[glist, lst_ /; lst =!= {} && Length[First[lst]] == 2,  {}] /. {G[a__] :> j[asym1L, a]};

    trep4L = Thread@Rule[#, IBPReduce[#]] &[Complement[target4L, reducedg]];
    trep3L = Thread@Rule[#, IBPReduce[#]] &[Complement[target3L, reducedg]];
    trep2L = Thread@Rule[#, IBPReduce[#]] &[Complement[target2L, reducedg]];
    trep1L = Thread@Rule[#, IBPReduce[#]] &[Complement[target1L, reducedg]];
    trep = Join[trep, trep4L, trep3L, trep2L, trep1L];
    Export[filepath <> "tmp/targetIntegrals_reduced.m", trep];
    trep1 = trep /. {j[_, a__] :> G[1, {a}]} /. {d -> 4 - 2 ep};
    trep2 = trep /. {j[_, a__] :> G[2, {a}]} /. {u -> 1} /. {d -> 4 - 2 ep};
    Grep = Join[trep1, trep2] // Dispatch;

    Gmasterrep4L = Import[filepath <> "Gmaterrep4L.m"];
    Gmasterrep3L = Import[filepath <> "Gmaterrep3L.m"];
    Gmasterrep2L = Import[filepath <> "Gmaterrep2L.m"];
    Gmasterrep1L = Import[filepath <> "Gmaterrep1L.m"];
    Gmasterrep = Join[Gmasterrep4L, Gmasterrep3L, Gmasterrep2L, Gmasterrep1L] // Dispatch;
    
    Print["Testing order of epsilon for regions..."];
    CheckEpsOrder[{test, {}}, gtransform, Grep, basischange, Gmasterrep, order]
];
