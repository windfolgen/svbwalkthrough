$HistoryLength = 0;
runDir   = DirectoryName[$InputFileName] <> "runs/fourloopI41/";
rootDir  = DirectoryName[$InputFileName];
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

parsed = ParseInput[runDir];
Print["Length of outBasisSVList: ", Length[parsed["BasisSV"]]];
If[Length[parsed["BasisSV"]] > 0,
  Print["Type of element 1: ", Head[parsed["BasisSV"][[1]]]];
  If[Head[parsed["BasisSV"][[1]]] === List,
    Print["Length of element 1: ", Length[parsed["BasisSV"][[1]]]]
  ]
]
