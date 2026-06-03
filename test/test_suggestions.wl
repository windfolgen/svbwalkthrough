rootDir = "../";
mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
  raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
          If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
  fmt = raw[[2]];
  If[fmt === "txt", StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression, raw[[1]]]
];

svlistmple0 = mplLoad[FileNameJoin[{rootDir, "allsvlistmpl_threeloope0"}]];
expr = svlistmple0[[82]];

Print["Testing Pre-Expanded Roots Approach"];

tC1 = AbsoluteTiming[
  (* Pre-expand the fundamental quantities in u then Y *)
  zRadical = 1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y};
  zzRadical = 1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y};
  invSqrtRadical = 1 / (-Sqrt[-4 u + (1 + u - v)^2]) /. {v -> 1 - Y};

  zSeries = Normal[Series[zRadical, {u, 0, 0}, {Y, 0, 8}, Assumptions -> {Y > 0}]];
  zzSeries = Normal[Series[zzRadical, {u, 0, 0}, {Y, 0, 8}, Assumptions -> {Y > 0}]];
  invSqrtSeries = Normal[Series[invSqrtRadical, {u, 0, 0}, {Y, 0, 8}, Assumptions -> {Y > 0}]];

  zrepSeries = Table[{
    Power[z, i] -> Normal[Series[Power[zSeries, i], {u, 0, 0}, {Y, 0, 8}]],
    Power[zz, i] -> Normal[Series[Power[zzSeries, i], {u, 0, 0}, {Y, 0, 8}]]
  }, {i, 1, 10}] // Flatten;
][[1]];
Print["  Pre-expansion of roots: ", tC1];

tC2 = AbsoluteTiming[
  test3 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
  test3 = test3 /. {zz->u/z} // Expand;
  test3 = test3 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
][[1]];
Print["  Constants and z/zz setup: ", tC2];

tC3 = AbsoluteTiming[
  (* Substitute the pre-expanded roots into the expression *)
  test3 = test3 /. zrepSeries;
  test3 = test3 /. {z->zSeries, zz->zzSeries};
  test3 = Expand[test3 * invSqrtSeries];
][[1]];
Print["  Substitute pre-expanded roots & multiply invSqrt: ", tC3];

tC4 = AbsoluteTiming[
  If[Head[test3]===Plus, test3=List@@test3, test3={test3}];
  res3 = Table[Normal[Series[test3[[j]], {u, 0, 0}, {Y, 0, 4}]], {j, 1, Length[test3]}] // Total // Expand;
][[1]];
Print["  Final truncation: ", tC4];
Print["  TOTAL PRE-EXPANDED TIME: ", tC1+tC2+tC3+tC4];

(* Let's run the original for comparison on the same exact test *)
zrep0 = Table[{Power[z, i] -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &), Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)}, {i, 1, 10}] // Flatten;
tA = AbsoluteTiming[
  test1 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
  test1 = test1 /. {zz->u/z} // Expand;
  test1 = test1 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
  test1 = test1 / (-Sqrt[-4 u+(1+u-v)^2]);
  test1 = test1 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
  If[Head[test1]===Plus, test1=List@@test1, test1={test1}];
  res1 = Table[Series[test1[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test1]}] // Total // Expand;
][[1]];
Print["\n  TOTAL ORIGINAL TIME: ", tA];
Print["\nResults match (Pre-expanded vs Original): ", Expand[res1 - res3] === 0];

Print["\nTesting Rationalized Denom Approach"];
tD = AbsoluteTiming[
  test4 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]};
  test4 = test4 /. {zz->u/z} // Expand;
  test4 = test4 /. {Power[z,a_/;(a<0)]:>Power[zz/u,-a]};
  test4 = test4 * (-Sqrt[-4 u+(1+u-v)^2]) / (-4 u+(1+u-v)^2);
  test4 = test4 /. zrep0 /. {z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)} /. {v->1-Y} // Expand;
  If[Head[test4]===Plus, test4=List@@test4, test4={test4}];
  res4 = Table[Series[test4[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[test4]}] // Total // Expand;
][[1]];
Print["  TOTAL RATIONALIZED TIME: ", tD];
Print["\nResults match (Rationalized vs Original): ", Expand[res1 - res4] === 0];
