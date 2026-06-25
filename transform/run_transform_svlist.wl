(* Optimized script to transform the 3 original SVHPL expansion files to 6 _inuv.m files *)
rootDir = DirectoryName[$InputFileName];
If[rootDir === "", rootDir = Directory[]];
If[StringEndsQ[rootDir, "transform/"] || StringEndsQ[rootDir, "transform"] || StringEndsQ[rootDir, "scratch/"] || StringEndsQ[rootDir, "scratch"], rootDir = ParentDirectory[rootDir]];
SetDirectory[rootDir];

Print["Root Directory: ", rootDir];

(* Helper for reading square-bracket list *)
loadList[path_] := Module[{raw},
  raw = Import[path, "String"];
  StringTrim[raw, "["|"]"] // ("{" <> # <> "}") & // ToExpression
];

(* Helper for saving as standard .m expression file *)
saveListM[lst_, path_] := Export[path, lst];

(* Step 1: Convert completed e0 files to .m if they exist as .txt *)
Do[
  Module[{txtPath = FileNameJoin[{rootDir, "allsvliste0_uptow8_inuv_" <> sfx <> ".txt"}], 
          mPath = FileNameJoin[{rootDir, "allsvliste0_uptow8_inuv_" <> sfx <> ".m"}], lst},
    If[FileExistsQ[txtPath] && !FileExistsQ[mPath],
      Print["Converting ", txtPath, " -> ", mPath];
      lst = loadList[txtPath];
      saveListM[lst, mPath];
      Print["  Conversion complete."];
    ]
  ],
  {sfx, {"e0uv", "e0uvp"}}
];

(* Step 2: Initialize 6 parallel helper kernels for remaining transformations *)
LaunchKernels[6];

zrep1 = Dispatch@Flatten@Table[{
  Power[z, i]    -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

zrep1P = Dispatch@Flatten@Table[{
  Power[z, i]    -> (Power[1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

zrepInf = Dispatch@Flatten@Table[{
  Power[z, i]  -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

zrepInfP = Dispatch@Flatten@Table[{
  Power[z, i]  -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

radical1 = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)];
sqrtSeries1 = Series[radical1, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

radical0 = Sqrt[-4*u + (u + Y)^2];
sqrtSeries0 = Series[radical0, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

radical0P = Sqrt[-4*u*(1 - Y) + (u - Y)^2];
sqrtSeries0P = Series[radical0P, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

DistributeDefinitions[
  zrep1, zrep1P, zrepInf, zrepInfP,
  sqrtSeries1, sqrtSeries0, sqrtSeries0P
];

RobustTransform[test_, zrep_, zSub_, exp_, sqrtSeries_] := Module[{reduced, A, B, seriesA, seriesB, finalSeries, res},
  reduced = (test /. zrep /. zSub /. {v->1-Y} // Expand);
  reduced = reduced /. {Power[Sqrt[x_], n_Integer] :> If[EvenQ[n], x^(n/2), Sqrt[x] * x^((n-1)/2)]} // Expand;
  A = reduced /. Sqrt[_] -> 0 // Expand;
  B = (reduced - A) / Sqrt[Expand[exp]] // Expand;
  seriesA = Series[A, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  seriesB = Series[B, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  finalSeries = seriesA + seriesB * sqrtSeries // Expand;
  res = Series[finalSeries, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  res
];

TransformEinf[term_] := Module[{test, exp, zSub},
  test = (((term /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]}) /. {zz->1/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]});
  exp = -4*u + (u + Y)^2;
  zSub = {z -> (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), zz -> (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u)};
  RobustTransform[test, zrepInf, zSub, exp, sqrtSeries0]
];

TransformEinfP[term_] := Module[{test, exp, zSub},
  test = (((term /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u/v]}) /. {zz->v/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u/v,-a]});
  exp = -4*u*(1 - Y) + (u - Y)^2;
  zSub = {z -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), zz -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u)};
  RobustTransform[test, zrepInfP, zSub, exp, sqrtSeries0P]
];

TransformE1[term_] := Module[{test, exp, zSub},
  test = (((term /. {-1+z->z1, -1+zz->zz1} /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}) /. {zz1->u/v/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1*v/u,-a]});
  exp = (-2 + u + Y)^2 - 4*(1 - Y);
  zSub = {z1 -> (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), zz1 -> (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v)};
  RobustTransform[test, zrep1, zSub, exp, sqrtSeries1]
];

TransformE1P[term_] := Module[{test, exp, zSub},
  test = (((term /. {-1+z->z1, -1+zz->zz1} /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}) /. {zz1->u/z1} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[zz1/u,-a]});
  exp = (-2 + u + Y)^2 - 4*(1 - Y);
  zSub = {z1 -> 1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), zz1 -> 1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2])};
  RobustTransform[test, zrep1P, zSub, exp, sqrtSeries1]
];

DistributeDefinitions[
  RobustTransform,
  TransformEinf, TransformEinfP,
  TransformE1, TransformE1P
];

runFile[inName_, outName_, transFunc_] := Module[{list, t0, t1, res},
  Print["Processing '", inName, "' -> '", outName, "'..."];
  t0 = AbsoluteTime[];
  list = loadList[inName];
  Print["  Loaded ", Length[list], " terms."];
  res = ParallelTable[transFunc[list[[i]]], {i, 1, Length[list]}];
  saveListM[res, outName];
  t1 = AbsoluteTime[];
  Print["  Finished in ", Round[t1 - t0, 0.01], " seconds."];
];

(* Run the remaining 4 transformations directly as .m files *)
runFile["allsvliste1_uptow8.txt",           "allsvliste1_uptow8_inuv_e1uv.m",           TransformE1];
runFile["allsvliste1_uptow8.txt",           "allsvliste1_uptow8_inuv_e1uvp.m",          TransformE1P];

runFile["allsvlisteinf_uptow8.txt",         "allsvlisteinf_uptow8_inuv_einfuv.m",         TransformEinf];
runFile["allsvlisteinf_uptow8.txt",         "allsvlisteinf_uptow8_inuv_einfuvp.m",        TransformEinfP];

CloseKernels[];
Print["All SVHPL transformations complete!"];
