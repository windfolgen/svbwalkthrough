(* Native arguments of the single-valued GPLs, in physical graph coordinates. *)
ClearAll[periodWord, periodAtom, periodBasis, writePeriodExpression, runPeriodBootstrap];
periodWord[{}] = 1;
periodWord[{3}] = -3 f[3]/4;
periodWord[{5}] = -15 f[5]/16;
periodWord[{7}] = -63 f[7]/64;
periodWord[{3, 3}] = 9 f[3]^2/32;
periodWord[indices_List] := Apply[f2, indices];

periodAtom[{sector_, digits_, power_, indices_}, label_] := Module[{arg, bar, kernels, word},
  {arg, bar} = Switch[label,
    "fourloopI144", If[StringEndsQ[sector, "@inv"], {1/z, 1/zz}, {z, zz}],
    "fourloopI233", If[sector === "C3", {1-z, 1-zz}, {1/(1-z), 1/(1-zz)}]
  ];
  kernels = {0, 1, bar, 1/bar, 1-bar};
  word = If[digits === {}, 1, Apply[I, Join[{arg}, kernels[[digits + 1]], {0}]]];
  Pi^power periodWord[indices] word
];

periodBasis[dir_] := Module[{keys, groups, label = FileNameTake[dir]},
  keys = Import[FileNameJoin[{dir, "fit", "words.json"}], "RawJSON"];
  groups = SplitBy[keys, First[StringSplit[First[#], "@"]] &];
  Map[periodAtom[#, label] &, groups, {2}]
];

writePeriodExpression[expr_, path_] := Module[{rendered},
  rendered = ToString[expr, InputForm, PageWidth -> 100];
  Export[path, StringReplace[rendered, RegularExpression["(?m)[ \\t]+$"] -> ""] <> "\n", "Text"]
];

runPeriodBootstrap[dir_] := Module[
  {label = FileNameTake[dir], root, python, tmp, process, recovered, parameters,
   lengths, coefficients, numerators, full},
  root = Nest[ParentDirectory, dir, 2];
  python = Environment["PERIOD_BOOTSTRAP_PYTHON"];
  If[!StringQ[python] || python === "", python = "python3"];
  tmp = CreateTemporary[];
  process = RunProcess[{python, FileNameJoin[{root, "scripts", "period_bootstrap", "replay.py"}], dir, tmp}];
  If[process["ExitCode"] =!= 0, Print[process["StandardError"]]; DeleteFile[tmp]; Return[False]];
  recovered = Import[tmp, "RawJSON"]; DeleteFile[tmp];
  Get[FileNameJoin[{dir, "input.wl"}]];
  parameters = Apply[Rational, recovered["coefficients"], {1}];
  lengths = Length /@ ansatzlist;
  If[Total[lengths] =!= Length[parameters] || Length[lengths] =!= Length[leadingsingularitylist], Return[False]];
  coefficients = TakeList[parameters, lengths];
  numerators = MapThread[Dot, {coefficients, ansatzlist}];
  full = numerators . (leadingsingularitylist /. {u -> z zz, v -> (1-z) (1-zz)});
  writePeriodExpression[coefficients, FileNameJoin[{dir, "coeff_sol.m"}]];
  writePeriodExpression[numerators, FileNameJoin[{dir, "result.m"}]];
  writePeriodExpression[full, FileNameJoin[{dir, label <> ".txt"}]];
  Export[FileNameJoin[{dir, "workflow_validation.json"}], recovered["validation"], "RawJSON"];
  Print[StringTrim[process["StandardOutput"]]];
  True
];
