$HistoryLength = 0;
SetDirectory[DirectoryName[$InputFileName]];
oldDir = "/tmp/fb1c12e8fe9261c60ed3c7cc6c5f1891bf832a24/series_agent";
newDir = "runs/fourloopI41/series";

files = FileNames["fourloopI41*.m", oldDir];
Do[
  name = FileNameTake[f];
  oldData = Import[f];
  newData = Import[FileNameJoin[{newDir, name}]];
  If[oldData =!= newData,
    Print[name, " IS DIFFERENT!!!"];
  ,
    Print[name, " is identical."];
  ];
, {f, files}];
