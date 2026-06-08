$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];

record = If[FileExistsQ[commonCache], Import[commonCache], {}];
Print["Length of record: ", Length[record]];
If[Length[record] > 0,
  Do[
    Print["Entry ", i, ": indexlist shape = ", record[[i, 1]]];
  , {i, 1, Length[record]}]
];
