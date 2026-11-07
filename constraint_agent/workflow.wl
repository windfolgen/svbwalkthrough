(* Explicitly selected extension; loading the legacy workflow does not load this file. *)
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "series_agent", "weighted_workflow.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "constraints.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName], "profile.wl"}]];
ClearAll[RunExtendedWorkflow];
RunExtendedWorkflow[root_, label_, config_, order_, yOrder_] := Module[
  {spec, dir, stream, answer, start, report, profile, blocks, requested},
  If[config["BootstrapMethod"] === "Weighted",
    spec = SVBResolveWeightedProfile[root, config];
    If[FailureQ[spec], SVBWriteFailureReport[root, label, spec]; Return[spec]];
    Return[RunWeightedWorkflow[root, label, config, spec, order, yOrder]]
  ];
  dir = FileNameJoin[{root, "runs", label}];
  If[!DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  stream = OpenWrite[FileNameJoin[{dir, "run.log"}], PageWidth -> Infinity];
  answer = CheckAbort[Block[{$Output = Append[$Output, stream], $Messages = Append[$Messages, stream]},
    Catch[
      start = AbsoluteTime[];
      Print["=== SolveIntegrandSystem: additional constraints for ", label, " ==="];
      profile = SVBLoadConstraintProfile[root, config];
      If[FailureQ[profile], Throw[profile]];
      requested = Lookup[config, "RegionOrder", order];
      blocks = SVBProfileBlocks[root, config, profile, requested];
      If[FailureQ[blocks], Throw[blocks]];
      report = RunCoefficientSolving[root, label, config, blocks, profile["ParameterMap"]];
      If[FailureQ[report], Throw[report]];
      report = Join[report, <|"Profile" -> profile["Name"], "TotalSeconds" -> (AbsoluteTime[]-start),
        "BoundarySource" -> If[AssociationQ[Lookup[config,"BoundaryData",Automatic]], "UserExpressions", "CertifiedGraphCache"],
        "WholeFunctionNullCertificate" -> profile["NullCertificate"],
        "Qualification" -> profile["Qualification"]|>];
      Export[FileNameJoin[{dir, "workflow_validation.json"}], report, "RawJSON"];
      Print["[Solve] PASS: unique generators; every original constraint checked."];
      report
    ]], Close[stream]; SVBWriteFailureReport[root, label, Failure["Aborted", <||>]]; Abort[]];
  Close[stream];
  If[FailureQ[answer], SVBWriteFailureReport[root, label, answer]];
  answer
];
