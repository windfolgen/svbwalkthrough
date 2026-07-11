(* ::Package:: *)
(* =================================================================== *)
(*  Skill 1: Mirror Ansatz Series Expansion Agent                      *)
(*  Location: ./series_agent/series_agent_mirror.wl                    *)
(*                                                                     *)
(*  Input files contain basisTerm * poleSeries * add factor already.   *)
(*  Only transformation needed: z/zz -> u/Y via zrep, then Series.     *)
(*  Uses ParallelTable for performance.                                 *)
(* =================================================================== *)

(* zrep for einf *)
zrepInf = Table[{
  Power[z, i]  -> (Power[(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for einfP *)
zrepInfP = Table[{
  Power[z, i]  -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0 *)
zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0P *)
zrep0P = Table[{
  Power[z, i]  -> (Power[(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1 *)
zrep1 = Table[{
  Power[z, i]    -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u - v - Sqrt[(-1 + u - v)^2 - 4 v])/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u - v + Sqrt[(-1 + u - v)^2 - 4 v])/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1P *)
zrep1P = Table[{
  Power[z, i]    -> (Power[1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]    /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), i]   /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

ClearAll[RunSeriesExpansionMirror, ParseListString];

ParseListString[s_String] := Module[{trim = StringTrim[s]},
  If[StringStartsQ[trim, "["] && StringEndsQ[trim, "]"],
    ToExpression["{" <> StringTrim[trim, "["|"]"] <> "}"],
    If[StringStartsQ[trim, "{"] && StringEndsQ[trim, "}"],
      ToExpression[trim],
      ToExpression["{" <> trim <> "}"]
    ]
  ]
];

RunSeriesExpansionMirror[rootDir_, label_, config_, lsBase_, poleType_, yOrder_:4, svIndices_:{}, mplIndices_:{}, poleOrder_:1, mplBasisFile_:None] := Module[
  {i, svRes, mplRes, suffix, mplPrefix,
   suffixes, existingFiles, dataDir, hasI0constant, lsIdx},

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  dataDir = $DataDir;

  lsIdx = 1;
  If[Length[config["LeadingSingularities"]] > 1,
    Module[{match},
      match = StringCases[label, "_ls" ~~ n : NumberString :> ToExpression[n]];
      If[Length[match] > 0, lsIdx = match[[-1]]];
    ];
  ];
  hasI0constant = !FreeQ[config["LeadingSingularities"][[lsIdx, 3]], I0constant];

  If[mplBasisFile =!= None,
    mplPrefix = FileBaseName[mplBasisFile];
  ];

  mirrorLimits = $MirrorLimits;
  suffixes = Switch[#, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"] & /@ mirrorLimits;
  existingFiles = Flatten[Table[
    With[{sfx = s},
      Select[{
        FileNameJoin[{rootDir, "series_agent", label <> "_svlist_mirror" <> sfx <> ".m"}],
        FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl_mirror" <> sfx <> ".m"}]
      }, FileExistsQ]
    ],
    {s, suffixes}
  ]];
  
  If[Length[existingFiles] == 2 * Length[mirrorLimits],
    Module[{cacheValid = True, expectedSVLen, expectedMPLLen, svData, mplData},
      expectedSVLen = Length[svIndices] + If[hasI0constant, 1, 0];
      expectedMPLLen = Length[mplIndices];
      Do[
        With[{sfx = s},
          Quiet[
            svData = Import[FileNameJoin[{rootDir, "series_agent", label <> "_svlist_mirror" <> sfx <> ".m"}]];
            mplData = Import[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl_mirror" <> sfx <> ".m"}]];
            If[Length[svData] =!= expectedSVLen || Length[mplData] =!= expectedMPLLen,
              cacheValid = False;
            ];
          ];
        ],
        {s, suffixes}
      ];
      If[cacheValid,
        Print["[Skill 1 Mirror] All ", Length[existingFiles], " series expansion files already exist. Skipping expansion!"];
        Return[];
      ,
        Print["[Skill 1 Mirror] Stale series cache detected. Forcing regeneration..."];
      ];
    ];
  ];
  If[existingFiles =!= {},
    Print["[Skill 1 Mirror] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
  ];

  Print["[Skill 1 Mirror] Starting ", Length[mirrorLimits], " expansions (limits: ", mirrorLimits, "), poleType=", poleType,
    ", SVHPL indices=", Length[svIndices], ", MPL indices=", Length[mplIndices]];

  If[Length[Kernels[]] == 0, LaunchKernels[]];
    
  For[i = 1, i <= 6, i++,
    If[!MemberQ[mirrorLimits, i], Continue[]];

    Module[{ptr, svFile, mplFile, svList, mplList, ExpandInuvList, svResList, mplResList,
            ext, suffix, assumption, basisListN},

      Switch[i,
        1, {ptr = 0; suffix = "e0uv";    ext = "e0"},
        2, {ptr = 0; suffix = "e0uvp";   ext = "e0p"},
        3, {ptr = 2; suffix = "einfuv";  ext = "einf"},
        4, {ptr = 2; suffix = "einfuvp"; ext = "einfp"},
        5, {ptr = 1; suffix = "e1uv";    ext = "e1"},
        6, {ptr = 1; suffix = "e1uvp";   ext = "e1p"}
      ];

      poleNum = If[poleType === "simple", 1, 2];
      svFile = FileNameJoin[{dataDir, "allsvlist_fourloop_" <> ext <> "_" <> ToString[poleNum] <> "_order5.txt"}];
      If[!FileExistsQ[svFile],
        svFile = FileNameJoin[{dataDir, "allsvlist_fourloop_" <> ext <> "_" <> ToString[poleNum] <> ".txt"}];
      ];
      
      Print["[Skill 1 Mirror] Loading ", FileNameTake[svFile], "..."];
      svList = ParseListString[Import[svFile, "String"]];
      If[svIndices =!= {}, svList = svList[[svIndices]]];
      
      If[hasI0constant,
        AppendTo[svList, I0constant];
      ];

      If[mplBasisFile =!= None && mplIndices =!= {},
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
          Print["[Skill 1 Mirror] ERROR: Missing MPL basis file ", mplFile];
          mplList = {};
        ];
      ,
        mplList = {};
      ];

      assumption = If[OddQ[i], Y > 0, Y < 0];

      ExpandInuvList[basisList_] := Module[{len},
        len = Length[basisList];
        Table[
          Module[{expr},
            If[basisList[[j]] === I0constant,
              expr = 1;
            ,
              expr = basisList[[j]];
            ];
            Switch[ptr,
              0, If[OddQ[i],
                   expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]} /. {zz->u/z};
                   expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz/u, -a]};
                   expr = expr /. zrep0 /. {v -> 1 - Y};
                 ,
                   expr = expr /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]} /. {zz->u/z/v};
                   expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*v/u, -a]};
                   expr = expr /. zrep0P /. {v -> 1 - Y};
                 ],
              1, If[OddQ[i],
                   expr = expr /. {-1 + z -> z1, -1 + zz -> zz1}
                     /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}
                     /. {zz1 -> u/v/(z1)}
                     /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)*v/u, -a]} // Expand;
                   expr = expr /. zrep1;
                  expr = expr /. {
                    z  -> ((1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v) /. {v -> 1 - Y}),
                    zz -> ((1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v) /. {v -> 1 - Y}),
                    z1 -> ((1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}),
                    zz1 -> ((1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y})
                  };
                 ,
                   expr = expr /. {-1 + z -> z1, -1 + zz -> zz1}
                     /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}
                     /. {zz1 -> u/(z1)}
                     /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)/u, -a]} // Expand;
                   expr = expr /. zrep1P;
                  expr = expr /. {
                    z  -> (1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
                    zz -> (1/2*(1 - u + v + Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
                    z1 -> (1/2*(-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}),
                    zz1 -> (1/2*(-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y})
                  };
                 ],
              2, If[OddQ[i],
                   expr = expr /. {zz -> 1/u/z};
                   expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*u, -a]};
                   expr = expr /. zrepInf /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]} /. {z -> (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u), zz -> (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u)} /. {v -> 1 - Y};
                 ,
                   expr = expr /. {zz -> v/u/z};
                   expr = expr /. {Power[z, a_ /; (a < 0)] :> Power[zz*u/v, -a]};
                   expr = expr /. zrepInfP /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u/v]} /. {z -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), zz -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u)} /. {v -> 1 - Y};
                 ]
            ];
            expr = expr /. {Log[u] -> logU};
            expr = Normal[Series[expr, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {assumption}]];
            (expr /. {logU -> Log[u]}) // Expand
          ],
          {j, 1, len}
        ]
      ];

      Print["[Skill 1 Mirror] Limit ", i, " expand ", Length[svList], " SV terms + ", Length[mplList], " MPL terms..."];
      tStart = AbsoluteTime[];
      svResList = ExpandInuvList[svList];
      tSv = AbsoluteTime[] - tStart;
      Print["[Skill 1 Mirror] SV done in ", tSv, "s"];
      If[Length[mplList] > 0,
        mplResList = ExpandInuvList[mplList];
      ,
        mplResList = {};
      ];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlist_mirror" <> suffix <> ".m"}], svResList];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl_mirror" <> suffix <> ".m"}], mplResList];
      Print["[Skill 1 Mirror] Limit ", i, "/6 (", suffix, "): done."];
    ]
  ];

  CloseKernels[];
  Print["Mirrored series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
];
