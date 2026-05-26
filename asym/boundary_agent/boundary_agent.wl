(* =================================================================== *)
(*  Skill 2: Boundary Condition Calculation Agent                      *)
(*  Location: ./asym/boundary_agent/                                   *)
(*                                                                     *)
(*  Follows the exact syntax of asym/run_I3Lhard_parallel.wl.          *)
(*  Only the integrand expression varies per problem.                  *)
(*                                                                     *)
(*  Input (set before calling):                                        *)
(*    rootDir      — project root                                      *)
(*    label        — file name prefix shared by all skills             *)
(*    $Integrand   — the integrand expression (global, set externally) *)
(*    $Perms       — list of 6 permutations (global, set externally)    *)
(*                                                                     *)
(*  Options:                                                            *)
(*    "InputDir" -> None  — alternative directory for boundary files    *)
(*                          (e.g., runs/<label>/boundaries/)            *)
(*                                                                     *)
(*  Output: 6 .m files in ./asym/boundary_agent/:                      *)
(*    <label><perm>_order<order>_asyexp.m                              *)
(*                                                                     *)
(*  If boundary files already exist in asym/boundary_agent/ (or the    *)
(*  optional "InputDir"), the computation is skipped and existing       *)
(*  files are reused.                                                   *)
(*                                                                     *)
(*  Temporary files in asym/tmp/ are reused across runs.               *)
(* =================================================================== *)

ClearAll[RunBoundaryConditions];
Options[RunBoundaryConditions] = {"InputDir" -> None, "IBPDir" -> "/Users/windfolgen/Documents/aether/svbwalkthrough_ibp"};

RunBoundaryConditions[rootDir_, label_, order_:3, loopPoints_:{5,6,7}, opts : OptionsPattern[]] := Module[
  {asymDir, tmpDir, boundaryDir, expectedFiles, altDir, altFiles,
   fullIntegrand, results, i, j, perm, permStr, ibpDir, origDir},

  asymDir  = FileNameJoin[{rootDir, "asym"}];

  (* ---- check if boundary files already exist ---- *)
  boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
  expectedFiles = Table[
    FileNameJoin[{boundaryDir, label <> StringJoin[ToString /@ perm] <> "_order" <> ToString[order] <> "_asyexp.m"}],
    {perm, $Perms}
  ];
  If[AllTrue[expectedFiles, FileExistsQ],
    Print["Boundary files already exist for '", label, "' in '", boundaryDir, "'. Skipping computation."];
    Return[];
  ];

  (* check alternative InputDir *)
  altDir = OptionValue["InputDir"];
  If[altDir =!= None,
    altFiles = Table[
      FileNameJoin[{altDir, label <> StringJoin[ToString /@ perm] <> "_order" <> ToString[order] <> "_asyexp.m"}],
      {perm, $Perms}
    ];
    If[AllTrue[altFiles, FileExistsQ],
      Print["Found boundary files for '", label, "' in '", altDir, "'. Copying to boundary_agent/."];
      If[! DirectoryQ[boundaryDir], CreateDirectory[boundaryDir]];
      Do[CopyFile[altFiles[[j]], expectedFiles[[j]], OverwriteTarget -> True], {j, 1, 6}];
      Return[];
    ];
  ];

  (* ensure tmp directory exists for cached results *)
  tmpDir = FileNameJoin[{asymDir, "tmp"}];
  If[! DirectoryQ[tmpDir], CreateDirectory[tmpDir]];

  (* ---- exact syntax from run_I3Lhard_parallel.wl ---- *)

  (* load package LiteRed2 *)
  Get["LiteRed2`"];

  (* kinematic settings *)
  SetDim[d];
  Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
  SetConstraints[{p}, sp[p, p] = u];

  (* load LiteRed2 bases *)
  Get[FileNameJoin[{asymDir, "Bases", "asym", "asym"}]];
  Get[FileNameJoin[{asymDir, "Bases", "asym3L", "asym3L"}]];
  Get[FileNameJoin[{asymDir, "Bases", "asym2L", "asym2L"}]];
  Get[FileNameJoin[{asymDir, "Bases", "asym1L", "asym1L"}]];

  LaunchKernels[6];

  (* load asymptotic expansion engine *)
  Get[FileNameJoin[{asymDir, "asym_new.wl"}]];
  ParallelEvaluate[Get[FileNameJoin[{asymDir, "asym_new.wl"}]]];

  (* redirect IBP reduction output to external directory *)
  ibpDir = OptionValue["IBPDir"];
  If[!DirectoryQ[ibpDir], CreateDirectory[ibpDir]];
  origDir = Directory[];
  SetDirectory[ibpDir];
  Print["IBP output redirected to: ", ibpDir];

  (* run parallel asymptotic expansion for all 6 permutations *)
  (* RunAsymExpansionParallel saves results to asym/check<label><perm>_order<order>_asyexp.m *)
  (* We relocate them to asym/boundary_agent/ and strip the "check" prefix *)
  RunAsymExpansionParallel[label, $Integrand, $Perms, order, loopPoints];

  (* restore original working directory *)
  SetDirectory[origDir];

  (* relocate output files *)
  Table[
    Module[{permStr, src, dst},
      permStr = StringJoin[ToString /@ perm];
      src = FileNameJoin[{asymDir, "check" <> label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
      dst = FileNameJoin[{rootDir, "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
      If[FileExistsQ[src],
        CopyFile[src, dst, OverwriteTarget -> True];
        DeleteFile[src];
        Print["  Moved boundary output: ", label, permStr]
      ];
    ],
    {perm, $Perms}
  ];

  Print["Boundary condition files saved."];
  Print["Cached temporary results in ", tmpDir, " can be reused for subsequent bootstrap problems."];
];
