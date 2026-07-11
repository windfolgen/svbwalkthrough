(* =================================================================== *)
(*  Bootstrap Run: fourloopI173                                         *)
(* =================================================================== *)

$HistoryLength = 0;

runDir   = DirectoryName[$InputFileName];
rootDir  = ParentDirectory[ParentDirectory[runDir]];
SetDirectory[rootDir];
Print["Root: ", rootDir];
Print["Run:  ", runDir];

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "fourloopI173";
order = 4;
yOrder = 5;

(* Mirror input files — enables the mirror solve stage (Stage 4).
   Keys are ext types (e0, einf, e1); values are lists of per-LS files.
   List length per ext must match the number of leading singularities (2 for this problem).
   Comment out or set to None to disable the mirror stage.
   Uses $MirrorInputFilesOverride because config.wl (loaded inside the engine)
   resets $MirrorInputFiles to None. *)
$MirrorInputFilesOverride = <|
  "e0"   -> {FileNameJoin[{rootDir, "data", "svansatzw8_e0_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_e0_2.txt"}]},
  "einf" -> {FileNameJoin[{rootDir, "data", "svansatzw8_einf_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_einf_2.txt"}]},
  "e1"   -> {FileNameJoin[{rootDir, "data", "svansatzw8_e1_1.txt"}],
             FileNameJoin[{rootDir, "data", "svansatzw8_e1_2.txt"}]}
|>;

parsed = ParseInput[runDir];
If[parsed === $Failed, Print["Failed to parse input."]; Exit[1]];

SolveIntegrandSystem[rootDir, label, parsed, order, yOrder];
