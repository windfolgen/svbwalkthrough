(* Test Script test_e1.wl *)
svliste1 = Import["../allsvliste1_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svliste1[[1]];

zrep1 = Table[{
  Power[z, i]    -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}] // Flatten;

test = ((((expr*1 /.{-1+z->z1,-1+zz->zz1}/.{I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}/.{zz1->u/v/(z1)}//Expand)/.{Power[z1,a_/;(a<0)]:>Power[(zz1)*v/u,-a]})/(-Sqrt[(-1+u-v)^2-4 v])));
test = test /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)}/.{v->1-Y}//Expand;
If[Head[test]===Plus, testList=List@@test, testList={test}];
res1 = Table[Series[testList[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList]}] // Total // Expand;

test2 = expr /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]};
test2 = test2 /. {-1+z->z1, -1+zz->zz1, z->z1+1, zz->zz1+1};

test2 = test2 / (z1-zz1);
test2 = Normal[Series[test2, {z1, 0, 8}, {zz1, 0, 8}]];

test2 = test2 /. {zz1->u/v/z1} // Expand;
test2 = test2 /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]};
test2 = test2 /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)}/.{v->1-Y}//Expand;

If[Head[test2]===Plus, testList2=List@@test2, testList2={test2}];
res2 = Table[Series[testList2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList2]}] // Total // Expand;

Print["Diff if dividing by z1-zz1: ", InputForm[Expand[res1 - res2]]];

res2v = Expand[res2 / v /. {v->1-Y}];
res2v = Series[res2v, {u,0,0}, {Y,0,4}] // Normal // Expand;
Print["Diff if dividing by v*(z1-zz1): ", InputForm[Expand[res1 - res2v]]];
