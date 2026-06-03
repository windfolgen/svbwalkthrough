Get["config.wl"];
order = 4; label = "fourloopI41";
targetData = Table[
  permStr = StringJoin[ToString /@ $Perms[[i]]];
  path = FileNameJoin[{Directory[], "asym", "boundary_agent", label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
  Import[path] // Normal,
  {i, 1, 6}
];
Print["Length of Target Data lists: ", Length /@ targetData];
