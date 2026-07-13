(* Assemble full integral from per-LS result.m for all runs under runs/ *)
(* Skill 5: Result Assembly — see SKILL.md in the same folder *)
(*
  - Scans every subdirectory of runs/.
  - Assembles (or renews) <label>.txt for any run that has result.m.
  - Skips runs without result.m (not yet successfully calculated).
*)

rootDir = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
runsDir = FileNameJoin[{rootDir, "runs"}];

runDirs = Select[FileNames["*", runsDir], DirectoryQ];
labels  = Last /@ FileNameSplit /@ runDirs;

nAssembled = 0;
nSkipped   = 0;

Do[
  runDir     = FileNameJoin[{runsDir, label}];
  inputFile  = FileNameJoin[{runDir, "input.wl"}];
  resultFile = FileNameJoin[{runDir, "result.m"}];
  outFile    = FileNameJoin[{runDir, label <> ".txt"}];

  (* Skip runs without result.m — not yet successfully calculated *)
  If[!FileExistsQ[resultFile],
    Print["SKIP ", label, ": result.m missing (not yet solved)"];
    nSkipped++;
    Continue[]
  ];

  (* Load leading singularity from input.wl in isolated scope *)
  lsExpr =.;
  Block[{integrand, integrandlist, coeff, leadingsingularity,
         leadingsingularitylist, ansatz, ansatzlist, OrderY},
    Get[inputFile];
    (* Prefer leadingsingularitylist if defined; otherwise leadingsingularity *)
    If[ValueQ[leadingsingularitylist],
      lsExpr = leadingsingularitylist,
      lsExpr = leadingsingularity
    ];
  ];

  resultList = Import[resultFile];

  (* Assemble: multi-LS (list) vs single-LS (scalar) *)
  If[ListQ[lsExpr],
    assembled = Sum[lsExpr[[k]] * resultList[[k]], {k, 1, Length[resultList]}];
    nLS = Length[resultList];
  ,
    assembled = lsExpr * resultList[[1]];
    nLS = 1;
  ];

  (* Replace cross-ratio variables u,v with z,zz before export *)
  assembled = assembled /. {u -> z*zz, v -> (1-z)*(1-zz)};

  (* Renew if <label>.txt already exists, otherwise create *)
  action = If[FileExistsQ[outFile], "renewed", "created"];
  Export[outFile, assembled // InputForm // ToString];
  Print["Assembled ", label, " -> ", label, ".txt (", action, ", ", nLS, " LS, ",
        StringLength[assembled // InputForm // ToString], " chars)"];
  nAssembled++;
, {label, labels}];

Print["Done. Assembled ", nAssembled, " run(s); skipped ", nSkipped, "."];
