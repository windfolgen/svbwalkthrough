(* Compare the general producer against frozen pre-refactor coefficients in
   every channel; also exercise a new prefactor beyond the former N6 limit. *)
$HistoryLength = 0;
package = ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
Get[FileNameJoin[{package,"series_agent","weighted_series.wl"}]];
catalog = SVBWeightedCatalog[package];
reference = Get[FileNameJoin[{DirectoryName[$InputFileName],"fixtures","weighted_jet_reference.m"}]];
checks = <||>;
Do[
  setup = TwoFamilyJetSetup[catalog["Profiles"][entry["Profile"]],
    entry["Channel"], entry["Sector"], entry["Order"]];
  actual = HigherJetPhi @@ # & /@ entry["Atoms"];
  name = StringRiffle[ToString /@ Lookup[entry,{"Profile","Channel","Sector","Order"}],"_"];
  AssociateTo[checks, name -> (!FailureQ[setup] &&
    AllTrue[Expand[actual-entry["Expected"]], # === 0 &])];
  Print[name,": ",checks[name]], {entry,reference}];
(* With prefactor u^2(1-v)/(z-zbar), the constant bare function has a
   simple exact generating expression. This is independent of any graph. *)
setup = HigherJetSetup[u^2(1-v),1,1,2,8];
actual = HigherJetPhi[0,0,0];
expected = Sum[u^(2+r) Normal[Series[
  SeriesCoefficient[(1+2(Y-2)u/Y^2+u^2/Y^2)^(-1/2),{u,0,r}],
  {Y,0,8-2r}]], {r,0,4}];
AssociateTo[checks,"NewPrefactorOrderEight" ->
  (!FailureQ[setup] && Expand[actual-expected] === 0)];
AssociateTo[checks,"IncorrectLeadingPowerRejected" ->
  FailureQ[HigherJetSetup[1/u,1,1,0,6]]];
Export[FileNameJoin[{DirectoryName[$InputFileName],"weighted_jets_validation.json"}],checks,"RawJSON"];
Print[checks]; Exit[If[And@@Values[checks],0,1]];
