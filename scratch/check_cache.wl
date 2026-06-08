(* check_cache.wl *)
$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
cachePath = FileNameJoin[{rootDir, "asym", "tmp", "cache_tensor_record_noremove.mx"}];

If[FileExistsQ[cachePath],
  Print["Loading cache..."];
  record = Import[cachePath];
  Print["Record length: ", Length[record]];
  
  Do[
    tp1 = record[[k, 3, 1]];
    If[Depth[tp1] > 0,
      (* Check if tp[[1]] is a matrix or vector *)
      dims = Dimensions[tp1];
      If[Length[dims] > 1,
        Print["Found matrix/nested tp[[1]] at index ", k, " with dimensions: ", dims];
        Print["InputForm: ", Short[InputForm[tp1], 10]];
      ]
    ];
  , {k, 1, Length[record]}];
  Print["Done checking!"];
,
  Print["Cache file not found at: ", cachePath];
];
