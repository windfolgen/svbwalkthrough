(* =================================================================== *)
(*  Skill 2: Boundary Condition Calculation Agent                      *)
(*  Location: ./asym/boundary_agent/                                   *)
(*                                                                     *)
(*  Follows the exact syntax of asym/run_I3Lhard_parallel.wl.          *)
(*  Only the integrand expression varies per problem.                  *)
(*                                                                     *)
(*  Input (set before calling):                                        *)
(*    rootDir      a^\200\224 project root                                      *)
(*    label        a^\200\224 file name prefix shared by all skills             *)
(*    $Integrand   a^\200\224 the integrand expression (global, set externally) *)
(*    $Perms       a^\200\224 list of 6 permutations (global, set externally)    *)
(*                                                                     *)
(*  Options:                                                            *)
(*    "InputDir" -> None  a^\200\224 alternative directory for boundary files    *)
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

ClearAll[RunBoundaryConditions, VerifyOrConstructAssociation, CheckIntegrandCache];
Options[RunBoundaryConditions] = {"InputDir" -> None, "IBPDir" -> "/Users/windfolgen/Documents/aether/svbwalkthrough_ibp"};

VerifyOrConstructAssociation[rootDir_] := Module[
  {boundaryDir, assocFile, assoc, runsDir, runs, label, inputPath, integrandVal, p, integrandList, files},
  boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
  assocFile = FileNameJoin[{boundaryDir, "calculated_integrands.m"}];
  
  If[FileExistsQ[assocFile],
    Quiet[assoc = Get[assocFile]];
    If[AssociationQ[assoc], Return[assoc]]
  ];
  
  Print["[Boundary Agent] Association file missing or invalid. Constructing from runs directory..."];
  assoc = <||>;
  runsDir = FileNameJoin[{rootDir, "runs"}];
  If[DirectoryQ[runsDir],
    runs = FileNames["*", runsDir];
    Do[
      If[DirectoryQ[run],
        label = FileNameTake[run, -1];
        inputPath = FileNameJoin[{run, "input.wl"}];
        If[FileExistsQ[inputPath],
          Quiet[
            Block[{integrand, integrandlist, coeff, leadingsingularity, leadingsingularitylist, ansatz, ansatzlist, OrderY},
              Get[inputPath];
              If[ValueQ[integrandlist],
                If[Length[integrandlist] == 1,
                  integrandVal = integrandlist[[1]];
                  files = FileNames[label <> "*_order*_asyexp.m", boundaryDir];
                  files = Select[files, FreeQ[FileBaseName[#], "_comp"] &];
                  If[Length[files] > 0,
                    AssociateTo[assoc, integrandVal -> label]
                  ];
                ,
                  Do[
                    integrandVal = integrandlist[[p]];
                    files = FileNames[label <> "_comp" <> ToString[p] <> "_*_order*_asyexp.m", boundaryDir];
                    If[Length[files] > 0,
                      AssociateTo[assoc, integrandVal -> label <> "_comp" <> ToString[p] <> "_"]
                    ];
                  , {p, 1, Length[integrandlist]}];
                ];
              ,
                If[ValueQ[integrand],
                  integrandVal = integrand;
                  files = FileNames[label <> "*_order*_asyexp.m", boundaryDir];
                  files = Select[files, FreeQ[FileBaseName[#], "_comp"] &];
                  If[Length[files] > 0,
                    AssociateTo[assoc, integrandVal -> label]
                  ];
                ]
              ];
            ]
          ];
        ];
      ];
    , {run, runs}];
  ];
  
  If[!DirectoryQ[boundaryDir], CreateDirectory[boundaryDir]];
  Put[assoc, assocFile];
  Print["[Boundary Agent] Construction complete. Saved association list of length ", Length[assoc], " to ", assocFile];
  Return[assoc];
];

CheckIntegrandCache[rootDir_, label_, config_, order_] := Module[
  {boundaryDir, perms, expectedFiles, calcAssoc, matchFound = False,
   matchedLabel = None, matchedFactor = 1, key, ratio, keyEval,
   matchedFileTry, matchedFiles, data, dst, src, jIdx, perm, permStr, baseName},
   
  boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
  perms = $Perms;
  
  calcAssoc = VerifyOrConstructAssociation[rootDir];
  If[!AssociationQ[calcAssoc] || Length[calcAssoc] == 0,
    Return[False]
  ];
  
  Quiet[
    Do[
      keyEval = key /. {
        coeff -> config["Coefficients"],
        integrandlist -> config["Integrands"]
      };
      
      ratio = Simplify[$Integrand / keyEval];
      If[NumberQ[ratio] || NumericQ[ratio],
        matchFound = True;
        matchedLabel = calcAssoc[key];
        matchedFactor = ratio;
        Break[];
      ];
    , {key, Keys[calcAssoc]}]
  ];
  
  If[matchFound,
    expectedFiles = Table[
      FileNameJoin[{boundaryDir, label <> StringJoin[ToString /@ perm] <> "_order" <> ToString[order] <> "_asyexp.m"}],
      {perm, perms}
    ];
    
    matchedFiles = Table[
      permStr = StringJoin[ToString /@ perm];
      baseName = If[StringEndsQ[matchedLabel, "_"], matchedLabel <> permStr, matchedLabel <> "_" <> permStr];
      matchedFileTry = FileNameJoin[{boundaryDir, baseName <> "_order" <> ToString[order] <> "_asyexp.m"}];
      If[!FileExistsQ[matchedFileTry],
        baseName = matchedLabel <> permStr;
        matchedFileTry = FileNameJoin[{boundaryDir, baseName <> "_order" <> ToString[order] <> "_asyexp.m"}];
      ];
      matchedFileTry
    , {perm, perms}];
    
    If[AllTrue[matchedFiles, FileExistsQ],
      Print["[Boundary Cache Hit] Integrand matches '", matchedLabel, "' with factor ", matchedFactor];
      Do[
        Print["  Loading boundary file: ", matchedFiles[[jIdx]]];
        data = Import[matchedFiles[[jIdx]]] // Normal;
        data = Expand[matchedFactor * data];
        Put[data, expectedFiles[[jIdx]]];
        Print["  Saved scaled boundary to: ", expectedFiles[[jIdx]]];
      , {jIdx, 1, Length[perms]}];
      Return[True];
    ,
      Print["[Boundary Cache Hit Warning] Matches pattern '", matchedLabel, "', but some boundary files were missing on disk under ", boundaryDir];
    ];
  ];
  
  False
];

RunBoundaryConditions[rootDir_, label_, config_, order_:3, opts : OptionsPattern[]] := Module[
  {asymDir, tmpDir, boundaryDir, expectedFiles, altDir, altFiles,
   fullIntegrand, results, i, jIdx, perm, permStr, ibpDir, origDir, loopPoints, perms},

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  loopPoints = config["LoopPoints"];
  perms = $Perms;
  
  asymDir  = FileNameJoin[{rootDir, "asym"}];

  (* ---- check if boundary files already exist ---- *)
  boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
  expectedFiles = Table[
    FileNameJoin[{boundaryDir, label <> StringJoin[ToString /@ perm] <> "_order" <> ToString[order] <> "_asyexp.m"}],
    {perm, perms}
  ];
  If[AllTrue[expectedFiles, FileExistsQ],
    Print["Boundary files already exist for '", label, "' in '", boundaryDir, "'. Skipping computation."];
    Return[];
  ];

  (* ---- check cache ---- *)
  If[CheckIntegrandCache[rootDir, label, config, order],
    Print["Boundary files created from cache for '", label, "'. Skipping computation."];
    Return[];
  ];

  (* check alternative InputDir *)
  altDir = OptionValue["InputDir"];
  If[altDir =!= None,
    altFiles = Table[
      FileNameJoin[{altDir, label <> StringJoin[ToString /@ perm] <> "_order" <> ToString[order] <> "_asyexp.m"}],
      {perm, perms}
    ];
    If[AllTrue[altFiles, FileExistsQ],
      Print["Found boundary files for '", label, "' in '", altDir, "'. Copying to boundary_agent/."];
      If[! DirectoryQ[boundaryDir], CreateDirectory[boundaryDir]];
      Do[CopyFile[altFiles[[jIdx]], expectedFiles[[jIdx]], OverwriteTarget -> True], {jIdx, 1, 6}];
      Return[];
    ];
  ];

  (* ensure tmp directory exists for cached results *)
  tmpDir = FileNameJoin[{asymDir, "tmp"}];
  If[! DirectoryQ[tmpDir], CreateDirectory[tmpDir]];

  (* ---- exact syntax from run_I3Lhard_parallel.wl ---- *)

  (* load package LiteRed2 *)
  If[!MemberQ[$Packages, "LiteRed`"], Get["LiteRed2`"]];

  (* kinematic settings *)
  SetDim[d];
  Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
  SetConstraints[{p}, sp[p, p] = u];

  (* load LiteRed2 bases *)
  Do[
    Get[FileNameJoin[{asymDir, "Bases", b, b}]];
    Quiet[ExecuteDefinitions[ToExpression["LiteRed2`" <> b]]];
  , {b, $LiteRedBases}];

  LaunchKernels[6];
  ParallelEvaluate[Quiet[If[NameQ["Global`j"], Remove["Global`j"]]]];

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
  RunAsymExpansionParallel[label, $Integrand, perms, order, loopPoints];

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
    {perm, perms}
  ];

  (* update the dynamic cache association *)
  Module[{assocFile, assoc},
    assoc = VerifyOrConstructAssociation[rootDir];
    If[AssociationQ[assoc],
      AssociateTo[assoc, $Integrand -> label];
      assocFile = FileNameJoin[{rootDir, "asym", "boundary_agent", "calculated_integrands.m"}];
      Quiet[Put[assoc, assocFile]];
      Print["[Boundary Agent] Added new computed integrand to association: '", label, "'"];
    ];
  ];

  Print["Boundary condition files saved."];
  Print["Cached temporary results in ", tmpDir, " can be reused for subsequent bootstrap problems."];
];
