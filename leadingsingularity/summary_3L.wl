results = Get["ls_results_3.m"];

normalize[res_] := Module[{normList},
  (* Check for failure conditions *)
  If[!ListQ[res] || res === {} || !FreeQ[res, $Failed] || !FreeQ[res, "Failed"] || !FreeQ[res, TimeConstraint] || !FreeQ[res, MemoryLimit],
    Return["Failed"]
  ];
  
  (* Process each singularity in the list *)
  normList = Table[
    Module[{norm},
      norm = Factor[val * V2[x[1, 3]] * V2[x[2, 4]]];
      (* Heuristic to fix sign *)
      If[MatchQ[norm, Times[-1, ___]], norm = -norm];
      If[Head[norm] === Times && Head[norm[[1]]] === Integer && norm[[1]] < 0, norm = -norm];
      norm
    ],
    {val, res}
  ];
  
  (* Remove duplicates within the list for a single integral and sort *)
  Return[Sort[DeleteDuplicates[normList]]]
];

normalizedResults = Table[{r[[1]], normalize[r[[2]]]}, {r, results}];

groups = GatherBy[normalizedResults, #[[2]]&];

(* Sort groups by descending number of integrands, but keep "Failed" at the end if possible *)
groups = SortBy[groups, {If[#[[1, 2]] === "Failed", 1, 0], -Length[#]}&];

Print["Total distinct results after normalization: ", Length[groups]];

(* Generate LaTeX *)
tex = "\\documentclass[11pt,a4paper]{article}\n\\usepackage{jheppub}\n\\title{Three-Loop Leading Singularities Summary}\n\\author{AntiGravity}\n\\abstract{This document summarizes the leading singularities of the 15 three-loop integrands. Integrands are classified by their set of leading singularities (and the number of such singularities). All failed or empty results are grouped into a single class.}\n\\begin{document}\n\\maketitle\n\n";

tex = tex <> "\\section{Summary of Results}\nTotal integrands: 15. Total distinct classes: " <> ToString[Length[groups]] <> ".\n\n";

Do[
  grp = groups[[i]];
  val = grp[[1, 2]];
  inds = grp[[All, 1]];
  tex = tex <> "\\subsection*{Class " <> ToString[i] <> " (" <> ToString[Length[inds]] <> " integrands)}\n";
  tex = tex <> "Integrand Indices: " <> StringRiffle[ToString /@ inds, ", "] <> "\n\n";
  
  If[val === "Failed",
    tex = tex <> "Result: Failed to evaluate / Timeout / Empty set.\\\\[1em]\n\n",
    
    tex = tex <> "Number of Leading Singularities: " <> ToString[Length[val]] <> "\n\n";
    Do[
       tex = tex <> "\\begin{equation}\n" <> ToString[TeXForm[val[[j]]]] <> "\n\\end{equation}\n";
    , {j, 1, Length[val]}];
    tex = tex <> "\n\n";
  ];
, {i, 1, Length[groups]}];

tex = tex <> "\\end{document}\n";
Export["summary_3L.tex", tex, "Text"];
Print["Exported to summary_3L.tex"];
