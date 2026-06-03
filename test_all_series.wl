$HistoryLength = 0;
SetDirectory[DirectoryName[$InputFileName]];
oldDir = "/tmp/fb1c12e8fe9261c60ed3c7cc6c5f1891bf832a24/series_agent";
newDir = "series_agent";

files = FileNames["fourloopI41*.m", oldDir];
Do[
  name = FileNameTake[f];
  oldData = Import[f];
  newData = Import[FileNameJoin[{newDir, name}]];
  Print[name, " identical? ", oldData === newData];
  If[oldData =!= newData,
    Print["  Length old: ", Length[oldData], ", new: ", Length[newData]];
    repRules = {u -> 0.123, Y -> 0.456, Log[_] -> 1.0, Zeta[_] -> 1.0};
    oldNum = N[Normal[oldData] /. repRules, 20];
    newNum = N[Normal[newData] /. repRules, 20];
    diff = Max[Abs[oldNum - newNum]];
    Print["  Max numerical diff: ", diff];
  ];
, {f, files}];
