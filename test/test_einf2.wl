(* Test Script test_einf2.wl *)
svlisteinf = Import["../allsvlisteinf_uptow8.txt", "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
expr = svlisteinf[[1]];

zrepInf = Table[{
  Power[z, i]  -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}] // Flatten;

(* Expand expr in 1/z and 1/zz explicitly by substituting z->1/w, zz->1/ww ? *)
(* No, user says: "expansion around infinity is actually up to (1/z)^7 and (1/zz)^7" *)

(* Let's see what user meant for einf. *)
(* User approach for SeriesExpansionInf *)
test2 = expr /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]};
test2 = test2 / (z-zz);
test2 = test2 /. {z->1/w, zz->1/ww};
test2 = Normal[Series[test2, {w, 0, 8}, {ww, 0, 8}]];
test2 = test2 /. {w->1/z, ww->1/zz};

test2 = test2 /. {zz->1/u/z} // Expand;
test2 = test2 /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]};
test2 = test2 /. zrepInf /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y} // Expand;
test2 = Expand[test2 * (1/u)];

If[Head[test2]===Plus, testList2=List@@test2, testList2={test2}];
res2 = Table[Series[testList2[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList2]}] // Total // Expand;

(* Original approach for SeriesExpansionInf *)
test = ((((expr*1 /. {zz->1/u/z} // Expand) /. {Power[z,a_/;(a<0)]:>Power[zz*u,-a]}) / (-Sqrt[-4 u+(-1-u+v)^2])) /. zrepInf /. {f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]} /. {z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)} /. {v->1-Y} // Expand);
If[Head[test]===Plus, testList=List@@test, testList={test}];
res1 = Table[Series[testList[[j]],{u,0,0},{Y,0,4},Assumptions->{Y>0}]//Normal//Expand,{j,1,Length[testList]}] // Total // Expand;

Print["Diff if expanding 1/w and 1/ww at 0: ", InputForm[Expand[res1 - res2]]];
