(* =================================================================== *)
(*  Skill 0: Input Parser                                              *)
(*                                                                     *)
(*  Standardizes user input from global variables (or input.wl) into    *)
(*  the unified WorkflowConfig Association.                            *)
(* =================================================================== *)

ClearAll[ParseInput];

ParseInput[runDir_String] := Module[
  {inputFile, outIntegrandList, outCoeffList, outLsConfigList, outWeightN, loopPoints, maxIndex, config},
  
  (* Load input.wl if it exists in the run directory *)
  inputFile = FileNameJoin[{runDir, "input.wl"}];
  If[FileExistsQ[inputFile],
    Get[inputFile];
  ];
  
  (* Use Directory[] as fallback if runDir is relative, or derive from runDir *)
  rootDir = If[AbsoluteFileName[runDir] =!= $Failed,
               ParentDirectory[ParentDirectory[AbsoluteFileName[runDir]]],
               Directory[]];

  (* Audit the input file format if ReviewGate is loaded *)
  LoadReviewAgent[rootDir]; If[ValueQ[ReviewGate] || Length[DownValues[ReviewGate]] > 0,
    report = ReviewGate[rootDir, FileNameTake[runDir, -1], "input", <||>];
    If[report["Status"] === "FAIL",
      Print["[ABORT] Input audit FAIL."];
      Return[$Failed]
    ];
  ];
  
  Get[FileNameJoin[{rootDir, "ConformalWeight.m"}]];
  Get[FileNameJoin[{rootDir, "config.wl"}]];

  (* 1. Parse Integrand & Coefficients *)
  If[ValueQ[integrandlist],
    outIntegrandList = integrandlist;
    outCoeffList = If[ValueQ[coeff], coeff, Table[1, {Length[integrandlist]}]];
  ,
    If[ValueQ[integrand],
      outIntegrandList = {integrand};
      outCoeffList = {1};
    ,
      Print["Error: Neither `integrandlist` nor `integrand` found."];
      Return[$Failed];
    ]
  ];

  (* 2. Derive LoopPoints *)
  maxIndex = Max[Cases[Variables[outIntegrandList[[1]]], x[i_, j_] :> {i, j}, Infinity]];
  If[maxIndex < 5, maxIndex = 5]; (* Fallback *)
  loopPoints = Range[5, maxIndex];

  (* 3. Compute Conformal Weight from External Vertex 1 *)
  outWeightN = -ConformalWeight[outIntegrandList[[1]], 1];

  (* 4. Parse Leading Singularities & Ansatz *)
  If[ValueQ[lsConfigList],
    outLsConfigList = Table[
      {lsConfigList[[k, 1]], lsConfigList[[k, 2]], Flatten[lsConfigList[[k, 3]]]},
      {k, 1, Length[lsConfigList]}
    ];
  ,
    (* Helper to extract cType and cPrefactor from a single LS expression *)
    ExtractPole[expr_, integr_] := Module[{den, pOrder, primaryPoleOrder, pref, cType, zRoot0, zzRoot0},
      den = Denominator[Cancel[expr]];
      pOrder = Exponent[den, z-zz];
      
      (* For pOrder > 2 (e.g., triple pole), use primary pole order 1 per summarize.md *)
      primaryPoleOrder = If[pOrder >= 2 && EvenQ[pOrder], 2, If[pOrder >= 2 && OddQ[pOrder], 1, pOrder]];
      
      cType = If[primaryPoleOrder == 2, "double", "simple"];
      pref = Simplify[expr * (z-zz)^primaryPoleOrder];
      
      (* Transform parity-even prefactor to pure u, v expressions *)
      zRoot0 = 1/2 * (1 + u - v - Sqrt[-4u + (1+u-v)^2]);
      zzRoot0 = 1/2 * (1 + u - v + Sqrt[-4u + (1+u-v)^2]);
      pref = Simplify[pref /. {z -> zRoot0, zz -> zzRoot0}];
      
      (* Critical: apply additional normalization prefactor v if not normalized *)
      pref = GetAdditionalPrefactor[integr, pref];
      
      {cType, pref}
    ];

    (* Handle Multi-LS mode from lists *)
    If[ValueQ[leadingsingularitylist] && ValueQ[ansatzlist],
      If[Length[leadingsingularitylist] =!= Length[ansatzlist],
        Print["Error: Length of `leadingsingularitylist` and `ansatzlist` must match."];
        Return[$Failed];
      ];
      outLsConfigList = Table[
        Module[{extracted},
          extracted = ExtractPole[leadingsingularitylist[[k]], outIntegrandList[[k]]];
          {extracted[[1]], extracted[[2]], Flatten[ansatzlist[[k]]]}
        ],
        {k, 1, Length[leadingsingularitylist]}
      ];
    ,
      (* Handle Single-LS mode from scalar variables *)
      If[!ValueQ[ansatz], 
        Print["Error: No `ansatz`, `ansatzlist`, or `lsConfigList` provided."];
        Return[$Failed];
      ];
      If[!ValueQ[leadingsingularity], 
        leadingsingularity = 1/(z-zz);
      ];
      
      Module[{extracted},
        extracted = ExtractPole[leadingsingularity, outIntegrandList[[1]]];
        outLsConfigList = {{extracted[[1]], extracted[[2]], Flatten[ansatz]}};
      ];
    ];
  ];

  config = <|
    "Integrands" -> outIntegrandList,
    "Coefficients" -> outCoeffList,
    "LeadingSingularities" -> outLsConfigList,
    "WeightN" -> outWeightN,
    "LoopPoints" -> loopPoints
  |>;

  Return[config];
];
