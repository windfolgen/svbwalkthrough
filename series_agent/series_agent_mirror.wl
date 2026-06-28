(* =================================================================== *)
(*  Skill 1: Mirror Ansatz Series Expansion Agent                      *)
(*  Location: ./series_agent/series_agent_mirror.wl                    *)
(* =================================================================== *)

(* =================================================================== *)
(*  zrep DEFINITIONS (6 limits, labelled by variable name)              *)
(* =================================================================== *)

(* zrep for einf: used by SeriesExpansionInf, SeriesExpansion2Inf *)
zrepInf = Table[{
  Power[z, i]  -> (Power[2/(1 + u - v - Sqrt[-4 u + (-1 - u + v)^2]), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[2/(1 + u - v + Sqrt[-4 u + (-1 - u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for einfP: used by SeriesExpansionInfP, SeriesExpansion2InfP *)
zrepInfP = Table[{
  Power[z, i]  -> (Power[(2*v)/(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(2*v)/(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0: used by SeriesExpansion0, SeriesExpansion20 *)
zrep0 = Table[{
  Power[z, i]  -> (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e0P: used by SeriesExpansion0P, SeriesExpansion20P *)
zrep0P = Table[{
  Power[z, i]  -> (Power[(2*u)/(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i] -> (Power[(2*u)/(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1: used by SeriesExpansion1, SeriesExpansion21 *)
zrep1 = Table[{
  Power[z, i]    -> (Power[2 / (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[2 / (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[2 / (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v) - 1, i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[2 / (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v) - 1, i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
  }, {i, 1, 10}] // Flatten;

(* zrep for e1P: used by SeriesExpansion1P, SeriesExpansion21P *)
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
  {weightN, i, add, svRes, mplRes, suffix, mplPrefix, mplFormat,
   suffixes, existingFiles, response, dataDir, hasI0constant, lsIdx},

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  dataDir = $DataDir;
  weightN = config["WeightN"];

  lsIdx = 1;
  If[Length[config["LeadingSingularities"]] > 1,
    Module[{match},
      match = StringCases[label, "_ls" ~~ n : NumberString :> ToExpression[n]];
      If[Length[match] > 0, lsIdx = match[[-1]]];
    ];
  ];
  hasI0constant = !FreeQ[config["LeadingSingularities"][[lsIdx, 3]], I0constant];

  If[mplBasisFile =!= None,
    mplPrefix = FileBaseName[mplBasisFile]; (* e.g., allsvlistmpl_threeloop *)
  ];

  (* ---- warn if overwriting existing output files ---- *)
  suffixes = {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"};
  existingFiles = Flatten[Table[
    With[{sfx = s},
      Select[{
        FileNameJoin[{rootDir, "series_agent", label <> "_svlist_mirror" <> sfx <> ".m"}],
        FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl_mirror" <> sfx <> ".m"}]
      }, FileExistsQ]
    ],
    {s, suffixes}
  ]];
  
  If[Length[existingFiles] == 12,
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
        Print["[Skill 1 Mirror] Stale series cache detected (length mismatch). Forcing regeneration..."];
      ];
    ];
  ];
  If[existingFiles =!= {},
    Print["[Skill 1 Mirror] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
    Print["[Skill 1 Mirror] Overwriting " , Length[existingFiles], " existing files."];
  ];

  Print["[Skill 1 Mirror] Starting 6 expansions, poleType=", poleType, ", n=", weightN,
    ", k=", poleOrder, ", SVHPL indices=", Length[svIndices], ", MPL indices=", Length[mplIndices]];
    
  If[Length[Kernels[]] == 0, LaunchKernels[]];
    
  For[i = 1, i <= 6, i++,
    If[i === 3 || i === 4, Continue[]];

    Module[{uRule, vRule, F, transformed, ptr, svFile, mplFile, svList, mplList, ExpandInuvList, svResList, mplResList,
            radical, sqrtSeries, expTerm, ext, sfxSuffix, sign, assumption},

      Switch[i,
        1, {uRule = u->u;   vRule = v->v;   F = 1; ptr = 0; suffix = "e0uv";    ext = "e0";   sfxSuffix = "_inuv"},
        2, {uRule = u->u/v; vRule = v->1/v; F = v; ptr = 0; suffix = "e0uvp";   ext = "e0";   sfxSuffix = "_inuvp"},
        3, {uRule = u->1/u; vRule = v->v/u; F = u; ptr = 2; suffix = "einfuv";  ext = "einf"; sfxSuffix = "_inuv"},
        4, {uRule = u->v/u; vRule = v->1/u; F = u; ptr = 2; suffix = "einfuvp"; ext = "einf"; sfxSuffix = "_inuvp"},
        5, {uRule = u->1/v; vRule = v->u/v; F = v; ptr = 1; suffix = "e1uv";    ext = "e1";   sfxSuffix = "_inuv"},
        6, {uRule = u->v;   vRule = v->u;   F = 1; ptr = 1; suffix = "e1uvp";   ext = "e1";   sfxSuffix = "_inuvp"}
      ];
      sign = Switch[i, 1 | 2 | 5 | 6, 1, 3 | 4, -1];

      svFile = $SVTextPrefix <> ext <> "_uptow8" <> sfxSuffix <> "_mirror.txt";
      If[!FileExistsQ[FileNameJoin[{dataDir, svFile}]],
        svFile = $SVTextPrefix <> ext <> "_uptow8" <> sfxSuffix <> ".txt";
      ];
      
      svList = ParseListString[Import[FileNameJoin[{dataDir, svFile}], "String"]];
      If[svIndices =!= {}, svList = svList[[svIndices]]];
      
      (* Algebraic Mirroring on SV basis elements *)
      svList = svList /. {z -> zz, zz -> z, z1 -> zz1, zz1 -> z1};
      
      If[hasI0constant,
        AppendTo[svList, I0constant];
      ];

      If[mplBasisFile =!= None && mplIndices =!= {},
        mplFile = mplPrefix <> ext <> sfxSuffix <> "_mirror.txt";
        If[!FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
          mplFile = mplPrefix <> ext <> sfxSuffix <> ".txt";
        ];
        
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
            Print["[Skill 1 Mirror] ERROR: Missing MPL basis file ", mplFile];
            mplList = {};
          ]
        ];
        (* Algebraic Mirroring on MPL basis elements *)
        mplList = mplList /. {z -> zz, zz -> z, z1 -> zz1, zz1 -> z1};
      ,
        mplList = {};
      ];

      maxUPole = Module[{exponents},
        exponents = Cases[Join[svList, mplList], u^a_ ?NumberQ :> a, All];
        If[exponents === {}, 0, Max[0, -Min[exponents]]]
      ];

      transformed = Simplify[lsBase /. {uRule, vRule}];
      add = If[F === 1, transformed, Simplify[transformed / F^(weightN - poleOrder)]] /. {v -> 1 - Y} // Expand;
      Print["[Skill 1 Mirror] Limit ", i, "/6: additional = ", add // InputForm];

      prefactorExpansion = Module[{test},
        test = If[poleType === "simple",
          add * (1/z + zz/z^2 + zz^2/z^3),
          add * (1/z^2 + (2 zz)/z^3 + (3 zz^2)/z^4)
        ];
        
        (* Apply limit-specific substitutions *)
        Switch[ptr,
          0, If[OddQ[i],
               test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[zz,0,0]->Log[u]} /. {z->u/zz} // Expand;
               test = test /. {Power[zz, a_ /; (a < 0)] :> Power[z/u, -a]};
               test = test /. zrep0 /. {z -> 1/2 (1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), zz -> 1/2 (1 + u + Sqrt[-4 u + (1 + u - v)^2] - v)} /. {v -> 1 - Y} // Expand;
             ,
               test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[zz,0,0]->Log[u/v]} /. {z->u/zz/v} // Expand;
               test = test /. {Power[zz, a_ /; (a < 0)] :> Power[z*v/u, -a]};
               test = test /. zrep0P /. {z -> 1/2 * (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]), zz -> 1/2 * (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])} /. {v -> 1 - Y} // Expand;
             ],
          1, If[OddQ[i],
               test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[zz,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {z1 -> u/v/(zz1)} // Expand;
               test = test /. {Power[zz1, a_ /; (a < 0)] :> Power[(z1)*v/u, -a]};
               test = test /. zrep1 /. {z1 -> 1/2 * (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v), zz1 -> 1/2 * (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)} /. {v -> 1 - Y} // Expand;
             ,
               test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[zz,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {z1 -> u/(zz1)} // Expand;
               test = test /. {Power[zz1, a_ /; (a < 0)] :> Power[(z1)/u, -a]};
               test = test /. zrep1P /. {z1 -> 1/2 (-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]), zz1 -> 1/2 (-1 - u + v + Sqrt[-4 v + (1 - u + v)^2])} /. {v -> 1 - Y} // Expand;
             ]
        ];
        
        test = test /. {Log[u] -> logU};
        test = Series[test, {u, 0, maxUPole}, {Y, 0, yOrder}, Assumptions -> {If[OddQ[i], Y > 0, Y < 0]}] // Normal;
        test /. {logU -> Log[u]} // Expand
      ];

      ExpandInuvList[basisList_, prefExp_] := ParallelTable[
        Module[{basisTerm, test2, seriesY, assumption},
          basisTerm = If[basisList[[j]] === I0constant, 1, basisList[[j]]];
          assumption = If[OddQ[i], Y > 0, Y < 0];
          test2 = (basisTerm * prefExp) /. {Log[u] -> logU};
          seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {assumption}] // Normal;
          (seriesY /. {logU -> Log[u]}) // Expand
        ],
        {j, 1, Length[basisList]}
      ];

      svResList = ExpandInuvList[svList, prefactorExpansion];
      If[Length[mplList] > 0,
        mplResList = ExpandInuvList[mplList, prefactorExpansion];
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
