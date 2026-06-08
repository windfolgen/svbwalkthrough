$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
commonCache = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];

record = If[FileExistsQ[commonCache], Import[commonCache], {}];
Print["Original record length: ", Length[record]];

newRecord = Table[
  Module[{shape, tem, tp, vecProj, tensorBasis, transMat, mat, tpNew},
    shape = record[[i, 1]];
    tem = record[[i, 2]];
    tp = record[[i, 3]];
    If[MatrixQ[tp[[1]]],
      Print["Entry ", i, " is already in matrix format. shape = ", shape];
      tpNew = tp;
    ,
      Print["Converting Entry ", i, " (vector -> matrix). shape = ", shape];
      vecProj = tp[[1]];
      tensorBasis = tp[[2]];
      transMat = Normal[CoefficientArrays[vecProj, tensorBasis]][[2]];
      mat = Transpose[transMat];
      tpNew = {mat, tensorBasis};
    ];
    {shape, tem, tpNew}
  ]
, {i, 1, Length[record]}];

Export[commonCache, newRecord];
Print["Conversion complete! Global cache updated."];
