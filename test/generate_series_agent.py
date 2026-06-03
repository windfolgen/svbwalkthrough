import re

def gen_function(name, is_double, type_str):
    if type_str == "Inf":
        z_val = "1/2 * (1 - u + v - Sqrt[-4 u + (1 - u + v)^2]) /. {v -> 1 - Y}"
        zz_val = "1/2 * (1 - u + v + Sqrt[-4 u + (1 - u + v)^2]) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("(-4 u + (1 - u + v)^2)" if is_double else "-Sqrt[-4 u + (1 - u + v)^2]") + " /. {v -> 1 - Y}"
        var1, var2 = "z", "zz"
        zz_sub = "{zz -> 1/u/z}"
        neg_sub = "{Power[z, a_ /; (a < 0)] :> Power[zz * u, -a]}"
        pre_sub = "{f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]}"
    elif type_str == "InfP":
        z_val = "(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]) / (2 u) /. {v -> 1 - Y}"
        zz_val = "(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]) / (2 u) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("(-4 u v + (-1 + u + v)^2)" if is_double else "-Sqrt[-4 u v + (-1 + u + v)^2]") + " /. {v -> 1 - Y}"
        var1, var2 = "z", "zz"
        zz_sub = "{zz -> v/u/z}"
        neg_sub = "{Power[z, a_ /; (a < 0)] :> Power[zz * u / v, -a]}"
        pre_sub = "{f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u/v]}"
    elif type_str == "0":
        z_val = "1/2 * (1 + u - Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y}"
        zz_val = "1/2 * (1 + u + Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("(-4 u + (1 + u - v)^2)" if is_double else "-Sqrt[-4 u + (1 + u - v)^2]") + " /. {v -> 1 - Y}"
        var1, var2 = "z", "zz"
        zz_sub = "{zz -> u/z}"
        neg_sub = "{Power[z, a_ /; (a < 0)] :> Power[zz / u, -a]}"
        pre_sub = "{f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]}"
    elif type_str == "0P":
        z_val = "(-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y}"
        zz_val = "(-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("(-4 u v + (-1 + u + v)^2)" if is_double else "-Sqrt[-4 u v + (-1 + u + v)^2]") + " /. {v -> 1 - Y}"
        var1, var2 = "z", "zz"
        zz_sub = "{zz -> u/z/v}"
        neg_sub = "{Power[z, a_ /; (a < 0)] :> Power[zz * v / u, -a]}"
        pre_sub = "{f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]}"
    elif type_str == "1":
        z_val = "(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v) / (2 v) /. {v -> 1 - Y}"
        zz_val = "(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v) / (2 v) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("((-1 + u - v)^2 - 4 v)" if is_double else "-Sqrt[(-1 + u - v)^2 - 4 v]") + " /. {v -> 1 - Y}"
        var1, var2 = "z1", "zz1"
        zz_sub = "{zz1 -> 1/z1}"
        neg_sub = "{Power[z1, a_ /; (a < 0)] :> Power[zz1, -a]}"
        pre_sub = "{-1+z->z1, -1+zz->zz1} /. {I[z,1,0]->Log[v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}"
    elif type_str == "1P":
        z_val = "1/2 * (-1 - u + v - Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}"
        zz_val = "1/2 * (-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]) /. {v -> 1 - Y}"
        pref_val = "1 / " + ("(-4 v + (1 - u + v)^2)" if is_double else "-Sqrt[-4 v + (1 - u + v)^2]") + " /. {v -> 1 - Y}"
        var1, var2 = "z1", "zz1"
        zz_sub = "{zz1 -> u/z1}"
        neg_sub = "{Power[z1, a_ /; (a < 0)] :> Power[zz1 / u, -a]}"
        pre_sub = "{-1+z->z1, -1+zz->zz1} /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]}"

    code = f"""ClearAll[{name}];
Options[{name}] = {{"additional" -> 1, "Yorder" -> 5, "uorder" -> 0}};
{name}[temp_, zrepUnused_, OptionsPattern[]] := Module[
  {{result, prefVal, addVal, uOrder = OptionValue["uorder"], yOrder = OptionValue["Yorder"]}},
  
  prefVal = Normal[Series[{pref_val} /. {{v -> 1 - Y}}, {{u, 0, uOrder}}, {{Y, 0, yOrder}}, Assumptions -> Y > 0]];
  addVal = OptionValue["additional"] /. {{v -> 1 - Y}};
  
  result = Table[
    Module[{{el}},
      el = temp[[i]] * addVal /. {zz_sub} // Expand;
      el = el /. {neg_sub};
      el = el * prefVal;
      el = el /. {pre_sub};
      el = el /. {{z -> Series[{z_val}, {{u, 0, uOrder + 6}}, {{Y, 0, yOrder + 6}}, Assumptions -> Y > 0], zz -> Series[{zz_val}, {{u, 0, uOrder + 6}}, {{Y, 0, yOrder + 6}}, Assumptions -> Y > 0]}};
"""
    if type_str in ["1", "1P"]:
        code += f"""      el = el /. {{z1 -> Series[{z_val}, {{u, 0, uOrder + 6}}, {{Y, 0, yOrder + 6}}, Assumptions -> Y > 0], zz1 -> Series[{zz_val}, {{u, 0, uOrder + 6}}, {{Y, 0, yOrder + 6}}, Assumptions -> Y > 0]}};\n"""
    
    code += f"""      el = el /. {{v -> 1 - Y}};
      Series[el, {{u, 0, uOrder}}, {{Y, 0, yOrder}}, Assumptions -> Y > 0] // Normal // Expand
    ],
    {{i, 1, Length[temp]}}
  ];
  Return[result];
];
"""
    return code

