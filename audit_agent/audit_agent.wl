(* =================================================================== *)
(*  Skill 4: Audit Agent                                               *)
(*  Location: ./audit_agent/                                           *)
(*                                                                     *)
(*  Performs basic file-existence and format validation after each     *)
(*  pipeline stage.  Designed to be always-on in the pipeline.         *)
(*                                                                     *)
(*  Benchmark labels: I3Lhard (boundary), I3Lhard (series/solve)       *)
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

RunReviewGate[rootDir_, label_String, stage_String] := Module[
  {checker},

  checker = Switch[stage,
    "boundary",    AuditBoundaryStage,
    "series",      AuditSeriesStage,
    "solve",       AuditSolveStage,
    "preflight",   AuditPreflight,
    "preboundary", AuditPreBoundary,
    "preseries",   AuditPreSeries,
    "presolve",    AuditPreSolve,
    "pipeline",    AuditPipeline,
    _,             Function[{r, l}, SVBAuditReport["unknown:" <> stage, "FAIL", {}]]
  ];

  checker[rootDir, label]
];

(* =================================================================== *)
(*  Preflight check                                                     *)
(* =================================================================== *)

AuditPreflight[rootDir_, label_] := Module[
  {checks = {}, file},

  (* required source files exist *)
  AppendTo[checks, Association[
    "Status" -> If[FileExistsQ[FileNameJoin[{rootDir, "ConformalWeight.m"}]], "PASS", "FAIL"],
    "Check"  -> "preflight-file-ConformalWeight",
    "Message"-> "ConformalWeight.m exists"
  ]];

  AppendTo[checks, Association[
    "Status" -> If[FileExistsQ[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}]], "PASS", "FAIL"],
    "Check"  -> "preflight-file-svhpl-txt",
    "Message"-> "allsvliste*_uptow8.txt files present"
  ]];

  AppendTo[checks, Association[
    "Status" -> If[FileExistsQ[FileNameJoin[{rootDir, "allsvlistmpl_threeloope0.txt"}]], "PASS", "FAIL"],
    "Check"  -> "preflight-file-mpl-txt",
    "Message"-> "allsvlistmpl_*e*.txt files present"
  ]];

  SVBAuditReport["preflight", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL", "PASS"], checks]
];

(* =================================================================== *)
(*  Pre-Boundary stage: verify inputs before running boundary expansion  *)
(* =================================================================== *)

