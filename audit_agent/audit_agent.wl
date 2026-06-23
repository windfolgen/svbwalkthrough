(* =================================================================== *)
(*  Skill 4: Audit Agent                                               *)
(*  Location: ./audit_agent/                                           *)
(*                                                                     *)
(*  Performs basic file-existence and format validation after each     *)
(*  pipeline stage. Designed to be always-on in the pipeline.          *)
(* =================================================================== *)

ClearAll[RunReviewGate, SVBAuditReport, SVBAuditCombine];

(* =================================================================== *)
(*  Report helpers                                                      *)
(* =================================================================== *)

SVBAuditReport[name_, status_, checks_List] := Association[
  "Name"    -> name,
  "Status"  -> status,
  "Summary" -> Association[
    "Total"  -> Length[checks],
    "PASS"   -> Count[checks, _?(#["Status"] === "PASS" &)],
    "WARN"   -> Count[checks, _?(#["Status"] === "WARN" &)],
    "FAIL"   -> Count[checks, _?(#["Status"] === "FAIL" &)]
  ],
  "Checks"  -> checks
];

SVBAuditCombine[reports__Association] := Association[
  "Name"    -> StringJoin[Riffle[Lookup[{reports}, "Name"], " + "]],
  "Status"  -> If[MemberQ[Lookup[{reports}, "Status"], "FAIL"], "FAIL",
               If[MemberQ[Lookup[{reports}, "Status"], "WARN"], "WARN", "PASS"]],
  "Summary" -> Fold[
    AssociationThread[{"Total", "PASS", "WARN", "FAIL"} ->
      MapThread[Plus, {Lookup[#1, #2], Lookup[#2["Summary"], #2]}] &],
    Association[{"Total" -> 0, "PASS" -> 0, "WARN" -> 0, "FAIL" -> 0}],
    {"Total", "PASS", "WARN", "FAIL"}
  ],
  "Checks"  -> Join @@ Lookup[{reports}, "Checks"]
];
SetAttributes[SVBAuditCombine, {Flat, OneIdentity}];

(* =================================================================== *)
(*  Unified review gate                                                 *)
(* =================================================================== *)

RunReviewGate[rootDir_, label_String, stage_String, config_Association] := Module[
  {checker},

  Get[FileNameJoin[{rootDir, "config.wl"}]];

  checker = Switch[stage,
    "input",       AuditInput,
    "boundary",    AuditBoundaryStage,
    "series",      AuditSeriesStage,
    "solve",       AuditSolveStage,
    "preflight",   AuditPreflight,
    "preboundary", AuditPreBoundary,
    "preseries",   AuditPreSeries,
    "presolve",    AuditPreSolve,
    "pipeline",    AuditPipeline,
    _,             Function[{r, l, c}, SVBAuditReport["unknown:" <> stage, "FAIL", {}]]
  ];

  checker[rootDir, label, config]
];

(* =================================================================== *)
(*  Preflight check                                                     *)
(* =================================================================== *)

AuditPreflight[rootDir_, label_, config_] := Module[
  {checks = {}, file},

  AppendTo[checks, Association[
    "Status" -> If[FileExistsQ[FileNameJoin[{rootDir, "ConformalWeight.m"}]], "PASS", "FAIL"],
    "Check"  -> "preflight-file-ConformalWeight",
    "Message"-> "ConformalWeight.m exists"
  ]];

  AppendTo[checks, Association[
    "Status" -> If[FileExistsQ[$SVBasisFile], "PASS", "FAIL"],
    "Check"  -> "preflight-svbasis",
    "Message"-> "SVBasisFile exists at " <> $SVBasisFile
  ]];

  SVBAuditReport["preflight", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL", "PASS"], checks]
];

(* =================================================================== *)
(*  Input validation check                                              *)
(* =================================================================== *)

AuditInput[rootDir_, label_, config_] := Module[
  {checks = {}, inputFile, runFile, hasIntegrand, hasIntegrandList, hasCoeff,
   hasLS, hasLSList, hasAnsatz, hasAnsatzList, hasOrderY, runContent},

  (* 1. Validate run.wl existence and basic content *)
  runFile = FileNameJoin[{rootDir, "runs", label, "run.wl"}];
  If[FileExistsQ[runFile],
    AppendTo[checks, Association["Status"->"PASS", "Check"->"run-file-exists", "Message"->"run.wl exists"]];
    Quiet[
      runContent = Import[runFile, "String"];
      If[StringQ[runContent],
        If[StringContainsQ[runContent, "workflow_engine.wl"] && 
           StringContainsQ[runContent, "input_parser.wl"] && 
           StringContainsQ[runContent, "SolveIntegrandSystem"],
          AppendTo[checks, Association["Status"->"PASS", "Check"->"run-file-structure", "Message"->"run.wl contains expected imports and call"]],
          AppendTo[checks, Association["Status"->"WARN", "Check"->"run-file-structure", "Message"->"run.wl might be missing standard imports or SolveIntegrandSystem call"]]
        ],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"run-file-readable", "Message"->"run.wl is not readable"]]
      ]
    ];
  ,
    AppendTo[checks, Association["Status"->"FAIL", "Check"->"run-file-exists", "Message"->"Missing run.wl file at " <> runFile]]
  ];

  (* 2. Validate input.wl *)
  inputFile = FileNameJoin[{rootDir, "runs", label, "input.wl"}];
  If[FileExistsQ[inputFile],
    AppendTo[checks, Association["Status"->"PASS", "Check"->"input-file-exists", "Message"->"input.wl exists"]];
    
    Block[{integrand, integrandlist, coeff, leadingsingularity, leadingsingularitylist, ansatz, ansatzlist, OrderY},
      Quiet[Get[inputFile]];
      
      hasIntegrand = ValueQ[integrand];
      hasIntegrandList = ValueQ[integrandlist];
      hasCoeff = ValueQ[coeff];
      hasLS = ValueQ[leadingsingularity];
      hasLSList = ValueQ[leadingsingularitylist];
      hasAnsatz = ValueQ[ansatz];
      hasAnsatzList = ValueQ[ansatzlist];
      hasOrderY = ValueQ[OrderY];
      
      (* Check integrand validation *)
      If[hasIntegrandList,
        If[hasCoeff,
          If[ListQ[integrandlist] && ListQ[coeff] && Length[integrandlist] == Length[coeff],
            AppendTo[checks, Association["Status"->"PASS", "Check"->"input-integrand", "Message"->"integrandlist and coeff are matching lists"]],
            AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-integrand", "Message"->"integrandlist and coeff must be lists of equal length"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-integrand", "Message"->"integrandlist provided but coeff is missing"]]
        ],
        If[hasIntegrand,
          AppendTo[checks, Association["Status"->"PASS", "Check"->"input-integrand", "Message"->"integrand provided"]],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-integrand", "Message"->"Neither integrand nor integrandlist + coeff found"]]
        ]
      ];
      
      (* Check leading singularity validation *)
      If[hasLSList,
        If[hasAnsatzList,
          If[ListQ[leadingsingularitylist] && ListQ[ansatzlist] && Length[leadingsingularitylist] == Length[ansatzlist],
            AppendTo[checks, Association["Status"->"PASS", "Check"->"input-ls-ansatz", "Message"->"leadingsingularitylist and ansatzlist are matching lists"]],
            AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-ls-ansatz", "Message"->"leadingsingularitylist and ansatzlist must be lists of equal length"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-ls-ansatz", "Message"->"leadingsingularitylist provided but ansatzlist is missing"]]
        ],
        If[hasLS,
          If[hasAnsatz,
            AppendTo[checks, Association["Status"->"PASS", "Check"->"input-ls-ansatz", "Message"->"leadingsingularity and ansatz provided"]],
            AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-ls-ansatz", "Message"->"leadingsingularity provided but ansatz is missing"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-ls-ansatz", "Message"->"Neither leadingsingularity nor leadingsingularitylist found"]]
        ]
      ];
      
      If[hasOrderY,
        AppendTo[checks, Association["Status"->"PASS", "Check"->"input-ordery", "Message"->"OrderY provided"]],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-ordery", "Message"->"Missing OrderY"]]
      ];
    ];
  ,
    AppendTo[checks, Association["Status"->"FAIL", "Check"->"input-file-exists", "Message"->"Missing input.wl file at " <> inputFile]]
  ];
  
  SVBAuditReport["input", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                                If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pre-Boundary stage: verify inputs before running boundary expansion  *)
(* =================================================================== *)

AuditPreBoundary[rootDir_, label_, config_] := Module[
  {checks = {}, asymDir, path, data, i, f},

  asymDir = FileNameJoin[{rootDir, "asym"}];

  (* check LiteRed2 bases from config.wl *)
  Table[
    path = FileNameJoin[{asymDir, "Bases", b, b}];
    If[FileExistsQ[path],
      AppendTo[checks, Association["Status"->"PASS", "Check"->"preboundary-liteRed-basis-"<>b,
        "Message"->"LiteRed basis '"<>b<>"' exists"]],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"preboundary-liteRed-basis-missing-"<>b,
        "Message"->"Missing LiteRed basis: " <> path]]
    ],
    {b, $LiteRedBases}
  ];

  (* check asym_new.wl *)
  path = FileNameJoin[{asymDir, "asym_new.wl"}];
  AppendTo[checks, If[FileExistsQ[path],
    Association["Status"->"PASS", "Check"->"preboundary-asym-engine", "Message"->"asym_new.wl exists"],
    Association["Status"->"FAIL", "Check"->"preboundary-asym-engine-missing", "Message"->"Missing asym_new.wl"]
  ]];

  (* check Gmaterrep files *)
  Table[
    path = FileNameJoin[{asymDir, f}];
    AppendTo[checks, If[FileExistsQ[path],
      Association["Status"->"PASS", "Check"->"preboundary-gmaterrep-"<>f, "Message"->f<>" exists"],
      Association["Status"->"WARN", "Check"->"preboundary-gmaterrep-missing-"<>f, "Message"->"Missing "<>f<>" (may not be needed)"]
    ]],
    {f, $GmaterrepFiles}
  ];

  (* check that tmp dir exists or can be created *)
  path = FileNameJoin[{asymDir, "tmp"}];
  AppendTo[checks,
    Association["Status"->"PASS", "Check"->"preboundary-tmp-dir",
      "Message"->"tmp directory " <> If[DirectoryQ[path], "exists", "will be created"]]];

  SVBAuditReport["preboundary", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                                If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pre-Series stage: verify inputs and infer MPL dependency           *)
(* =================================================================== *)

AuditPreSeries[rootDir_, label_, config_] := Module[
  {checks = {}, path, fname, lsConfig, k, cAnsatz, basisElements = {},
   svNames = {}, mplFiles, bestCount = 0, bestFile = None, 
   mplTry, idx, mplPrefix, mplBaseLength, ext, expPath, expData,
   suffixes, expectedFile, sfxSuffix, s},

  (* 1. Check SVHPL text files *)
  Do[
    Do[
      fname = $SVTextPrefix <> lim <> sfx;
      AppendTo[svNames, fname];
    , {sfx, $SVTextSuffixes}]
  , {lim, $Limits}];
  
  Do[
    path = FileNameJoin[{$DataDir, fname}];
    If[FileExistsQ[path],
      AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-svhpl-" <> fname, "Message"->fname <> " exists"]],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-svhpl-missing-" <> fname, "Message"->"Missing: " <> path]]
    ],
    {fname, svNames}
  ];

  (* 2. Strict MPL Inference & Cache Validation *)
  bestFile = Lookup[config, "BestFile", None];

  (* Collect all basis elements from all leading singularities in config *)
  Do[
    cAnsatz = config["LeadingSingularities"][[k, 3]];
    basisElements = Join[basisElements, Cases[cAnsatz, _I | _f, {1, Infinity}]];
  , {k, 1, Length[config["LeadingSingularities"]]}];
  
  basisElements = DeleteDuplicates[basisElements];

  If[Length[basisElements] == 0,
    AppendTo[checks, Association["Status"->"WARN", "Check"->"preseries-mpl-none", "Message"->"No basis elements found in ansatz."]];
  ,
    Module[{mplElements, fullBasisSV},
      fullBasisSV = Import[FileNameJoin[{$DataDir, "allsvlist_fourloop.m"}]];
      mplElements = Select[basisElements, Head[#] === I && FreeQ[fullBasisSV, #] &];
      
      If[Length[mplElements] == 0,
        AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-none-needed", "Message"->"No MPL elements in ansatz; all elements covered by HPL basis."]];
      ,
        (* If bestFile was not passed, search for covering basis *)
        If[bestFile === None,
          mplFiles = FileNames[FileNameJoin[{$DataDir, "allsvlistmpl_*.m"}]];
          mplFiles = Select[mplFiles, !StringMatchQ[#, ___ ~~ ("e0.m" | "e1.m" | "einf.m")] &];

          Do[
            mplTry = Import[f];
            idx = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[mplTry, e, {1}]] /@ mplElements;
            idx = Select[idx, Positive];
            If[Length[idx] == Length[mplElements],
              bestFile = f;
              Break[];
            ];
          , {f, mplFiles}];
        ];

        If[bestFile === None,
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-missing-basis", 
            "Message"->"FAIL: No MPL basis file fully covers the required elements from your ansatz! Please generate a matching allsvlistmpl_*.m in ./data/"]];
        ,
          mplTry = Import[bestFile];
          mplBaseLength = Length[mplTry];
          mplPrefix = FileBaseName[bestFile];
          
          AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-basis-found", 
            "Message"->"Found covering MPL basis: " <> bestFile <> " (Length=" <> ToString[mplBaseLength] <> ")"]];
            
          (* Check expansions e0, e1, einf *)
          Do[
            expPath = FileNameJoin[{$DataDir, mplPrefix <> ext <> ".m"}];
            If[FileExistsQ[expPath],
              expData = Import[expPath];
              If[ListQ[expData] && Length[expData] == mplBaseLength,
                AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-expansion-" <> ext, "Message"->"Expansion " <> ext <> " exists and matches length " <> ToString[mplBaseLength]]],
                AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-expansion-lengthmismatch-" <> ext, 
                  "Message"->"FAIL: Expansion " <> ext <> " length (" <> ToString[If[ListQ[expData], Length[expData], "Invalid"]] <> ") does NOT match base length (" <> ToString[mplBaseLength] <> ")."]]
              ];
            ,
              expPath = FileNameJoin[{$DataDir, mplPrefix <> ext <> ".txt"}];
              If[FileExistsQ[expPath],
                AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-expansion-" <> ext, "Message"->"Expansion " <> ext <> " exists as .txt"]],
                AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-expansion-missing-" <> ext, 
                  "Message"->"FAIL: Missing required expansion file: " <> expPath]]
              ];
            ];
          , {ext, $Limits}];

          (* Check coordinate transformed caches *)
          suffixes = {
            {"e0", "_inuv"}, {"e0", "_inuvp"},
            {"einf", "_inuv"}, {"einf", "_inuvp"},
            {"e1", "_inuv"}, {"e1", "_inuvp"}
          };
          
          Do[
            ext = s[[1]]; sfxSuffix = s[[2]];
            expectedFile = FileNameJoin[{$DataDir, mplPrefix <> ext <> sfxSuffix <> ".txt"}];
            If[FileExistsQ[expectedFile],
              AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-cache-" <> ext <> sfxSuffix, "Message"->"Found MPL cache: " <> expectedFile]],
              AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-cache-missing-" <> ext <> sfxSuffix, "Message"->"Missing required MPL cache file: " <> expectedFile]]
            ];
          , {s, suffixes}];
        ];
      ];
    ];
  ];

  SVBAuditReport["preseries", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                               If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pre-Solve stage: verify inputs before coefficient solving           *)
