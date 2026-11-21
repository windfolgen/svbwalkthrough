$HistoryLength = 0;
With[{dir = DirectoryName[ExpandFileName[$InputFileName]]},
  Get[FileNameJoin[{Nest[ParentDirectory, dir, 2], "scripts", "period_bootstrap", "run_common.wl"}]];
  Exit[If[TrueQ[runPeriodBootstrap[dir]], 0, 1]]
]