with open("/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/series_agent/series_agent.wl", "w") as f:
    f.write("(* =================================================================== *)\n")
    f.write("(*  Skill 1: Ansatz Series Expansion Agent                            *)\n")
    f.write("(*  Location: ./series_agent/                                          *)\n")
    f.write("(* =================================================================== *)\n\n")
    
    # We write 6 zrep definitions just to keep compatibility if run.wl passes them
    zreps = """zrepInf = {};
zrepInfP = {};
zrep0 = {};
zrep0P = {};
zrep1 = {};
zrep1P = {};\n\n"""
    f.write(zreps)

    f.write(gen_function("SeriesExpansionInf", False, "Inf"))
    f.write(gen_function("SeriesExpansionInfP", False, "InfP"))
    f.write(gen_function("SeriesExpansion0", False, "0"))
    f.write(gen_function("SeriesExpansion0P", False, "0P"))
    f.write(gen_function("SeriesExpansion1", False, "1"))
    f.write(gen_function("SeriesExpansion1P", False, "1P"))

    f.write(gen_function("SeriesExpansion2Inf", True, "Inf"))
    f.write(gen_function("SeriesExpansion2InfP", True, "InfP"))
    f.write(gen_function("SeriesExpansion20", True, "0"))
    f.write(gen_function("SeriesExpansion20P", True, "0P"))
    f.write(gen_function("SeriesExpansion21", True, "1"))
    f.write(gen_function("SeriesExpansion21P", True, "1P"))

    # Now the main pipeline
    main_pipeline = """
(* =================================================================== *)
(*  MAIN PIPELINE                                                     *)
(* =================================================================== *)

ClearAll[RunSeriesExpansion];

RunSeriesExpansion[rootDir_, label_, lsBase_, poleType_, weightN_, yOrder_:4, svIndices_:{}, mplIndices_:{}, poleOrder_:1, mplBasisFile_:None, uOrder_Integer:0, limitIndex_Integer:0] := Module[
  {svliste0, svlistmple0, svliste1, svlistmple1, svlisteinf, svlistmpleinf,
   i, add, svRes, mplRes, suffix, zrep, mplPrefix, mplFormat},

  (* ---- load pre-computed .txt files from root ---- *)
  svliste0     = Import[FileNameJoin[{rootDir, "allsvliste0_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svliste1     = Import[FileNameJoin[{rootDir, "allsvliste1_uptow8.txt"}],    "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
  svlisteinf   = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}],  "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;

  (* ---- load MPL expansion files (if a basis is provided) ---- *)
  If[mplBasisFile =!= None && mplIndices =!= {},
    mplPrefix = FileBaseName[mplBasisFile] <> "e";
    Module[{mplLoad},
      mplLoad[fname_] := Module[{txtPath = fname <> ".txt", mPath = fname <> ".m", raw, fmt},
        raw = If[FileExistsQ[txtPath], {Import[txtPath, "String"], "txt"},
                If[FileExistsQ[mPath], {Import[mPath], "m"}, Return[$Failed]]];
        fmt = raw[[2]];
        If[fmt === "txt",
          StringTrim[raw[[1]], "["|"]"] // ("{" <> # <> "}" &) // ToExpression,
          raw[[1]]
        ]
      ];
      mplFormat = If[FileExistsQ[FileNameJoin[{rootDir, mplPrefix <> "0.m"}]], ".m", ".txt"];
      svlistmple0   = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "0"}]];
      svlistmple1   = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "1"}]];
      svlistmpleinf = mplLoad[FileNameJoin[{rootDir, mplPrefix <> "inf"}]];
      If[svlistmple0 === $Failed || svlistmple1 === $Failed || svlistmpleinf === $Failed,
        Print["[Skill 1] ERROR: Missing MPL expansions for '", mplPrefix, "{0,1,inf}.txt/.m'."];
        Return[$Failed]
      ];
      Print["[Skill 1] Loaded MPL expansions: ", mplPrefix, "{0,1,inf} (format: ", mplFormat, ")"];
    ];
  ,
    svlistmple0   = {};
    svlistmple1   = {};
    svlistmpleinf = {};
  ];

  (* ---- optionally reduce to only ansatz-relevant indices ---- *)
  If[svIndices =!= {},
    svliste0   = svliste0[[svIndices]];
    svliste1   = svliste1[[svIndices]];
    svlisteinf = svlisteinf[[svIndices]];
    Print["[Skill 1] Reduced SVHPL to ", Length[svliste0], " elements from ansatz indices"];
  ];
  If[mplIndices =!= {},
    svlistmple0   = svlistmple0[[mplIndices]];
    svlistmple1   = svlistmple1[[mplIndices]];
    svlistmpleinf = svlistmpleinf[[mplIndices]];
  ];

  If[limitIndex == 0,
    Print["[Skill 1] Dispatching 6 limits to separate processes to avoid cache explosion..."];
    For[i = 1, i <= 6, i++,
      Module[{scriptFile, scriptCode, res, ptr, suffix},
        ptr = Switch[i, 1,0, 2,0, 3,2, 4,2, 5,1, 6,1];
        suffix = Switch[ptr, 0, If[OddQ[i], "e0uv", "e0uvp"], 1, If[OddQ[i], "e1uv", "e1uvp"], 2, If[OddQ[i], "einfuv", "einfuvp"]];
        If[FileExistsQ[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> suffix <> ".m"}]],
          Print["[Skill 1] Limit ", i, "/6 (", suffix, "): already exists, skipping."];
          Continue[];
        ];

        scriptFile = FileNameJoin[{rootDir, "series_agent", "run_limit_" <> ToString[i] <> ".wl"}];
        scriptCode = StringTemplate["SetDirectory[\\"`1`\\"];
$HistoryLength = 0;
Get[FileNameJoin[{\\"`1`\\", \\"series_agent\\", \\"series_agent.wl\\"}]];
RunSeriesExpansion[\\"`1`\\", \\"`2`\\", `3`, \\"`4`\\", `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`];
"][rootDir, label, ToString[lsBase, InputForm], poleType, weightN, yOrder, ToString[svIndices], ToString[mplIndices], poleOrder, If[mplBasisFile === None, "None", "\\"" <> mplBasisFile <> "\\""], uOrder, i];
        Export[scriptFile, scriptCode, "String"];
        Print["[Skill 1] Evaluating Limit ", i, "/6 (", suffix, ") in isolated process..."];
        res = RunProcess[{"wolfram", "-script", scriptFile}];
        Print[res["StandardOutput"]];
        If[res["ExitCode"] != 0,
           Print["[Skill 1] ERROR in Limit ", i, ":\n", res["StandardError"]];
        ];
      ];
    ];
    Print["Series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
    Return[];
  ];

  Print["[Skill 1] Starting limit ", limitIndex, ", poleType=", poleType, ", n=", weightN,
    ", k=", poleOrder, ", SVHPL=", Length[svliste0], ", MPL=", Length[svlistmple0], ", uorder=", uOrder];
  For[i = limitIndex, i <= limitIndex, i++,
    Module[{uRule, vRule, F, transformed, ptr, headSV, headMPL},

      Switch[i,
        1, {uRule = u->u;   vRule = v->v;   F = 1; ptr = 0},
        2, {uRule = u->u/v; vRule = v->1/v; F = v; ptr = 0},
        3, {uRule = u->1/u; vRule = v->v/u; F = u; ptr = 2},
        4, {uRule = u->v/u; vRule = v->1/u; F = u; ptr = 2},
        5, {uRule = u->1/v; vRule = v->u/v; F = v; ptr = 1},
        6, {uRule = u->v;   vRule = v->u;   F = 1; ptr = 1}
      ];

      transformed = Simplify[lsBase /. {uRule, vRule}];
      add = If[F === 1, transformed, Simplify[transformed / F^(weightN - poleOrder)]];
      Print["[Skill 1] Limit ", i, "/6: additional = ", add // InputForm];

      Which[
        ptr == 0 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansion0,   "double"->SeriesExpansion20}; headMPL = headSV},
        ptr == 0 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansion0P,  "double"->SeriesExpansion20P}; headMPL = headSV},
        ptr == 1 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansion1,   "double"->SeriesExpansion21}; headMPL = headSV},
        ptr == 1 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansion1P,  "double"->SeriesExpansion21P}; headMPL = headSV},
        ptr == 2 && OddQ[i],  {headSV = poleType /. {"simple"->SeriesExpansionInf, "double"->SeriesExpansion2Inf}; headMPL = headSV},
        ptr == 2 && EvenQ[i], {headSV = poleType /. {"simple"->SeriesExpansionInfP,"double"->SeriesExpansion2InfP}; headMPL = headSV}
      ];

      Switch[ptr,
        0, If[OddQ[i],
             {svRes  = headSV[svliste0,      Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmple0,   Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]},
             {svRes  = headSV[svliste0,      Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmple0,   Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]}],
        1, If[OddQ[i],
             {svRes  = headSV[svliste1,      Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmple1,   Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]},
             {svRes  = headSV[svliste1,      Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmple1,   Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]}],
        2, If[OddQ[i],
             {svRes  = headSV[svlisteinf,    Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmpleinf, Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]},
             {svRes  = headSV[svlisteinf,    Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder];
              mplRes = headMPL[svlistmpleinf, Null, "Yorder"->yOrder, "additional"->add, "uorder"->uOrder]}]
      ];

      suffix = Switch[ptr,
        0, If[OddQ[i], "e0uv", "e0uvp"],
        1, If[OddQ[i], "e1uv", "e1uvp"],
        2, If[OddQ[i], "einfuv", "einfuvp"]
      ];

      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlist" <> suffix <> ".m"}], svRes];
      Export[FileNameJoin[{rootDir, "series_agent", label <> "_svlistmpl" <> suffix <> ".m"}], mplRes];
      Print["[Skill 1] Limit ", i, "/6 (", suffix, "): done."];
      ClearSystemCache[];
    ]
  ];

  Print["Series expansion files written to ", FileNameJoin[{rootDir, "series_agent"}]];
];
"""
    f.write(main_pipeline)

