$HistoryLength=0;
root=ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]];
Get[FileNameJoin[{root,"input_parser.wl"}]];
cfg=ParseInput[FileNameJoin[{root,"runs","fourloopI163"}]];
nums=Get[FileNameJoin[{root,"runs","fourloopI163","result.m"}]];
ls=(#[[2]]/(z-zz)^If[#[[1]]==="double",2,1]&)/@cfg["LeadingSingularities"];
assembled=ls.nums/.{u->z zz,v->(1-z)(1-zz)};
expected=Get[FileNameJoin[{root,"tests","bootstrap","fixtures","I163_six_image_result.m"}]];
(* Compare rational coefficients of formal MPL/period monomials separately,
   without constructing one enormous common symbolic denominator. *)
parts[expr_]:=Module[{e=Expand[expr],terms,fac,pairs},
 terms=If[Head[e]===Plus,List@@e,{e}];
 pairs=Table[fac=If[Head[t]===Times,List@@t,{t}];
  {ToString[Times@@Select[fac,!FreeQ[#,_I|_f|_f2]&],InputForm],Times@@Select[fac,FreeQ[#,_I|_f|_f2]&]}, {t,terms}];
 GroupBy[pairs,First->Last,Total]];
a=parts[assembled];b=parts[expected];keys=Union[Keys[a],Keys[b]];
Print["Checking ",Length[keys]," formal monomial coefficients"];
ok=AllTrue[MapThread[Together[#1-#2]===0&,{Lookup[a,keys,0],Lookup[b,keys,0]}],TrueQ];
point=Get[FileNameJoin[{root,"runs","fourloopI163","generator_coeff_sol.m"}]];
reference=Get[FileNameJoin[{root,"tests","bootstrap","fixtures","I163_generators.m"}]];
report=<|"PureNumeratorAssemblyMatchesSixImageResult"->ok,"GeneratorCoefficientsMatch"->(point===reference),"NumeratorPieces"->Length[nums]|>;
Print[report];Export[FileNameJoin[{DirectoryName[$InputFileName],"assembly_validation.json"}],report,"RawJSON"];
Exit[If[And@@(TrueQ/@Values[KeyDrop[report,"NumeratorPieces"]]),0,1]];
