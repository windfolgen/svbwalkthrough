(* test_e0_1.wl *)
rootDir = "../";

svliste0 = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svliste0[[1]];

zrep0 = Table[{Power[z, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 10}] // Flatten;

test1 = ((((expr*1 /. {zz->u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]}) / (-Sqrt[-4 u+(1+u-v)^2])) /. zrep0 /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]} /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand);
If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;

test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
test2 = test2 / (z-zz);
test2 = Normal[Series[test2, {z, 0, 8}, {zz, 0, 8}]];
test2 = test2 /. {zz->u/z} // Expand;
test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
test2 = test2 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
If[Head[test2]===Plus, test2=List@@test2, test2={test2}];
res2 = Table[Series[test2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test2]}] // Total // Expand;

Print["Diff: ", InputForm[Expand[res1 - res2]]];
