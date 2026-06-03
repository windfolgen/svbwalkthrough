(* Test Script test_user_idea_fast.wl *)
svliste0 = Import["../allsvliste0_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
svlistmple0 = Import["../allsvlistmpl_threeloope0.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

l1 = Length[svliste0];
l2 = Length[svlistmple0];
indicesSV = {1, 2, 3, Floor[l1/2], Floor[l1/2]+1, l1-2, l1-1, l1};
indicesMPL = {1, Floor[l2/2], l2};

testExprs = Join[svliste0[[indicesSV]], svlistmple0[[indicesMPL]]];

zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}] // Flatten;

time2 = AbsoluteTiming[
  res2 = Table[
    test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
    
    (* Multiply by explicit sum instead of using Series on the whole expression *)
    expansion = Sum[-(z^k) / (zz^(k+1)), {k, 0, 8}];
    test2 = Expand[test2 * expansion];
    
    (* Drop terms with power of z > 8 or zz > 8 ? *)
    (* Actually the user said "keep the expansion to the same order", 
       Normal[Series[...]] does this. Let's see if we need to drop terms. *)
    (* We can just drop terms with high powers using a substitution rule *)
    test2 = test2 /. {z^p_ /; p > 8 -> 0, zz^p_ /; p > 8 -> 0};
    
    test2 = test2 /. {zz->u/z} // Expand;
    test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
    
    test2 = test2 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
    
    If[Head[test2]===Plus, testList2=List@@test2, testList2={test2}];
    Table[Series[testList2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList2]}] // Total // Expand
  , {expr, testExprs}];
];
Print["Optimized User approach time: ", time2[[1]]];
