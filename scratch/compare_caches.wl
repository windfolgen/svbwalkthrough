$HistoryLength = 0;
rootDir = DirectoryName[$InputFileName];
If[rootDir === "", rootDir = Directory[]];
If[StringEndsQ[rootDir, "scratch/"] || StringEndsQ[rootDir, "scratch"], rootDir = ParentDirectory[rootDir]];
SetDirectory[rootDir];

Print["Starting exact substitution vs series substitution cache comparison..."];

limits = {{"e1", "_inuv"}, {"e1", "_inuvp"}, {"e0", "_inuv"}, {"e0", "_inuvp"}, {"einf", "_inuv"}, {"einf", "_inuvp"}};

allMatch = True;

Do[
  oldPath = "data/allsvlistmpl_fourloop_invzz" <> lim[[1]] <> lim[[2]] <> ".txt";
  newPath = "data/test_exact/allsvlistmpl_fourloop_invzz" <> lim[[1]] <> lim[[2]] <> ".txt";
  
  If[FileExistsQ[oldPath] && FileExistsQ[newPath],
    Print["Comparing ", lim[[1]], lim[[2]], "..."];
    oldData = ToExpression[Import[oldPath, "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" &];
    newData = ToExpression[Import[newPath, "String"] // StringTrim // StringTrim[#, "["|"]"] & // "{" <> # <> "}" &];
    
    If[Length[oldData] =!= Length[newData],
      Print["  [FAIL] Length mismatch! Old: ", Length[oldData], " New: ", Length[newData]];
      allMatch = False;
      Continue[];
    ];
    
    repRules = {u -> 0.123, Y -> 0.456, Log[_] -> 1.0, Zeta[_] -> 1.0};
    oldNum = N[Normal[oldData] /. repRules, 20];
    newNum = N[Normal[newData] /. repRules, 20];
    
    diff = Max[Abs[oldNum - newNum]];
    If[diff < 10^-10,
      Print["  [PASS] Elements agree perfectly. (Max diff = ", diff, ")"];
    ,
      Print["  [FAIL] Mathematical mismatch found! Max diff evaluation: ", diff];
      allMatch = False;
    ];
  ,
    Print["  [FAIL] Files missing for ", lim[[1]], lim[[2]]];
    allMatch = False;
  ];
, {lim, limits}];

If[allMatch,
  Print["\n=== SUCCESS: All caches generated precisely match mathematically! ==="];
  Exit[0];
,
  Print["\n=== FAILURE: Some caches disagreed! ==="];
  Exit[1];
];
