(* Common level-two period alphabet, using fresh Hyperlog Convert(...,f2).
   Shuffle products are expanded so equivalent period coefficients cannot
   become spurious independent constraints in mixed-letter calculations. *)
ClearAll[PeriodShuffles,MixedPeriodCanonical];
PeriodShuffles[{},b_List]:={b};PeriodShuffles[a_List,{}]:={a};
PeriodShuffles[a_List,b_List]/;(a=!={}&&b=!={}):=PeriodShuffles[a,b]=Join[
 Prepend[#,First[a]]&/@PeriodShuffles[Rest[a],b],
 Prepend[#,First[b]]&/@PeriodShuffles[a,Rest[b]]];
MixedPeriodCanonical[expr_]:=Module[{e,terms},
 e=expr/.{Zeta[n_Integer]:>f[n]};
 e=e/.{f[3,3]->f[3]^2/2,f[3,5]->f[3]f[5]-f[5,3]};
 e=Expand[e/.{f[3]->-4 f2[3]/3,f[5]->-16 f2[5]/15,f[7]->-64 f2[7]/63,
  f[5,3]->64 f2[5,3]/45-22319 Pi^8/96957000}];
 If[e===0,Return[0]];
 terms=If[Head[e]===Plus,List@@e,{e}];
 Expand[Total[Table[Module[{factors,periods={},rest={},words={{}}},
  factors=If[Head[term]===Times,List@@term,{term}];
  Do[Which[Head[fac]===f2,AppendTo[periods,List@@fac],
   Head[fac]===Power&&Head[First[fac]]===f2&&IntegerQ[Last[fac]]&&Last[fac]>=0,
    periods=Join[periods,ConstantArray[List@@First[fac],Last[fac]]],
   True,AppendTo[rest,fac]],{fac,factors}];
  Do[words=Flatten[PeriodShuffles[#,word]&/@words,1],{word,periods}];
  Times@@rest Total[If[#==={},1,f2@@#]&/@words]],{term,terms}]]]];
