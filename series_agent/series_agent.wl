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

RunSeriesExpansion[rootDir_, label_, lsBase_, poleType_, weightN_, yOrder_:4, svIndices_:{}, mplIndices_:{}, poleOrder_:1, mplBasisFile_:None] := Module[
  {svliste0, svlistmple0, svliste1, svlistmple1, svlisteinf, svlistmpleinf,
   i, add, svRes, mplRes, suffix, zrep, mplPrefix},

  (* ---- load pre-computed .txt files from root ---- *)
  svliste0     = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svliste1     = Import[FileNameJoin[{rootDir, "allsvliste1_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlisteinf   = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}],  "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

  (* ---- load MPL expansion files (if a basis is provided) ---- *)
  If[mplBasisFile =!= None && mplIndices =!= {},
    mplPrefix = FileBaseName[mplBasisFile] <> "e";  (* strip .m + path, append e *)
    (* .txt format: string-wrapped list, needs parsing.
       .m   format: Mathematica expression list, no parsing needed. *)
    mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
      raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
              If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
      fmt = raw[[2]];
      If[fmt === "txt",
        (* .txt files: string-wrapped list, parse via StringTrim + ToExpression *)
        StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression,
        (* .m files: already valid Mathematica expressions *)
        raw[[1]]
      ]
    ];
    (* detect format for output log *)
    mplFormat = If[FileExistsQ[FileNameJoin[{rootDir, mplPrefix <> "0.m"}]], ".m", ".txt"];
    svlistmple0   = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "0"}]];
    svlistmple1   = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "1"}]];
    svlistmpleinf = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "inf"}]];
    If[svlistmple0 === $Failed || svlistmple1 === $Failed || svlistmpleinf === $Failed,
      Print["[Skill 1] ERROR: Missing MPL expansions for '", mplPrefix, "{0,1,inf}.txt/.m'. ",
        "The three series expansions of SVMPL around z=0, z=1 and z=inf need to be provided to cover the ansatz."];
      Return[$Failed]
    ];
    Print["[Skill 1] Loaded MPL expansions: ", mplPrefix, "{0,1,inf} (format: ",
      mplFormat <> If[mplFormat === ".m", ", no parsing needed", ", parsed from string-wrapped list"] <> ")"];
  ,
    svlistmple0   = {};
    svlistmple1   = {};
    svlistmpleinf = {};
  ];

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

  (* ---- warn if overwriting existing output files ---- *)
  suffixes = {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"};
  existingFiles = Flatten[Table[
    With[{sfx = s},
      Select[{
        FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> sfx <> ".m"}],
        FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> sfx <> ".m"}]
      }, FileExistsQ]
    ],
    {s, suffixes}
  ]];
  If[existingFiles =!= {},
    Print["[Skill 1] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
    Print["[Skill 1] Proceed and overwrite? (y/n)"];
    response = InputString[];
    If[!StringMatchQ[response, "y" | "Y" | "yes" | "Yes"],
      Print["[Skill 1] ABORTED by user — existing files preserved."];
      Return[$Failed]
    ];
    Print["[Skill 1] Overwriting " , Length[existingFiles], " existing files."];
  ];

  (* ---- compute six additional prefactors ---- *)
  Print["[Skill 1] Starting 6 expansions, poleType=", poleType, ", n=", weightN,
    ", k=", poleOrder, ", SVHPL=", Length[svliste0], ", MPL=", Length[svlistmple0]];
  For[i = 1, i <= 6, i++,
    Module[{uRule, vRule, F, transformed, ptr, suffix, svFile, mplFile, svList, mplList, ExpandInuvList, zrep, svRes, mplRes},

      Switch[i,
        1, {uRule = u->u;   vRule = v->v;   F = 1; ptr = 0; suffix = "e0uv";
            svFile = "allsvliste0_uptow8_inuv.m";           mplFile = "allsvlistmpl_threeloope0_inuv.txt"},
        2, {uRule = u->u/v; vRule = v->1/v; F = v; ptr = 0; suffix = "e0uvp";
            svFile = "allsvliste0_uptow8_inuvp.m";          mplFile = "allsvlistmpl_threeloope0_inuvp.txt"},
        3, {uRule = u->1/u; vRule = v->v/u; F = u; ptr = 2; suffix = "einfuv";
            svFile = "allsvlisteinf_uptow8_inuv.m";       mplFile = "allsvlistmpl_threeloopeinf_inuv.txt"},
        4, {uRule = u->v/u; vRule = v->1/u; F = u; ptr = 2; suffix = "einfuvp";
            svFile = "allsvlisteinf_uptow8_inuvp.m";      mplFile = "allsvlistmpl_threeloopeinf_inuvp.txt"},
        5, {uRule = u->1/v; vRule = v->u/v; F = v; ptr = 1; suffix = "e1uv";
            svFile = "allsvliste1_uptow8_inuv.m";           mplFile = "allsvlistmpl_threeloope1_inuv.txt"},
        6, {uRule = u->v;   vRule = v->u;   F = 1; ptr = 1; suffix = "e1uvp";
            svFile = "allsvliste1_uptow8_inuvp.m";          mplFile = "allsvlistmpl_threeloope1_inuvp.txt"}
      ];

      svList = Get[FileNameJoin[{rootDir, svFile}]];
      If[svIndices =!= {}, svList = svList[[svIndices]]];

      If[mplBasisFile =!= None && mplIndices =!= {},
        mplList = Import[FileNameJoin[{rootDir, mplFile}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
        mplList = mplList[[mplIndices]];
      ,
        mplList = {};
      ];

      transformed = Simplify[lsBase /. {uRule, vRule}];
      add = If[F === 1, transformed, Simplify[transformed / F^(weightN - poleOrder)]] /. {v -> 1 - Y} // Expand;
      Print["[Skill 1] Limit ", i, "/6: additional = ", add // InputForm];

      ExpandInuvList[basisList_, sqrtSeries_, expTerm_] := ParallelTable[
        Module[{test, test2, seriesY},
          test = If[poleType === "simple",
            basisList[[j]] * add * (-sqrtSeries) / expTerm,
            basisList[[j]] * add * (-1) / expTerm
          ];
          test2 = (test /. {Log[u] -> logU});
          seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {Y > 0}] // Normal;
          (seriesY /. {logU -> Log[u]}) // Expand
        ],
        {j, 1, Length[basisList]}
      ];

      Module[{radical, sqrtSeries, expTerm},
        Switch[ptr,
          0, If[OddQ[i], 
               {radical = Sqrt[-4*u + (u + Y)^2]; expTerm = -4*u + (u + Y)^2;
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand},
               {radical = Sqrt[-4*u*(1 - Y) + (u - Y)^2]; expTerm = -4*u*(1 - Y) + (u - Y)^2;
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand}],
          1, If[OddQ[i],
               {radical = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)]; expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand},
               {radical = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)]; expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand}],
          2, If[OddQ[i],
               {radical = Sqrt[-4*u + (u + Y)^2]; expTerm = -4*u + (u + Y)^2;
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand},
               {radical = Sqrt[-4*u*(1 - Y) + (u - Y)^2]; expTerm = -4*u*(1 - Y) + (u - Y)^2;
                sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand}]
        ];
        
        svRes = ExpandInuvList[svList, sqrtSeries, expTerm];
        If[Length[mplList] > 0,
          mplRes = ExpandInuvList[mplList, sqrtSeries, expTerm];
        ,
          mplRes = {};
        ];
      ];

      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> suffix <> ".m"}], svRes];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> suffix <> ".m"}], mplRes];
      Print["[Skill 1] Limit ", i, "/6 (", suffix, "): done."];
    ]
  ];

  Print["Series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
];
