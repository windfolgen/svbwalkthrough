(* Test Script test_user_idea.wl *)
Print["Loading SVHPL expressions..."];
svliste0 = Import["../allsvliste0_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
Print["Loading MPL expressions..."];
svlistmple0 = Import["../allsvlistmpl_threeloope0.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

l1 = Length[svliste0];
l2 = Length[svlistmple0];
indicesSV = {1, 2, 3, Floor[l1/2], Floor[l1/2]+1, l1-2, l1-1, l1};
indicesMPL = {1, Floor[l2/2], l2};

testExprs = Join[svliste0[[indicesSV]], svlistmple0[[indicesMPL]]];
Print["Testing on ", Length[testExprs], " expressions."];

zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}] // Flatten;

(* Original approach *)
time1 = AbsoluteTiming[
  res1 = Table[
    test = (((expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]}) /. {zz->u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]} ) / (-Sqrt[-4 u+(1+u-v)^2]);
    test = test /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
    If[Head[test]===Plus, testList=List@@test, testList={test}];
    Table[Series[testList[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList]}] // Total // Expand
  , {expr, testExprs}];
];
Print["Original approach time: ", time1[[1]]];

(* User approach *)
time2 = AbsoluteTiming[
  res2 = Table[
    (* Replace f and logs FIRST *)
    test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
    
    (* Multiply by 1/(z-zz) and expand in z then zz to order 8 *)
    test2 = test2 / (z-zz);
    test2 = Normal[Series[test2, {z, 0, 8}, {zz, 0, 8}]];
    
    (* Handle negative powers using the original u substitution if any *)
    (* In user approach, we substitute zz -> u/z. Is it necessary? *)
    (* Actually the user said "then we substitute z and zz back to u and v using my original substitution rules" *)
    (* Original substitution rules: zrep0, z->..., zz->... *)
    (* But if there are negative powers like 1/zz, they must be eliminated first. *)
    test2 = test2 /. {zz->u/z} // Expand;
    test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
    
    test2 = test2 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
    
    If[Head[test2]===Plus, testList2=List@@test2, testList2={test2}];
    Table[Series[testList2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList2]}] // Total // Expand
  , {expr, testExprs}];
];
Print["User approach time: ", time2[[1]]];

diffs = Expand[res1 - res2];
maxDiff = Max[Abs[diffs /. {Y->1.2, u->0.5, Zeta[3]->1.2, Zeta[5]->1.0, Zeta[7]->1.0, Log[u]->-0.6}]];
Print["Maximum difference on evaluated points (should be 0 if identical): ", maxDiff];
Print["Are all differences exactly 0? ", Union[diffs] === {0}];
