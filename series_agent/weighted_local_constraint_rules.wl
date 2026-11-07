(* Collect transcendental monomials before clearing the rational denominator.
   The clearing factor depends only on zz, so this commutes exactly with
   coefficient extraction in the other variables and the retained projection. *)
ClearAll[ClearedLocalRules];
ClearedLocalRules[e_,variables_List,denominator_,keep_]:=Module[
 {rationalPosition,transcendentalVariables,terms,output,poly,zzRules},
 rationalPosition=First@FirstPosition[variables,zz];
 transcendentalVariables=Delete[variables,rationalPosition];
 If[!PolynomialQ[e,transcendentalVariables],Print["Nonpolynomial local expansion"];Abort[]];
 terms=Select[CoefficientRules[Expand[e],transcendentalVariables],TrueQ[keep[First[#]]]&];
 output=Reap[Do[
  poly=Cancel[denominator Last[term]];
  If[!PolynomialQ[poly,zz],Print["Uncleared local denominator"];Abort[]];
  zzRules=CoefficientRules[Expand[poly],{zz}];
  If[!AllTrue[Last/@zzRules,MatchQ[#,_Integer|_Rational]&],Print["Nonrational local coefficient"];Abort[]];
  Do[Sow[Insert[First[term],First[First[r]],rationalPosition]->Last[r]],{r,zzRules}],{term,terms}]][[2]];
 If[output==={},{},First[output]]];
