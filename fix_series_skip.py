import sys

with open("series_agent/series_agent.wl", "r") as f:
    text = f.read()

target = """  If[existingFiles =!= {},
    Print["[Skill 1] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
    Print["[Skill 1] Overwriting " , Length[existingFiles], " existing files."];
  ];"""

replacement = """  If[Length[existingFiles] == Length[filesToGenerate],
    Print["[Skill 1] All ", Length[existingFiles], " series expansion files already exist. Skipping expansion!"];
    Return[];
  ];
  If[existingFiles =!= {},
    Print["[Skill 1] WARNING: ", Length[existingFiles], " existing series expansion files will be overwritten:"];
    Do[Print["  - ", f], {f, existingFiles}];
    Print["[Skill 1] Overwriting " , Length[existingFiles], " existing files."];
  ];"""

text = text.replace(target, replacement)

with open("series_agent/series_agent.wl", "w") as f:
    f.write(text)
print("Updated series_agent.wl to properly skip if files exist.")
