$HistoryLength = 0;
package = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
here = DirectoryName[$InputFileName];
Get[FileNameJoin[{package, "workflow_engine.wl"}]];
checks = <|"ExtensionNotLoadedByLegacyEntryPoint" ->
  (DownValues[RunExtendedWorkflow] === {} && DownValues[RunConstrainedCoefficientSolving] === {})|>;
Get[FileNameJoin[{package, "constraint_agent", "workflow.wl"}]];
Get[FileNameJoin[{package, "input_parser.wl"}]];
Get[FileNameJoin[{package, "constraint_agent", "orbit.wl"}]];
check[name_, value_] := (AssociateTo[checks, name -> TrueQ[value]]; Print[name, ": ", value]);
check["ConstantContradictionRejected", FailureQ[SVBExactSolve[
  {<|"Name" -> "constant", "Matrix" -> {{0,0}}, "RHS" -> {1}|>}, 2]]];
check["InconsistentRedundantRowRejected", FailureQ[SVBExactSolve[
  {<|"Name" -> "redundant", "Matrix" -> {{1},{1}}, "RHS" -> {1,2}|>}, 1]]];
check["UnresolvedPeriodsRejected", FailureQ[SVBBoundaryBlock["period", {{1}}, {{0}},
  Zeta[11], {u}, 1, Identity]]];
check["MissingTargetMonomialRetained", With[{b = SVBBoundaryBlock["extra", {{1}}, {{0}}, 1+u, {u}, 1, Identity]},
  FailureQ[SVBExactSolve[{b},1]]]];
check["InvalidNullDirectionsRejected", FailureQ[SVBZeroGeneratorGauge[{{1},{0}},
  {<|"Name" -> "nonzero", "Matrix" -> {{1,0}}, "RHS" -> {0}|>}]]];
empty = SVBZeroGeneratorGauge[SparseArray[{}, {2,0}], {}];
state = SVBExactSolve[{empty,
  <|"Name" -> "fix", "Matrix" -> IdentityMatrix[2], "RHS" -> {3,4}|>, empty}, 2];
check["EmptyConstraintsPreserveState", AssociationQ[state] && state["Point"] === {3,4} &&
  state["FreeColumns"] === {}];
Do[
  cfg = ParseInput[FileNameJoin[{package, "runs", label}]];
  coeffs = Get[FileNameJoin[{package, "runs", label, "coeff_sol.m"}]];
  nums = Get[FileNameJoin[{package, "runs", label, "result.m"}]];
  validation = Import[FileNameJoin[{package, "runs", label, "workflow_validation.json"}], "RawJSON"];
  check[label<>"UniqueVerifiedSolve", validation["Status"] === "Complete" && validation["RemainingFree"] === 0 &&
    TrueQ[validation["AllOriginalRowsSatisfied"]]];
  check[label<>"StandardOutputShape", Length[nums] === Length[cfg["LeadingSingularities"]] &&
    (Length /@ coeffs) === (Length /@ cfg["LeadingSingularities"][[All,3]])];
  check[label<>"NumeratorAssembly", MapThread[Expand[#1.#2] &, {coeffs,
    cfg["LeadingSingularities"][[All,3]] /. I0constant -> 1}] === nums];
  If[label =!= "fourloopI163",
    check[label<>"BaselineCoefficients", coeffs === Get[FileNameJoin[{here,"fixtures",label<>"_coeff_sol.m"}]]];
    check[label<>"BaselineNumerators", nums === Get[FileNameJoin[{here,"fixtures",label<>"_result.m"}]]]],
  {label,{"fourloopI163","fourloopI167","fourloopI169","fourloopI246"}}];
check["I167I246IdentityCoefficients", Get[FileNameJoin[{package,"runs","fourloopI167","coeff_sol.m"}]] ===
  Get[FileNameJoin[{package,"runs","fourloopI246","coeff_sol.m"}]]];
check["I167I246IdentityNumerators", Get[FileNameJoin[{package,"runs","fourloopI167","result.m"}]] ===
  Get[FileNameJoin[{package,"runs","fourloopI246","result.m"}]]];
cfg246 = ParseInput[FileNameJoin[{package,"runs","fourloopI246"}]];
check["I246GraphMatchesAncillary", Cancel[Total[MapThread[Times,
  {cfg246["Integrands"],cfg246["Coefficients"]}]] -
  Apply[Times,Get[FileNameJoin[{package,"anc","4Loop_int_basis.m"}]][[246]]]] === 0];
cfg = ParseInput[FileNameJoin[{package,"runs","fourloopI163"}]];
profile = SVBLoadConstraintProfile[package,cfg];
check["I163GeneratorReference", Get[FileNameJoin[{package,"runs","fourloopI163","generator_coeff_sol.m"}]] ===
  Get[FileNameJoin[{here,"fixtures","I163_generators.m"}]]];
Do[check["Hash:"<>file, FileHash[FileNameJoin[{package,file}],"SHA256","HexString"] === hash],
  {rule, Normal[profile["Hashes"]]}, {file,{First[rule]}}, {hash,{Last[rule]}}];
badProfile = Append[profile,"Hashes" -> Append[profile["Hashes"],profile["OrbitData"] -> "wrong"]];
check["CorruptDataRejected", FailureQ[SVBVerifiedRead[package,profile["OrbitData"],badProfile]]];
check["UnknownGraphRejected", FailureQ[SVBProfileBlocks[package,
  Append[cfg,"Integrands" -> {x[1,5]}],profile,6]]];
check["MissingBoundaryRejected", FailureQ[SVBProfileBlocks[package,Append[cfg,"BoundaryData" -> <||>],profile,6]]];
check["ChangedBasisRejected", FailureQ[SVBLoadConstraintProfile[package,
  Append[cfg,"LeadingSingularities" -> ReplacePart[cfg["LeadingSingularities"],{1,3,1}->1]]]]];
seed = Get[FileNameJoin[{package,"data","constraints","reciprocal_s3_w8","seed.m"}]];
orbit = SVBOrbitAnsatz[seed["Sectors"],seed["SeedMap"],
  Table[{z->im,zz->(im/.z->zz)},{im,seed["Images"]}],seed["Weights"]];
cached = SVBVerifiedRead[package,profile["OrbitData"],profile];
check["OrbitRegeneratedFromSeed", orbit === cached];
catalog = SVBWeightedCatalog[package];
Do[check["Hash:"<>First[rule], FileHash[FileNameJoin[{package,First[rule]}],"SHA256","HexString"] === Last[rule]],
  {rule,Normal[catalog["Hashes"]]}];
malformed = FileNameJoin[{package,"scratch","malformed_constraint_profile.wl"}];
If[!DirectoryQ[DirectoryName[malformed]],CreateDirectory[DirectoryName[malformed]]];
Put[<||>,malformed];
check["MalformedProfileRejected",FailureQ[SVBLoadConstraintProfile[package,
  Append[cfg,"ConstraintProfile"->"scratch/malformed_constraint_profile.wl"]]]];
DeleteFile[malformed];
Export[FileNameJoin[{here,"checks.json"}],checks,"RawJSON"];
Exit[If[And @@ Values[checks],0,1]];
