(* The weighted path is part of SolveIntegrandSystem, not a label-specific replay. *)
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "solve_agent", "exact_linear.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "weighted_series.wl"}]];
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "asym", "boundary_agent", "weighted_boundary.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "series_agent.wl"}]];
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "solve_agent", "solve_agent.wl"}]];
ClearAll[RunWeightedWorkflow, SVBWriteFailureReport];
SVBWriteFailureReport[root_, label_, failure_Failure] := Module[{dir, report},
  dir = FileNameJoin[{root, "runs", label}];
  If[!DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  report = <|"Status" -> "Failed", "OutputsValidForThisRun" -> False,
    "FailureTag" -> First[failure], "Details" -> ToString[Last[failure], InputForm],
    "Message" -> "Any existing result files belong to an earlier successful run."|>;
  Export[FileNameJoin[{dir, "workflow_validation.json"}], report, "RawJSON"];
];
RunWeightedWorkflow[root_, label_, config_, spec_, order_, yOrder_] := Module[
  {dir, stream, result, data, blocks, start, boundaries, series, report, requested, activeSpec = spec},
  dir = FileNameJoin[{root, "runs", label}];
  If[!DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  stream = OpenWrite[FileNameJoin[{dir, "run.log"}], FormatType -> OutputForm, PageWidth -> Infinity];
  result = CheckAbort[Block[{$Output = Append[$Output, stream], $Messages = Append[$Messages, stream]},
    Catch[
      start = AbsoluteTime[];
      Print["=== SolveIntegrandSystem: weighted expansions for ", label, " ==="];
      Print["[Preflight] LS profile ", spec["Profile"], "; input basis dimensions ", spec["BasisDimensions"]];
      requested = Lookup[config, "RegionOrder", order];
      If[!IntegerQ[requested] || requested < 0 ||
          requested > spec["SeriesProfile"]["MaximumOrder"], Throw[Failure["SeriesDepthUnavailable", <|"RequestedOrder" -> requested|>]]];
      (* Available depth belongs to the profile, not the shared workflow. *)
      activeSpec = Append[spec, "SeriesProfile" -> Append[spec["SeriesProfile"], "Blocks" ->
        Select[spec["SeriesProfile"]["Blocks"], #["Order"] <= requested &]]];
      {boundaries, data} = AbsoluteTiming[RunBoundaryConditions[root, label, config, requested, "WeightedSpec" -> activeSpec]];
      If[FailureQ[data], Throw[data]];
      Print["[Boundary] PASS: required boundary expressions loaded."];
      {series, blocks} = AbsoluteTiming[RunSeriesExpansion[root, label, config, activeSpec, data]];
      If[FailureQ[blocks], Throw[blocks]];
      Print["[Series] PASS: projected ", Length[blocks], " blocks onto the supplied ansatz."];
      report = RunCoefficientSolving[root, label, config, blocks];
      If[FailureQ[report], Throw[report]];
      report = Join[report, <|"Profile" -> spec["Profile"], "BoundarySeconds" -> boundaries,
        "SeriesSeconds" -> series, "TotalSeconds" -> (AbsoluteTime[]-start),
        "BoundarySource" -> If[AssociationQ[Lookup[config,"BoundaryData",Automatic]], "UserExpressions", "CertifiedGraphCache"],
        "EquationMatrixRebuiltFromInput" -> True|>];
      Export[FileNameJoin[{dir,"workflow_validation.json"}], report, "RawJSON"];
      Print["[Solve] PASS: unique coefficients and every original row checked."];
      Print["Total weighted workflow seconds: ", report["TotalSeconds"]]; report
    ]
  ], Close[stream]; SVBWriteFailureReport[root, label, Failure["Aborted", <||>]]; Abort[]];
  If[FailureQ[result],
    Block[{$Output = Append[$Output, stream]}, Print["[Workflow failed] ", result]];
    SVBWriteFailureReport[root, label, result]];
  Close[stream];
  result
];
