import sys
with open("solve_agent/solve_agent.wl", "r") as f:
    text = f.read()

head_find = """RunCoefficientSolving[rootDir_, label_, config_,
                      ansatzList_List, labelsList_List,
                      basisSVList_List, basisMPLList_List,
                      targetData_, order_:3] := Module[
  {$LEN, $Order, c,
   setup, temp, temp1, sys, solt,
   i, j, k, suffix, filePrefix, ansatzK, svrepK, mplRules, offset, varsList},

  (* ---- global setups ---- *)"""

head_repl = """RunCoefficientSolving[rootDir_, label_, config_,
                      ansatzList_List, labelsList_List,
                      basisSVList_List, basisMPLList_List,
                      targetData_, order_:3] := Module[
  {$LEN, $Order, c,
   setup, temp, temp1, sys, solt,
   i, j, k, suffix, filePrefix, ansatzK, svrepK, mplRules, offset, varsList,
   logStream},

  logStream = OpenWrite[FileNameJoin[{rootDir, "runs", label, "run.log"}]];
  AppendTo[$Output, logStream];

  (* ---- global setups ---- *)"""

tail_find = """  (* save to disk *)
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];
];"""

tail_repl = """  (* save to disk *)
  Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], solt /. c[i_] :> Symbol["c"][i]];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];

  $Output = DeleteCases[$Output, logStream];
  Close[logStream];
];"""

text = text.replace(head_find, head_repl)
text = text.replace(tail_find, tail_repl)

with open("solve_agent/solve_agent.wl", "w") as f:
    f.write(text)
print("Done fixing solve_agent log.")
