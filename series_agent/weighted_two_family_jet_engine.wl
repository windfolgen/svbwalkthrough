(* Coordinate reflection adapter shared by all weighted profiles.
   A reflected input basis is written in w=1-z, wbar=1-zbar. Reflection
   exchanges u,v and changes (z-zbar)^(-pole) by (-1)^pole. It exchanges
   channel j with 7-j; it does not change the ordered expansion convention. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "weighted_higher_jet_engine.wl"}]];
ClearAll[TwoFamilyJetSetup];
TwoFamilyJetSetup[profile_Association, physicalChannel_Integer, sector_Integer,
    regionOrder_Integer : 4] := Module[
  {ls, pole, prefactor, channel, minimum},
  ls = profile["LeadingSingularities"][[sector]];
  pole = If[ls[[1]] === "double", 2, 1];
  prefactor = ls[[2]];
  channel = physicalChannel;
  minimum = profile["MinimumUPowers"][[physicalChannel]];
  If[TrueQ[Lookup[profile, "BasisReflection", False]],
    prefactor = (-1)^pole (prefactor /. {u -> v, v -> u});
    channel = 7-physicalChannel];
  HigherJetSetup[prefactor, channel, pole, minimum, regionOrder]
];
