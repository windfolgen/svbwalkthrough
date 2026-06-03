(* Test Script test_einf_order.wl *)
svlisteinf = Import["../allsvlisteinf_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svlisteinf[[1]];

zrepInf = Table[{
  Power[z, i]  -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 20}] // Flatten;

(* Original approach for SeriesExpansionInf *)
test = ((((expr*1 /. {zz->1/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]}) / (-Sqrt[-4 u+(-1-u+v)^2])) /. zrepInf /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]} /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y} // Expand);
If[Head[test]===Plus, testList=List@@test, testList={test}];
res1 = Table[Series[testList[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList]}] // Total // Expand;

(* User approach for SeriesExpansionInf with HIGHER ORDER *)
For[ord = 8, ord <= 20, ord += 2,
  test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]};
  test2 = test2 / (z-zz);
  test2 = Normal[Series[test2, {z, Infinity, ord}, {zz, Infinity, ord}]];

  test2 = test2 /. {zz->1/u/z} // Expand;
  test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]};
  test2 = test2 /. zrepInf /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y} // Expand;

  test2 = Expand[test2 * (1/u)];

  If[Head[test2]===Plus, testList2=List@@test2, testList2={test2}];
  res2 = Table[Series[testList2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList2]}] // Total // Expand;

  diff = Expand[res1 - res2];
  Print["Order ", ord, " diff is 0? ", diff === 0];
  If[diff =!= 0, Print[" Max diff term coeff: ", Max[Abs[Cases[diff, c_ * _ :> c, {1}]]]]];
];
