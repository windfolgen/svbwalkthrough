content = Import["series_agent/series_agent.wl", "String"];
newContent = StringReplace[content, 
  "mplList = Import[FileNameJoin[{rootDir, mplFile}], \"String\"] // StringTrim[#, \"[\"|\"]\"] & // \"{\" <> # <> \"}\" & // ToExpression;" ->
  "mplListStr = Import[FileNameJoin[{rootDir, mplFile}], \"String\"];\n        If[StringStartsQ[StringTrim[mplListStr], \"{\"],\n          mplList = ToExpression[mplListStr];\n        ,\n          mplList = ToExpression[\"{\" <> StringTrim[mplListStr, \"[\"|\"]\"] <> \"}\"];\n        ];"
];
Export["series_agent/series_agent.wl", newContent, "String"];
