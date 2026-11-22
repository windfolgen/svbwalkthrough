$HistoryLength = 0;
Module[{dir = DirectoryName[ExpandFileName[$InputFileName]], python, tmp, process, fit,
        symbol, periods, parts, terms, primitive, numerators, full, ray, disc,
        rational, a, m, az, ab, mz, mb, write},
  python = Environment["PERIOD_BOOTSTRAP_PYTHON"];
  If[!StringQ[python] || python === "", python = "python3"];
  tmp = CreateTemporary[];
  process = RunProcess[{python, FileNameJoin[{dir, "replay.py"}], tmp}];
  If[process["ExitCode"] =!= 0, Print[process["StandardError"]]; DeleteFile[tmp]; Exit[1]];
  fit = Import[tmp, "RawJSON"]; DeleteFile[tmp];
  Get[FileNameJoin[{dir, "input.wl"}]];
  symbol = ToExpression /@ fit["symbol"]; periods = ToExpression /@ fit["periods"];
  parts = ansatzlist["particular"]; terms = ansatzlist["columns"];
  If[Length[periods] =!= Length[terms] || Length[parts] =!= 5, Exit[1]];
  Do[If[periods[[j]] =!= 0,
    Do[parts[[term[[1]]]] += periods[[j]] term[[2]], {term, terms[[j]]}]], {j, Length[terms]}];
  rational = Take[parts, 3]; {a, m} = Take[parts, -2];
  disc = (1-z zz)^2 - 4 (1-z) (1-zz);
  az = -(z zz-2 zz+1)/(z-1); ab = -(z zz-2 z+1)/(zz-1);
  mz = (z zz+2 zz-3)/(z-1); mb = -(z zz+2 z-3)/(zz-1);
  ray[expr_] := expr /. {z -> i214Ray z, zz -> i214Ray zz};
  primitive = With[{integrandOnRay = (z ray[a az + m mz] + zz ray[a ab + m mb])/Sqrt[ray[disc]]},
    Inactive[Integrate][integrandOnRay, {i214Ray, 0, 1}]];
  numerators = Append[rational, primitive];
  full = numerators . (leadingsingularitylist /. {u -> z zz, v -> (1-z) (1-zz), y -> Sqrt[disc]});
  write[file_, expr_] := Export[FileNameJoin[{dir, file}],
    StringReplace[ToString[expr, InputForm, PageWidth -> 110], RegularExpression["(?m)[ \\t]+$"] -> ""] <> "\n", "Text"];
  write["coeff_sol.m", {symbol, periods}];
  write["result.m", numerators]; write["fourloopI214.txt", full];
  Export[FileNameJoin[{dir, "workflow_validation.json"}], fit["validation"], "RawJSON"];
  Print[StringTrim[process["StandardOutput"]]];
]
