(* Boundary data are independent of the chosen svMPL basis and its coefficients. *)
Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "weighted_region_expand.wl"}]];
ClearAll[RunWeightedBoundaryConditions, SVBWeightedTruncate,
  SVBWeightedBoundaryFromMasters, ComputeWeightedBoundary];
RunWeightedBoundaryConditions[root_, label_, config_, spec_] := Catch[Module[
  {catalog = spec["Catalog"], provided, combined, profile, match = None, factor, id, file, data = <||>, value},
  provided = Lookup[config, "BoundaryData", Automatic];
  If[AssociationQ[provided],
    If[!AllTrue[Select[spec["SeriesProfile"]["Blocks"], #["Kind"] === "Boundary" &],
      KeyExistsQ[provided, #["Name"]] &], Return[Failure["IncompleteBoundaryData", <||>]]];
    Print["[Boundary] Using explicitly supplied boundary expressions."]; Return[Map[Normal, provided]]];
  combined = Total[MapThread[Times, {config["Integrands"], config["Coefficients"]}]];
  profile = spec["Profile"];
  Do[
    If[Lookup[catalog["IdentityAliases"], candidate, candidate] =!= profile, Continue[]];
    factor = Cancel[combined/catalog["Integrands"][candidate]];
    If[MatchQ[factor, _Integer | _Rational], match = candidate; Break[]],
    {candidate, Keys[catalog["Integrands"]]}];
  If[match === None, Return[Failure["BoundaryDataRequired", <|
    "Message" -> "No certified boundary cache matches this integrand. Supply BoundaryData in bootstrapOptions, or compute new boundaries with ComputeWeightedBoundary."|>]]];
  If[match =!= profile, Print["[Boundary] Applying the registered I", match,
    " = I", profile, " identity."]];
  Do[
    file = catalog["BoundaryRecords"][profile][name];
    value = SVBVerifiedRead[root, file, catalog]; If[FailureQ[value], Throw[value, "WeightedBoundary"]];
    AssociateTo[data, name -> Expand[factor Normal[value]]],
    {name, Keys[catalog["BoundaryRecords"][profile]]}];
  Print["[Boundary] Certified graph cache matched I", match, "; normalization factor ", factor, "."];
  data
], "WeightedBoundary"];
SVBWeightedTruncate[expression_, minimum_Integer, order_Integer?NonNegative] := Module[{e, result},
  e = Expand[expression /. Log[u] -> ell];
  result = Sum[u^a Normal[Series[Coefficient[e, u, a], {Y, 0, order-2(a-minimum)}]],
    {a, minimum, minimum+Quotient[order, 2]}];
  Expand[result /. ell -> Log[u]]
];
SVBWeightedBoundaryFromMasters[expression_, masterRules_List, minimum_Integer,
    order_Integer?NonNegative] := Catch[Module[{expanded, terms, parts, m, result},
  expanded = Expand[expression]; terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  parts = Table[
    m = term /. Dispatch[masterRules];
    If[!FreeQ[m, _G | _j], Throw[Failure["UnreducedMaster", <||>], "WeightedMaster"]];
    m = Series[m, {ep, 0, 0}];
    If[Cases[{m}, sd_SeriesData /; sd[[1]] === ep && sd[[5]] <= 0, Infinity] =!= {},
      Throw[Failure["InsufficientEpsilonDepth", <||>], "WeightedMaster"]];
    m = Expand[Normal[m]] /. Log[u] -> ell;
    Normal[Series[m, {u, 0, minimum+Quotient[order, 2]}, {Y, 0, order}]], {term, terms}];
  expanded = Expand[Total[parts]];
  If[expanded =!= 0 && Exponent[expanded, u, Min] < minimum,
    Return[Failure["UnexpectedLeadingPower", <|"Minimum" -> minimum|>]]];
  result = SVBWeightedTruncate[expanded, minimum, order];
  If[!FreeQ[result, ep | _G | _j | _SeriesData | Indeterminate | ComplexInfinity],
    Return[Failure["NonFiniteBoundary", <||>]]]; result
], "WeightedMaster"];
(* Native reconstruction for a new graph/channel. LiteRed and topology bases
   must be initialized as in RunBoundaryConditions. Existing IBP rules are
   reused, and newly reduced rules are kept in this calculation's own folder. *)
ComputeWeightedBoundary[root_, integrand_, permutation_List, loops_List,
    order_Integer, minimum_Integer, outputDirectory_String] := Module[
  {int, expansion, top, top1, top2, products, tensors, grep, groups, transform,
   cache, targets, missing, rules, first, second, expression, masters, result, originalDirectory, reduced},
  If[ExpandFileName[outputDirectory] =!= FileNameJoin[FileNameSplit[outputDirectory]],
    Return[Failure["AbsoluteOutputDirectoryRequired", <||>]]];
  Get[FileNameJoin[{root, "asym", "asym_new.wl"}]];
  If[!DirectoryQ[outputDirectory], CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  int = integrand /. x[a__] :> (x[a] /. Thread[Range[4] -> permutation]);
  expansion = WeightedRegionExpand[int, loops, "order" -> order, "check" -> True, "verbose" -> False];
  If[!FreeQ[expansion, $Failed], Return[Failure["RegionExpansion", <||>]]];
  {top, top1, top2} = expansion[[1]];
  products = Flatten[ToTensorProduct[#, top, top1, top2, "check" -> True] & /@ expansion[[2]], 1];
  tensors = ProjectTensor[products, p, top1, top2, "check" -> True, "dir" -> (outputDirectory <> "/")];
  {grep, groups} = ClassifyGs[tensors, top1];
  transform = Dispatch[Join[grep /. G[a__] :> G[1, {a}], grep /. G[a__] :> G[2, {a}]]];
  cache = FileNameJoin[{root, "asym", "tmp", "targetIntegrals_reduced.m"}];
  rules = If[FileExistsQ[cache], Get[cache], {}];
  targets = DeleteDuplicates[Flatten[Table[group /. G[a__] :>
    j[Switch[Length[{a}], 14, asym, 9, asym3L, 5, asym2L, 2, asym1L], a], {group, groups}]]];
  missing = Complement[targets, Keys[rules]];
  If[missing =!= {},
    originalDirectory = Directory[]; SetDirectory[outputDirectory];
    reduced = CheckAbort[IBPReduce[missing], SetDirectory[originalDirectory]; Abort[]];
    SetDirectory[originalDirectory];
    rules = Join[rules, Thread[missing -> reduced]]];
  Put[Select[rules, MemberQ[targets, First[#]] &], FileNameJoin[{outputDirectory, "reduction_rules.m"}]];
  first = rules /. {j[_, a_List] :> G[1, a], j[_, a__] :> G[1, {a}]} /. d -> 4-2 ep;
  second = first /. {u -> 1, G[1, a_] :> G[2, a]};
  expression = Total[tensors] /. transform /. D -> 4-2 ep;
  expression = Collect[expression /. Dispatch[Join[first, second]], _G] /.
    Dispatch[Get[FileNameJoin[{root, "asym", "asym4LbasisChange.m"}]]];
  masters = Join @@ (Get[FileNameJoin[{root, "asym", #}]] & /@
    {"Gmaterrep4L.m", "Gmaterrep3L.m", "Gmaterrep2L.m", "Gmaterrep1L.m"});
  result = SVBWeightedBoundaryFromMasters[expression, masters, minimum, order];
  If[!FailureQ[result], Put[result, FileNameJoin[{outputDirectory, "boundary.m"}]]]; result
];
