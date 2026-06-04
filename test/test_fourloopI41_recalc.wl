(* test_fourloopI41_recalc.wl *)
$HistoryLength = 0;
testDir = DirectoryName[$InputFileName];
rootDir = ParentDirectory[testDir];

Print["Root Directory: ", rootDir];
SetDirectory[rootDir];

boundaryAgentDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
backupDir = FileNameJoin[{boundaryAgentDir, "backup_fourloopI41"}];
If[!DirectoryQ[backupDir], CreateDirectory[backupDir]];

(* Get list of current fourloopI41 boundary files *)
fourloopI41Files = FileNames["fourloopI41*_order4_asyexp.m", boundaryAgentDir];
Print["Found existing boundary files to backup: ", Length[fourloopI41Files]];

(* Backup existing boundary files *)
Do[
  dest = FileNameJoin[{backupDir, FileNameTake[f]}];
  If[FileExistsQ[dest], DeleteFile[dest]];
  CopyFile[f, dest];
  Print["Backed up: ", FileNameTake[f], " -> ", dest];
, {f, fourloopI41Files}];

(* Backup and modify calculated_integrands.m *)
assocFile = FileNameJoin[{boundaryAgentDir, "calculated_integrands.m"}];
backupAssoc = FileNameJoin[{boundaryAgentDir, "calculated_integrands_backup.m"}];
If[FileExistsQ[assocFile],
  If[FileExistsQ[backupAssoc], DeleteFile[backupAssoc]];
  CopyFile[assocFile, backupAssoc];
  Print["Backed up calculated_integrands.m"];
  
  assoc = Get[assocFile];
  If[AssociationQ[assoc],
    (* Remove fourloopI41 key *)
    filteredAssoc = Select[assoc, # =!= "fourloopI41" &];
    Put[filteredAssoc, assocFile];
    Print["Removed 'fourloopI41' from calculated_integrands.m"];
  ];
];

(* Delete the original fourloopI41 boundary files so recalculation is forced *)
Do[
  If[FileExistsQ[f], DeleteFile[f]];
  Print["Deleted original: ", f];
, {f, fourloopI41Files}];

(* Run the calculation *)
Print["\n=== Launching fourloopI41 recalculation ==="];
runScript = FileNameJoin[{rootDir, "runs", "fourloopI41", "run.wl"}];
proc = RunProcess[{"wolfram", "-script", runScript}, "ProcessDirectory" -> rootDir];

Print["\n--- Recalculation Output ---"];
Print[proc["StandardOutput"]];
Print["--- Recalculation Error ---"];
Print[proc["StandardError"]];
Print["ExitCode: ", proc["ExitCode"]];

(* Verify that the recalculated files exist and are mathematically identical *)
Print["\n=== Verifying recalculated boundary files ==="];
allValid = True;
Do[
  fileName = FileNameTake[f];
  newPath = FileNameJoin[{boundaryAgentDir, fileName}];
  backupPath = FileNameJoin[{backupDir, fileName}];
  
  If[!FileExistsQ[newPath],
    Print["FAILED: Recalculated file missing: ", fileName];
    allValid = False;
    Continue[];
  ];
  
  newData = Import[newPath] // Normal;
  backupData = Import[backupPath] // Normal;
  
  diff = Expand[newData - backupData] // Simplify;
  If[Normal[diff] === 0,
    Print["SUCCESS: ", fileName, " is mathematically identical to backup!"];
  ,
    Print["FAILED: ", fileName, " differs from backup!"];
    Print["Diff: ", Short[diff, 10]];
    allValid = False;
  ];
, {f, fourloopI41Files}];

(* Restore backup of calculated_integrands.m *)
If[FileExistsQ[backupAssoc],
  CopyFile[backupAssoc, assocFile, OverwriteTarget -> True];
  DeleteFile[backupAssoc];
  Print["Restored original calculated_integrands.m"];
];

If[allValid,
  Print["\nALL RECALCULATED BOUNDARY FILES MATCH BENCHMARKS PERFECTLY!"];
,
  Print["\nVERIFICATION FAILED!"];
  Exit[1];
];