AuditPreBoundary[rootDir_, label_] := Module[
  {checks = {}, asymDir, path, data, i, f},

  asymDir = FileNameJoin[{rootDir, "asym"}];

  (* check LiteRed2 bases *)
  Table[
    path = FileNameJoin[{asymDir, "Bases", b, b}];
    f = If[FileExistsQ[path],
      AppendTo[checks, Association["Status"->"PASS", "Check"->"preboundary-liteRed-basis-"<>b,
        "Message"->"LiteRed basis '"<>b<>"' exists"]],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"preboundary-liteRed-basis-missing-"<>b,
        "Message"->"Missing LiteRed basis: " <> path]]
    ],
    {b, {"asym", "asym3L", "asym2L", "asym1L"}}
  ];

  (* check asym_new.wl *)
  path = FileNameJoin[{asymDir, "asym_new.wl"}];
  AppendTo[checks, If[FileExistsQ[path],
    Association["Status"->"PASS", "Check"->"preboundary-asym-engine",
      "Message"->"asym_new.wl exists"],
    Association["Status"->"FAIL", "Check"->"preboundary-asym-engine-missing",
      "Message"->"Missing asym_new.wl"]
  ]];

  (* check Gmaterrep files *)
  Table[
    path = FileNameJoin[{asymDir, "Gmaterrep4L.m"}];
    AppendTo[checks, If[FileExistsQ[path],
      Association["Status"->"PASS", "Check"->"preboundary-gmaterrep4l",
        "Message"->"Gmaterrep4L.m exists"],
      Association["Status"->"FAIL", "Check"->"preboundary-gmaterrep4l-missing",
        "Message"->"Missing Gmaterrep4L.m"]
    ]];
    path = FileNameJoin[{asymDir, "Gmaterrep3L.m"}];
    AppendTo[checks, If[FileExistsQ[path],
      Association["Status"->"PASS", "Check"->"preboundary-gmaterrep3l",
        "Message"->"Gmaterrep3L.m exists"],
      Association["Status"->"WARN", "Check"->"preboundary-gmaterrep3l-missing",
        "Message"->"Missing Gmaterrep3L.m (may not be needed)"]
    ]],
    {path}
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
(*  Pre-Series stage: verify inputs before running series expansion     *)
(*                                                                     *)
(*    File format convention:                                          *)
(*      .m   — Mathematica expression (e.g. {e1, e2, ...}), no parsing *)
(*      .txt — string-wrapped list (e.g. "[e1, e2, ...]"), needs parse *)
(* =================================================================== *)

AuditPreSeries[rootDir_, label_] := Module[
  {checks = {}, path, data, txtFiles, mplPrefix, mplFiles, loadOk,
   svNames, mplNames, i, fname, nEntries, fileType},

  (* check SVHPL text files *)
  svNames = {"allsvliste0_uptow8.txt", "allsvliste1_uptow8.txt", "allsvlisteinf_uptow8.txt"};
  Do[
    path = FileNameJoin[{rootDir, fname}];
    If[FileExistsQ[path],
      Quiet[data = Import[path, "String"], Import::nffil];
      If[StringQ[data],
        (* try parsing to verify it's valid *)
        Quiet[data = ToExpression["{" <> StringTrim[data, "["|"]"] <> "}"]];
        If[ListQ[data],
          AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-svhpl-" <> fname,
            "Message"->fname <> " (.txt, parsed to list, " <> ToString[Length[data]] <> " elements)"]],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-svhpl-parse-" <> fname,
            "Message"->fname <> " (.txt) exists but cannot be parsed as list"]]
        ],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-svhpl-string-" <> fname,
          "Message"->fname <> " (.txt) exists but Import did not return a string"]]
      ],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-svhpl-missing-" <> fname,
        "Message"->"Missing: " <> path]]
    ],
    {fname, svNames}
  ];

  (* check MPL expansion files — scan for pattern *_e0, *_e1, *_einf *)
  (* priority: .m (expression format, no parsing) over .txt (string format, needs parsing) *)
  mplFiles = FileNames[FileNameJoin[{rootDir, "allsvlistmpl_*e0.m"}]];
  If[mplFiles =!= {},
    (* ---- .m format: expression list, no parsing ---- *)
    mplPrefix = StringReplace[FileBaseName[First[mplFiles]], "e0" -> "e"];
    fileType = ".m";
    AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-format-convention",
      "Message"->"MPL basis format: .m — loaded as Mathematica expression (no string parsing needed)"]];
    Do[
      fname = mplPrefix <> ext <> ".m";
      path = FileNameJoin[{rootDir, fname}];
      If[FileExistsQ[path],
        Quiet[data = Import[path], Import::nffil];
        If[ListQ[data] && data =!= $Failed,
          AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-" <> fname,
            "Message"->fname <> " (.m) loaded as expression list (" <> ToString[Length[data]] <> " elements) — no parsing needed"]],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-format-" <> fname,
            "Message"->fname <> " (.m) exists but is not a valid expression list (type: " <> ToString[Head[data]] <> ") — expected a list"]]
        ],
        AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-missing-" <> fname,
          "Message"->"Missing MPL expansion: " <> path]]
      ],
      {ext, {"0", "1", "inf"}}
    ];
  ,
    (* ---- .txt format: string-wrapped list, needs parsing ---- *)
    mplFiles = FileNames[FileNameJoin[{rootDir, "allsvlistmpl_*e0.txt"}]];
    If[mplFiles =!= {},
      mplPrefix = StringReplace[FileBaseName[First[mplFiles]], "e0" -> "e"];
      fileType = ".txt";
      AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-format-convention",
        "Message"->"MPL basis format: .txt — loaded as string, parsed via StringTrim+ToExpression"]];
      Do[
        fname = mplPrefix <> ext <> ".txt";
        path = FileNameJoin[{rootDir, fname}];
        If[FileExistsQ[path],
          Quiet[data = Import[path, "String"], Import::nffil];
          If[StringQ[data],
            Quiet[data = ToExpression["{" <> StringTrim[data, "["|"]"] <> "}"]];
            If[ListQ[data] && data =!= $Failed,
              AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-" <> fname,
                "Message"->fname <> " (.txt) loaded as string, parsed to list (" <> ToString[Length[data]] <> " elements)"]],
              AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-parse-" <> fname,
                "Message"->fname <> " (.txt) exists but parsing to list failed — format: .txt files must be string-wrapped lists"]]
            ],
            AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-string-" <> fname,
              "Message"->fname <> " (.txt) exists but Import did not return a string"]]
          ],
          AppendTo[checks, Association["Status"->"FAIL", "Check"->"preseries-mpl-missing-" <> fname,
            "Message"->"Missing MPL expansion: " <> path]]
        ],
        {ext, {"0", "1", "inf"}}
      ];
    ,
      AppendTo[checks, Association["Status"->"WARN", "Check"->"preseries-mpl-none",
        "Message"->"No allsvlistmpl_*e0.m or .txt files found — MPL expansions may not be needed"]]
    ];
  ];

  SVBAuditReport["preseries", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                               If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pre-Solve stage: verify inputs before coefficient solving           *)
