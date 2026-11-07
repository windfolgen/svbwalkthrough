(* Data-driven constrained profiles: independent boundaries, homogeneous
   local conditions and a certified whole-function redundancy space. *)
ClearAll[SVBLoadConstraintProfile, SVBProfileBlocks];
SVBLoadConstraintProfile[root_, config_] := Module[{path, profile, data, actual},
  path = Lookup[config, "ConstraintProfile", None];
  If[!StringQ[path] || !FileExistsQ[FileNameJoin[{root, path}]],
    Return[Failure["ConstraintProfileRequired", <||>]]];
  profile = Get[FileNameJoin[{root, path}]];
  If[!AssociationQ[profile] || !AllTrue[
      {"Name", "OrbitData", "Integrand", "MaximumOrder", "MinimumUPower", "KeyShift",
       "MonomialShift", "Variables", "PeriodTagger", "NullDirections", "NullCertificate",
       "Qualification", "Blocks", "Hashes"}, KeyExistsQ[profile, #] &],
    Return[Failure["InvalidConstraintProfile", <||>]]];
  If[!AssociationQ[profile["Hashes"]] || !ListQ[profile["Blocks"]] ||
      !AllTrue[profile["Blocks"], Function[entry, AssociationQ[entry] &&
        AllTrue[{"Name","Kind","Order","File"}, KeyExistsQ[entry,#] &] &&
        MemberQ[{"Boundary","Homogeneous"}, entry["Kind"]] && IntegerQ[entry["Order"]] &&
        (entry["Kind"] =!= "Boundary" || KeyExistsQ[entry, "BoundaryFile"])]],
    Return[Failure["InvalidConstraintBlocks", <||>]]];
  data = SVBVerifiedRead[root, profile["OrbitData"], profile];
  If[FailureQ[data], Return[data]];
  actual = config["LeadingSingularities"] /. I0constant -> 1;
  If[actual =!= data["LeadingSingularities"],
    Return[Failure["ConstraintBasisMismatch", <|
      "Message" -> "The supplied basis must match this profile's ordered orbit basis. Supply a new profile for a changed basis."|>]]];
  Join[profile, <|"ParameterMap" -> data["ParameterMap"]|>]
];
SVBProfileBlocks[root_, config_, profile_, requested_Integer] := Catch[Module[
  {blocks = {}, packet, selected, keys, matrix, boundary, provided, factor, combined,
   name, block, gauge, null, n},
  If[requested < 0 || requested > profile["MaximumOrder"],
    Throw[Failure["SeriesDepthUnavailable", <|"RequestedOrder" -> requested|>], "Profile"]];
  provided = Lookup[config, "BoundaryData", Automatic];
  combined = Total[MapThread[Times, {config["Integrands"], config["Coefficients"]}]];
  factor = Cancel[combined/profile["Integrand"]];
  If[!AssociationQ[provided] && !MatchQ[factor, _Integer | _Rational],
    Throw[Failure["BoundaryDataRequired", <||>], "Profile"]];
  Do[
    If[entry["Order"] > requested, Continue[]];
    name = entry["Name"];
    packet = SVBVerifiedRead[root, entry["File"], profile];
    If[FailureQ[packet], Throw[packet, "Profile"]];
    If[entry["Kind"] === "Boundary",
      keys = packet["Keys"]; matrix = packet["Matrix"];
      selected = Select[Range[Length[keys]], With[
        {a = keys[[#, 1]] - profile["KeyShift"][[1]], b = keys[[#, 2]] - profile["KeyShift"][[2]]},
        profile["MinimumUPower"] <= a <= profile["MinimumUPower"] + Quotient[entry["Order"], 2] &&
          b <= entry["Order"] - 2 (a-profile["MinimumUPower"])] &];
      boundary = If[AssociationQ[provided], Lookup[provided, name, Missing["Boundary"]],
        SVBVerifiedRead[root, entry["BoundaryFile"], profile]];
      If[MissingQ[boundary], Throw[Failure["IncompleteBoundaryData", <|"Stage" -> name|>], "Profile"]];
      If[FailureQ[boundary], Throw[boundary, "Profile"]];
      If[!AssociationQ[provided], boundary = factor boundary];
      block = SVBBoundaryBlock[name, matrix[[selected]], keys[[selected]], boundary,
        profile["Variables"], profile["MonomialShift"], profile["PeriodTagger"]],
      matrix = packet["Matrix"];
      block = SVBConstraintBlock[name, matrix, ConstantArray[0, First[Dimensions[matrix]]]]
    ];
    If[FailureQ[block], Throw[block, "Profile"]]; AppendTo[blocks, block],
    {entry, profile["Blocks"]}];
  null = SVBVerifiedRead[root, profile["NullDirections"], profile];
  If[FailureQ[null], Throw[null, "Profile"]];
  gauge = SVBZeroGeneratorGauge[null, blocks];
  If[FailureQ[gauge], Throw[gauge, "Profile"]];
  Prepend[blocks, gauge]
], "Profile"];
