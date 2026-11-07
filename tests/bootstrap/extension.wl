(* Renaming/scaling is independent of profile selection; insufficient data
   must fail without legitimizing outputs from an earlier successful solve. *)
$HistoryLength = 0;
package = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
rootDir = FileNameJoin[{package,"scratch","bootstrap_validation"}];
Get[FileNameJoin[{package,"workflow_engine.wl"}]];
Get[FileNameJoin[{package,"input_parser.wl"}]];
cfg = ParseInput[FileNameJoin[{package,"runs","fourloopI163"}]];
cfg = Append[cfg,"Integrands" -> (2 cfg["Integrands"])];
answer = SolveIntegrandSystem[rootDir,"renamed_scaled_example",cfg,6,6];
checks = <|"RenamedScaledRunCompleted" -> (!FailureQ[answer] && answer =!= $Failed)|>;
If[!TrueQ[First[Values[checks]]], Print[answer]; Exit[1]];
point = Get[FileNameJoin[{rootDir,"runs","renamed_scaled_example","generator_coeff_sol.m"}]];
reference = Get[FileNameJoin[{package,"tests","bootstrap","fixtures","I163_generators.m"}]];
AssociateTo[checks,"ScaledCoefficientsMatch" -> (point === 2 reference)];
old = FileHash[FileNameJoin[{rootDir,"runs","renamed_scaled_example","result.m"}],"SHA256"];
answer = SolveIntegrandSystem[rootDir,"renamed_scaled_example",cfg,4,4];
validation = Import[FileNameJoin[{rootDir,"runs","renamed_scaled_example","workflow_validation.json"}],"RawJSON"];
AssociateTo[checks,{
  "InsufficientOrderRejected" -> (FailureQ[answer] && First[answer] === "Underdetermined"),
  "StaleOutputsMarkedInvalid" -> (validation["Status"] === "Failed" && validation["OutputsValidForThisRun"] === False),
  "EarlierResultPreserved" -> (old === FileHash[FileNameJoin[{rootDir,"runs","renamed_scaled_example","result.m"}],"SHA256"])}];
(* Change a target independently of the coefficient solution. *)
cfg = ParseInput[FileNameJoin[{package,"runs","fourloopI163"}]];
Get[FileNameJoin[{package,"constraint_agent","workflow.wl"}]];
profile = SVBLoadConstraintProfile[package,cfg];
badBoundaries = Association@Table[entry["Name"] ->
  (Get[FileNameJoin[{package,entry["BoundaryFile"]}]] + If[entry["Order"]===2,1,0]),
  {entry,Select[profile["Blocks"],#["Kind"]==="Boundary"&]}];
blocks = SVBProfileBlocks[package,Append[cfg,"BoundaryData"->badBoundaries],profile,6];
inconsistent = SVBExactSolve[blocks,profile["ParameterMap"]//Dimensions//Last];
AssociateTo[checks,"InconsistentPhysicalBoundariesRejected" -> FailureQ[inconsistent]];
(* Loading/running the extension must not change a later ordinary run. *)
legacy = ParseInput[FileNameJoin[{rootDir,"runs","threeloopI5"}]];
answer = SolveIntegrandSystem[rootDir,"threeloopI5",legacy,3,4];
AssociateTo[checks,"LegacyAfterExtendedRunUnchanged" ->
  (Get[FileNameJoin[{rootDir,"runs","threeloopI5","coeff_sol.m"}]] ===
   Get[FileNameJoin[{package,"runs","threeloopI5","coeff_sol.m"}]] &&
   Get[FileNameJoin[{rootDir,"runs","threeloopI5","result.m"}]] ===
   Get[FileNameJoin[{package,"runs","threeloopI5","result.m"}]] &&
   !FailureQ[answer] && answer =!= $Failed)];
Export[FileNameJoin[{package,"tests","bootstrap","extension_validation.json"}],checks,"RawJSON"];
Print[checks]; Exit[If[And@@Values[checks],0,1]];
