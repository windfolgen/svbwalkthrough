(* test_split.wl *)
rootDir = "../";
mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
  raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
          If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
  fmt = raw[[2]];
  If[fmt === "txt", StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression, raw[[1]]]
];

svlistmple1 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope1"}]];
expr = svlistmple1[[23]];

zrep1 = Table[{Power[z, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[z1, i] -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz1, i] -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 10}] // Flatten;

Print["Testing Rationalized Approach (No Split)"];
t1 = AbsoluteTiming[
  test1 = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[(-1+u-v)^2-4 v]) / ((-1+u-v)^2-4 v)) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y}) * (1/v) ];
  If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
  res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
][[1]];
Print["  TOTAL TIME: ", t1];

Print["\nTesting Rationalized + Split Sqrt Approach"];
t2 = AbsoluteTiming[
  test2Raw = Expand[ ((((expr*1 /. {-1+z->z1,-1+zz->zz1} /. {I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]}) * (-Sqrt[(-1+u-v)^2-4 v]) / ((-1+u-v)^2-4 v)) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y}) * (1/(1-Y)) ];
  If[Head[test2Raw]===Plus, test2Raw=List@@test2Raw, test2Raw={test2Raw}];

  rad = Sqrt[(-1+u-v)^2-4 v] /. {v->1-Y};
  radSeries = Normal[Series[rad, {u,0,0}, {Y,0,4}, Assumptions->{Y>0}]];

  res2 = Table[
    term = test2Raw[[j]];
    Q = Coefficient[term, rad];
    P = term /. {rad -> 0};
    
    QSeries = Normal[Series[Q, {u,0,0}, {Y,0,4}, Assumptions->{Y>0}]];
    PSeries = Normal[Series[P, {u,0,0}, {Y,0,4}, Assumptions->{Y>0}]];
    
    Normal[Series[PSeries + QSeries * radSeries, {u,0,0}, {Y,0,4}, Assumptions->{Y>0}]]
  , {j, 1, Length[test2Raw]}] // Total // Expand;
][[1]];
Print["  TOTAL SPLIT TIME: ", t2];
Print["\nResults match: ", Expand[res1 - res2] === 0];
