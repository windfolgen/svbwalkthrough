(* Weighted region expansion: the small squared norm has twice the scaling degree of the mixed scalar product. *)
Options[WeightedRegionExpand] = {"order" -> 4, "deBug" -> False, "check" -> False, "keepr" -> False, "verbose" -> True};
WeightedRegionExpand[oint_, loops_, OptionsPattern[]] :=
  Module[{int, intl, den, num, subset = {}, rep, result = 0, pos, com, tem, tem1, tem2, top, top1, top2, check, start, i, j},
   If[OptionValue["verbose"], Print["set 1 to 0, 4 to infinity."]];
   If[OptionValue["verbose"], Print["performing region expansion..."]];
   start = SessionTime[];
   intl=oint//Expand;
   If[Head[intl]===Plus, intl = List@@intl, intl = {intl}];
   top = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 2], d2[loops[[i]], 3]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   top1 = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 2]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   top2 = Join[Table[{d2[loops[[i]], 1], d2[loops[[i]], 3]}, {i, 1, Length[loops]}] // Flatten, Table[d2[loops[[i]], loops[[j]]], {i, 1, Length[loops]}, {j, i + 1, Length[loops]}] // Flatten];
   kinRep = {invd2[a_, b_] :> 1/d2[a, b], d2[1, 3] -> 1, d2[1, 2] -> u, d2[2, 3] -> v};
   If[OptionValue["verbose"],
     Print["topology: ", top, " can be split into"];
     Print["topo1: ", top1]; Print["topo2: ", top2];
   ];
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
            If[OptionValue["verbose"],
              Print["Loops: ", Subscript[x, #] & /@ loops, ". There are totally ", Power[2, Length[loops]], " regions."];
              Print["classifying topologies: "];
            ];
            Do[
                pos = Position[subset[[i]], 0, 1] // Flatten;
                com = Complement[loops, loops[[pos]]];
                rep = {
                    invd2[a_ /; (MemberQ[loops[[pos]], a]), 3] :> Sum[Power[(2 r d[3, a] - r^2 d2[a, 1]), n]/Power[d2[3, 1], n + 1], {n, 0, OptionValue["order"]}],
                    invd2[a_ /; (MemberQ[com, a]), 2] :> Sum[Power[(2 r d[2, a] - r^2 d2[2, 1]), n]/Power[d2[a, 1], n + 1], {n, 0, OptionValue["order"]}],
                    invd2[a_ /; (MemberQ[loops[[pos]], a]), b_ /; (MemberQ[com, b])] :> Sum[Power[(2 r d[b, a] - r^2 d2[a, 1]), n]/Power[d2[b, 1], n + 1], {n, 0, OptionValue["order"]}]
                };
                tem = (Normal[Series[(((Times @@ den)*(Times @@ num) /. rep) //. kinRep), {r, 0, OptionValue["order"]}]] // Expand);
                If[Head[tem] === Plus,
                    tem = List @@ tem,
                    tem = {tem};
                ];
                If[OptionValue["deBug"], Print["tem: ", tem]];
                If[Not@OptionValue["keepr"], tem = tem /. {r -> 1}];
                If[OptionValue["verbose"], Print["region ", i, ": total terms ", Length[tem]]];

                Do[
                    tem1 = ClassifyTopology[tem[[j]], top, 1, "loops" -> loops, "subloops" -> loops[[pos]], "ClassifySub" -> False];
                    If[tem1 === $Failed, Print["this term cannot be classified: ", {tem[[j]], loops[[pos]], com}]; Continue[]];
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