(* =================================================================== *)

AuditPreSolve[rootDir_, label_, config_] := Module[
  {checks = {}, path, data, sfx, suffixes},

  Table[
    path = FileNameJoin[{rootDir, "asym", "boundary_agent",
      label <> "*" <> StringJoin[ToString /@ perm] <> "_order*_asyexp.m"}];
    If[FileNames[path] =!= {},
      AppendTo[checks, Association["Status"->"PASS", "Check"->"presolve-targetdata-" <> StringJoin[ToString/@perm],
        "Message"->"Boundary file for permutation " <> StringJoin[ToString/@perm] <> " exists"]],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"presolve-targetdata-missing-" <> StringJoin[ToString/@perm],
        "Message"->"Missing boundary file for permutation " <> StringJoin[ToString/@perm]]
      ]
    ],
    {perm, $Perms}
  ];

  suffixes = {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"};
  If[KeyExistsQ[config, "LeadingSingularities"] && Length[config["LeadingSingularities"]] > 1,
    Do[
      Table[
        path = FileNameJoin[{rootDir, "series_agent", label <> "_ls" <> ToString[k] <> "_svlist" <> sfx <> ".m"}];
        If[FileExistsQ[path],
          Quiet[data = Import[path], Import::nffil];
          If[ListQ[data] && data =!= $Failed,
            AppendTo[checks, Association["Status"->"PASS", "Check"->"presolve-series-ls"<>ToString[k]<>"-"<>sfx, "Message"->"Series svlist ls"<>ToString[k]<>" " <> sfx <> " loaded (" <> ToString[Length[data]] <> " elements)"]],
            AppendTo[checks, Association["Status"->"WARN", "Check"->"presolve-series-format-ls"<>ToString[k]<>"-"<>sfx, "Message"->"Series svlist ls"<>ToString[k]<>" " <> sfx <> " exists but not a valid list"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"presolve-series-missing-ls"<>ToString[k]<>"-"<>sfx, "Message"->"Missing series file: " <> path]]
        ],
        {sfx, suffixes}
      ]
    , {k, 1, Length[config["LeadingSingularities"]]}]
  ,
    Table[
      path = FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> sfx <> ".m"}];
      If[FileExistsQ[path],
        Quiet[data = Import[path], Import::nffil];
        If[ListQ[data] && data =!= $Failed,
          AppendTo[checks, Association["Status"->"PASS", "Check"->"presolve-series-" <> sfx, "Message"->"Series svlist " <> sfx <> " loaded (" <> ToString[Length[data]] <> " elements)"]],
          AppendTo[checks, Association["Status"->"WARN", "Check"->"presolve-series-format-" <> sfx, "Message"->"Series svlist " <> sfx <> " exists but not a valid list"]]
        ],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"presolve-series-missing-" <> sfx, "Message"->"Missing series file: " <> path]]
      ],
      {sfx, suffixes}
    ]
  ];

  SVBAuditReport["presolve", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                              If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Boundary stage checks                                               *)
