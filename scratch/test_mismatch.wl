(* scratch/test_mismatch.wl *)
rootDir = DirectoryName[DirectoryName[$InputFileName]];
SetDirectory[rootDir];

Print["Loading solution..."];
sol = Get[FileNameJoin[{rootDir, "solve_agent", "fourloopI41_sol.m"}]];

Print["Constructing Limit 1 check..."];
label = "fourloopI41";
order = 4;
yOrder = 5;

Get[FileNameJoin[{rootDir, "workflow_engine.wl"}]];
Get[FileNameJoin[{rootDir, "input_parser.wl"}]];

config = ParseInput[FileNameJoin[{rootDir, "runs", "fourloopI41"}]];
integrandList = config["Integrands"];
coeffList = config["Coefficients"];
ansatzList = {config["LeadingSingularities"][[1, 3]]};
labelsList = {label};
basisSVList = {};
basisMPLList = {};

Get[FileNameJoin[{rootDir, "asym", "boundary_agent", "boundary_agent.wl"}]];
Get[FileNameJoin[{rootDir, "series_agent", "series_agent.wl"}]];

(* Re-load basis elements *)
fullBasisSV = Import[$SVBasisFile];
cAnsatz = config["LeadingSingularities"][[1, 3]];
basisElements = DeleteDuplicates @ Cases[cAnsatz, _I | _f, {1, Infinity}];
svIndices = Function[e, If[# === {}, 0, #[[1,1]]] & @ Position[fullBasisSV, e, {1}]] /@ basisElements;
svIndices = DeleteDuplicates[Select[svIndices, Positive]];
basisSVReduced = fullBasisSV[[svIndices]];

(* We only have 1 LS *)
boundaryDir = FileNameJoin[{rootDir, "runs", label, "boundaries"}];
If[!DirectoryQ[boundaryDir], boundaryDir = FileNameJoin[{rootDir, "asym", "boundary_agent"}]];

i = 1; (* Limit 1 *)
perm = $Perms[[i]];
permStr = StringJoin[ToString /@ perm];
subPath = FileNameJoin[{boundaryDir, label <> permStr <> "_order" <> ToString[order] <> "_asyexp.m"}];
data = Import[subPath] // Normal;
coeffVal = EvaluateCoeff[coeffList[[1]], perm];
targetDataVal = Expand[coeffVal * data];

ansatzK = ansatzList[[1]];
filePrefix = FileNameJoin[{rootDir, "series_agent", labelsList[[1]]}];
suffix = "e0uv";

svrepK = Thread @ Rule[basisSVReduced, ((Series[#, {Y, 0, order}]) &) /@ Import[filePrefix <> "_svlist" <> suffix <> ".m"]];

c = Symbol["c"];
setup = ((c /@ Range[1, Length[ansatzK]]) . ansatzK) /. svrepK /. sol;

temp = Normal[setup - targetDataVal] /. {
  f[3, 3] -> Zeta[3]^2 / 2, f[3, 5] -> Zeta[3] Zeta[5] - f[5, 3], f[a_] :> Zeta[a]
};

Print["Raw temp is 0? ", temp === 0];
Print["Simplified temp:"];
Print[InputForm[Simplify[temp]]];
Print["FullSimplified temp:"];
Print[InputForm[FullSimplify[temp]]];
