With[{dir = DirectoryName[ExpandFileName[$InputFileName]]},
  Get[FileNameJoin[{Nest[ParentDirectory, dir, 2], "scripts", "period_bootstrap", "run_common.wl"}]];
  periodBasis[dir]
]
