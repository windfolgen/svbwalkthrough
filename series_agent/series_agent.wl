(* =================================================================== *)
(*  Skill 1: Ansatz Series Expansion Agent                            *)
(*  Location: ./series_agent/                                          *)
(*                                                                     *)
(*  Self-contained: includes all 12 SeriesExpansion* function           *)
(*  definitions and 6 zrep definitions from svbwalkthrough.nb.         *)
(* =================================================================== *)

(* =================================================================== *)
(*  zrep DEFINITIONS (6 limits, labelled by variable name)              *)
(* =================================================================== *)

(* zrep for einf: used by SeriesExpansionInf, SeriesExpansion2Inf *)
zrepInf = Table[{
  Power[z, i]  -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for einfP: used by SeriesExpansionInfP, SeriesExpansion2InfP *)
zrepInfP = Table[{
  Power[z, i]  -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0: used by SeriesExpansion0, SeriesExpansion20 *)
zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0P: used by SeriesExpansion0P, SeriesExpansion20P *)
zrep0P = Table[{
  Power[z, i]  -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1: used by SeriesExpansion1, SeriesExpansion21 *)
zrep1 = Table[{
  Power[z, i]    -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1P: used by SeriesExpansion1P, SeriesExpansion21P *)
zrep1P = Table[{
  Power[z, i]    -> (Power[1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* =================================================================== *)
(*  SeriesExpansion FUNCTION DEFINITIONS (from svbwalkthrough.nb)       *)
(* =================================================================== *)

(* --- einf straight: simple pole --- *)
ClearAll[SeriesExpansionInf];
Options[SeriesExpansionInf]={"additional"->1,"Yorder"->5};
SeriesExpansionInf[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{zz->1/u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*u,-a]})/(-Sqrt[-4 u+(-1-u+v)^2]))/.zrep/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]}/.{z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansionInfP];
Options[SeriesExpansionInfP]={"additional"->1,"Yorder"->5};
SeriesExpansionInfP[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{zz->v/u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*u/v,-a]})/(-Sqrt[-4 u v+(-1+u+v)^2]))/.zrep/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u/v]}/.{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 u),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 u)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion0];
Options[SeriesExpansion0]={"additional"->1,"Yorder"->5};
SeriesExpansion0[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=(((((temp[[i]]*OptionValue["additional"]/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]})/.{zz->u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz/u,-a]})/(-Sqrt[-4 u+(1+u-v)^2]))/.zrep/.{z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion0P];
Options[SeriesExpansion0P]={"additional"->1,"Yorder"->5};
SeriesExpansion0P[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=(((((temp[[i]]*OptionValue["additional"]/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u/v]})/.{zz->u/z/v}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*v/u,-a]})/(-Sqrt[-4 u v+(-1+u+v)^2]))/.zrep/.{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 v),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion1];
Options[SeriesExpansion1]={"additional"->1,"Yorder"->5};
SeriesExpansion1[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{-1+z->z1,-1+zz->zz1}/.{I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}/.{zz1->u/v/(z1)}//Expand)/.{Power[z1,a_/;(a<0)]:>Power[(zz1)*v/u,-a]})/(-Sqrt[(-1+u-v)^2-4 v]))/.zrep/.{z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion1P];
Options[SeriesExpansion1P]={"additional"->1,"Yorder"->5};
SeriesExpansion1P[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{-1+z->z1,-1+zz->zz1}/.{I[z,1,0]->Log[u],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}/.{zz1->u/(z1)}//Expand)/.{Power[z1,a_/;(a<0)]:>Power[(zz1)/u,-a]})/(-Sqrt[-4 v+(1-u+v)^2]))/.zrep/.{z1->1/2 (-1-u+v-Sqrt[-4 v+(1-u+v)^2]),zz1->1/2 (-1-u+v+Sqrt[-4 v+(1-u+v)^2])}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
(* --- einf straight: double pole --- *)
ClearAll[SeriesExpansion2Inf];
Options[SeriesExpansion2Inf]={"additional"->1,"Yorder"->5};
SeriesExpansion2Inf[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{zz->1/u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*u,-a]})/(-4 u+(-1-u+v)^2))/.zrep/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]}/.{z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion2InfP];
Options[SeriesExpansion2InfP]={"additional"->1,"Yorder"->5};
SeriesExpansion2InfP[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{zz->v/u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*u/v,-a]})/(-4 u v+(-1+u+v)^2))/.zrep/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u/v]}/.{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 u),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 u)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion20];
Options[SeriesExpansion20]={"additional"->1,"Yorder"->5};
SeriesExpansion20[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=(((((temp[[i]]*OptionValue["additional"]/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]})/.{zz->u/z}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz/u,-a]})/(-4 u+(1+u-v)^2))/.zrep/.{z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion20P];
Options[SeriesExpansion20P]={"additional"->1,"Yorder"->5};
SeriesExpansion20P[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=(((((temp[[i]]*OptionValue["additional"]/.{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u/v]})/.{zz->u/z/v}//Expand)/.{Power[z,a_/;(a<0)]:>Power[zz*v/u,-a]})/(-4 u v+(-1+u+v)^2))/.zrep/.{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 v),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion21];
Options[SeriesExpansion21]={"additional"->1,"Yorder"->5};
SeriesExpansion21[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{-1+z->z1,-1+zz->zz1}/.{I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}/.{zz1->u/v/(z1)}//Expand)/.{Power[z1,a_/;(a<0)]:>Power[(zz1)*v/u,-a]})/((-1+u-v)^2-4 v))/.zrep/.{z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];
ClearAll[SeriesExpansion21P];
Options[SeriesExpansion21P]={"additional"->1,"Yorder"->5};
SeriesExpansion21P[temp_,zrep_,OptionsPattern[]]:=Module[{result,test,test1},
result=Reap[Do[
test=((((temp[[i]]*OptionValue["additional"]/.{-1+z->z1,-1+zz->zz1}/.{I[z,1,0]->Log[u],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}/.{zz1->u/(z1)}//Expand)/.{Power[z1,a_/;(a<0)]:>Power[(zz1)/u,-a]})/(-4 v+(1-u+v)^2))/.zrep/.{z1->1/2 (-1-u+v-Sqrt[-4 v+(1-u+v)^2]),zz1->1/2 (-1-u+v+Sqrt[-4 v+(1-u+v)^2])}/.{v->1-Y}//Expand);
If[Head[test]===Plus,test=List@@test,test={test}];
test1=ParallelTable[Series[test[[i]],{u,0,0},{Y,0,OptionValue["Yorder"]},Assumptions->{Y>0}]//Normal//Expand,{i,1,Length[test]}];
Sow[test1//Total//Expand];
,{i,1,Length[temp]}]][[2]];
If[result=!={},Return[result[[1]]],Return[{}]];
];

(* --- einf permuted: simple pole --- *)
(*  MAIN PIPELINE                                                     *)
(* =================================================================== *)

ClearAll[RunSeriesExpansion];

RunSeriesExpansion[rootDir_, label_, lsBase_, poleType_, weightN_, yOrder_:4, svIndices_:{}, mplIndices_:{}, poleOrder_:1] := Module[
  {svliste0, svlistmple0, svliste1, svlistmple1, svlisteinf, svlistmpleinf,
   i, add, svRes, mplRes, suffix, zrep},

  (* ---- load pre-computed .txt files from root ---- *)
  svliste0     = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svliste1     = Import[FileNameJoin[{rootDir, "allsvliste1_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlisteinf   = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}],  "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlistmple0   = Import[FileNameJoin[{rootDir, "allsvlistmpl_threeloopharde0.txt"}],  "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlistmple1   = Import[FileNameJoin[{rootDir, "allsvlistmpl_threeloopharde1.txt"}],  "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlistmpleinf = Import[FileNameJoin[{rootDir, "allsvlistmpl_threeloophardeinf.txt"}],"String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

  (* ---- optionally reduce to only ansatz-relevant indices ---- *)
  If[svIndices =!= {},
    svliste0   = svliste0[[svIndices]];
    svliste1   = svliste1[[svIndices]];
    svlisteinf = svlisteinf[[svIndices]];
    Print["[Skill 1] Reduced SVHPL to ", Length[svliste0], " elements from ansatz indices"];
  ];
  If[mplIndices =!= {},
    svlistmple0   = svlistmple0[[mplIndices]];
    svlistmple1   = svlistmple1[[mplIndices]];
    svlistmpleinf = svlistmpleinf[[mplIndices]];
  ,
    (* no MPL elements needed — set to empty *)
    svlistmple0   = {};
    svlistmple1   = {};
    svlistmpleinf = {};
  ];

  (* ---- compute six additional prefactors ---- *)
  Print["[Skill 1] Starting 6 expansions, poleType=", poleType, ", n=", weightN,
    ", k=", poleOrder, ", SVHPL=", Length[svliste0], ", MPL=", Length[svlistmple0]];
  For[i = 1, i <= 6, i++,
    Module[{uRule, vRule, F, transformed, ptr, headSV, headMPL},

      (* solving order: {1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4} *)
      Switch[i,
        1, {uRule = u->u;   vRule = v->v;   F = 1; ptr = 0},   (* {1,2,3,4} e0uv *)
        2, {uRule = u->u/v; vRule = v->1/v; F = v; ptr = 0},   (* {2,1,3,4} e0uvp *)
        3, {uRule = u->1/u; vRule = v->v/u; F = u; ptr = 2},   (* {1,3,2,4} einfuv *)
        4, {uRule = u->v/u; vRule = v->1/u; F = u; ptr = 2},   (* {2,3,1,4} einfuvp *)
        5, {uRule = u->1/v; vRule = v->u/v; F = v; ptr = 1},   (* {3,1,2,4} e1uv *)
        6, {uRule = u->v;   vRule = v->u;   F = 1; ptr = 1}    (* {3,2,1,4} e1uvp *)
      ];

      transformed = Simplify[lsBase /. {uRule, vRule}];
      add = If[F === 1, transformed, Simplify[transformed / F^(weightN - poleOrder)]];
      Print["[Skill 1] Limit ", i, "/6: additional = ", add // InputForm];

      Which[
        ptr == 0 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansion0,   "double"->SeriesExpansion20}; headMPL = headSV},
        ptr == 0 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansion0P,  "double"->SeriesExpansion20P}; headMPL = headSV},
        ptr == 1 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansion1,   "double"->SeriesExpansion21}; headMPL = headSV},
        ptr == 1 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansion1P,  "double"->SeriesExpansion21P}; headMPL = headSV},
        ptr == 2 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansionInf, "double"->SeriesExpansion2Inf}; headMPL = headSV},
        ptr == 2 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansionInfP,"double"->SeriesExpansion2InfP}; headMPL = headSV}
      ];

      Switch[ptr,
        0, If[OddQ[i],
             {zrep = zrep0;     svRes  = headSV[svliste0,      zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmple0,   zrep, "Yorder"->yOrder, "additional"->add]},
             {zrep = zrep0P;   svRes  = headSV[svliste0,      zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmple0,   zrep, "Yorder"->yOrder, "additional"->add]}],
        1, If[OddQ[i],  (* i=5 → e1uv, i=6 → e1uvp *)
             {zrep = zrep1;     svRes  = headSV[svliste1,      zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmple1,   zrep, "Yorder"->yOrder, "additional"->add]},
             {zrep = zrep1P;   svRes  = headSV[svliste1,      zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmple1,   zrep, "Yorder"->yOrder, "additional"->add]}],
        2, If[OddQ[i],  (* i=3 → einfuv, i=4 → einfuvp *)
             {zrep = zrepInf;   svRes  = headSV[svlisteinf,    zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmpleinf, zrep, "Yorder"->yOrder, "additional"->add]},
             {zrep = zrepInfP; svRes  = headSV[svlisteinf,    zrep, "Yorder"->yOrder, "additional"->add];
                                mplRes = headMPL[svlistmpleinf, zrep, "Yorder"->yOrder, "additional"->add]}]
      ];

      suffix = Switch[ptr,
        0, If[OddQ[i], "e0uv", "e0uvp"],
        1, If[OddQ[i], "e1uv", "e1uvp"],
        2, If[OddQ[i], "einfuv", "einfuvp"]
      ];

      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> suffix <> ".m"}], svRes];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> suffix <> ".m"}], mplRes];
      Print["[Skill 1] Limit ", i, "/6 (", suffix, "): done."];
    ]
  ];

  Print["Series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
];
