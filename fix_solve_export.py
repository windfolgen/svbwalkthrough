import sys

with open("solve_agent/solve_agent.wl", "r") as f:
    text = f.read()

target = """  (* save to disk *)
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];"""

replacement = """  (* save to disk *)
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];

  Module[{values, offset, finalResultList, coeffListAll, ansatzK, resK, coeffK},
    values = varsList /. solt;
    finalResultList = {};
    coeffListAll = {};
    offset = 0;
    Do[
      ansatzK = ansatzList[[k]];
      coeffK = Table[values[[offset + i]], {i, 1, Length[ansatzK]}];
      resK = Sum[coeffK[[i]] * ansatzK[[i]], {i, 1, Length[ansatzK]}];
      
      AppendTo[finalResultList, Expand[resK]];
      AppendTo[coeffListAll, coeffK];
      
      offset = offset + Length[ansatzK];
    , {k, 1, Length[ansatzList]}];
    
    Export[FileNameJoin[{rootDir, "runs", label, "result.m"}], finalResultList];
    Export[FileNameJoin[{rootDir, "runs", label, "coeff_sol.m"}], coeffListAll];
    Print["Final result.m and coeff_sol.m saved to runs/", label, "/"];
  ];"""

text = text.replace(target, replacement)

with open("solve_agent/solve_agent.wl", "w") as f:
    f.write(text)
print("Updated solve_agent.wl successfully.")
