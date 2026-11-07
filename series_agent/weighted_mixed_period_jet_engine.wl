Get[FileNameJoin[{DirectoryName[$InputFileName],"weighted_two_family_jet_engine.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName],"weighted_mixed_period_algebra.wl"}]];
OddPeriodWords[0]:={{}};
OddPeriodWords[n_Integer]/;n>0:=OddPeriodWords[n]=Flatten[Table[
 Prepend[#,k]&/@OddPeriodWords[n-k],{k,Select[{1,3,5,7},#<=n&]}],1];
$MixedPeriodWords=Join@@Table[OddPeriodWords[k],{k,1,8}];
$MixedPeriodIndex=AssociationThread[ToString[#,InputForm]&/@$MixedPeriodWords,Range[Length[$MixedPeriodWords]]];
MixedPeriodTag[e_]:=Module[{expanded=MixedPeriodCanonical[e]},
 If[!FreeQ[expanded,_f|_f3|_f4|_f6|_f12|_f23],Print["Unconverted period"];Abort[]];
 expanded=expanded/.p_f2:>With[{k=Lookup[$MixedPeriodIndex,ToString[List@@p,InputForm],0]},If[k===0,Print["Period word outside weight eight ",p];Abort[],periodTag^k]];
 Expand[expanded/.Pi->pi]];
$MixedJetVariables={u,Y,ell,pi,rho,periodTag};
$JetVariables=$MixedJetVariables;
MixedPrepareRecords[data_]:=Block[{CanonicalConstants},CanonicalConstants[e_]:=MixedPeriodTag[e];PrepareBareRecords[data,"e0",3]];
