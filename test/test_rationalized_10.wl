(* test_rationalized_10.wl *)

rootDir = "../";

(* ZREP definitions *)
zrepInf = Table[{Power[z, i] -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;
zrep0 = Table[{Power[z, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;
zrep1 = Table[{Power[z, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[z1, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz1, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 15}] // Flatten;

TestE0[expr_] := Module[{res1, res2, test1, test2, diff, t1, t2},
  t1 = First@AbsoluteTiming[
    test1 = Expand[ (((expr*1 /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]}) /. {zz->u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]}) / (-Sqrt[-4 u+(1+u-v)^2]) /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} ];
    If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
    res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];

  t2 = First@AbsoluteTiming[
    test2 = Expand[ ((((expr*1 /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]}) /. {zz->u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]}) * (-Sqrt[-4 u+(1+u-v)^2]) / (-4 u+(1+u-v)^2)) /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} ];
    If[Head[test2]===Plus, test2=List@@test2, test2={test2}];
    res2 = Table[Series[test2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test2]}] // Total // Expand;
  ];

  diff = Expand[res1 - res2];
  Return[{diff === 0, t1, t2}];
];

TestE1[expr_] := Module[{res1, res2, test1, test2, diff, t1, t2},
  t1 = First@AbsoluteTiming[
    test1 = Expand[ (((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) / (-Sqrt[(-1+u-v)^2-4 v]) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y}) * (1/v) ];
    If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
    res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];

  t2 = First@AbsoluteTiming[
    test2 = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[(-1+u-v)^2-4 v]) / ((-1+u-v)^2-4 v)) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y}) * (1/v) ];
    If[Head[test2]===Plus, test2=List@@test2, test2={test2}];
    res2 = Table[Series[test2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test2]}] // Total // Expand;
  ];

  diff = Expand[res1 - res2];
  Return[{diff === 0, t1, t2}];
];

TestEinf[expr_] := Module[{res1, res2, test1, test2, diff, t1, t2},
  t1 = First@AbsoluteTiming[
    test1 = Expand[ (((expr*1 /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]} /. {zz->1/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]}) / (-Sqrt[-4 u+(-1-u+v)^2]) /. zrepInf /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y}) * (1/u) ];
    If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
    res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
  ];

  t2 = First@AbsoluteTiming[
    test2 = Expand[ ((((expr*1 /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]} /. {zz->1/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]}) * (-Sqrt[-4 u+(-1-u+v)^2]) / (-4 u+(-1-u+v)^2)) /. zrepInf /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y}) * (1/u) ];
    If[Head[test2]===Plus, test2=List@@test2, test2={test2}];
    res2 = Table[Series[test2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test2]}] // Total // Expand;
  ];

  diff = Expand[res1 - res2];
  Return[{diff === 0, t1, t2}];
];

PickIndices[len_] := Module[{indices, numToPick},
  SeedRandom[1234];
  numToPick = Min[10, len];
  indices = RandomSample[Range[len], numToPick];
  Sort[indices]
];

mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
  raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
          If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
  fmt = raw[[2]];
  If[fmt === "txt", StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression, raw[[1]]]
];

Print["Loading SVHPL expressions..."];
svliste0 = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
svliste1 = Import[FileNameJoin[{rootDir, "allsvliste1_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
svlisteinf = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

Print["Loading MPL expressions..."];
svlistmple0 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope0"}]];
svlistmple1 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope1"}]];
svlistmpleinf = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloopeinf"}]];

Print["===================="];
Print["TESTING e0"];
Print["===================="];
idx = PickIndices[Length[svliste0]];
Print["SVHPL Indices: ", idx];
Do[Print["  SVHPL[", i, "] : ", TestE0[svliste0[[i]]]], {i, idx}];
idx = PickIndices[Length[svlistmple0]];
Print["MPL Indices: ", idx];
Do[Print["  MPL[", i, "] : ", TestE0[svlistmple0[[i]]]], {i, idx}];

Print["===================="];
Print["TESTING e1"];
Print["===================="];
idx = PickIndices[Length[svliste1]];
Print["SVHPL Indices: ", idx];
Do[Print["  SVHPL[", i, "] : ", TestE1[svliste1[[i]]]], {i, idx}];
idx = PickIndices[Length[svlistmple1]];
Print["MPL Indices: ", idx];
Do[Print["  MPL[", i, "] : ", TestE1[svlistmple1[[i]]]], {i, idx}];

Print["===================="];
Print["TESTING einf"];
Print["===================="];
idx = PickIndices[Length[svlisteinf]];
Print["SVHPL Indices: ", idx];
Do[Print["  SVHPL[", i, "] : ", TestEinf[svlisteinf[[i]]]], {i, idx}];
idx = PickIndices[Length[svlistmpleinf]];
Print["MPL Indices: ", idx];
Do[Print["  MPL[", i, "] : ", TestEinf[svlistmpleinf[[i]]]], {i, idx}];

Print["All checks finished!"];
