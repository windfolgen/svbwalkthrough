(* Common ordered-series readers and exact period/monomial conversion.
   Prefactors and retained powers are supplied by a data profile; this file
   makes no choice based on the identity of an integral. *)
ClearAll[ReadMapleList,CanonicalConstants,PrepareBareRecords,JetRules];
ReadMapleList[path_]:=Module[{s=StringTrim[Import[path,"Text"]]},
 If[StringStartsQ[s,"["],ToExpression["{"<>StringTake[s,{2,-2}]<>"}"],ToExpression[s]]];
(* Level-two periods occur in reflected reciprocal-letter jets. These exact
   conversions were independently checked with Hyperlog Convert(...,f). *)
CanonicalConstants[e_]:=(e/.{f2[3]->-3 f[3]/4,f2[5]->-15 f[5]/16,f2[7]->-63 f[7]/64,f2[3,3]->9 f[3,3]/16})/.{f[3,3]->q3^2/2,f[3,5]->q3 q5-q53,f[3]->q3,f[5]->q5,f[7]->q7,f[5,3]->q53,Zeta[3]->q3,Zeta[5]->q5,Zeta[7]->q7,Pi->pi};
PrepareBareRecords[exprs_,ext_,maxT_:1]:=Module[{converted,rec,c,cr,hcr,a,minT},
 Table[
  converted=CanonicalConstants[exprs[[i]]];
  converted=Switch[ext,
   "e0",converted/.I[z,0,0]->h/.{z->s,zz->t},
   "e1",converted/.I[z,1,0]->h/.{z->s+1,zz->t+1},
   "einf",converted/.{P[0]->-h,I[z,0,0]->-h}/.{z->1/s,zz->1/t}];
  If[!FreeQ[converted,_I|_P|_f],Print["Unresolved functions in bare record ",ext," ",i];Abort[]];
  minT=Exponent[converted,t,Min];
  If[minT<0,Print["Negative small-coordinate power at ",ext," ",i,": ",minT];Abort[]];
  rec=Reap[Do[
   c=Expand[Coefficient[converted,t,b] s^16];
   cr=CoefficientRules[c,{s}];
   Do[a=rule[[1,1]]-16;hcr=CoefficientRules[Expand[Last[rule]],{h}];
    Do[Sow[{{a,b,hr[[1,1]]},Last[hr]}],{hr,hcr}],{rule,cr}],{b,0,maxT}]][[2]];
  If[Mod[i,200]==0,Print[ext," parsed ",i,"/",Length[exprs]]];
  If[rec==={},{},First[rec]],
  {i,Length[exprs]}]];

$JetVariables={u,Y,ell,q3,q5,q7,q53,pi};
$JetShift=u^2 Y^16;
JetRules[e_]:=Module[{rules=CoefficientRules[Expand[$JetShift e],$JetVariables]},
 If[!AllTrue[Last/@rules,MatchQ[#,_Integer|_Rational]&],Print["Non-rational jet coefficient: ",Short[Select[Last/@rules,!MatchQ[#,_Integer|_Rational]&],2]];Abort[]];rules];
