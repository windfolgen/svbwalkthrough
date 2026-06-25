(* Comprehensive script to transform all 6 z/zz expansion files to u/v for straight and permuted limits *)
rootDir = DirectoryName[$InputFileName];
If[rootDir === "", rootDir = Directory[]];
If[StringEndsQ[rootDir, "transform/"] || StringEndsQ[rootDir, "transform"] || StringEndsQ[rootDir, "scratch/"] || StringEndsQ[rootDir, "scratch"], rootDir = ParentDirectory[rootDir]];
SetDirectory[rootDir];

Print["Root Directory: ", rootDir];

(* Initialize 6 Kernels *)
LaunchKernels[6];

(* =================================================================== *)
(*  zrep DEFINITIONS (up to power 15, optimized with Dispatch)          *)
(* =================================================================== *)
zrep0 = Dispatch@Flatten@Table[{
  Power[z, i]  -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

zrep0P = Dispatch@Flatten@Table[{
  Power[z, i]  -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 15}];

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

(* Pre-calculate the radical series expansions *)
radical0 = Sqrt[-4*u + (u + Y)^2];
sqrtSeries0 = Series[radical0, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

radical0P = Sqrt[-4*u*(1 - Y) + (u - Y)^2];
sqrtSeries0P = Series[radical0P, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

radical1 = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)];
sqrtSeries1 = Series[radical1, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

(* Distribute definitions to helper kernels *)
DistributeDefinitions[
  zrep0, zrep0P, zrep1, zrep1P, zrepInf, zrepInfP,
  sqrtSeries0, sqrtSeries0P, sqrtSeries1
];

(* Helper for robust algebraic division *)
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

(* Define the 6 specific transformation functions *)
TransformE0[term_] := Module[{test, exp, zSub},
  test = (((term /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]}) /. {zz->u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]});
  exp = -4*u + (u + Y)^2;
  zSub = {z -> 1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), zz -> 1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v)};
  RobustTransform[test, zrep0, zSub, exp, sqrtSeries0]
];

TransformE0P[term_] := Module[{test, exp, zSub},
  test = (((term /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]}) /. {zz->u/z/v} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*v/u,-a]});
  exp = -4*u*(1 - Y) + (u - Y)^2;
  zSub = {z -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), zz -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v)};
  RobustTransform[test, zrep0P, zSub, exp, sqrtSeries0P]
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
  TransformE0, TransformE0P,
  TransformEinf, TransformEinfP,
  TransformE1, TransformE1P
];

(* Helper for reading/writing square-bracket lists *)
loadList[path_] := Module[{raw},
  raw = Import[path, "String"];
  StringTrim[raw, "["|"]"] // ("{" <> # <> "}") & // ToExpression
];

saveList[lst_, path_] := Module[{str},
  str = ToString[InputForm[lst]];
  str = "[" <> StringTake[str, {2, -2}] <> "]";
  Export[path, str, "String"];
];

runFile[inName_, outName_, transFunc_] := Module[{list, t0, t1, res},
  Print["Processing '", inName, "' -> '", outName, "'..."];
  t0 = AbsoluteTime[];
  list = loadList[inName];
  Print["  Loaded ", Length[list], " terms."];
  res = ParallelTable[transFunc[list[[i]]], {i, 1, Length[list]}];
  saveList[res, outName];
  t1 = AbsoluteTime[];
  Print["  Finished in ", Round[t1 - t0, 0.01], " seconds."];
];

(* Run all 12 transformations *)
runFile["allsvliste0_uptow8.txt",           "allsvliste0_uptow8_inuv_e0uv.txt",           TransformE0];
runFile["allsvliste0_uptow8.txt",           "allsvliste0_uptow8_inuv_e0uvp.txt",          TransformE0P];
runFile["allsvlistmpl_threeloope0.txt",     "allsvlistmpl_threeloope0_inuv_e0uv.txt",     TransformE0];
runFile["allsvlistmpl_threeloope0.txt",     "allsvlistmpl_threeloope0_inuv_e0uvp.txt",    TransformE0P];

runFile["allsvliste1_uptow8.txt",           "allsvliste1_uptow8_inuv_e1uv.txt",           TransformE1];
runFile["allsvliste1_uptow8.txt",           "allsvliste1_uptow8_inuv_e1uvp.txt",          TransformE1P];
runFile["allsvlistmpl_threeloope1.txt",     "allsvlistmpl_threeloope1_inuv_e1uv.txt",     TransformE1];
runFile["allsvlistmpl_threeloope1.txt",     "allsvlistmpl_threeloope1_inuv_e1uvp.txt",    TransformE1P];

runFile["allsvlisteinf_uptow8.txt",         "allsvlisteinf_uptow8_inuv_einfuv.txt",         TransformEinf];
runFile["allsvlisteinf_uptow8.txt",         "allsvlisteinf_uptow8_inuv_einfuvp.txt",        TransformEinfP];
runFile["allsvlistmpl_threeloopeinf.txt",   "allsvlistmpl_threeloopeinf_inuv_einfuv.txt",   TransformEinf];
runFile["allsvlistmpl_threeloopeinf.txt",   "allsvlistmpl_threeloopeinf_inuv_einfuvp.txt",  TransformEinfP];

CloseKernels[];
Print["All transformations complete!"];
