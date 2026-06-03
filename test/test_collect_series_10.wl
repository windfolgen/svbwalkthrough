(* test_collect_series_10.wl *)
rootDir = "../";
mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
  raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
          If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
  fmt = raw[[2]];
  If[fmt === "txt", StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression, raw[[1]]]
];

Print["Loading SVHPL expressions..."];
svlisthard2e0 = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
svlistmple1 = Import[FileNameJoin[{rootDir, "allsvliste1_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
svlistmpleinf = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

Print["Loading MPL expressions..."];
mplhard2e0 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope0"}]];
mplthreeloope1 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope1"}]];
mplthreeloopeinf = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloopeinf"}]];

(* ZREP definitions - Power 15 *)
zrepInf = Table[{Power[z, i] -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;
zrep0 = Table[{Power[z, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;
zrep1 = Table[{Power[z, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[z1, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz1, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;

TestE0[expr_] := Module[{res1, res2, test1Raw, test1, test2, diff, t1, t2},
  test1Raw = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[-4 u+(1+u-v)^2]) / (-4 u+(1+u-v)^2)) /. zrep0 /. {z1->1/2*(1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz1->1/2*(1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y}) * (1/(1-Y)) ];
  
  (* Method 1: Table *)
  t1 = First@AbsoluteTiming[
    test1 = If[Head[test1Raw]===Plus, List@@test1Raw, {test1Raw}];
    res1 = Table[Normal[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]]//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];
  
  (* Method 2: Collect + Single Series *)
  t2 = First@AbsoluteTiming[
    test2 = Collect[test1Raw, Power[_, 1/2], Expand];
    res2 = Normal[Series[test2,{u,0,0},{Y,0,4},Assumptions->{Y>0}]] // Expand;
  ];
  
  diff = Expand[res1 - res2];
  {diff === 0, t1, t2}
];

TestE1[expr_] := Module[{res1, res2, test1Raw, test1, test2, diff, t1, t2},
  test1Raw = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[(-1+u-v)^2-4 v]) / ((-1+u-v)^2-4 v)) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y}) * (1/(1-Y)) ];
  
  (* Method 1: Table *)
  t1 = First@AbsoluteTiming[
    test1 = If[Head[test1Raw]===Plus, List@@test1Raw, {test1Raw}];
    res1 = Table[Normal[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]]//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];
  
  (* Method 2: Collect + Single Series *)
  t2 = First@AbsoluteTiming[
    test2 = Collect[test1Raw, Power[_, 1/2], Expand];
    res2 = Normal[Series[test2,{u,0,0},{Y,0,4},Assumptions->{Y>0}]] // Expand;
  ];
  
  diff = Expand[res1 - res2];
  {diff === 0, t1, t2}
];

TestEInf[expr_] := Module[{res1, res2, test1Raw, test1, test2, diff, t1, t2},
  test1Raw = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[-4 u+(-1-u+v)^2]) / (-4 u+(-1-u+v)^2)) /. zrepInf /. {z1->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz1->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y}) * (1/(1-Y)) ];
  
  (* Method 1: Table *)
  t1 = First@AbsoluteTiming[
    test1 = If[Head[test1Raw]===Plus, List@@test1Raw, {test1Raw}];
    res1 = Table[Normal[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]]//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];
  
  (* Method 2: Collect + Single Series *)
  t2 = First@AbsoluteTiming[
    test2 = Collect[test1Raw, Power[_, 1/2], Expand];
    res2 = Normal[Series[test2,{u,0,0},{Y,0,4},Assumptions->{Y>0}]] // Expand;
  ];
  
  diff = Expand[res1 - res2];
  {diff === 0, t1, t2}
];

SeedRandom[123];

Print["===================="];
Print["TESTING e0"];
Print["===================="];
sv0Idxs = Sort[RandomSample[Range[Length[svlisthard2e0]], 10]];
Print["SVHPL Indices: ", sv0Idxs];
Do[Print["  SVHPL[", idx, "] : ", TestE0[svlisthard2e0[[idx]]]], {idx, sv0Idxs}];
mpl0Idxs = Sort[RandomSample[Range[Length[mplhard2e0]], 10]];
Print["MPL Indices: ", mpl0Idxs];
Do[Print["  MPL[", idx, "] : ", TestE0[mplhard2e0[[idx]]]], {idx, mpl0Idxs}];

Print["===================="];
Print["TESTING e1"];
Print["===================="];
sv1Idxs = Sort[RandomSample[Range[Length[svlistmple1]], 10]];
Print["SVHPL Indices: ", sv1Idxs];
Do[Print["  SVHPL[", idx, "] : ", TestE1[svlistmple1[[idx]]]], {idx, sv1Idxs}];
mpl1Idxs = Sort[RandomSample[Range[Length[mplthreeloope1]], 10]];
Print["MPL Indices: ", mpl1Idxs];
Do[Print["  MPL[", idx, "] : ", TestE1[mplthreeloope1[[idx]]]], {idx, mpl1Idxs}];

Print["===================="];
Print["TESTING einf"];
Print["===================="];
svinfIdxs = Sort[RandomSample[Range[Length[svlistmpleinf]], 10]];
Print["SVHPL Indices: ", svinfIdxs];
Do[Print["  SVHPL[", idx, "] : ", TestEInf[svlistmpleinf[[idx]]]], {idx, svinfIdxs}];
mplinfIdxs = Sort[RandomSample[Range[Length[mplthreeloopeinf]], 10]];
Print["MPL Indices: ", mplinfIdxs];
Do[Print["  MPL[", idx, "] : ", TestEInf[mplthreeloopeinf[[idx]]]], {idx, mplinfIdxs}];

Print["All checks finished!"];
