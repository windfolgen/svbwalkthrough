$HistoryLength = 0;
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
asymDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}];
backupDir = FileNameJoin[{asymDir, "backup_fourloopI41"}];

files = {
  "fourloopI411234_order4_asyexp.m",
  "fourloopI411324_order4_asyexp.m",
  "fourloopI412134_order4_asyexp.m",
  "fourloopI412314_order4_asyexp.m",
  "fourloopI413124_order4_asyexp.m",
  "fourloopI413214_order4_asyexp.m"
};

Print["=== Boundary Verification ==="];
Do[
  fRecalc = Import[FileNameJoin[{asymDir, f}]];
  fBackup = Import[FileNameJoin[{backupDir, f}]];
  diff = Simplify[Normal[fRecalc] - Normal[fBackup]];
  Print["File: ", f, " | Diff evaluates to: ", diff];
, {f, files}];

Exit[];
