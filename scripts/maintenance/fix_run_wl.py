import os
import glob
import re

for run_wl in glob.glob("runs/*/run.wl"):
    with open(run_wl, "r") as f:
        content = f.read()
    
    # We want to replace the finalResult loop with a List construction
    old_loop_pattern = r"finalResult = 0;\noffset = 0;\nDo\[.*?^, \{k, 1, Length\[parsed\[\"LeadingSingularities\"\]\]\}\];\n\nfinalResult = Expand\[finalResult\];"
    
    new_loop = """finalResultList = {};
offset = 0;
Do[
  ansatzK = parsed["LeadingSingularities"][[k, 3]];
  resK = Sum[values[[offset + i]] * ansatzK[[i]], {i, 1, Length[ansatzK]}];
  AppendTo[finalResultList, Expand[resK]];
  offset = offset + Length[ansatzK];
, {k, 1, Length[parsed["LeadingSingularities"]]}];

finalResult = finalResultList;"""

    content = re.sub(old_loop_pattern, new_loop, content, flags=re.MULTILINE | re.DOTALL)
    
    with open(run_wl, "w") as f:
        f.write(content)
        
print("Fixed all run.wl scripts!")
