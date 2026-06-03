$HistoryLength = 0;
runDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/threeloopI8/";
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];
res = ParseInput[runDir];
Print[res];
