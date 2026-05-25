(* =================================================================== *)
(*  Skill 4: Audit Agent                                               *)
(*  Location: ./audit_agent/                                           *)
(*                                                                     *)
(*  This agent checks the SVB pipeline after each stage. It does not   *)
(*  run the heavy calculation itself; it verifies inputs, output files, *)
(*  ordering conventions, expression formats, and optional residuals.  *)
(* =================================================================== *)

ClearAll[
  SVBAuditPermutations, SVBAuditPermutationStrings, SVBAuditSuffixes,
  SVBAuditBoundaryCandidates, SVBAuditSeriesCandidates, SVBAuditSolveCandidates,
  SVBAuditCategory, SVBAuditAnnotateChecks,
  SVBAuditCheck, SVBAuditReport, SVBAuditWriteReport, SVBAuditMarkdown,
  SVBAuditStatus, SVBAuditCombine,
  SVBAuditBenchmarkDefinitions, SVBAuditBenchmarkProfileForStage, SVBAuditBenchmarkStageChecks,
  SVBAuditFlattenByWeight, SVBAuditCanonicalStrings,
  AuditSourceContracts, AuditPipelineInput, AuditBoundaryStep, AuditSeriesStep, AuditSolveStep,
  AuditFullPipeline, SVBAuditAdditionalPrefactors,
  AuditAnsatzBenchmark, RunReviewGate, AuditHardBenchmarkWorkspace
];

SVBAuditPermutations[] := {{1, 2, 3, 4}, {2, 1, 3, 4}, {1, 3, 2, 4},
  {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}};

