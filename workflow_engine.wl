(* workflow_engine.wl *)
(* =================================================================== *)
(*  Unified Workflow Engine                                            *)
(*  Replaces master_agent.wl and individual run.wl scripts.            *)
(*                                                                     *)
(*  Exports:                                                           *)
(*    SolveIntegrandSystem[rootDir, label, config, order, yOrder]      *)
(* =================================================================== *)

ClearAll[SolveIntegrandSystem, EvaluateCoeff];

(* Helper: Apply S4 permutation to x[i,j] and substitute kinematics *)
EvaluateCoeff[c_, perm_] := Module[{transformedC},
  (* Apply permutation to external indices 1, 2, 3 (4 is fixed at infinity) *)
  transformedC = c /. x[i_Integer, j_Integer] :> 
    x[If[i <= 3, perm[[i]], i], If[j <= 3, perm[[j]], j]];
  
  transformedC /. {
    x[i_, j_] /; MemberQ[{i, j}, 4] :> 1,
    x[1, 2] -> u,
    x[2, 3] -> 1 - Y,
    x[1, 3] -> 1,
    x[2, 1] -> u,
    x[3, 2] -> 1 - Y,
    x[3, 1] -> 1
  }
];

(* Unified Mode: Config driven *)
SolveIntegrandSystem[rootDir_, label_String, config_Association, order_:3, yOrder_:4] := Module[
  {integrandList, coeffList, lsConfigList, weightN, loopPoints,
   fullBasisSV, fullBasisMPL, boundaryDir,
   targetData, subTargetData, perm, permStr, path, subPath,
   i, p, k, coeffVal, poleOrder,
   ansatzList, labelsList, basisSVList, basisMPLList,
   cType, cPrefactor, cAnsatz, basisElements,
   svIndices, basisSVReduced, mplFiles, bestCount, bestFile, mplTry, idx, mplIndices, basisMPLReduced
  },

  Print["=== Starting Unified Workflow Engine for: ", label, " ==="];

  Get[FileNameJoin[{rootDir, "config.wl"}]];
  Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
  Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];
  Get[FileNameJoin[{rootDir, "solve_agent", "solve_agent.wl"}]];
  Get[FileNameJoin[{rootDir, "review_agent.wl"}]];
  LoadReviewAgent[rootDir];
  
  integrandList = config["Integrands"];
  coeffList = config["Coefficients"];
  lsConfigList = config["LeadingSingularities"];
  weightN = config["WeightN"];
  loopPoints = config["LoopPoints"];
  
  ReviewGate[rootDir, label, "preflight", config];

  Print["  Conformal weight n = ", weightN];

  (* 1. Boundary Target Data Orchestration (Integral dependent only) *)
  boundaryDir = FileNameJoin[{rootDir, "runs", label, "boundaries"}];
  If[!DirectoryQ[boundaryDir], boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}]];
  
  Print["  Checking for boundary target data..."];
  ReviewGate[rootDir, label, "preboundary", config];
  
  targetData = Table[
    subTargetData = 0;
    Do[
      perm = $Perms[[i]];
      permStr = StringJoin[ToString /@ perm];
      
      If[Length[integrandList] == 1,
        subPath = FileNameJoin[{boundaryDir, label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
      ,
        subPath = FileNameJoin[{boundaryDir, label <> "_comp" <> ToString[p] <> "_" <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
      ];
      
      If[!FileExistsQ[subPath],
        Block[{$Integrand = integrandList[[p]]},
          If[Length[integrandList] == 1,
            RunBoundaryConditions[rootDir, label, config, order, "InputDir" -> boundaryDir]
          ,
            RunBoundaryConditions[rootDir, label <> "_comp" <> ToString[p] <> "_", config, order, "InputDir" -> boundaryDir]
          ]
        ];
        If[!FileExistsQ[subPath], Print["  FATAL ERROR: boundary generation failed for ", subPath]; Exit[1]];
      ];
      
      data = Import[subPath] // Normal;
      coeffVal = EvaluateCoeff[coeffList[[p]], perm];
      subTargetData = subTargetData + Expand[coeffVal * data];
    , {p, 1, Length[integrandList]}];
    subTargetData
  , {i, 1, 6}];
  ReviewGate[rootDir, label, "boundary", config];

  (* 2. Process each Leading Singularity Configuration *)
  Print["  Loading full SV basis..."];
  fullBasisSV = Import[$SVBasisFile];
  
  mplFiles = FileNames[FileNameJoin[{$DataDir, $MPLTextPrefix <> "*.m"}]];
  mplFiles = Select[mplFiles, !StringMatchQ[#, ___ ~~ ("e0.m" | "e1.m" | "einf.m")] &];

  ansatzList = {};
  labelsList = {};
  basisSVList = {};
  basisMPLList = {};

  Do[
    cType = lsConfigList[[k, 1]];
    cPrefactor = lsConfigList[[k, 2]];
    cAnsatz = lsConfigList[[k, 3]];
    
    AppendTo[ansatzList, cAnsatz];
    If[Length[lsConfigList] == 1,
      AppendTo[labelsList, label];
    ,
      AppendTo[labelsList, label <> "_ls" <> ToString[k]];
    ];
    
    Print["  [Leading Singularity ", k, "/", Length[lsConfigList], " (", cType, ")]"];
    
    basisElements = DeleteDuplicates @ Cases[cAnsatz, _I | _f, {1, Infinity}];
    svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
    svIndices = DeleteDuplicates[Select[svIndices, Positive]];
    
    basisSVReduced = fullBasisSV[[svIndices]];
    AppendTo[basisSVList, basisSVReduced];
    
    bestCount = 0;
    bestFile = None;
    If[mplFiles =!= {},
      Do[
        mplTry = Import[f];
        idx = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[mplTry, e, {1}]] /@ basisElements;
        idx = Select[idx, Positive];
        If[Length[idx] > bestCount, bestCount = Length[idx]; bestFile = f],
        {f, mplFiles}
      ];
    ];
    If[bestCount > 0,
      fullBasisMPL = Import[bestFile];
      mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisMPL, e, {1}]] /@ basisElements;
      mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
      basisMPLReduced = fullBasisMPL[[mplIndices]];
      AppendTo[basisMPLList, basisMPLReduced];
      Print["  [MPL auto-detect] Found ", bestCount, " MPL elements in basis: ", FileBaseName[bestFile]];
    ,
      mplIndices = {};
      AppendTo[basisMPLList, {}];
      Print["  [MPL auto-detect] Found 0 MPL elements."];
    ];

    Print["  Executing RunSeriesExpansion for ", label, "..."];
    
    poleOrder = If[cType == "double", 2, 1];
    
    (* New Pre-Series Cache Check *)
    config["BestFile"] = bestFile;
    Module[{preseriesReport},
      preseriesReport = ReviewGate[rootDir, label, "preseries", config];
      If[preseriesReport["Status"] === "FAIL",
        Print["[Workflow Engine] FATAL ERROR: Missing required MPL caches. Aborting series expansion."];
        Print["Please generate the required _inuv.txt and _inuvp.txt files using transform/fourloop_generate_all_zrep.wl"];
        Exit[1];
      ];
    ];
    
    If[Length[lsConfigList] > 1,
      RunSeriesExpansion[rootDir, label <> "_ls" <> ToString[k], config, cPrefactor, cType, yOrder, svIndices, mplIndices, poleOrder, bestFile];
    ,
      RunSeriesExpansion[rootDir, label, config, cPrefactor, cType, yOrder, svIndices, mplIndices, poleOrder, bestFile];
    ];
    ReviewGate[rootDir, label, "series", config];
    
  , {k, 1, Length[lsConfigList]}];

  (* 3. Coefficient Solving *)
  ReviewGate[rootDir, label, "presolve", config];
  Print["  Executing RunCoefficientSolving..."];
  RunCoefficientSolving[rootDir, label, config, ansatzList, labelsList, basisSVList, basisMPLList, targetData, order];
  ReviewGate[rootDir, label, "solve", config];
  
  Print["=== Workflow Engine Complete for: ", label, " ==="];
];
