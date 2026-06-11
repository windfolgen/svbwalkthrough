(* ::Package:: *)

directory=If[$FrontEnd===Null,$InputFileName,NotebookFileName[]]//DirectoryName;
Get[FileNameJoin[{directory,"Calcloop/CalcLoop.wl"}]];
SetOptions[FeynArtsReadAmp,"ExternalMomentumName"->(Symbol["p"<>ToString@#]&)];


(*an interface to the package Calcloop, to calculate the tensor reduction only*)
ClearAll[ListToTensor];
Options[ListToTensor]={"krep"->{}};
(*the input indexlist should be in the form {{vc[a,m[1]],vc[a,m[2]]},{vc[b,m[3]],vc[b,m[4]],vc[b,m[5]]},{...},...}*)
ListToTensor[indexlist_,tagp_,OptionsPattern[]]:=Module[{uVal,lvar,ivar,rep,tmp,result,exp},
uVal = d2[1, tagp] /. OptionValue["krep"];
Pair[Momentum[tagp],Momentum[tagp]]=uVal;(*kinematics*)
lvar=ToExpression[("l"<>ToString[#])&/@Range[Length[indexlist]]];(*loop variables*)
ivar=ToExpression[("m"<>ToString[#])&/@Range[Length[indexlist//Flatten]]]//TakeList[#,Length/@indexlist]&;(*index variables*)
rep=Join[Thread@Rule[lvar,(indexlist[[All,1]])/.{vc[a_, b_] :> a}//Flatten](*replacement for loop variables*),Thread@Rule[ivar,indexlist/.{vc[a_, b_] :> b}//Flatten](*replacement for indices*)];
exp=Product[Times@@(LV[lvar[[i]],#]&/@ivar[[i]]),{i,1,Length[lvar]}];(*expressions to be reduced*)
tmp=(TensorDecomposition[lvar,{tagp},exp//CLForm]);

(*then we transform the expression back to symbols in our package*)
tmp=tmp/.{Pair[Momentum[a_],Momentum[b_]]:>d[a,b],Pair[LorentzIndex[a_],Momentum[b_]]:>vc[b,a]}/.rep; (*Now we should recover expressions in our notation*)
result=tmp/.OptionValue["krep"]//Collect[#,_Subscript,Together]&;
Return[result];
];