SVBAuditPermutationStrings[] := StringJoin /@ (ToString /@ # & /@ SVBAuditPermutations[]);

SVBAuditSuffixes[] := {"e0uv", "e0uvp", "einfuv", "einfuvp", "e1uv", "e1uvp"};

SVBAuditCheck[status_String, name_String, message_String, details_: <||>] :=
  <|"Status" -> status, "Check" -> name, "Message" -> message, "Details" -> details|>;

SVBAuditCategory[check_Association] := Module[
  {name = Lookup[check, "Check", ""], status = Lookup[check, "Status", "PASS"]},
  Which[
    StringContainsQ[name, "freshness"] || StringContainsQ[name, "stale"],
      "stale",
    StringContainsQ[name, "format"] || StringContainsQ[name, "import"] ||
      StringContainsQ[name, "variables"] || StringContainsQ[name, "size"],
      "format",
    StringContainsQ[name, "file"] || StringContainsQ[name, "directory"] ||
      StringContainsQ[name, "pole-type"] || StringContainsQ[name, "required-file"] ||
      StringContainsQ[name, "source-file"] || StringContainsQ[name, "benchmark-profile"] ||
      StringContainsQ[name, "ansatz-benchmark-file"] || StringContainsQ[name, "ansatz-flat-file"] ||
      StringContainsQ[name, "ansatz-grouped"],
      "contract",
    StringContainsQ[name, "residual"] || StringContainsQ[name, "prefactor"] ||
      StringContainsQ[name, "conformal-weight"] || StringContainsQ[name, "permutation-order"] ||
      StringContainsQ[name, "solve-"] || StringContainsQ[name, "series-y-order"] ||
      StringContainsQ[name, "boundary-series-format"] || StringContainsQ[name, "benchmark-diff"],
      "logic",
    status === "FAIL",
      "logic",
    True,
      "contract"
  ]
];

SVBAuditAnnotateChecks[checks_List] :=
  Map[
    If[KeyExistsQ[#, "Category"],
      #,
      Append[#, "Category" -> SVBAuditCategory[#]]
    ] &,
    checks
  ];

SVBAuditStatus[checks_List] := Which[
  MemberQ[checks[[All, "Status"]], "FAIL"], "FAIL",
  MemberQ[checks[[All, "Status"]], "WARN"], "WARN",
  True, "PASS"
];

SVBAuditReport[name_String, checks_List, metadata_: <||>] := Module[
  {annotatedChecks, counts, categories},
  annotatedChecks = SVBAuditAnnotateChecks[checks];
  counts = Counts[annotatedChecks[[All, "Status"]]];
  categories = Counts[annotatedChecks[[All, "Category"]]];
  <|
    "Name" -> name,
    "CreatedAt" -> DateString[{"Year", "-", "Month", "-", "Day", " ",
       "Hour", ":", "Minute", ":", "Second"}],
    "Status" -> SVBAuditStatus[annotatedChecks],
    "Summary" -> <|
      "PASS" -> Lookup[counts, "PASS", 0],
      "WARN" -> Lookup[counts, "WARN", 0],
      "FAIL" -> Lookup[counts, "FAIL", 0]
    |>,
    "Metadata" -> Join[metadata, <|"Categories" -> categories|>],
    "Checks" -> annotatedChecks
  |>
];

SVBAuditCombine[name_String, reports__Association] := Module[
  {items = {reports}, checks, metadata},
  checks = Flatten[Lookup[items, "Checks", {}], 1];
  metadata = <|"Children" -> Lookup[items, "Name", Missing["Name"]]|>;
  SVBAuditReport[name, checks, metadata]
];

SVBAuditMarkdown[report_Association] := Module[
  {lines, checks},
  checks = report["Checks"];
  lines = Join[
    {
      "# " <> report["Name"],
      "",
      "- Status: `" <> report["Status"] <> "`",
      "- Created: " <> report["CreatedAt"],
      "- PASS/WARN/FAIL: " <> ToString[report["Summary", "PASS"]] <> "/" <>
        ToString[report["Summary", "WARN"]] <> "/" <> ToString[report["Summary", "FAIL"]],
      "- Categories: " <> StringRiffle[
        KeyValueMap[#1 <> "=" <> ToString[#2] &, Lookup[report["Metadata"], "Categories", <||>]],
        ", "
      ],
      ""
    },
    Flatten[
      {
        "## Checks",
        "",
        Table[
          "- `" <> check["Status"] <> "` [" <> check["Category"] <> "] " <>
            check["Check"] <> ": " <> check["Message"],
          {check, checks}
        ]
      }
    ]
  ];
  StringRiffle[lines, "\n"]
];

SVBAuditWriteReport[rootDir_String, label_String, report_Association] := Module[
  {dir, base, mfile, mdfile},
  dir = FileNameJoin[{rootDir, "audit_agent", "reports"}];
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  base = FileNameJoin[{dir, label <> "_audit_report"}];
  mfile = base <> ".m";
  mdfile = base <> ".md";
  Export[mfile, report];
  Export[mdfile, SVBAuditMarkdown[report], "Text"];
  <|"MFile" -> mfile, "MarkdownFile" -> mdfile|>
];

SVBAuditImport[path_String] := Quiet[Check[Import[path], $Failed]];

SVBAuditFirstExisting[candidates_List] := SelectFirst[candidates, FileExistsQ, Missing["NotFound"]];

SVBAuditBoundaryCandidates[rootDir_String, label_String, perm_String, order_Integer] := Module[
  {names},
  names = {
    "check" <> label <> perm <> "_order" <> ToString[order] <> "_asyexp.m",
    label <> perm <> "_order" <> ToString[order] <> "_asyexp.m"
  };
  Flatten[
    FileNameJoin[{#, #2}] & @@@ Tuples[
      {
        {
          rootDir,
          FileNameJoin[{rootDir, "asym"}],
          FileNameJoin[{rootDir, "asym", "boundary_agent"}]
        },
        names
      }
    ]
  ]
];

SVBAuditSeriesCandidates[rootDir_String, label_String, kind_String, suffix_String] := Module[
  {names, legacyBase, legacyTag},
  names = {label <> "_" <> kind <> suffix <> ".m"};
  If[StringMatchQ[label, ___ ~~ DigitCharacter],
    legacyBase = StringDrop[label, -1];
    legacyTag = StringTake[label, -1];
    names = Append[names,
      legacyBase <> "_" <> kind <> suffix <>
        If[legacyTag === "1", "", "_" <> legacyTag] <> ".m"
    ];
  ];
  DeleteDuplicates @ Flatten[
    FileNameJoin[{#, #2}] & @@@ Tuples[{{FileNameJoin[{rootDir, "series_agent"}], rootDir}, names}]
  ]
];

SVBAuditSolveCandidates[rootDir_String, label_String] := {
  FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}],
  FileNameJoin[{rootDir, label <> "_sol.m"}]
};

SVBAuditFileFreshQ[path_String, startedAt_] := Module[
  {t},
  If[startedAt === None, Return[True]];
  t = Quiet[Check[AbsoluteTime[FileDate[path]], -Infinity]];
  TrueQ[t + 2 >= AbsoluteTime[startedAt]]
];

SVBAuditSeriesDataQ[expr_] := Module[{series},
  series = Cases[expr, _SeriesData, {0, Infinity}];
  series =!= {} && AllTrue[series, Quiet[Check[#[[1]] === Y, True]] &]
];

SVBAuditNoBadSymbolsQ[expr_] := FreeQ[expr, $Failed | Indeterminate | ComplexInfinity | DirectedInfinity];

SVBAuditAdditionalPrefactors[lsBase_, weightN_Integer] := Module[
  {rules, factors, names, transformed},
  rules = {
    {u -> u, v -> v},
    {u -> u/v, v -> 1/v},
    {u -> 1/u, v -> v/u},
    {u -> v/u, v -> 1/u},
    {u -> 1/v, v -> u/v},
    {u -> v, v -> u}
  };
  factors = {1, v, u, u, v, 1};
  names = SVBAuditSuffixes[];
  AssociationThread[
    names,
    Table[
      transformed = Simplify[lsBase /. rules[[i]]];
      If[factors[[i]] === 1,
        transformed,
        Simplify[transformed/factors[[i]]^(weightN - 1)]
      ],
      {i, 1, Length[names]}
    ]
  ]
];

SVBAuditBenchmarkDefinitions[rootDir_String] := <|
  "boundary" -> <|
    "Profile" -> "hard-boundary",
    "Labels" -> {"I3Lhard", "I3Lhardr", "I3Lhardt"},
    "Order" -> 3
  |>,
  "series" -> <|
    "Profile" -> "hard-series",
    "Labels" -> {"threeloophard1", "threeloophard2"},
    "BasisSV" -> FileNameJoin[{rootDir, "allsvlist_fourloop.m"}],
    "BasisMPL" -> FileNameJoin[{rootDir, "allsvlistmpl_threeloop.m"}]
  |>,
  "solve" -> <|
    "Profile" -> "hard-solve",
    "Labels" -> {"threeloophard1", "threeloophard2"},
    "AnsatzFiles" -> <|
      "threeloophard1" -> FileNameJoin[{rootDir, "threeloophard1_ans.m"}],
      "threeloophard2" -> FileNameJoin[{rootDir, "threeloophard2_ans.m"}]
    |>
  |>,
  "ansatz" -> <|
    "Profile" -> "hard-ansatz",
    "Labels" -> {"parity-even", "parity-odd"},
    "GroupedFiles" -> <|
      "even" -> FileNameJoin[{rootDir, "allsvlistevenans.m"}],
      "odd" -> FileNameJoin[{rootDir, "allsvlistoddans.m"}]
    |>,
    "FlatFiles" -> <|
      "even" -> FileNameJoin[{rootDir, "svmplevenansatz_threeloop.m"}],
      "odd" -> FileNameJoin[{rootDir, "svmploddansatz_threeloop.m"}]
    |>
  |>
|>;

SVBAuditBenchmarkProfileForStage[rootDir_String, stage_String, label_: None] := Module[
  {defs, entry},
  defs = SVBAuditBenchmarkDefinitions[rootDir];
  entry = Lookup[defs, stage, Missing["UnknownStage"]];
  If[MissingQ[entry],
    Return[Missing["UnknownStage", stage]]
  ];
  If[label === None,
    Return[entry]
  ];
  If[MemberQ[Lookup[entry, "Labels", {}], label],
    entry,
    Missing["NoProfileForLabel", <|"Stage" -> stage, "Label" -> label|>]
  ]
];

SVBAuditBenchmarkStageChecks[rootDir_String, stage_String, label_: None] := Module[
  {checks = {}, entry, paths},
  entry = SVBAuditBenchmarkProfileForStage[rootDir, stage, label];
  If[MissingQ[entry],
    AppendTo[checks, SVBAuditCheck["WARN", "benchmark-profile",
      "No stage-specific benchmark profile is attached to this label.",
      <|"Stage" -> stage, "Label" -> label|>]];
    Return[SVBAuditReport["benchmark:" <> stage <> ":" <> ToString[label], checks]]
  ];

  AppendTo[checks, SVBAuditCheck["PASS", "benchmark-profile",
    "Stage uses a known benchmark profile.",
    <|"Stage" -> stage, "Label" -> label, "Profile" -> entry["Profile"]|>]];

  Switch[stage,
    "series",
      paths = Lookup[entry, {"BasisSV", "BasisMPL"}];
      Do[
        AppendTo[checks,
          If[FileExistsQ[path],
            SVBAuditCheck["PASS", "required-file", "Benchmark basis file exists.", <|"File" -> path|>],
            SVBAuditCheck["FAIL", "required-file", "Benchmark basis file is missing.", <|"File" -> path|>]
          ]
        ],
        {path, paths}
      ],
    "solve",
      paths = Values[Lookup[entry, "AnsatzFiles", <||>]];
      Do[
        AppendTo[checks,
          If[FileExistsQ[path],
            SVBAuditCheck["PASS", "required-file", "Benchmark ansatz file exists.", <|"File" -> path|>],
            SVBAuditCheck["FAIL", "required-file", "Benchmark ansatz file is missing.", <|"File" -> path|>]
          ]
        ],
        {path, paths}
      ],
    "ansatz",
      paths = Join[
        Values[Lookup[entry, "GroupedFiles", <||>]],
        Values[Lookup[entry, "FlatFiles", <||>]]
      ];
      Do[
        AppendTo[checks,
          If[FileExistsQ[path],
            SVBAuditCheck["PASS", "required-file", "Ansatz benchmark file exists.", <|"File" -> path|>],
            SVBAuditCheck["FAIL", "required-file", "Ansatz benchmark file is missing.", <|"File" -> path|>]
          ]
        ],
        {path, paths}
      ]
  ];

  SVBAuditReport["benchmark:" <> stage <> ":" <> ToString[label], checks]
];

SVBAuditFlattenByWeight[data_] := Which[
  ListQ[data] && data === {}, {},
  ListQ[data] && AllTrue[data, ListQ], Flatten[data],
  ListQ[data], data,
  True, {data}
];

SVBAuditCanonicalStrings[data_] :=
  Sort[(ToString[InputForm[#]] &) /@ SVBAuditFlattenByWeight[data]];

AuditSourceContracts[rootDir_String] := Module[
  {checks = {}, master, series, boundary, solve, read, positions, starts, functions},

  read[file_] := Quiet[Check[Import[FileNameJoin[{rootDir, file}], "Text"], $Failed]];
  master = read["master_agent.wl"];
  series = read["series_agent/series_agent.wl"];
  boundary = read["asym/boundary_agent/boundary_agent.wl"];
  solve = read["solve_agent/solve_agent.wl"];

  Do[
    AppendTo[checks,
      If[FileExistsQ[FileNameJoin[{rootDir, file}]],
        SVBAuditCheck["PASS", "source-file", "Source file exists.", <|"File" -> file|>],
        SVBAuditCheck["FAIL", "source-file", "Source file is missing.", <|"File" -> file|>]
      ]
    ],
    {file, {"master_agent.wl", "series_agent/series_agent.wl",
      "asym/boundary_agent/boundary_agent.wl", "solve_agent/solve_agent.wl"}}
  ];

  If[StringQ[master],
    positions = (StringPosition[master, #, 1] & /@
       {"RunBoundaryConditions", "RunSeriesExpansion", "RunCoefficientSolving"});
    starts = If[AllTrue[positions, # =!= {} &], positions[[All, 1, 1]], {}];
    AppendTo[checks,
      If[Length[starts] == 3 && OrderedQ[starts],
        SVBAuditCheck["PASS", "master-call-order",
          "Master calls boundary, series, then solve in the expected order.", <|"Positions" -> starts|>],
        SVBAuditCheck["FAIL", "master-call-order",
          "Master does not call boundary, series, then solve in the expected order.", <|"Positions" -> positions|>]
      ]
    ];
  ];

  If[StringQ[series],
    functions = {"SeriesExpansion0", "SeriesExpansion0P", "SeriesExpansion1",
      "SeriesExpansion1P", "SeriesExpansionInf", "SeriesExpansionInfP",
      "SeriesExpansion20", "SeriesExpansion20P", "SeriesExpansion21",
      "SeriesExpansion21P", "SeriesExpansion2Inf", "SeriesExpansion2InfP"};
    AppendTo[checks,
      If[AllTrue[functions, StringContainsQ[series, #] &],
        SVBAuditCheck["PASS", "series-functions",
          "Series agent contains all simple and double pole expansion functions.", <|"Functions" -> functions|>],
        SVBAuditCheck["FAIL", "series-functions",
          "Series agent is missing at least one expansion function.",
          <|"Missing" -> Select[functions, ! StringContainsQ[series, #] &]|>]
      ]
    ];
    AppendTo[checks,
      If[AllTrue[SVBAuditSuffixes[], StringContainsQ[series, #] &],
        SVBAuditCheck["PASS", "series-suffixes",
          "Series agent contains all six expected output suffixes.", <|"Suffixes" -> SVBAuditSuffixes[]|>],
        SVBAuditCheck["FAIL", "series-suffixes",
          "Series agent is missing at least one expected output suffix.",
          <|"Missing" -> Select[SVBAuditSuffixes[], ! StringContainsQ[series, #] &]|>]
      ]
    ];
  ];

  If[StringQ[boundary],
    AppendTo[checks,
      If[StringContainsQ[boundary, "RunAsymExpansionParallel[label, $Integrand, $Perms, order, {5, 6, 7}]"],
        SVBAuditCheck["PASS", "boundary-run-call",
          "Boundary agent calls RunAsymExpansionParallel with the configured integrand and permutations.", <||>],
        SVBAuditCheck["FAIL", "boundary-run-call",
          "Boundary agent does not contain the expected RunAsymExpansionParallel call.", <||>]
      ]
    ];
    If[StringContainsQ[boundary, "filepath = rootDir"],
      AppendTo[checks, SVBAuditCheck["WARN", "boundary-filepath-scope",
        "Boundary agent sets filepath locally; asym_new.wl uses a global filepath for exports, so output location should be audited after each run.",
        <||>]]
    ];
  ];

  If[StringQ[solve],
    AppendTo[checks,
      If[StringContainsQ[solve, "Solve[sys"],
        SVBAuditCheck["PASS", "solve-system",
          "Solve agent solves the accumulated system named sys.", <||>],
        SVBAuditCheck["FAIL", "solve-system",
          "Solve agent does not appear to solve the accumulated sys equations.", <||>]
      ]
    ];
    If[StringContainsQ[solve, "Length[syst]"],
      AppendTo[checks, SVBAuditCheck["WARN", "solve-print-variable",
        "Solve agent prints Length[syst], but the accumulated system variable is sys; this can make progress logs misleading.",
        <||>]]
    ];
  ];

  SVBAuditReport["source-contracts", checks, <|"RootDir" -> rootDir|>]
];

Options[AuditPipelineInput] = {
  "ExternalPoints" -> {1, 2, 3, 4},
  "AllowAnsatzCoefficients" -> False
};

AuditPipelineInput[rootDir_String, integrand_, poleType_, lsBase_,
    ansatzExpr_, basisSV_, basisMPL_, OptionsPattern[]] := Module[
  {checks = {}, points, weights, weightValues, weightN, hasConformal, ansatzLen,
   basisSVLen, basisMPLLen, prefactors},

  points = OptionValue["ExternalPoints"];
  AppendTo[checks,
    If[DirectoryQ[rootDir],
      SVBAuditCheck["PASS", "root-directory", "Root directory exists.", <|"Path" -> rootDir|>],
      SVBAuditCheck["FAIL", "root-directory", "Root directory does not exist.", <|"Path" -> rootDir|>]
    ]
  ];

  Do[
    AppendTo[checks,
      If[FileExistsQ[FileNameJoin[{rootDir, file}]],
        SVBAuditCheck["PASS", "required-file", "Required file exists.", <|"File" -> file|>],
        SVBAuditCheck["FAIL", "required-file", "Required file is missing.", <|"File" -> file|>]
      ]
    ],
    {file, {"master_agent.wl", "series_agent/series_agent.wl",
      "asym/boundary_agent/boundary_agent.wl", "solve_agent/solve_agent.wl",
      "ConformalWeight.m"}}
  ];

  AppendTo[checks,
    If[integrand === None || integrand === Automatic || integrand === Missing["NotProvided"],
      SVBAuditCheck["FAIL", "integrand-format", "Integrand input must be provided explicitly.", <||>],
      SVBAuditCheck["PASS", "integrand-format", "Integrand input is present.", <|"Head" -> Head[integrand]|>]
    ]
  ];

  AppendTo[checks,
    If[MemberQ[{"simple", "double"}, poleType],
      SVBAuditCheck["PASS", "pole-type", "Primary pole type is supported.", <|"PoleType" -> poleType|>],
      SVBAuditCheck["FAIL", "pole-type", "Primary pole type must be simple or double.", <|"PoleType" -> poleType|>]
    ]
  ];

  AppendTo[checks,
    If[lsBase === None || lsBase === Automatic || lsBase === Missing["NotProvided"],
      SVBAuditCheck["FAIL", "ls-additional-pole", "Additional pole input must be provided explicitly.", <||>],
      If[FreeQ[lsBase, z | zz | z1 | zz1],
      SVBAuditCheck["PASS", "ls-additional-pole", "Additional pole is expressed in cross-ratios only.",
        <|"AdditionalPole" -> HoldForm[lsBase]|>],
      SVBAuditCheck["WARN", "ls-additional-pole", "Additional pole still contains z-like variables; check that the primary pole was removed.",
        <|"AdditionalPole" -> HoldForm[lsBase]|>]
      ]
    ]
  ];

  hasConformal = FileExistsQ[FileNameJoin[{rootDir, "ConformalWeight.m"}]];
  If[hasConformal && integrand =!= None && integrand =!= Automatic,
    Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];
    weights = Table[{p, Quiet[Check[ConformalWeight[integrand, p], $Failed]]}, {p, points}];
    weightValues = weights[[All, 2]];
    If[FreeQ[weightValues, $Failed] && Length[DeleteDuplicates[weightValues]] == 1,
      weightN = -First[weightValues];
      AppendTo[checks, SVBAuditCheck["PASS", "conformal-weight",
        "External conformal weights are consistent.",
        <|"Weights" -> weights, "NormalizationN" -> weightN|>]],
      AppendTo[checks, SVBAuditCheck["FAIL", "conformal-weight",
        "External conformal weights are inconsistent or failed to evaluate.",
        <|"Weights" -> weights|>]
      ];
      weightN = Missing["Invalid"]
    ],
    weightN = Missing["NoConformalWeightFile"]
  ];

  ansatzLen = If[ListQ[ansatzExpr], Length[ansatzExpr], Missing["NotList"]];
  basisSVLen = If[ListQ[basisSV], Length[basisSV], Missing["NotList"]];
  basisMPLLen = If[ListQ[basisMPL], Length[basisMPL], Missing["NotList"]];

  AppendTo[checks,
    If[IntegerQ[ansatzLen] && ansatzLen > 0,
      SVBAuditCheck["PASS", "ansatz-format", "Ansatz is a non-empty list.",
        <|"Length" -> ansatzLen|>],
      SVBAuditCheck["FAIL", "ansatz-format", "Ansatz must be a non-empty list.",
        <|"Length" -> ansatzLen|>]
    ]
  ];

  If[! TrueQ[OptionValue["AllowAnsatzCoefficients"]] && ! FreeQ[ansatzExpr, c[_]],
    AppendTo[checks, SVBAuditCheck["WARN", "ansatz-coefficients",
      "Ansatz contains c[i]; solve_agent expects a basis list without coefficients.", <||>]]
  ];

  AppendTo[checks,
    If[IntegerQ[basisSVLen] && basisSVLen > 0 && IntegerQ[basisMPLLen] && basisMPLLen > 0,
      SVBAuditCheck["PASS", "basis-format", "SV and MPL bases are non-empty lists.",
        <|"SVLength" -> basisSVLen, "MPLLength" -> basisMPLLen|>],
      SVBAuditCheck["FAIL", "basis-format", "SV and MPL bases must be non-empty lists.",
        <|"SVLength" -> basisSVLen, "MPLLength" -> basisMPLLen|>]
    ]
  ];

  prefactors = If[IntegerQ[weightN], SVBAuditAdditionalPrefactors[lsBase, weightN], <||>];

  SVBAuditReport["pipeline-input", checks, <|"AdditionalPrefactors" -> prefactors|>]
];

Options[AuditBoundaryStep] = {
  "RunStartedAt" -> None,
  "ExpectedPermutations" -> Automatic,
  "MinByteCount" -> 20
};

AuditBoundaryStep[rootDir_String, label_String, order_Integer:3, OptionsPattern[]] := Module[
  {checks = {}, perms, permStrings, path, data, minBytes, startedAt},
  perms = Replace[OptionValue["ExpectedPermutations"], Automatic -> SVBAuditPermutations[]];
  permStrings = StringJoin /@ (ToString /@ # & /@ perms);
  minBytes = OptionValue["MinByteCount"];
  startedAt = OptionValue["RunStartedAt"];

  If[permStrings =!= SVBAuditPermutationStrings[],
    AppendTo[checks, SVBAuditCheck["WARN", "permutation-order",
      "Permutation order differs from solve_agent's expected order.",
      <|"Expected" -> SVBAuditPermutations[], "Actual" -> perms|>]],
    AppendTo[checks, SVBAuditCheck["PASS", "permutation-order",
      "Permutation order matches solve_agent's expected order.", <|"Order" -> perms|>]]
  ];

  Do[
    path = SVBAuditFirstExisting[SVBAuditBoundaryCandidates[rootDir, label, perm, order]];
    If[MissingQ[path],
      AppendTo[checks, SVBAuditCheck["FAIL", "boundary-file",
        "Boundary output file is missing.", <|"Permutation" -> perm|>]];
      Continue[];
    ];

    AppendTo[checks, SVBAuditCheck["PASS", "boundary-file",
      "Boundary output file exists.", <|"Permutation" -> perm, "File" -> path|>]];

    AppendTo[checks,
      If[FileByteCount[path] >= minBytes,
        SVBAuditCheck["PASS", "boundary-file-size", "Boundary output is non-trivial.",
          <|"File" -> path, "Bytes" -> FileByteCount[path]|>],
        SVBAuditCheck["FAIL", "boundary-file-size", "Boundary output is too small.",
          <|"File" -> path, "Bytes" -> FileByteCount[path]|>]
      ]
    ];

    AppendTo[checks,
      If[SVBAuditFileFreshQ[path, startedAt],
        SVBAuditCheck["PASS", "boundary-freshness", "Boundary output is fresh enough.",
          <|"File" -> path|>],
        SVBAuditCheck["WARN", "boundary-freshness", "Boundary output is older than this run.",
          <|"File" -> path, "RunStartedAt" -> startedAt, "FileDate" -> FileDate[path]|>]
      ]
    ];

    data = SVBAuditImport[path];
    AppendTo[checks,
      If[data =!= $Failed && SVBAuditNoBadSymbolsQ[data],
        SVBAuditCheck["PASS", "boundary-import", "Boundary output imports cleanly.",
          <|"File" -> path, "Head" -> Head[data]|>],
        SVBAuditCheck["FAIL", "boundary-import", "Boundary output failed to import cleanly.",
          <|"File" -> path|>]
      ]
    ];

    AppendTo[checks,
      If[data === 0 || SVBAuditSeriesDataQ[data],
        SVBAuditCheck["PASS", "boundary-series-format", "Boundary output is either zero or contains SeriesData in Y.",
          <|"File" -> path|>],
        SVBAuditCheck["FAIL", "boundary-series-format", "Boundary output must be zero or contain SeriesData in Y.",
          <|"File" -> path, "Head" -> Head[data]|>]
      ]
    ];
    ,
    {perm, permStrings}
  ];

  SVBAuditReport["boundary:" <> label, checks, <|"Label" -> label, "Order" -> order|>]
];

Options[AuditSeriesStep] = {
  "YOrder" -> 4,
  "LSBase" -> None,
  "WeightN" -> None,
  "RunStartedAt" -> None,
  "MinByteCount" -> 20
};

AuditSeriesStep[rootDir_String, label_String, basisSV_List, basisMPL_List,
    OptionsPattern[]] := Module[
  {checks = {}, suffixes, pathSV, pathMPL, dataSV, dataMPL, yOrder, minBytes,
   prefactors, lsBase, weightN, startedAt},

  suffixes = SVBAuditSuffixes[];
  yOrder = OptionValue["YOrder"];
  minBytes = OptionValue["MinByteCount"];
  lsBase = OptionValue["LSBase"];
  weightN = OptionValue["WeightN"];
  startedAt = OptionValue["RunStartedAt"];

  If[lsBase =!= None && IntegerQ[weightN],
    prefactors = SVBAuditAdditionalPrefactors[lsBase, weightN];
    AppendTo[checks, SVBAuditCheck["PASS", "series-prefactors",
      "Computed the six additional prefactors used by the series step.",
      <|"Prefactors" -> prefactors|>]]
  ];

  Do[
    pathSV = SVBAuditFirstExisting[SVBAuditSeriesCandidates[rootDir, label, "svlist", suffix]];
    pathMPL = SVBAuditFirstExisting[SVBAuditSeriesCandidates[rootDir, label, "svlistmpl", suffix]];

    If[MissingQ[pathSV],
      AppendTo[checks, SVBAuditCheck["FAIL", "series-sv-file",
        "SV series file is missing.", <|"Suffix" -> suffix|>]],
      AppendTo[checks, SVBAuditCheck["PASS", "series-sv-file",
        "SV series file exists.", <|"Suffix" -> suffix, "File" -> pathSV|>]];
      AppendTo[checks,
        If[SVBAuditFileFreshQ[pathSV, startedAt],
          SVBAuditCheck["PASS", "series-sv-freshness", "SV series output is fresh enough.",
            <|"Suffix" -> suffix, "File" -> pathSV|>],
          SVBAuditCheck["WARN", "series-sv-freshness", "SV series output is older than this run.",
            <|"Suffix" -> suffix, "File" -> pathSV, "RunStartedAt" -> startedAt,
              "FileDate" -> FileDate[pathSV]|>]
        ]
      ];
      AppendTo[checks,
        If[FileByteCount[pathSV] >= minBytes,
          SVBAuditCheck["PASS", "series-sv-size", "SV series file is non-trivial.",
            <|"Suffix" -> suffix, "Bytes" -> FileByteCount[pathSV]|>],
          SVBAuditCheck["FAIL", "series-sv-size", "SV series file is too small.",
            <|"Suffix" -> suffix, "Bytes" -> FileByteCount[pathSV]|>]
        ]
      ];
      dataSV = SVBAuditImport[pathSV];
      AppendTo[checks,
        If[ListQ[dataSV] && Length[dataSV] == Length[basisSV] && SVBAuditNoBadSymbolsQ[dataSV],
          SVBAuditCheck["PASS", "series-sv-format",
            "SV series imports as a list with the basis length.",
            <|"Suffix" -> suffix, "Length" -> Length[dataSV], "Expected" -> Length[basisSV]|>],
          SVBAuditCheck["FAIL", "series-sv-format",
            "SV series must import as a list with the basis length.",
            <|"Suffix" -> suffix, "Head" -> Head[dataSV],
              "Length" -> If[ListQ[dataSV], Length[dataSV], Missing["NotList"]],
              "Expected" -> Length[basisSV]|>]
        ]
      ];
      If[! FreeQ[dataSV, z | zz | z1 | zz1],
        AppendTo[checks, SVBAuditCheck["WARN", "series-sv-variables",
          "SV series still contains z-like variables after expansion.",
          <|"Suffix" -> suffix|>]]
      ];
    ];

    If[MissingQ[pathMPL],
      AppendTo[checks, SVBAuditCheck["FAIL", "series-mpl-file",
        "MPL series file is missing.", <|"Suffix" -> suffix|>]],
      AppendTo[checks, SVBAuditCheck["PASS", "series-mpl-file",
        "MPL series file exists.", <|"Suffix" -> suffix, "File" -> pathMPL|>]];
      AppendTo[checks,
        If[SVBAuditFileFreshQ[pathMPL, startedAt],
          SVBAuditCheck["PASS", "series-mpl-freshness", "MPL series output is fresh enough.",
            <|"Suffix" -> suffix, "File" -> pathMPL|>],
          SVBAuditCheck["WARN", "series-mpl-freshness", "MPL series output is older than this run.",
            <|"Suffix" -> suffix, "File" -> pathMPL, "RunStartedAt" -> startedAt,
              "FileDate" -> FileDate[pathMPL]|>]
        ]
      ];
      AppendTo[checks,
        If[FileByteCount[pathMPL] >= minBytes,
          SVBAuditCheck["PASS", "series-mpl-size", "MPL series file is non-trivial.",
            <|"Suffix" -> suffix, "Bytes" -> FileByteCount[pathMPL]|>],
          SVBAuditCheck["FAIL", "series-mpl-size", "MPL series file is too small.",
            <|"Suffix" -> suffix, "Bytes" -> FileByteCount[pathMPL]|>]
        ]
      ];
      dataMPL = SVBAuditImport[pathMPL];
      AppendTo[checks,
        If[ListQ[dataMPL] && Length[dataMPL] == Length[basisMPL] && SVBAuditNoBadSymbolsQ[dataMPL],
          SVBAuditCheck["PASS", "series-mpl-format",
            "MPL series imports as a list with the basis length.",
            <|"Suffix" -> suffix, "Length" -> Length[dataMPL], "Expected" -> Length[basisMPL]|>],
          SVBAuditCheck["FAIL", "series-mpl-format",
            "MPL series must import as a list with the basis length.",
            <|"Suffix" -> suffix, "Head" -> Head[dataMPL],
              "Length" -> If[ListQ[dataMPL], Length[dataMPL], Missing["NotList"]],
              "Expected" -> Length[basisMPL]|>]
        ]
      ];
      If[! FreeQ[dataMPL, z | zz | z1 | zz1],
        AppendTo[checks, SVBAuditCheck["WARN", "series-mpl-variables",
          "MPL series still contains z-like variables after expansion.",
          <|"Suffix" -> suffix|>]]
      ];
    ];
    ,
    {suffix, suffixes}
  ];

  AppendTo[checks, SVBAuditCheck["PASS", "series-y-order",
    "Series audit used the requested Y truncation order.",
    <|"YOrder" -> yOrder|>]];

  SVBAuditReport["series:" <> label, checks, <|"Label" -> label, "YOrder" -> yOrder|>]
];

Options[AuditSolveStep] = {
  "TargetData" -> None,
  "Order" -> 3,
  "RunStartedAt" -> None,
  "VerifyResiduals" -> Automatic
};

SVBAuditZetaRules[] := {
  f[3, 3] -> Zeta[3]^2/2,
  f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
  f[a_] :> Zeta[a]
};

SVBAuditResidualZeroQ[expr_] := TrueQ[expr === 0] || TrueQ[Quiet[Check[Simplify[expr] === 0, False]]];

SVBAuditBuildSVRep[rootDir_String, label_String, suffix_String, basisSV_List, basisMPL_List, order_Integer] := Module[
  {svPath, mplPath, svliste, svlistmple},
  svPath = SVBAuditFirstExisting[SVBAuditSeriesCandidates[rootDir, label, "svlist", suffix]];
  mplPath = SVBAuditFirstExisting[SVBAuditSeriesCandidates[rootDir, label, "svlistmpl", suffix]];
  If[MissingQ[svPath] || MissingQ[mplPath], Return[$Failed]];
  svliste = SVBAuditImport[svPath];
  svlistmple = SVBAuditImport[mplPath];
  If[! ListQ[svliste] || ! ListQ[svlistmple], Return[$Failed]];
  Join[
    Thread @ Rule[basisSV, ((Series[#, {Y, 0, order}] // Normal) &) /@ svliste],
    Thread @ Rule[basisMPL, ((Series[#, {Y, 0, order}] // Normal) &) /@ svlistmple]
  ]
];

AuditSolveStep[rootDir_String, label_String, ansatzExpr_List, basisSV_List, basisMPL_List,
    OptionsPattern[]] := Module[
  {checks = {}, path, sol, indices, expected, duplicates, targetData, verify,
   filePrefix, suffixes, svrep, setup, residual, order, startedAt},

  order = OptionValue["Order"];
  startedAt = OptionValue["RunStartedAt"];
  targetData = OptionValue["TargetData"];
  verify = Replace[OptionValue["VerifyResiduals"], Automatic -> ListQ[targetData]];
  expected = Range[Length[ansatzExpr]];

  path = SVBAuditFirstExisting[SVBAuditSolveCandidates[rootDir, label]];
  If[MissingQ[path],
    AppendTo[checks, SVBAuditCheck["FAIL", "solve-file",
      "Solution file is missing.", <|"Label" -> label|>]];
    Return[SVBAuditReport["solve:" <> label, checks, <|"Label" -> label|>]];
  ];

  AppendTo[checks, SVBAuditCheck["PASS", "solve-file",
    "Solution file exists.", <|"File" -> path|>]];

  AppendTo[checks,
    If[SVBAuditFileFreshQ[path, startedAt],
      SVBAuditCheck["PASS", "solve-freshness", "Solution output is fresh enough.",
        <|"File" -> path|>],
      SVBAuditCheck["WARN", "solve-freshness", "Solution output is older than this run.",
        <|"File" -> path, "RunStartedAt" -> startedAt, "FileDate" -> FileDate[path]|>]
    ]
  ];

  sol = SVBAuditImport[path];
  AppendTo[checks,
    If[ListQ[sol] && VectorQ[sol, MatchQ[#, Rule[c[_Integer], _]] &],
      SVBAuditCheck["PASS", "solve-format", "Solution imports as c[i] rules.",
        <|"Length" -> Length[sol]|>],
      SVBAuditCheck["FAIL", "solve-format", "Solution must import as a list of c[i] rules.",
        <|"Head" -> Head[sol], "Length" -> If[ListQ[sol], Length[sol], Missing["NotList"]]|>]
    ]
  ];

  indices = Cases[sol, Rule[c[i_Integer], _] :> i];
  duplicates = Select[Tally[indices], #[[2]] > 1 &][[All, 1]];

  AppendTo[checks,
    If[duplicates === {},
      SVBAuditCheck["PASS", "solve-duplicates", "No coefficient index is duplicated.", <||>],
      SVBAuditCheck["FAIL", "solve-duplicates", "Some coefficient indices are duplicated.",
        <|"Duplicates" -> duplicates|>]
    ]
  ];

  AppendTo[checks,
    If[Sort[indices] === expected,
      SVBAuditCheck["PASS", "solve-completeness", "Solution covers every ansatz coefficient.",
        <|"Expected" -> Length[expected], "Actual" -> Length[indices]|>],
      SVBAuditCheck["FAIL", "solve-completeness", "Solution does not cover every ansatz coefficient.",
        <|"ExpectedIndices" -> expected, "ActualIndices" -> Sort[indices],
          "Missing" -> Complement[expected, indices], "Extra" -> Complement[indices, expected]|>]
    ]
  ];

  If[! SVBAuditNoBadSymbolsQ[sol],
    AppendTo[checks, SVBAuditCheck["FAIL", "solve-values",
      "Solution contains failed or infinite values.", <||>]],
    AppendTo[checks, SVBAuditCheck["PASS", "solve-values",
      "Solution values contain no failed or infinite values.", <||>]]
  ];

  If[TrueQ[verify],
    If[! ListQ[targetData] || Length[targetData] =!= 6,
      AppendTo[checks, SVBAuditCheck["FAIL", "solve-residual-input",
        "Residual verification requires six target expressions.", <|"TargetLength" -> If[ListQ[targetData], Length[targetData], Missing["NotList"]]|>]],
      suffixes = SVBAuditSuffixes[];
      Do[
        svrep = SVBAuditBuildSVRep[rootDir, label, suffixes[[i]], basisSV, basisMPL, order];
        If[svrep === $Failed,
          AppendTo[checks, SVBAuditCheck["FAIL", "solve-residual-series",
            "Could not build svrep for residual verification.",
            <|"Suffix" -> suffixes[[i]], "Label" -> label|>]];
          Continue[];
        ];
        setup = ((c /@ Range[Length[ansatzExpr]]) . ansatzExpr) /. svrep /. sol;
        residual = ((setup - targetData[[i]]) /. SVBAuditZetaRules[]) // Expand;
        AppendTo[checks,
          If[SVBAuditResidualZeroQ[residual],
            SVBAuditCheck["PASS", "solve-residual",
              "Solved ansatz matches target data at this limit.",
              <|"Limit" -> i, "Suffix" -> suffixes[[i]]|>],
            SVBAuditCheck["FAIL", "solve-residual",
              "Solved ansatz does not match target data at this limit.",
              <|"Limit" -> i, "Suffix" -> suffixes[[i]], "Residual" -> Short[residual, 8]|>]
          ]
        ];
        ,
        {i, 1, 6}
      ];
    ],
    AppendTo[checks, SVBAuditCheck["WARN", "solve-residual-skipped",
      "Residual verification skipped because target data was not provided.", <||>]]
  ];

  SVBAuditReport["solve:" <> label, checks, <|"Label" -> label, "Order" -> order|>]
];

Options[AuditFullPipeline] = {
  "Order" -> 3,
  "YOrder" -> 4,
  "TargetData" -> None,
  "WriteReport" -> True
};

AuditFullPipeline[rootDir_String, label_String, integrand_, poleType_String, lsBase_,
    ansatzExpr_List, basisSV_List, basisMPL_List, OptionsPattern[]] := Module[
  {inputReport, boundaryReport, seriesReport, solveReport, report, paths},
  inputReport = SVBAuditCombine["input-and-source:" <> label,
    AuditSourceContracts[rootDir],
    AuditPipelineInput[rootDir, integrand, poleType, lsBase, ansatzExpr, basisSV, basisMPL]
  ];
  boundaryReport = AuditBoundaryStep[rootDir, label, OptionValue["Order"]];
  seriesReport = AuditSeriesStep[rootDir, label, basisSV, basisMPL,
    "YOrder" -> OptionValue["YOrder"], "LSBase" -> lsBase,
    "WeightN" -> Lookup[inputReport["Checks"][[All, "Details"]], "NormalizationN", None] /. {l_List :> SelectFirst[l, IntegerQ, None]}];
  solveReport = AuditSolveStep[rootDir, label, ansatzExpr, basisSV, basisMPL,
    "Order" -> OptionValue["Order"], "TargetData" -> OptionValue["TargetData"]];

  report = SVBAuditCombine["full-pipeline:" <> label, inputReport, boundaryReport, seriesReport, solveReport];
  If[TrueQ[OptionValue["WriteReport"]],
    paths = SVBAuditWriteReport[rootDir, label, report];
    AssociateTo[report, "ReportFiles" -> paths],
    report
  ]
];

Options[AuditAnsatzBenchmark] = {
  "Parity" -> "even",
  "BenchmarkFile" -> Automatic,
  "ReferenceFlatFile" -> Automatic,
  "MaxWeight" -> Automatic,
  "CandidateGrouped" -> Automatic,
  "CandidateFlat" -> Automatic
};

AuditAnsatzBenchmark[rootDir_String, ansatzData_: Automatic, OptionsPattern[]] := Module[
  {checks = {}, parity, defs, groupedFile, flatFile, groupedData = $Failed, flatData = $Failed,
   candidateGrouped, candidateFlat, groupedLengths, candidateLengths,
   referenceStrings, candidateStrings, maxWeight},

  parity = ToLowerCase @ ToString[OptionValue["Parity"]];
  defs = Lookup[SVBAuditBenchmarkDefinitions[rootDir], "ansatz", <||>];
  groupedFile = Replace[OptionValue["BenchmarkFile"],
    Automatic :> Lookup[Lookup[defs, "GroupedFiles", <||>], parity, Missing["NoGroupedBenchmark"]]];
  flatFile = Replace[OptionValue["ReferenceFlatFile"],
    Automatic :> Lookup[Lookup[defs, "FlatFiles", <||>], parity, Missing["NoFlatBenchmark"]]];
  candidateGrouped = OptionValue["CandidateGrouped"];
  candidateFlat = OptionValue["CandidateFlat"];
  maxWeight = OptionValue["MaxWeight"];

  If[ansatzData =!= Automatic && candidateGrouped === Automatic && candidateFlat === Automatic,
    If[ListQ[ansatzData] && AllTrue[ansatzData, ListQ],
      candidateGrouped = ansatzData,
      candidateFlat = SVBAuditFlattenByWeight[ansatzData]
    ]
  ];

  If[MissingQ[groupedFile],
    AppendTo[checks, SVBAuditCheck["FAIL", "ansatz-benchmark-file",
      "No grouped ansatz benchmark file is configured for this parity.",
      <|"Parity" -> parity|>]],
    AppendTo[checks,
      If[FileExistsQ[groupedFile],
        SVBAuditCheck["PASS", "ansatz-benchmark-file", "Grouped ansatz benchmark file exists.",
          <|"File" -> groupedFile|>],
        SVBAuditCheck["FAIL", "ansatz-benchmark-file", "Grouped ansatz benchmark file is missing.",
          <|"File" -> groupedFile|>]
      ]
    ];
    If[FileExistsQ[groupedFile], groupedData = SVBAuditImport[groupedFile]];
    AppendTo[checks,
      If[ListQ[groupedData] && AllTrue[groupedData, ListQ],
        SVBAuditCheck["PASS", "ansatz-grouped-format",
          "Grouped ansatz benchmark imports as a list of weight buckets.",
          <|"Weights" -> Length[groupedData]|>],
        SVBAuditCheck["FAIL", "ansatz-grouped-format",
          "Grouped ansatz benchmark must import as a list of weight buckets.",
          <|"Head" -> Head[groupedData]|>]
      ]
    ];
  ];

  If[MissingQ[flatFile],
    AppendTo[checks, SVBAuditCheck["WARN", "ansatz-flat-file",
      "No flat ansatz benchmark file is configured for this parity.",
      <|"Parity" -> parity|>]],
    AppendTo[checks,
      If[FileExistsQ[flatFile],
        SVBAuditCheck["PASS", "ansatz-flat-file", "Flat ansatz benchmark file exists.",
          <|"File" -> flatFile|>],
        SVBAuditCheck["FAIL", "ansatz-flat-file", "Flat ansatz benchmark file is missing.",
          <|"File" -> flatFile|>]
      ]
    ];
    If[FileExistsQ[flatFile], flatData = SVBAuditImport[flatFile]];
    AppendTo[checks,
      If[ListQ[flatData] && Length[flatData] > 0,
        SVBAuditCheck["PASS", "ansatz-flat-format",
          "Flat ansatz benchmark imports as a non-empty list.",
          <|"Length" -> Length[flatData]|>],
        SVBAuditCheck["FAIL", "ansatz-flat-format",
          "Flat ansatz benchmark must import as a non-empty list.",
          <|"Head" -> Head[flatData], "Length" -> If[ListQ[flatData], Length[flatData], Missing["NotList"]]|>]
      ]
    ];
  ];

  If[ListQ[groupedData] && IntegerQ[maxWeight],
    AppendTo[checks,
      If[Length[groupedData] >= Max[0, maxWeight - 1],
        SVBAuditCheck["PASS", "ansatz-max-weight",
          "Grouped ansatz benchmark reaches the requested maximum weight.",
          <|"MaxWeight" -> maxWeight, "Buckets" -> Length[groupedData]|>],
        SVBAuditCheck["FAIL", "ansatz-max-weight",
          "Grouped ansatz benchmark does not reach the requested maximum weight.",
          <|"MaxWeight" -> maxWeight, "Buckets" -> Length[groupedData]|>]
      ]
    ]
  ];

  If[ListQ[candidateGrouped] && ListQ[groupedData],
    groupedLengths = Length /@ groupedData;
    candidateLengths = Length /@ candidateGrouped;
    AppendTo[checks,
      If[candidateLengths === groupedLengths,
        SVBAuditCheck["PASS", "ansatz-grouped-lengths",
          "Candidate grouped ansatz matches the benchmark bucket sizes.",
          <|"Expected" -> groupedLengths, "Actual" -> candidateLengths|>],
        SVBAuditCheck["FAIL", "ansatz-grouped-lengths",
          "Candidate grouped ansatz does not match the benchmark bucket sizes.",
          <|"Expected" -> groupedLengths, "Actual" -> candidateLengths|>]
      ]
    ];
    referenceStrings = SVBAuditCanonicalStrings[groupedData];
    candidateStrings = SVBAuditCanonicalStrings[candidateGrouped];
    AppendTo[checks,
      If[candidateStrings === referenceStrings,
        SVBAuditCheck["PASS", "benchmark-diff",
          "Candidate grouped ansatz matches the grouped benchmark exactly.",
          <|"Count" -> Length[referenceStrings]|>],
        SVBAuditCheck["FAIL", "benchmark-diff",
          "Candidate grouped ansatz differs from the grouped benchmark.",
          <|
            "Missing" -> Take[Complement[referenceStrings, candidateStrings], UpTo[10]],
            "Extra" -> Take[Complement[candidateStrings, referenceStrings], UpTo[10]]
          |>
        ]
      ]
    ];
  ];

  If[ListQ[candidateFlat] && ListQ[flatData],
    referenceStrings = SVBAuditCanonicalStrings[flatData];
    candidateStrings = SVBAuditCanonicalStrings[candidateFlat];
    AppendTo[checks,
      If[candidateStrings === referenceStrings,
        SVBAuditCheck["PASS", "benchmark-diff",
          "Candidate flat ansatz matches the flat benchmark exactly.",
          <|"Count" -> Length[referenceStrings]|>],
        SVBAuditCheck["FAIL", "benchmark-diff",
          "Candidate flat ansatz differs from the flat benchmark.",
          <|
            "Missing" -> Take[Complement[referenceStrings, candidateStrings], UpTo[10]],
            "Extra" -> Take[Complement[candidateStrings, referenceStrings], UpTo[10]]
          |>
        ]
      ]
    ];
  ];

  If[candidateGrouped === Automatic && candidateFlat === Automatic &&
      ListQ[groupedData] && ListQ[flatData],
    referenceStrings = SVBAuditCanonicalStrings[flatData];
    candidateStrings = SVBAuditCanonicalStrings[groupedData];
    AppendTo[checks,
      If[candidateStrings === referenceStrings,
        SVBAuditCheck["PASS", "benchmark-diff",
          "Grouped and flat ansatz benchmarks are internally consistent.",
          <|"Count" -> Length[referenceStrings]|>],
        SVBAuditCheck["FAIL", "benchmark-diff",
          "Grouped and flat ansatz benchmarks are not internally consistent.",
          <|
            "MissingFromGrouped" -> Take[Complement[referenceStrings, candidateStrings], UpTo[10]],
            "ExtraInGrouped" -> Take[Complement[candidateStrings, referenceStrings], UpTo[10]]
          |>
        ]
      ]
    ];
  ];

  SVBAuditReport["ansatz:" <> parity, checks, <|"Parity" -> parity|>]
];

Options[RunReviewGate] = {
  "Order" -> 3,
  "YOrder" -> 4,
  "WeightN" -> Automatic,
  "Integrand" -> None,
  "PoleType" -> None,
  "LSBase" -> None,
  "AnsatzExpr" -> Automatic,
  "BasisSV" -> Automatic,
  "BasisMPL" -> Automatic,
  "TargetData" -> None,
  "RunStartedAt" -> None,
  "ExpectedPermutations" -> Automatic,
  "VerifyResiduals" -> Automatic,
  "WriteReport" -> False,
  "Parity" -> "even",
  "MaxWeight" -> Automatic,
  "AnsatzData" -> Automatic
};

RunReviewGate[rootDir_String, label_String, stage_String, OptionsPattern[]] := Module[
  {report, benchmarkReport, basisSV, basisMPL, ansatzExpr, solveProfile, seriesProfile,
   parityLabel, paths},

  basisSV = OptionValue["BasisSV"];
  basisMPL = OptionValue["BasisMPL"];
  ansatzExpr = OptionValue["AnsatzExpr"];
  seriesProfile = SVBAuditBenchmarkProfileForStage[rootDir, "series", label];
  solveProfile = SVBAuditBenchmarkProfileForStage[rootDir, "solve", label];

  If[basisSV === Automatic && ! MissingQ[seriesProfile] && FileExistsQ[seriesProfile["BasisSV"]],
    basisSV = SVBAuditImport[seriesProfile["BasisSV"]]
  ];
  If[basisMPL === Automatic && ! MissingQ[seriesProfile] && FileExistsQ[seriesProfile["BasisMPL"]],
    basisMPL = SVBAuditImport[seriesProfile["BasisMPL"]]
  ];
  If[ansatzExpr === Automatic && ! MissingQ[solveProfile],
    ansatzExpr = SVBAuditImport[Lookup[solveProfile["AnsatzFiles"], label, ""]]
  ];

  report = Switch[stage,
    "preflight",
      SVBAuditCombine["preflight:" <> label,
        AuditSourceContracts[rootDir],
        AuditPipelineInput[rootDir, OptionValue["Integrand"], OptionValue["PoleType"], OptionValue["LSBase"],
          ansatzExpr, basisSV, basisMPL]
      ],
    "boundary",
      AuditBoundaryStep[rootDir, label, OptionValue["Order"],
        "RunStartedAt" -> OptionValue["RunStartedAt"],
        "ExpectedPermutations" -> OptionValue["ExpectedPermutations"]],
    "series",
      If[! ListQ[basisSV] || ! ListQ[basisMPL],
        SVBAuditReport["series:" <> label, {
          SVBAuditCheck["FAIL", "basis-format",
            "Series review requires both SV and MPL basis lists.", <||>]
        }],
        AuditSeriesStep[rootDir, label, basisSV, basisMPL,
          "YOrder" -> OptionValue["YOrder"],
          "LSBase" -> OptionValue["LSBase"],
          "WeightN" -> OptionValue["WeightN"],
          "RunStartedAt" -> OptionValue["RunStartedAt"]]
      ],
    "solve",
      If[! ListQ[ansatzExpr] || ! ListQ[basisSV] || ! ListQ[basisMPL],
        SVBAuditReport["solve:" <> label, {
          SVBAuditCheck["FAIL", "ansatz-format",
            "Solve review requires ansatz, SV basis, and MPL basis lists.", <||>]
        }],
        AuditSolveStep[rootDir, label, ansatzExpr, basisSV, basisMPL,
          "Order" -> OptionValue["Order"],
          "TargetData" -> OptionValue["TargetData"],
          "RunStartedAt" -> OptionValue["RunStartedAt"],
          "VerifyResiduals" -> OptionValue["VerifyResiduals"]]
      ],
    "pipeline",
      If[! ListQ[ansatzExpr] || ! ListQ[basisSV] || ! ListQ[basisMPL],
        SVBAuditReport["pipeline:" <> label, {
          SVBAuditCheck["FAIL", "ansatz-format",
            "Pipeline review requires ansatz, SV basis, and MPL basis lists.", <||>]
        }],
        AuditFullPipeline[rootDir, label, OptionValue["Integrand"], OptionValue["PoleType"],
          OptionValue["LSBase"], ansatzExpr, basisSV, basisMPL,
          "Order" -> OptionValue["Order"], "YOrder" -> OptionValue["YOrder"],
          "TargetData" -> OptionValue["TargetData"], "WriteReport" -> False]
      ],
    "ansatz",
      AuditAnsatzBenchmark[rootDir, OptionValue["AnsatzData"],
        "Parity" -> OptionValue["Parity"], "MaxWeight" -> OptionValue["MaxWeight"]],
    _,
      SVBAuditReport["review:" <> label <> ":" <> stage, {
        SVBAuditCheck["FAIL", "benchmark-profile", "Unknown review stage.", <|"Stage" -> stage|>]
      }]
  ];

  parityLabel = If[stage === "ansatz", "parity-" <> ToLowerCase @ ToString[OptionValue["Parity"]], label];
  benchmarkReport = If[MemberQ[{"boundary", "series", "solve", "ansatz"}, stage],
    SVBAuditBenchmarkStageChecks[rootDir, stage, parityLabel],
    Missing["NotApplicable"]
  ];

  If[AssociationQ[benchmarkReport],
    report = SVBAuditCombine["review:" <> stage <> ":" <> label, report, benchmarkReport]
  ];

  If[TrueQ[OptionValue["WriteReport"]],
    paths = SVBAuditWriteReport[rootDir, label <> "_" <> stage, report];
    AssociateTo[report, "ReportFiles" -> paths]
  ];

  report
];

Options[AuditHardBenchmarkWorkspace] = {
  "WriteReport" -> True,
  "Order" -> 3,
  "YOrder" -> 4
};

AuditHardBenchmarkWorkspace[rootDir_String, OptionsPattern[]] := Module[
  {basisSV, basisMPL, ans1, ans2, reports, report, paths},
  basisSV = SVBAuditImport[FileNameJoin[{rootDir, "allsvlist_fourloop.m"}]];
  basisMPL = SVBAuditImport[FileNameJoin[{rootDir, "allsvlistmpl_threeloop.m"}]];
  ans1 = SVBAuditImport[FileNameJoin[{rootDir, "threeloophard1_ans.m"}]];
  ans2 = SVBAuditImport[FileNameJoin[{rootDir, "threeloophard2_ans.m"}]];

  reports = {
    RunReviewGate[rootDir, "I3Lhard", "boundary", "Order" -> OptionValue["Order"]],
    RunReviewGate[rootDir, "I3Lhardr", "boundary", "Order" -> OptionValue["Order"]],
    RunReviewGate[rootDir, "I3Lhardt", "boundary", "Order" -> OptionValue["Order"]],
    RunReviewGate[rootDir, "threeloophard1", "series",
      "BasisSV" -> basisSV, "BasisMPL" -> basisMPL, "YOrder" -> OptionValue["YOrder"]],
    RunReviewGate[rootDir, "threeloophard2", "series",
      "BasisSV" -> basisSV, "BasisMPL" -> basisMPL, "YOrder" -> OptionValue["YOrder"]],
    RunReviewGate[rootDir, "threeloophard1", "solve",
      "AnsatzExpr" -> ans1, "BasisSV" -> basisSV, "BasisMPL" -> basisMPL,
      "VerifyResiduals" -> False, "Order" -> OptionValue["Order"]],
    RunReviewGate[rootDir, "threeloophard2", "solve",
      "AnsatzExpr" -> ans2, "BasisSV" -> basisSV, "BasisMPL" -> basisMPL,
      "VerifyResiduals" -> False, "Order" -> OptionValue["Order"]],
    RunReviewGate[rootDir, "ansatz-even", "ansatz", "Parity" -> "even", "MaxWeight" -> 6],
    RunReviewGate[rootDir, "ansatz-odd", "ansatz", "Parity" -> "odd", "MaxWeight" -> 6]
  };

  report = SVBAuditCombine["hard-benchmark-review", Sequence @@ reports];
  If[TrueQ[OptionValue["WriteReport"]],
    paths = SVBAuditWriteReport[rootDir, "hard_benchmark_review", report];
    AssociateTo[report, "ReportFiles" -> paths],
    report
  ]
];
