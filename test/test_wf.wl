$HistoryLength = 0;
runDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/runs/threeloopI8/";
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
SetDirectory[rootDir];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
RunWorkflowEngine[runDir, "threeloopI8", 3, 4, "Audit" -> True];
