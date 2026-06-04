(* compare_fourloopI41_symmetry_terms.wl *)
$HistoryLength = 0;
testDir = DirectoryName[$InputFileName];
rootDir = ParentDirectory[testDir];
asymDir = FileNameJoin[{rootDir, "asym"}];

Get[FileNameJoin[{rootDir, "config.wl"}]];
Get["LiteRed2`"];
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

Do[
  Get[FileNameJoin[{asymDir, "Bases", b, b}]];
  Quiet[ExecuteDefinitions[ToExpression[b]]];
, {b, {"asym", "asym3L", "asym2L", "asym1L"}}];

Get[FileNameJoin[{asymDir, "asym_new.wl"}]];

inputPath = FileNameJoin[{rootDir, "runs", "fourloopI41", "input.wl"}];
Block[{integrand, leadingsingularity, ansatz, OrderY},
  Get[inputPath];
  testIntegrand = integrand;
];

Print["\n=== Analyzing RegionExpand Term Counts for all 4 Exchange Symmetry Cases of fourloopI41 ==="];

perms = $Perms;
Do[
  Print["\nPermutation: ", perm];
  
  case1 = perm;
  case2 = perm /. {1 -> 3, 3 -> 1, 2 -> 4, 4 -> 2};
  case3 = perm /. {1 -> 2, 2 -> 1, 3 -> 4, 4 -> 3};
  case4 = perm /. {1 -> 4, 4 -> 1, 2 -> 3, 3 -> 2};
  cases = {case1, case2, case3, case4};
  
  Do[
    intCase = testIntegrand /. {x[a__] :> (x[a] /. Thread@Rule[{1, 2, 3, 4}, c])};
    Quiet[
      terms = Length[RegionExpand[intCase, {5, 6, 7, 8}, "order" -> 4, "check" -> False][[2]]];
    ];
    Print["  Case ", idx, " (", c, ") -> ", terms, " terms"];
  , {idx, 1, Length[cases]}, {c, {cases[[idx]]}}];
, {perm, perms}];
