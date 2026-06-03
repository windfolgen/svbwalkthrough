import glob
import re

for run_wl in glob.glob("runs/*/run.wl"):
    with open(run_wl, "r") as f:
        content = f.read()
    
    idx = content.find("SolveIntegrandSystem")
    if idx != -1:
        # Find the next semicolon after SolveIntegrandSystem
        semi_idx = content.find(";", idx)
        if semi_idx != -1:
            new_content = content[:semi_idx+1] + "\n"
            with open(run_wl, "w") as f:
                f.write(new_content)
print("Properly stripped run.wl scripts.")
