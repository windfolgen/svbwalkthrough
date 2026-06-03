(* test_efficiency.wl *)

rootDir = "../";

zrep0 = Table[{Power[z, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 10}] // Flatten;

svliste0 = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svliste0[[256]];

Print["Testing Original Approach (using 1/-Sqrt)"];
tA1 = AbsoluteTiming[
  test1 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
][[1]];
Print["  Constants Replacement: ", tA1];

tA2 = AbsoluteTiming[
  test1 = test1 /. {zz->u/z} // Expand;
][[1]];
Print["  zz->u/z Expand: ", tA2];

tA3 = AbsoluteTiming[
  test1 = test1 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
][[1]];
Print["  Negative Powers: ", tA3];

tA4 = AbsoluteTiming[
  test1 = test1 / (-Sqrt[-4 u+(1+u-v)^2]);
][[1]];
Print["  Divide by Sqrt: ", tA4];

tA5 = AbsoluteTiming[
  test1 = test1 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
][[1]];
Print["  zrep0 and Root Subst: ", tA5];

tA6 = AbsoluteTiming[
  If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
  res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
][[1]];
Print["  Final u, Y Series: ", tA6];
Print["  TOTAL ORIGINAL TIME: ", tA1+tA2+tA3+tA4+tA5+tA6];

Print["\nTesting New Approach (using 1/(z-zz) and Series over z, zz)"];
tB1 = AbsoluteTiming[
  test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
][[1]];
Print["  Constants Replacement: ", tB1];

tB2 = AbsoluteTiming[
  test2 = test2 / (z-zz);
][[1]];
Print["  Divide by (z-zz): ", tB2];

tB3 = AbsoluteTiming[
  test2 = Normal[Series[test2, {z, 0, 8}, {zz, 0, 8}]];
][[1]];
Print["  Series over z, zz: ", tB3];

tB3b = AbsoluteTiming[
  test2 = Collect[test2, {z, zz}, Factor];
][[1]];
Print["  Collect & Factor: ", tB3b];

tB4 = AbsoluteTiming[
  test2 = test2 /. {zz->u/z} // Expand;
][[1]];
Print["  zz->u/z Expand: ", tB4];

tB5 = AbsoluteTiming[
  test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
][[1]];
Print["  Negative Powers: ", tB5];

tB6 = AbsoluteTiming[
  test2 = test2 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
][[1]];
Print["  zrep0 and Root Subst: ", tB6];

tB7 = AbsoluteTiming[
  If[Head[test2]===Plus, test2=List@@test2, test2={test2}];
  res2 = Table[Series[test2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test2]}] // Total // Expand;
][[1]];
Print["  Final u, Y Series: ", tB7];
Print["  TOTAL NEW APPROACH TIME: ", tB1+tB2+tB3+tB3b+tB4+tB5+tB6+tB7];

Print["\nResults match: ", Expand[res1 - res2] === 0];
