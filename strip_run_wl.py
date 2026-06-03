import glob
import re

for run_wl in glob.glob("runs/*/run.wl"):
    with open(run_wl, "r") as f:
        content = f.read()
    
    # We want to remove everything after SolveIntegrandSystem
    new_content = re.sub(
        r"SolveIntegrandSystem\[rootDir, runDir, parsed, \$Order, yOrder\];.*",
        "SolveIntegrandSystem[rootDir, runDir, parsed, $Order, yOrder];",
        content,
        flags=re.DOTALL
    )
    
    with open(run_wl, "w") as f:
        f.write(new_content)
print("Stripped old result loops from all run.wl scripts.")
