(* =================================================================== *)
(*  Skill 3: Coefficient Solving Agent                                 *)
(*  Location: ./solve_agent/                                           *)
(*                                                                     *)
(*  Follows the exact syntax of svbwalkthrough.nb (Section 6).         *)
(*  Only file paths and ansatz construction vary per integrand.         *)
(*                                                                     *)
(*  Input (set before calling):                                        *)
(*    rootDir      — project root                                      *)
(*    label        — file name prefix shared by all skills             *)
(*    ansatzExpr   — the full testansatz expression (Join[svhpl,svmpl]) *)
(*    basisSV      — allsvlist (SVHPL basis)                            *)
(*    basisMPL     — allsvlistmpl (MPL basis)                           *)
(*    targetData   — list of 6 target expressions from boundary calc   *)
(*    order        — $Order                                            *)
(*                                                                     *)
(*  Output:                                                             *)
(*    solve_agent/<label>_sol.m                                        *)
(* =================================================================== *)

ClearAll[RunCoefficientSolving];

RunCoefficientSolving[rootDir_, label_,
                     ansatzExpr_, basisSV_, basisMPL_,
                     targetData_List, order_ : 3] := Module[
  {allsvlist, allsvlistmpl, testansatz, $LEN, $Order, c,
   svliste, svlistmple, svrep, setup, temp, temp1, sys, solt,
   i, j, k, suffix, filePrefix},

  (* ---- load basis lists ---- *)
  allsvlist    = basisSV;
  allsvlistmpl = basisMPL;
  testansatz   = ansatzExpr;
  $LEN         = Length[testansatz];
  $Order       = order;
  Clear[Y];  (* defensive: Y must remain symbolic *)

  Print["[Skill 3] $LEN=", $LEN, " $Order=", $Order, " SV=", Length[allsvlist], " MPL=", Length[allsvlistmpl]];
  Print["[Skill 3] Y=", Y // InputForm];

  filePrefix = FileNameJoin[{rootDir, "series_agent", label}];

  (* ---- process each limit incrementally, as in the notebook ---- *)
  sys = {};
  solt = {};

  Do[
    suffix = Switch[i,
      1, "e0uv",  2, "e0uvp",  3, "einfuv",
      4, "einfuvp", 5, "e1uv",  6, "e1uvp"
    ];

    svliste    = Import[filePrefix <> "_svlist" <> suffix <> ".m"];
    svlistmple = Import[filePrefix <> "_svlistmpl" <> suffix <> ".m"];

    (* svrep: exact notebook syntax *)
    svrep = Join[
      Thread @ Rule[allsvlist, ((Series[#, {Y, 0, $Order}]) &) /@ svliste],
      Thread @ Rule[allsvlistmpl, ((Series[#, {Y, 0, $Order}]) &) /@ svlistmple]
    ];
    Print["[DBG] After svrep, Y=", Y // InputForm];
    Print["[Skill 3] Limit ", i, " (", suffix, "): equations="];

    (* setup: substitute partial solution from previous limits *)
    Quiet[setup = ((c /@ Range[$LEN]) . testansatz) /. solt /. svrep];

    (* temp: exact notebook syntax *)
    temp = MonomialList[
      Normal[setup - targetData[[i]]] /. {
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
        f[a_] :> Zeta[a]
      },
      {Log[u]}
    ] // DeleteCases[#, 0] &;

    (* If temp is empty, this limit provides no new constraints — skip *)
    If[temp === {},
      Print["Limit ", i, " (", suffix, "): temp is empty, skipping."];
      Continue[];
    ];

    (***** FIXED: extract coefficients (temp1) — from notebook, never changes *****)
    temp1 = Table[
      (
        (temp[[j]] /. {
          Log[u] -> 1,
          Power[Y, -1] -> invY,
          Power[u, -1] -> invu,
          Power[Y, a_ /; (a < 0)] :> Power[invY, -a],
          Power[u, a_ /; (a < 0)] :> Power[invu, -a]
        } // (MonomialList[#, {u, Y, invY, invu}] &))
      ) /. {
        Y -> 1, invY -> 1, invu -> 1,
        f[3, 3] -> Zeta[3]^2 / 2,
        f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3]
      },
      {j, 1, Length[temp]}
    ];

    (***** FIXED: build linear system (sys1) — from notebook, never changes *****)
    Module[{sys1},
      sys1 = Table[
        Table[
          Thread @ Equal[
            (MonomialList[
              temp1[[j]][[k]] /. {Zeta[3] -> z3, Zeta[5] -> z5, Zeta[7] -> z7, Pi -> pi},
              {z3, z5, z7, f[5, 3], pi}
            ] /. {z3 -> 1, z5 -> 1, z7 -> 1, f[5, 3] -> 1, pi -> 1})
            // DeleteDuplicates // DeleteCases[#, 0] &,
            0
          ],
          {k, 1, Length[temp1[[j]]]}
        ] // Flatten,
        {j, 1, Length[temp1]}
      ] // Flatten // DeleteCases[#, True | False] &;

      (* incremental join and solve, only if real equations were found *)
      If[sys1 =!= {},
        sys = Join[sys, sys1];
        (* Extract only c[i]-like variables (c$nnn or c), exclude I,u,Y,etc. *)
        allVars = Variables[sys[[All, 1]]];
        cVars = Select[allVars, MatchQ[#, _[_]] && StringMatchQ[SymbolName[Head[#]], "c*"] &];
        Print["  system size after limit ", i, ": ", Length[sys], " vars: ", Length[cVars]];
        solt = Solve[sys, cVars][[1]];
      ,
        Print["  no new equations from limit ", i];
      ];
    ];

    , {i, 1, 6}
  ];

  (* ---- final solution ---- *)
  soltClean = Table[Symbol["c"][i] -> (c[i] /. solt), {i, 1, $LEN}]; Export[FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}], soltClean];
  Print["Solution written to ", FileNameJoin[{rootDir, "solve_agent", label <> "_sol.m"}]];

  (* ---- verify: substitute back and check all limits ---- *)
  Do[
    suffix = Switch[i,
      1, "e0uv",  2, "e0uvp",  3, "einfuv",
      4, "einfuvp", 5, "e1uv",  6, "e1uvp"
    ];
    svliste    = Import[filePrefix <> "_svlist" <> suffix <> ".m"];
    svlistmple = Import[filePrefix <> "_svlistmpl" <> suffix <> ".m"];
    svrep = Join[
      Thread @ Rule[allsvlist,    ((Series[#, {Y, 0, $Order}]) &) /@ svliste],
      Thread @ Rule[allsvlistmpl, ((Series[#, {Y, 0, $Order}]) &) /@ svlistmple]
    ];
    setup = ((c /@ Range[$LEN]) . testansatz) /. svrep /. solt;
    temp = setup - targetData[[i]] /. {
      f[3, 3] -> Zeta[3]^2 / 2,
      f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3],
      f[a_] :> Zeta[a]
    } // Simplify;
    If[temp === 0,
      Print["Limit ", i, " verified."],
      Print["Limit ", i, " mismatch: ", temp // InputForm]
    ],
    {i, 1, 6}
  ];
];