(* =================================================================== *)

AuditPreSolve[rootDir_, label_] := Module[
  {checks = {}, path, data},

  (* check that targetData is loaded (boundary conditions must be available) *)
  Table[
    path = FileNameJoin[{rootDir, "asym", "boundary_agent",
      label <> StringJoin[ToString /@ perm] <> "_order*_asyexp.m"}];
    If[FileNames[path] =!= {},
      AppendTo[checks, Association["Status"->"PASS", "Check"->"presolve-targetdata-" <> StringJoin[ToString/@perm],
        "Message"->"Boundary file for permutation " <> StringJoin[ToString/@perm] <> " exists"]],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"presolve-targetdata-missing-" <> StringJoin[ToString/@perm],
        "Message"->"Missing boundary file for permutation " <> StringJoin[ToString/@perm]]
      ]
    ],
    {perm, {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}}}
  ];

  (* check series expansion output exists *)
  Table[
    path = FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> sfx <> ".m"}];
    If[FileExistsQ[path],
      Quiet[data = Import[path], Import::nffil];
      If[ListQ[data] && data =!= $Failed,
        AppendTo[checks, Association["Status"->"PASS", "Check"->"presolve-series-" <> sfx,
          "Message"->"Series svlist " <> sfx <> " loaded (" <> ToString[Length[data]] <> " elements)"]],
        AppendTo[checks, Association["Status"->"WARN", "Check"->"presolve-series-format-" <> sfx,
          "Message"->"Series svlist " <> sfx <> " exists but not a valid list"]]
      ],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"presolve-series-missing-" <> sfx,
        "Message"->"Missing series file: " <> path]]
    ],
    {sfx, {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"}}
  ];

  SVBAuditReport["presolve", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                              If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Boundary stage checks                                               *)
(* =================================================================== *)

AuditBoundaryStage[rootDir_, label_] := Module[
  {checks = {}, perms, i, perm, permStr, pathPattern, found, path, data},

  perms = {{1,2,3,4},{2,1,3,4},{1,3,2,4},{2,3,1,4},{3,1,2,4},{3,2,1,4}};

  For[i = 1, i <= Length[perms], i++,
    perm = perms[[i]];
    permStr = StringJoin[ToString /@ perm];
    (* accept any order, since it's set by the pipeline *)
    pathPattern = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order*_asyexp.m"}];
    found = FileNames[pathPattern];

    If[found =!= {},
      path = First[found];
      Quiet[data = Import[path], Import::nffil];
      If[Head[data] === SeriesData || NumberQ[data] || ListQ[data],
        AppendTo[checks, Association[
          "Status"  -> "PASS",
          "Check"   -> "boundary-file-exists-" <> permStr,
          "Message" -> "Boundary file " <> permStr <> " exists and importable"
        ]],
        AppendTo[checks, Association[
          "Status"  -> "WARN",
          "Check"   -> "boundary-file-format-" <> permStr,
          "Message" -> "Boundary file " <> permStr <> " exists but unexpected format: " <> ToString[Head[data]]
        ]]
      ],
      AppendTo[checks, Association[
        "Status"  -> "FAIL",
        "Check"   -> "boundary-file-missing-" <> permStr,
        "Message" -> "Missing boundary file matching: " <> pathPattern
      ]]
    ];
  ];

  SVBAuditReport["boundary", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                            If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Series stage checks                                                 *)
(* =================================================================== *)

AuditSeriesStage[rootDir_, label_] := Module[
  {checks = {}, suffixes, sfx, svPath, mplPath, svData, mplData},

  suffixes = {"e0uv","e0uvp","einfuv","einfuvp","e1uv","e1uvp"};

  Do[
    svPath  = FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> sfx <> ".m"}];
    mplPath = FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> sfx <> ".m"}];

    If[FileExistsQ[svPath],
      Quiet[svData = Import[svPath], Import::nffil];
      If[ListQ[svData],
        AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlist-"<>sfx,
          "Message"->"svlist " <> sfx <> " exists (Length="<>ToString[Length[svData]]<>")"]],
        AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlist-"<>sfx,
          "Message"->"svlist " <> sfx <> " exists but not a list"]]
      ],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"series-file-missing-svlist-"<>sfx,
        "Message"->"Missing: " <> svPath]]
    ];

    If[FileExistsQ[mplPath],
      Quiet[mplData = Import[mplPath], Import::nffil];
      If[ListQ[mplData],
        AppendTo[checks, Association["Status"->"PASS", "Check"->"series-file-exists-svlistmpl-"<>sfx,
          "Message"->"svlistmpl " <> sfx <> " exists (Length="<>ToString[Length[mplData]]<>")"]],
        AppendTo[checks, Association["Status"->"WARN", "Check"->"series-file-format-svlistmpl-"<>sfx,
          "Message"->"svlistmpl " <> sfx <> " exists but not a list"]]
      ],
      AppendTo[checks, Association["Status"->"FAIL", "Check"->"series-file-missing-svlistmpl-"<>sfx,
        "Message"->"Missing: " <> mplPath]]
    ],
    {sfx, suffixes}
  ];

  SVBAuditReport["series", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                          If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Solve stage checks                                                  *)
