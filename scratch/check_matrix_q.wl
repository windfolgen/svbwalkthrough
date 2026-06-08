$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];
record = Import[commonCache];
Do[
  Print["Entry ", i, " has matrix? ", MatrixQ[record[[i, 3, 1]]], " shape = ", Dimensions[record[[i, 3, 1]]]];
, {i, 1, Length[record]}];
