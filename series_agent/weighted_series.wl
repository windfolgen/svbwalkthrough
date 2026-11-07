(* Weighted, multi-prefactor series provider. Its matrices contain function
   expansions only; physical boundary values are supplied by the boundary agent. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "weighted_mixed_period_jet_engine.wl"}]];
ClearAll[SVBWeightedCatalog, SVBVerifiedRead, SVBResolveWeightedProfile,
  SVBFunctionMatrix, SVBBasisCoordinates, RunWeightedSeriesExpansion,
  SVBBuildWeightedJetMatrix];
If[!AssociationQ[$SVBVerifiedData], $SVBVerifiedData = <||>];
SVBWeightedCatalog[root_] := Get[FileNameJoin[{root, "data", "series", "fourloop_hard", "catalog.m"}]];
SVBVerifiedRead[root_, file_String, catalog_] := Module[{path, expected, actual, key, value},
  path = FileNameJoin[{root, file}]; expected = Lookup[catalog["Hashes"], file, Missing["Hash"]];
  If[!FileExistsQ[path], Return[Failure["MissingSeriesData", <|"File" -> file|>]]];
  actual = FileHash[path, "SHA256", "HexString"];
  If[actual =!= expected, Return[Failure["DataHashMismatch", <|"File" -> file|>]]];
  key = {path, actual};
  If[KeyExistsQ[$SVBVerifiedData, key], Return[$SVBVerifiedData[key]]];
  value = Get[path]; AssociateTo[$SVBVerifiedData, key -> value]; value
];
SVBResolveWeightedProfile[root_, config_] := Module[
  {method, ls, catalog, matches, profile, sectors, scales, choices, ratio, ref, map, offsets, projection},
  method = Lookup[config, "BootstrapMethod", Automatic];
  If[method === "Legacy", Return[None]];
  ls = config["LeadingSingularities"];
  If[method === Automatic && FreeQ[ls[[All, 3]], I[1-z, ___]], Return[None]];
  catalog = SVBWeightedCatalog[root]; matches = {};
  Do[
    profile = catalog["Profiles"][id]; sectors = {}; scales = {};
    Do[
      choices = Select[Range[Length[profile["LeadingSingularities"]]],
        ls[[j, 1]] === profile["LeadingSingularities"][[#, 1]] &&
        MatchQ[Cancel[ls[[j, 2]]/profile["LeadingSingularities"][[#, 2]]], _Integer | _Rational] &&
        Cancel[ls[[j, 2]]/profile["LeadingSingularities"][[#, 2]]] =!= 0 &];
      If[Length[choices] =!= 1, Break[]];
      AppendTo[sectors, First[choices]];
      AppendTo[scales, Cancel[ls[[j, 2]]/profile["LeadingSingularities"][[First[choices], 2]]]], {j, Length[ls]}];
    If[Length[sectors] === Length[ls], AppendTo[matches, {id, sectors, scales}]],
    {id, Keys[catalog["Profiles"]]}];
  If[Length[matches] =!= 1, Return[Failure["WeightedPrefactorsUnavailable", <|"Matches" -> Length[matches]|>]]];
  {profile, sectors, scales} = First[matches];
  ref = SVBVerifiedRead[root, catalog["Profiles"][profile]["BasisFile"], catalog];
  If[FailureQ[ref], Return[ref]];
  offsets = Prepend[Accumulate[Length /@ ref], 0];
  projection = Table[
    map = SVBBasisCoordinates[ls[[j, 3]] /. I0constant -> 1, ref[[sectors[[j]]]]];
    If[FailureQ[map], map,
      SparseArray[(#[[1]] + {offsets[[sectors[[j]]]], 0} -> scales[[j]] #[[2]]) & /@
        Most[ArrayRules[SparseArray[map]]], {Total[Length /@ ref], Length[ls[[j, 3]]]}]], {j, Length[ls]}];
  If[AnyTrue[projection, FailureQ], Return[FirstCase[projection, _Failure]]];
  <|"Profile" -> profile, "Catalog" -> catalog,
    "Projection" -> SparseArray[Join[Sequence @@ projection, 2]],
    "BasisDimensions" -> (Length /@ ls[[All, 3]]),
    "SeriesProfile" -> catalog["Profiles"][profile]|>
];
SVBFunctionMatrix[expressions_List, atomKeys_:Automatic] := Module[
  {parts, terms, factors, number, key, keys, index, entries, missing},
  parts = Table[terms = If[Head[e] === Plus, List @@ e, {e}];
    Table[factors = If[Head[t] === Times, List @@ t, {t}];
      number = Times @@ Select[factors, MatchQ[#, _Integer | _Rational] &];
      {ToString[Times @@ Select[factors, !MatchQ[#, _Integer | _Rational] &], InputForm], number},
      {t, DeleteCases[terms, 0]}],
    {e, Expand /@ (expressions /. {I0constant -> 1, f[a_, a_] :> f[a]^2/2})}];
  keys = If[atomKeys === Automatic, Union[Flatten[parts[[All, All, 1]]]], atomKeys];
  index = AssociationThread[keys, Range[Length[keys]]];
  missing = Complement[Union[Flatten[parts[[All, All, 1]]]], keys];
  If[missing =!= {}, Return[Failure["FunctionsOutsideSeriesBasis", <|"Count" -> Length[missing]|>]]];
  entries = Flatten[Table[({j, index[#[[1]]]} -> #[[2]]) & /@ parts[[j]], {j, Length[parts]}], 1];
  {keys, SparseArray[entries, {Length[parts], Length[keys]}]}
];
SVBBasisCoordinates[ansatz_List, reference_List] := Module[{index, indices, keys, b, e, red, pivots, map, result},
  If[ansatz === reference, Return[IdentityMatrix[Length[reference], SparseArray]]];
  index = AssociationThread[Hash[#, "SHA256"] & /@ reference, Range[Length[reference]]];
  indices = Lookup[index, Hash[#, "SHA256"] & /@ ansatz, 0];
  If[FreeQ[indices, 0] && reference[[indices]] === ansatz,
    Return[SparseArray[Table[{indices[[j]], j} -> 1, {j, Length[indices]}], {Length[reference], Length[ansatz]}]]];
  {keys, b} = SVBFunctionMatrix[reference]; result = SVBFunctionMatrix[ansatz, keys];
  If[FailureQ[result], Return[result]]; e = Last[result];
  red = SparseArray[RowReduce[Normal[b]]];
  pivots = (Min[#[[All, 2]]] &) /@ GatherBy[red["NonzeroPositions"], First];
  If[Length[pivots] =!= Length[reference], Return[Failure["DependentReferenceBasis", <||>]]];
  map = LinearSolve[Transpose[Normal[b[[All, pivots]]]], Transpose[Normal[e[[All, pivots]]]]];
  If[!SVBExactZeroQ[SparseArray[Transpose[map].b-e]], Return[Failure["AnsatzOutsideSeriesSpan", <||>]]];
  SparseArray[map]
];
RunWeightedSeriesExpansion[root_, label_, config_, spec_, boundaryData_] := Catch[Module[
  {blocks = {}, packet, matrix, target, rules, lookup, keys, rhs, extra, variables, tagged, ring, catalog},
  catalog = spec["Catalog"]; ring = spec["SeriesProfile"]["PeriodRing"];
  variables = If[ring === "MZV", {u,Y,ell,q3,q5,q7,q53,pi,rho}, $MixedJetVariables];
  Do[
    packet = SVBVerifiedRead[root, entry["File"], catalog]; If[FailureQ[packet], Throw[packet, "WeightedSeries"]];
    matrix = SparseArray[packet["Matrix"].spec["Projection"]];
    If[entry["Kind"] === "Boundary",
      target = boundaryData[entry["Name"]] /. Log[u] -> ell;
      tagged = If[ring === "MZV", CanonicalConstants[target], MixedPeriodTag[target]];
      rules = CoefficientRules[Expand[u^2 Y^16 tagged], variables];
      If[!AllTrue[Last /@ rules, MatchQ[#, _Integer | _Rational] &], Throw[Failure["UnresolvedBoundaryPeriods", <||>], "WeightedSeries"]];
      lookup = Association[(ToString[First[#], InputForm] -> Last[#]) & /@ rules];
      keys = ToString[#, InputForm] & /@ packet["Keys"];
      rhs = Lookup[lookup, keys, 0]; extra = Complement[Keys[lookup], keys];
      If[extra =!= {}, matrix = Join[matrix, SparseArray[{}, {Length[extra], Last[Dimensions[matrix]]}]];
        rhs = Join[rhs, Lookup[lookup, extra]]],
      rhs = ConstantArray[0, Length[matrix]]];
    AppendTo[blocks, <|"Name" -> entry["Name"], "Matrix" -> matrix, "RHS" -> rhs|>],
    {entry, spec["SeriesProfile"]["Blocks"]}];
  blocks
], "WeightedSeries"];
(* Rebuild weighted function matrices from ordered bare expansions. The
   reference profile is explicit, never inferred from a run label. *)
SVBBuildWeightedJetMatrix[records_List, coordinates_List, profile_Association,
    channel_Integer, order_Integer] := Module[{rules, keys, index, matrices, setup},
  If[Length[coordinates] =!= Length[profile["LeadingSingularities"]],
    Return[Failure["JetSectorDimensions", <||>]]];
  rules = Table[
    setup = TwoFamilyJetSetup[profile, channel, sector, order];
    If[FailureQ[setup], Return[setup]];
    HigherJetRules /@ (HigherAtomJet /@ records), {sector, Length[coordinates]}];
  keys = Union[Flatten[rules[[All, All, All, 1]], 2]];
  index = AssociationThread[ToString[#, InputForm] & /@ keys, Range[Length[keys]]];
  matrices = Table[SparseArray[Flatten[Table[
    ({index[ToString[First[#], InputForm]], j} -> Last[#]) & /@ rules[[k, j]],
    {j, Length[records]}], 1], {Length[keys], Length[records]}].Transpose[coordinates[[k]]], {k, Length[coordinates]}];
  <|"Keys" -> keys, "Matrix" -> SparseArray[Join[Sequence @@ matrices, 2]]|>
];
