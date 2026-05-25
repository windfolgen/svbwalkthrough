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
    "boundary",  AuditBoundaryStage,
    "series",    AuditSeriesStage,
    "solve",     AuditSolveStage,
    "preflight", AuditPreflight,
    "pipeline",  AuditPipeline,
    _,           Function[{r, l}, SVBAuditReport["unknown:" <> stage, "FAIL", {}]]
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
    "Status" -> If[FileExistsQ[FileNameJoin[{rootDir, "allsvlistmpl_threeloopharde0.txt"}]], "PASS", "FAIL"],
    "Check"  -> "preflight-file-mpl-txt",
    "Message"-> "allsvlistmpl_threeloopharde*.txt files present"
  ]];

  SVBAuditReport["preflight", If[MemberQ[checks, _?(#["Status"] === "FAIL" &)], "FAIL", "PASS"], checks]
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
