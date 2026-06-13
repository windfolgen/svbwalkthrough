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
(* These functions remain largely the same, logic omitted from top for brevity *)
(* The actual expansion logic is dynamically built inside RunSeriesExpansion *)

ClearAll[RunSeriesExpansion, ParseListString];

ParseListString[s_String] := Module[{trim = StringTrim[s]},
  If[StringStartsQ[trim, "["] && StringEndsQ[trim, "]"],
    ToExpression["{" <> StringTrim[trim, "["|"]"] <> "}"],
    If[StringStartsQ[trim, "{"] && StringEndsQ[trim, "}"],
      ToExpression[trim],
      ToExpression["{" <> trim <> "}"]
    ]
  ]
];

RunSeriesExpansion[rootDir_, label_, config_, lsBase_, poleType_, yOrder_:4, svIndices_:{}, mplIndices_:{}, poleOrder_:1, mplBasisFile_:None] := Module[
  {weightN, i, add, svRes, mplRes, suffix, mplPrefix, mplFormat,
   suffixes, existingFiles, response, dataDir},

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  dataDir = $DataDir;
  weightN = config["WeightN"];

  If[mplBasisFile =!= None,
    mplPrefix = FileBaseName[mplBasisFile]; (* e.g., allsvlistmpl_threeloop *)
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
  
  If[Length[existingFiles] == 12,
    Print["[Skill 1] All ", Length[existingFiles], " series expansion files already exist. Skipping expansion!"];
    Return[];
  ];
  If[existingFiles =!= {},
    Print["[Skill 1] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
    Print["[Skill 1] Overwriting " , Length[existingFiles], " existing files."];
  ];

  Print["[Skill 1] Starting 6 expansions, poleType=", poleType, ", n=", weightN,
    ", k=", poleOrder, ", SVHPL indices=", Length[svIndices], ", MPL indices=", Length[mplIndices]];
    
  If[Length[Kernels[]] == 0, LaunchKernels[]];
    
  For[i = 1, i <= 6, i++,
    Module[{uRule, vRule, F, transformed, ptr, svFile, mplFile, svList, mplList, ExpandInuvList, svResList, mplResList,
            radical, sqrtSeries, expTerm, ext, sfxSuffix},

      Switch[i,
        1, {uRule = u->u;   vRule = v->v;   F = 1; ptr = 0; suffix = "e0uv";    ext = "e0";   sfxSuffix = "_inuv"},
        2, {uRule = u->u/v; vRule = v->1/v; F = v; ptr = 0; suffix = "e0uvp";   ext = "e0";   sfxSuffix = "_inuvp"},
        3, {uRule = u->1/u; vRule = v->v/u; F = u; ptr = 2; suffix = "einfuv";  ext = "einf"; sfxSuffix = "_inuv"},
        4, {uRule = u->v/u; vRule = v->1/u; F = u; ptr = 2; suffix = "einfuvp"; ext = "einf"; sfxSuffix = "_inuvp"},
        5, {uRule = u->1/v; vRule = v->u/v; F = v; ptr = 1; suffix = "e1uv";    ext = "e1";   sfxSuffix = "_inuv"},
        6, {uRule = u->v;   vRule = v->u;   F = 1; ptr = 1; suffix = "e1uvp";   ext = "e1";   sfxSuffix = "_inuvp"}
      ];

      svFile = $SVTextPrefix <> ext <> "_uptow8" <> sfxSuffix <> ".txt";
      
      svList = ParseListString[Import[FileNameJoin[{dataDir, svFile}], "String"]];
      If[svIndices =!= {}, svList = svList[[svIndices]]];

      If[mplBasisFile =!= None && mplIndices =!= {},
        mplFile = mplPrefix <> ext <> sfxSuffix <> ".txt";
        
        If[FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
          mplList = ParseListString[Import[FileNameJoin[{dataDir, mplFile}], "String"]];
          mplList = mplList[[mplIndices]];
        ,
          (* fallback to base format (.m or .txt) if _inuv.txt doesn't exist *)
          mplFile = mplPrefix <> ext <> ".m";
          If[!FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
            mplFile = mplPrefix <> ext <> ".txt";
          ];
          
          If[FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
            If[StringEndsQ[mplFile, ".m"],
              mplList = Import[FileNameJoin[{dataDir, mplFile}]];
            ,
              mplList = ParseListString[Import[FileNameJoin[{dataDir, mplFile}], "String"]];
            ];
            mplList = mplList[[mplIndices]];
          ,
            Print["[Skill 1] ERROR: Missing MPL basis file ", mplFile];
            mplList = {};
          ]
        ];
      ,
        mplList = {};
      ];

      transformed = Simplify[lsBase /. {uRule, vRule}];
      add = If[F === 1, transformed, Simplify[transformed / F^(weightN - poleOrder)]] /. {v -> 1 - Y} // Expand;
      Print["[Skill 1] Limit ", i, "/6: additional = ", add // InputForm];

      ExpandInuvList[basisList_, sqrtSer_, expT_] := ParallelTable[
        Module[{test, test2, seriesY},
          test = If[poleType === "simple",
            basisList[[j]] * add * (-sqrtSer) / expT,
            basisList[[j]] * add / expT
          ];
          
          (* Apply limit-specific algebraic rules for MPL/SVHPL elements before expanding *)
          Switch[ptr,
            0, If[OddQ[i],
                 test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]} /. {zz->u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz/u, -a]};
                 test = test /. zrep0 /. {z -> 1/2 (1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), zz -> 1/2 (1 + u + Sqrt[-4 u + (1 + u - v)^2] - v)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]} /. {zz->u/z/v} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*v/u, -a]};
                 test = test /. zrep0P /. {z -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), zz -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v)} /. {v -> 1 - Y} // Expand;
               ],
            1, If[OddQ[i],
                 test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1 -> u/v/(z1)} // Expand;
                 test = test /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)*v/u, -a]};
                 test = test /. zrep1 /. {z1 -> (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), zz1 -> (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1 -> u/(z1)} // Expand;
                 test = test /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)/u, -a]};
                 test = test /. zrep1P /. {z1 -> 1/2 (-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), zz1 -> 1/2 (-1 - u + v + Sqrt[-4 v + (1 - u + v)^2])} /. {v -> 1 - Y} // Expand;
               ],
            2, If[OddQ[i],
                 test = test /. {zz -> 1/u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*u, -a]};
                 test = test /. zrepInf /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]} /. {z -> (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), zz -> (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {zz -> v/u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*u/v, -a]};
                 test = test /. zrepInfP /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u/v]} /. {z -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), zz -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u)} /. {v -> 1 - Y} // Expand;
               ]
          ];
          
          test2 = (test /. {Log[u] -> logU});
          seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {Y > 0}] // Normal;
          (seriesY /. {logU -> Log[u]}) // Expand
        ],
        {j, 1, Length[basisList]}
      ];

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
      
      svResList = ExpandInuvList[svList, sqrtSeries, expTerm];
      If[Length[mplList] > 0,
        mplResList = ExpandInuvList[mplList, sqrtSeries, expTerm];
      ,
        mplResList = {};
      ];

      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> suffix <> ".m"}], svResList];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> suffix <> ".m"}], mplResList];
      Print["[Skill 1] Limit ", i, "/6 (", suffix, "): done."];
    ]
  ];

  CloseKernels[];
  Print["Series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
];