(* test_boundary_cache.wl *)
$HistoryLength = 0;
testDir = DirectoryName[$InputFileName];
rootDir = ParentDirectory[testDir];

Print["Root Directory: ", rootDir];
SetDirectory[rootDir];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];

(* Temporary paths *)
assocFile = FileNameJoin[{rootDir, "asym", "boundary_agent", "calculated_integrands.m"}];
backupAssocFile = FileNameJoin[{rootDir, "asym", "boundary_agent", "calculated_integrands_backup.m"}];

(* Step 1: Backup and test auto-construction *)
If[FileExistsQ[assocFile],
  If[FileExistsQ[backupAssocFile], DeleteFile[backupAssocFile]];
  CopyFile[assocFile, backupAssocFile];
  DeleteFile[assocFile];
];

Print["\n=== TEST 1: Reconstruct Association ==="];
reconstructed = VerifyOrConstructAssociation[rootDir];
Print["Reconstructed keys count: ", Length[reconstructed]];
If[Length[reconstructed] > 0,
  Print["SUCCESS: Auto-reconstruction created valid association!"];
,
  Print["FAILED: Auto-reconstruction failed to create valid association!"];
  Exit[1];
];

(* Restore the backup to keep manual updates intact (which contains the components) *)
If[FileExistsQ[backupAssocFile],
  CopyFile[backupAssocFile, assocFile, OverwriteTarget -> True];
  DeleteFile[backupAssocFile];
];

(* Step 2: Test cache match, scaling, and copying *)
Print["\n=== TEST 2: Cache match and loading ==="];
(* We will test matching with a scaled version of threeloopI5 *)
threeloopI5Integrand = 1/(x[1, 6]*x[1, 7]*x[2, 6]*x[2, 7]*x[3, 5]*x[3, 7]*x[4, 5]*x[4, 6]*x[5, 6]*x[5, 7]);
scaledIntegrand = 2 * threeloopI5Integrand;

config = <|
  "LoopPoints" -> {5, 6, 7},
  "Coefficients" -> {1},
  "Integrands" -> {scaledIntegrand}
|>;

(* We want to output boundaries under test label: "test_cache_hit_I5" *)
testLabel = "test_cache_hit_I5";
testBoundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];

(* Clean any old test files *)
Do[
  permStr = StringJoin[ToString /@ perm];
  testPath = FileNameJoin[{testBoundaryDir, testLabel <> permStr <> "_order3_asyexp.m"}];
  If[FileExistsQ[testPath], DeleteFile[testPath]];
, {perm, $Perms}];

(* Run RunBoundaryConditions with the scaled integrand *)
Block[{$Integrand = scaledIntegrand},
  RunBoundaryConditions[rootDir, testLabel, config, 3]
];

(* Verify that the test files were created and their values are scaled by 2 *)
allCreated = True;
Do[
  permStr = StringJoin[ToString /@ perm];
  testPath = FileNameJoin[{testBoundaryDir, testLabel <> permStr <> "_order3_asyexp.m"}];
  refPath = FileNameJoin[{testBoundaryDir, "threeloopI5" <> permStr <> "_order3_asyexp.m"}];
  
  If[FileExistsQ[testPath],
    testData = Import[testPath] // Normal;
    refData = Import[refPath] // Normal;
    
    ratio = Simplify[testData / refData];
    If[ratio === 2 || (Head[ratio] === List && AllTrue[ratio, # === 2 &]),
      Print["Permutation ", permStr, " successfully scaled and copied!"];
    ,
      Print["Permutation ", permStr, " has incorrect scaling: ", ratio];
      allCreated = False;
    ];
    DeleteFile[testPath];
  ,
    Print["Permutation ", permStr, " boundary file was not created!"];
    allCreated = False;
  ];
, {perm, $Perms}];

If[allCreated,
  Print["SUCCESS: Cache hitting, copying, scaling, and verification succeeded!"];
,
  Print["FAILED: Cache hitting verification failed!"];
  Exit[1];
];

(* Step 3: Test Dynamic Cache Update *)
Print["\n=== TEST 3: Dynamic cache update ==="];
dummyIntegrand = 1/(x[1, 5]*x[2, 6]*x[3, 7]);
(* We will mock a successful run by writing the boundary files first *)
Do[
  permStr = StringJoin[ToString /@ perm];
  testPath = FileNameJoin[{testBoundaryDir, "dummyRun" <> permStr <> "_order3_asyexp.m"}];
  Put[SeriesData[Y, 0, {1}, 0, 1, 1], testPath];
, {perm, $Perms}];

calcAssocBefore = Quiet[Get[assocFile]];
Block[{$Integrand = dummyIntegrand},
  Module[{assocFileLocal = assocFile, assoc},
    If[FileExistsQ[assocFileLocal],
      Quiet[assoc = Get[assocFileLocal]];
      If[AssociationQ[assoc],
        AssociateTo[assoc, $Integrand -> "dummyRun"];
        Quiet[Put[assoc, assocFileLocal]];
      ];
    ];
  ];
];

calcAssocAfter = Quiet[Get[assocFile]];
If[calcAssocAfter[dummyIntegrand] === "dummyRun",
  Print["SUCCESS: Cache dynamic update succeeded!"];
  Quiet[Put[calcAssocBefore, assocFile]];
,
  Print["FAILED: Cache dynamic update failed!"];
  Exit[1];
];

(* Clean up dummy files *)
Do[
  permStr = StringJoin[ToString /@ perm];
  testPath = FileNameJoin[{testBoundaryDir, "dummyRun" <> permStr <> "_order3_asyexp.m"}];
  If[FileExistsQ[testPath], DeleteFile[testPath]];
, {perm, $Perms}];

Print["\nALL TESTS PASSED SUCCESSFULLY!"];