(* =================================================================== *)

AuditBoundaryStage[rootDir_, label_, config_] := Module[
  {checks = {}, perms, i, perm, permStr, pathPattern, found, path, data},

  perms = $Perms;
  For[i = 1, i <= Length[perms], i++,
    perm = perms[[i]];
    permStr = StringJoin[ToString /@ perm];
    pathPattern = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> "*" <> permStr <> "_order*_asyexp.m"}];
    found = FileNames[pathPattern];

    If[found =!= {},
      path = First[found];
      Quiet[data = Import[path], Import::nffil];
      If[Head[data] === SeriesData,
        Module[{vars, syms, badSyms},
          vars = Variables[Normal[data]];
          syms = Cases[vars, _Symbol, Infinity] // DeleteDuplicates;
          badSyms = Select[syms, Context[#] === "Global`" && !MemberQ[{u, Y}, #] &];
          
          If[Length[badSyms] == 0 && !FreeQ[data, Y],
            AppendTo[checks, Association[
              "Status"  -> "PASS", "Check"   -> "boundary-file-valid-" <> permStr,
              "Message" -> "Boundary file " <> permStr <> " is a valid SeriesData containing ONLY u and Y"
            ]],
            AppendTo[checks, Association[
              "Status"  -> "FAIL", "Check"   -> "boundary-file-variables-" <> permStr,
              "Message" -> "Boundary file " <> permStr <> " is SeriesData but contains unauthorized variables or is missing Y: " <> ToString[badSyms]
            ]]
          ]
        ],
        If[NumberQ[data] || ListQ[data],
          AppendTo[checks, Association[
            "Status"  -> "PASS", "Check"   -> "boundary-file-fallback-" <> permStr, "Message" -> "Boundary file " <> permStr <> " is a valid fallback format (" <> ToString[Head[data]] <> ")"
          ]],
          AppendTo[checks, Association[
            "Status"  -> "WARN", "Check"   -> "boundary-file-format-" <> permStr, "Message" -> "Boundary file " <> permStr <> " exists but unexpected format: " <> ToString[Head[data]]
          ]]
        ]
      ],
      AppendTo[checks, Association[
        "Status"  -> "FAIL", "Check"   -> "boundary-file-missing-" <> permStr, "Message" -> "Missing boundary file matching: " <> pathPattern
      ]]
    ];
  ];

  SVBAuditReport["boundary", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                            If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];



(* =================================================================== *)
(*  Series stage checks                                                 *)
(* =================================================================== *)

AuditSeriesStage[rootDir_, label_, config_] := Module[
  {checks = {}, suffixes, sfx, svPath, mplPath, svData, mplData},
  suffixes = {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"};
  If[KeyExistsQ[config, "LeadingSingularities"] && Length[config["LeadingSingularities"]] > 1 && !StringContainsQ[label, "_ls"],
    Do[
      Do[
        svPath  = FileNameJoin[{rootDir, "series_agent", label <> "_ls" <> ToString[k] <> "_svlist" <> sfx <> ".m"}];
        mplPath = FileNameJoin[{rootDir, "series_agent", label <> "_ls" <> ToString[k] <> "_svlistmpl" <> sfx <> ".m"}];

        If[FileExistsQ[svPath],
          Quiet[svData = Import[svPath], Import::nffil];
          If[ListQ[svData],
            AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlist-ls"<>ToString[k]<>"-"<>sfx, "Message"->"svlist ls"<>ToString[k]<>" " <> sfx <> " exists (Length="<>ToString[Length[svData]]<>")"]],
            AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlist-ls"<>ToString[k]<>"-"<>sfx, "Message"->"svlist ls"<>ToString[k]<>" " <> sfx <> " exists but not a list"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"series-file-missing-svlist-ls"<>ToString[k]<>"-"<>sfx, "Message"->"Missing: " <> svPath]]
        ];
        If[FileExistsQ[mplPath],
          Quiet[mplData = Import[mplPath], Import::nffil];
          If[ListQ[mplData],
            AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlistmpl-ls"<>ToString[k]<>"-"<>sfx, "Message"->"svlistmpl ls"<>ToString[k]<>" " <> sfx <> " exists (Length="<>ToString[Length[mplData]]<>")"]],
            AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlistmpl-ls"<>ToString[k]<>"-"<>sfx, "Message"->"svlistmpl ls"<>ToString[k]<>" " <> sfx <> " exists but not a list"]]
          ]
        ],
        {sfx, suffixes}
      ]
    , {k, 1, Length[config["LeadingSingularities"]]}]
  ,
    Do[
      svPath  = FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> sfx <> ".m"}];
      mplPath = FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> sfx <> ".m"}];

      If[FileExistsQ[svPath],
        Quiet[svData = Import[svPath], Import::nffil];
        If[ListQ[svData],
          AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlist-"<>sfx, "Message"->"svlist " <> sfx <> " exists (Length="<>ToString[Length[svData]]<>")"]],
          AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlist-"<>sfx, "Message"->"svlist " <> sfx <> " exists but not a list"]]
        ],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"series-file-missing-svlist-"<>sfx, "Message"->"Missing: " <> svPath]]
      ];
      If[FileExistsQ[mplPath],
        Quiet[mplData = Import[mplPath], Import::nffil];
        If[ListQ[mplData],
          AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlistmpl-"<>sfx, "Message"->"svlistmpl " <> sfx <> " exists (Length="<>ToString[Length[mplData]]<>")"]],
          AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlistmpl-"<>sfx, "Message"->"svlistmpl " <> sfx <> " exists but not a list"]]
        ]
      ],
      {sfx, suffixes}
    ]
  ];

  SVBAuditReport["series", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                          If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Solve stage checks                                                  *)
