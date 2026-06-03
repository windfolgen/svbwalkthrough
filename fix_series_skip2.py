import sys

with open("series_agent/series_agent.wl", "r") as f:
    text = f.read()

text = text.replace("If[Length[existingFiles] == Length[filesToGenerate],", "If[Length[existingFiles] == 12,")

with open("series_agent/series_agent.wl", "w") as f:
    f.write(text)
print("Fixed skip logic in series_agent.wl to explicitly check for 12 existing files.")
