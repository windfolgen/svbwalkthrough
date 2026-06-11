(* scratch/test_mpartition.wl *)
$HistoryLength = 0;

rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/";
asymDir = FileNameJoin[{rootDir, "asym"}];

Get[FileNameJoin[{asymDir, "asym_test.wl"}]];

olist = {{m[3]}, {m[9], m[11]}, {m[1], m[5], m[7]}};
tagp = p;

Print["Running MPartition on olist..."];
t0 = SessionTime[];
tensor = MPartition[olist, tagp];
Print["MPartition finished. Length of tensor: ", Length[tensor]];
Print["Time: ", SessionTime[] - t0, "s"];