(* =================================================================== *)

AuditSolveStage[rootDir_, label_, config_] := Module[
  {checks = {}, path, data},
  path = FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}];
  If[FileExistsQ[path],
    Quiet[data = Import[path], Import::nffil];
    If[ListQ[data] && AllTrue[data, MatchQ[#, _Rule | _RuleDelayed] &],
      AppendTo[checks, Association["Status"  -> "PASS", "Check"   -> "solve-file-exists", "Message" -> "Solution file exists with " <> ToString[Length[data]] <> " rules"]];
      
      (* Check for unsolved coefficients / free parameters *)
      Module[{totalCoeffs, missingCoeffs, unsolvedVars},
        totalCoeffs = If[KeyExistsQ[config, "LeadingSingularities"],
          Total[Length /@ config["LeadingSingularities"][[All, 3]]],
          Max[Cases[data[[All, 1]], Symbol["c"][i_Integer] :> i]]
        ];
        If[!IntegerQ[totalCoeffs] || totalCoeffs <= 0, totalCoeffs = 0];
        
        missingCoeffs = Select[Table[Symbol["c"][i], {i, 1, totalCoeffs}], !MemberQ[data[[All, 1]], #] &];
        unsolvedVars = Cases[data[[All, 2]], Symbol["c"][i_Integer] :> Symbol["c"][i], Infinity] // DeleteDuplicates;
        
        If[Length[missingCoeffs] > 0 || Length[unsolvedVars] > 0,
          If[Length[missingCoeffs] > 0,
            AppendTo[checks, Association[
              "Status"  -> "WARN",
              "Check"   -> "solve-coefficients-missing",
              "Message" -> "Warning: some coefficients are missing from the solution: " <> ToString[missingCoeffs]
            ]]
          ];
          If[Length[unsolvedVars] > 0,
            AppendTo[checks, Association[
              "Status"  -> "WARN",
              "Check"   -> "solve-coefficients-unsolved",
              "Message" -> "Warning: not all coefficients are uniquely solved. " <> ToString[Length[unsolvedVars]] <> " free parameters remaining: " <> ToString[unsolvedVars]
            ]]
          ];
        ,
          AppendTo[checks, Association[
            "Status"  -> "PASS",
            "Check"   -> "solve-coefficients-complete",
            "Message" -> "All " <> ToString[totalCoeffs] <> " coefficients are uniquely solved."
          ]]
        ];
      ],
      AppendTo[checks, Association["Status"  -> "WARN", "Check"   -> "solve-file-format", "Message" -> "Solution file exists but not a list of rules"]]
    ],
    AppendTo[checks, Association["Status"  -> "FAIL", "Check"   -> "solve-file-missing", "Message" -> "Missing solution file: " <> path]]
  ];

  SVBAuditReport["solve", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                         If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pipeline combined check                                             *)
(* =================================================================== *)

AuditPipeline[rootDir_, label_, config_] := Module[
  {rBoundary, rSeries, rSolve, combined},
  rBoundary = AuditBoundaryStage[rootDir, label, config];
  rSeries   = AuditSeriesStage[rootDir, label, config];
  rSolve    = AuditSolveStage[rootDir, label, config];
  combined  = SVBAuditCombine[rBoundary, rSeries, rSolve];

  Print["[Audit] Pipeline: ", combined["Status"],
    " (PASS:", combined["Summary", "PASS"],
    " WARN:", combined["Summary", "WARN"],
    " FAIL:", combined["Summary", "FAIL"], ")"];

  combined
];