(* =================================================================== *)

AuditSolveStage[rootDir_, label_] := Module[
  {checks = {}, path, data},

  path = FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}];

  If[FileExistsQ[path],
    Quiet[data = Import[path], Import::nffil];
    If[ListQ[data] && AllTrue[data, MatchQ[#, _Rule | _RuleDelayed] &],
      AppendTo[checks, Association[
        "Status"  -> "PASS",
        "Check"   -> "solve-file-exists",
        "Message" -> "Solution file exists with " <> ToString[Length[data]] <> " rules"
      ]],
      AppendTo[checks, Association[
        "Status"  -> "WARN",
        "Check"   -> "solve-file-format",
        "Message" -> "Solution file exists but not a list of rules"
      ]]
    ],
    AppendTo[checks, Association[
      "Status"  -> "FAIL",
      "Check"   -> "solve-file-missing",
      "Message" -> "Missing solution file: " <> path
    ]]
  ];

  SVBAuditReport["solve", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL",
                         If[MemberQ[checks, _?(#["Status"] === "WARN" &)], "WARN", "PASS"]], checks]
];

(* =================================================================== *)
(*  Pipeline combined check                                             *)
(* =================================================================== *)

AuditPipeline[rootDir_, label_] := Module[
  {rBoundary, rSeries, rSolve, combined},

  rBoundary = AuditBoundaryStage[rootDir, label];
  rSeries   = AuditSeriesStage[rootDir, label];
  rSolve    = AuditSolveStage[rootDir, label];
  combined  = SVBAuditCombine[rBoundary, rSeries, rSolve];

  Print["[Audit] Pipeline: ", combined["Status"],
    " (PASS:", combined["Summary", "PASS"],
    " WARN:", combined["Summary", "WARN"],
    " FAIL:", combined["Summary", "FAIL"], ")"];

  combined
];
