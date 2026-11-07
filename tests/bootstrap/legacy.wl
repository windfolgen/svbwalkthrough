(* Run against existing boundary/series caches in an isolated output root.
   Set SVB_LEGACY_ROOT to a prepared test root; the default is scratch/. *)
$HistoryLength = 0;
package = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
testRoot = Environment["SVB_LEGACY_ROOT"];
If[!StringQ[testRoot], testRoot = FileNameJoin[{package, "scratch", "bootstrap_validation"}]];
rootDir = testRoot;
SetDirectory[rootDir];
Get[FileNameJoin[{package, "workflow_engine.wl"}]];
Get[FileNameJoin[{package, "input_parser.wl"}]];
labels = {"threeloopI5", "threeloopI8", "threeloophard1", "threeloophard2", "fourloopI41", "fourloopI42"};
reports = {};
Do[
  config = ParseInput[FileNameJoin[{testRoot, "runs", label}]];
  If[config === $Failed, Exit[1]];
  (* No stale saved result may satisfy a regression. Only isolated outputs are removed. *)
  Do[If[FileExistsQ[path],DeleteFile[path]],
    {path,FileNameJoin[{testRoot,"runs",label,#}]& /@ {"coeff_sol.m","result.m"}}];
  {seconds, answer} = AbsoluteTiming[SolveIntegrandSystem[testRoot, label, config,
    If[StringStartsQ[label, "four"], 4, 3], If[StringStartsQ[label, "four"], 5, 4]]];
  checks = Table[Get[FileNameJoin[{testRoot, "runs", label, file}]] ===
    Get[FileNameJoin[{package, "runs", label, file}]], {file, {"coeff_sol.m", "result.m"}}];
  row = <|"Label" -> label, "CoefficientMatch" -> First[checks], "NumeratorMatch" -> Last[checks],
    "Seconds" -> seconds, "CachedBoundariesAndSeries" -> True|>;
  AppendTo[reports, row]; Print[row];
  Export[FileNameJoin[{package, "tests", "bootstrap", "legacy_validation.json"}], reports, "RawJSON"];
  If[answer === $Failed || FailureQ[answer] || !And @@ checks, Exit[1]], {label, labels}];
Exit[0];
