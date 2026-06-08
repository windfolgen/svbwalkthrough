(* scratch/test_mismatch_proper.wl *)
rootDir = DirectoryName[DirectoryName[$InputFileName]];
SetDirectory[rootDir];

Print["Loading packages and parsed input..."];
Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

label = "fourloopI41";
order = 4;
yOrder = 5;

config = ParseInput[FileNameJoin[{rootDir, "runs", "fourloopI41"}]];
integrandList = config["Integrands"];
coeffList = config["Coefficients"];
ansatzList = {config["LeadingSingularities"][[1, 3]]};
labelsList = {label};

Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];

(* Reconstruct basis SV and MPL exactly like workflow_engine.wl does *)
Print["Loading full SV basis..."];
fullBasisSV = Import[$SVBasisFile];
cAnsatz = config["LeadingSingularities"][[1, 3]];
basisElements = DeleteDuplicates @ Cases[cAnsatz, _I | _f, {1, Infinity}];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
basisSVReduced = fullBasisSV[[svIndices]];
basisSVList = {basisSVReduced};

mplFiles = FileNames[FileNameJoin[{$DataDir, $MPLTextPrefix <> "*.m"}]];
mplFiles = Select[mplFiles, !StringMatchQ[#, ___ ~~ ("e0.m" | "e1.m" | "einf.m")] &];

bestCount = 0;
bestFile = None;
If[mplFiles =!= {},
  Do[
    mplTry = Import[f];
    idx = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[mplTry, e, {1}]] /@ basisElements;
    idx = Select[idx, Positive];
    If[Length[idx] > bestCount, bestCount = Length[idx]; bestFile = f],
    {f, mplFiles}
  ];
];

If[bestCount > 0,
  fullBasisMPL = Import[bestFile];
  mplIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisMPL, e, {1}]] /@ basisElements;
  mplIndices = DeleteDuplicates[Select[mplIndices, Positive]];
  basisMPLReduced = fullBasisMPL[[mplIndices]];
  basisMPLList = {basisMPLReduced};
,
  basisMPLList = {{}};
];

boundaryDir = FileNameJoin[{rootDir, "runs", label, "boundaries"}];
If[!DirectoryQ[boundaryDir], boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}]];

Print["Orchestrating boundary data..."];
targetData = Table[
  subTargetData = 0;
  Do[
    perm = $Perms[[i]];
    permStr = StringJoin[ToString /@ perm];
    subPath = FileNameJoin[{boundaryDir, label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
    data = Import[subPath] // Normal;
    coeffVal = EvaluateCoeff[coeffList[[p]], perm];
    subTargetData = subTargetData + Expand[coeffVal * data];
  , {p, 1, Length[integrandList]}];
  subTargetData
, {i, 1, 6}];

Print["Loading solution..."];
sol = Get[FileNameJoin[{rootDir, "solve_agent", "fourloopI41_sol.m"}]];
solt = sol /. Symbol["c"][i_] :> c[i];

Print["Checking limits..."];
For[i = 1, i <= 6, i++,
  suffix = Switch[i, 1, "e0uv", 2, "e0uvp", 3, "einfuv", 4, "einfuvp", 5, "e1uv", 6, "e1uvp"];
  
  Quiet[
    setup = 0;
    offset = 0;
    Do[
      ansatzK = ansatzList[[k]];
      filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[k]]}];
      
      mplRules = If[basisMPLList[[k]] =!= {},
        Thread @ Rule[basisMPLList[[k]], ((Series[#, {Y, 0, order}]) &) /@ Import[filePrefix <> "_svlistmpl" <> suffix <> ".m"]],
        {}
      ];
      svrepK = Join[
        Thread @ Rule[basisSVList[[k]], ((Series[#, {Y, 0, order}]) &) /@ Import[filePrefix <> "_svlist" <> suffix <> ".m"]],
        mplRules
      ];
      
      setup = setup + ((c /@ Range[offset + 1, offset + Length[ansatzK]]) . ansatzK) /. svrepK /. solt;
      offset = offset + Length[ansatzK];
    , {k, 1, Length[ansatzList]}];
  ];

  temp = Normal[setup - targetData[[i]]] /. {
    f[3, 3] -> Zeta[3]^2 / 2, f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3], f[a_] :> Zeta[a]
  };
  
  Print["Limit ", i, " (", suffix, "):"];
  Print["  temp === 0: ", temp === 0];
  If[temp =!= 0,
    Print["  Simplify[temp] === 0: ", Simplify[temp] === 0];
    If[Simplify[temp] =!= 0,
      Print["  Simplified temp non-zero: ", InputForm[Simplify[temp]]];
    ];
  ];
];
