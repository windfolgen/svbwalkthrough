(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


DiracSimplify::"usage"="DiracSimplify[exp] calculates traces of Dirac matrices \
and simplifies multiplicaitons of Dirac gamma matrices.
Options[\"Gamma5Scheme\"] determines the scheme of \!\(\*SuperscriptBox[\(\[Gamma]\), \(5\)]\) in \
general spacetime dimention. \
Currently only \"NDR\" is implemented.";


DiracGamma::"usage"="DiracGamma[LorentzIndex[\[Mu]]] is Dirac gamma \
matrix \!\(\*SuperscriptBox[\(\[Gamma]\), \(\[Mu]\)]\). 
DiracGamma[Momentum[p]] is \!\(\*SubscriptBox[\(p\), \(\[Mu]\)]\)\!\(\*SuperscriptBox[\(\[Gamma]\), \(\[Mu]\)]\).
DiracGamma[5] is \!\(\*SuperscriptBox[\(\[Gamma]\), \(5\)]\).";

DiracSpinor::"usage"="DiracSpinor[{mom,x},m] denotes Dirac spinor of (anti-)fermion \
with momentum mom and mass m.
x=1 for fermion, and x=-1 for antifermion. ";

DiracChain::"usage"="DiracChain[_DiracSpinor,x___,_DiracSpinor] denotes \
Dirac spinor chain with Dirac gamma matrices 'x' inserted.
DiracChain[0,x___,0] denotes trace of Dirac gamma matrices.
DiracChain[x___] denotes noncommunitive multiplication of Dirac gamma matrices.
A special case is DiracChain[__,0,__]=0.";


Begin["`Private`"];
$DiracFunctions={DiracGamma,DiracSpinor,DiracChain};
diracChainExpand;
diracChainExpandQ
End[];


Begin["`DiracSimplify`"];


(* ::Section::Closed:: *)
(*Typesetting*)


DiracGamma/:MakeBoxes[DiracGamma[a_LorentzIndex],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox["\[Gamma]",TDBox[a]];
DiracGamma/:MakeBoxes[DiracGamma[a_Momentum],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox["\[Gamma]",TDBox[a]];
DiracGamma/:MakeBoxes[DiracGamma[5],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox["\[Gamma]","5"];

DiracChain/:MakeBoxes[DiracChain[DiracSpinor[x1_,s1_],g___,DiracSpinor[x2_,s2_]],f_]/;MemberQ[$CLDefinedForm,f]:=
	RowBox[{RowBox[{SubscriptBox[OverscriptBox[If[x1[[2]]===-1,"v","u"],"_"],TDBox[s1]],"(",TDBox[x1[[1]]],")"}],
If[{g}==={},".",TDBox[Dot["",g,""]]],
RowBox[{SubscriptBox[If[x2[[2]]===-1,"v","u"],TDBox[s2]],"(",TDBox[x2[[1]]],")"}]}//Flatten];
DiracChain/:MakeBoxes[DiracChain[0,a__,0],f_]/;MemberQ[$CLDefinedForm,f]:=RowBox[{"Tr(",TDBox[Dot[a]],")"}];
DiracChain/:MakeBoxes[DiracChain[x__/;{x}[[1]]=!=0&&Head@{x}[[1]]=!=DiracSpinor],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[Dot[x]];
DiracChain/:MakeBoxes[DiracChain[],f_]/;MemberQ[$CLDefinedForm,f]:=SubscriptBox["1","Dirac"];


(* ::Section::Closed:: *)
(*DiracSimplify*)


Attributes[DiracSimplify]={Listable};
Options[DiracSimplify]={"Gamma5Scheme"->"Anti-Commutative","OrderQ"->False};
DiracSimplify[exp_,opt:OptionsPattern[]]:=Module[
	{head,temp,scheme,res,factor,cluster,left,right,pJoin,pBack,p},
	
	If[FreeQ[exp,DiracChain],Return[exp,Module]];
	
	If[MatchQ[exp,DiracChain[]^(_:1)],Return[exp,Module]];
	
	head=Head@exp;
	
	(*Deal with a*a*... one by one*)
	If[head===Power,
		If[IntegerQ@exp[[2]]&&exp[[2]]>1,
			temp=DiracSimplify[exp[[1]],opt]*exp[[1]]^(exp[[2]]-1);
			DiracSimplify[LorentzSimplify@temp,opt]//Return
		]
	];
	
	(*when Lorentz contraction is impossible*)
	If[head=!=Times&&head=!=DiracChain,
		head@@DiracSimplify[List@@exp,opt]//Return
	];
	
	If[head===Times,
		factor=Select[exp,FreeQ[#,DiracChain]&];
		If[factor=!=1,factor*DiracSimplify[exp/factor,opt]//Return];
		
		(*cluster terms with Lorentz indexes contracted, if possible*)
		temp=List@@exp;
		cluster=findTensorIndex@temp;
		cluster=clusterTensorIndex[cluster];
		If[Length@cluster>1, Times@@(DiracSimplify[Times@@temp[[#]],opt]&/@cluster)//Return];
		
		(*Find the term with shortest gamma chain*)
		temp=SortBy[temp,Max[Length/@Cases[#,_DiracChain,Infinity]]&];
		
		temp=DiracSimplify[temp[[1]],opt]*Times@@temp[[2;;-1]];
		
		temp=temp//LorentzSimplify;
		
		temp=DiracSimplify[temp,opt];
		Return[temp];
	];
	
	(*For head===DiracChain*)
	temp=exp//.DiracChain[a___,DiracChain[b___],c___]:>DiracChain[a,b,c];
	If[Head@temp[[1]]=!=DiracSpinor&&!FreeQ[temp[[1]],DiracSpinor]||Head@temp[[-1]]=!=DiracSpinor&&!FreeQ[temp[[-1]],DiracSpinor],
		ErrorPrint["Unknown structure for DiracSimplify: ",{temp[[1]],temp[[-1]]}];
		Return[temp];
	];
	temp=Expand//@temp;
	
	(*change all Dirac chains to standard form: spinor...spinor or 0...0*)
	If[Head@temp[[1]]=!=DiracSpinor&&temp[[1]]=!=0,PrependTo[temp,DiracSpinor[{left,1},left]]];
	If[Head@temp[[-1]]=!=DiracSpinor&&temp[[-1]]=!=0,AppendTo[temp,DiracSpinor[{right,1},right]]];
	(*only one zero*)
	If[Head@temp[[1]]=!=Head@temp[[-1]],Return[0]];		
		
	(*Replace something like q1+q2 in DiracSpinor by p1, so that Dirac equations can be easily used*)
	pJoin=Cases[{temp[[1]],temp[[-1]]},_DiracSpinor,Infinity]/.DiracSpinor[{p_,_},_]:>p;
	pBack=Thread[Array[p,Length@pJoin]->pJoin];
	pJoin=Reduce[pBack/.Rule->Equal,Variables@pJoin];
	pJoin=If[pJoin===True,{},{pJoin}/.Equal->Rule/.And->List//Flatten];
	pJoin=If[Head@#[[2]]===p,#[[2]]->#[[1]],#[[1]]->#[[2]]]&/@pJoin;
	pJoin[[All,2]]=pJoin[[All,2]]/.pJoin;
	temp=temp/.pJoin;
	
	(*Expand momentum if open Dirac chain exists*)	
	If[temp[[1]]=!=0,temp=MomentumSimplify@temp];
	

	scheme=Switch[OptionValue["Gamma5Scheme"],
		"Anti-Commutative", anticommutative,
		_,cyclic
	];
	
	(*Move \[Gamma]^5 to the leftmost, if possible*)
	temp=temp/.DiracChain:>diracChainExpand/.diracChainExpand:>scheme/.scheme:>zero/.
		zero:>DiracChain;
	
	(*For sameDirac: Not efficient right now.*)
	(*temp=sameDirac[temp];*)

	temp=diracAlgebra[temp,"Gamma5Scheme"->OptionValue["Gamma5Scheme"],"OrderQ"->OptionValue["OrderQ"]];


	temp=temp//diracTrace;
	
	(*change back to original form*)
	temp=temp/.DiracChain[DiracSpinor[{left,1},left],x___]:>DiracChain[x]/.
		DiracChain[x___,DiracSpinor[{right,1},right]]:>DiracChain[x]/.pBack;

	Return[temp];
];


(* ::Section::Closed:: *)
(*diracChainExpand*)


diracChainExpandQ=diracChainExpand|DiracGamma|DiracSpinor;

(*Flatten DiracChain*)
diracChainExpand[a__,diracChainExpand[b___],c__]:=diracChainExpand[a,b,c];

(*Extract constant factor*)
diracChainExpand[a__,b1_*b2_,c__]/;FreeQ[b1,diracChainExpandQ]:=
	b1*diracChainExpand[a,b2,c];
diracChainExpand[a__,b_,c__]/;FreeQ[b,diracChainExpandQ]:=b*diracChainExpand[a,c];

(*Expand Plus*)
diracChainExpand[a__,b1_+b2_,c__]/;
	!FreeQ[b2,diracChainExpandQ]&&FreeQ[b1,diracChainExpandQ]:=
	b1*diracChainExpand[a,c]+diracChainExpand[a,b2,c];
diracChainExpand[a__,b1_+b2_,c__]/;
	!FreeQ[b2,diracChainExpandQ]&&!FreeQ[b1,diracChainExpandQ]:=
	diracChainExpand[a,b1,c]+diracChainExpand[a,b2,c];


(* ::Section::Closed:: *)
(*zero*)


	(*****judge zero*****)
zero[0,a__,0]/;FreeQ[{a},DiracGamma[5]]&&OddQ[Length@{a}]:=0;
zero[0,DiracGamma[5],a__,0]/;FreeQ[{a},DiracGamma[5]]&&OddQ[Length@{a}]:=0;


(* ::Section::Closed:: *)
(*gamma5 Schemes*)


	(********************Anti-commutative Gamma5 Scheme*******************)
	(*remove pair of gamma5*)
	anticommutative[sp1__,DiracGamma[5],x___/;FreeQ[{x},DiracGamma[5]],DiracGamma[5],sp2__]:=
		anticommutative[sp1,Sequence@@({x}/.a_DiracGamma:>-a),sp2];
	
	(*move gamma5 to the left most*)
	anticommutative[sp_,x__,DiracGamma[5],y___]/;FreeQ[{x},DiracGamma[5]]:=
		anticommutative[sp,DiracGamma[5],Sequence@@({x}/.a_DiracGamma:>-a),y];
		
	anticommutative[x___,-1*a_DiracGamma,y___]:=-anticommutative[x,a,y];
	(***************************End****************************)


	(********************Cyclic*******************)
	(*Using it if there is only one \[Gamma]^5 in the chain*)
	cyclic[0,x__,DiracGamma[5],y___,0]/;FreeQ[{x,y},DiracGamma[5]]:=cyclic[0,DiracGamma[5],y,x,0];
	(***************************End****************************)


(* ::Section::Closed:: *)
(*fourDimRelations (not used)*)


(*Chisholm[exp_,d_]:=DiracSimplify[exp,Gamma5Scheme->NaiveScheme,Chisholm2->False]/.
	DiracChain[x1___,DiracGamma[a_],DiracGamma[b_],DiracGamma[c_],x2___]/;a=!=5:>
		Pair[a,b]DiracChain[x1,DiracGamma[c],x2]-Pair[a,c]DiracChain[x1,DiracGamma[b],x2]+
		Pair[b,c]DiracChain[x1,DiracGamma[a],x2]-I*Eps[a,b,c,LorentzIndex[d]]*
		DiracSimplify[DiracChain[x1,GA[5],GA[d],x2],Gamma5Scheme->NaiveScheme,Chisholm2->False];
		*)


(* ::Input:: *)
(*(*Chisholm[exp_]:=DiracSimplify[exp,Gamma5Scheme\[Rule]NaiveScheme,Chisholm2\[Rule]False]//.DiracChain[x1___,DiracGamma[a_],DiracGamma[b_],DiracGamma[c_],x2___]/;a=!=5\[RuleDelayed]Module[{d},(DiracSimplify[DiracChain[x1,Pair[a,b] DiracGamma[c]-Pair[a,c] DiracGamma[b]+Pair[b,c] DiracGamma[a]+I*Eps[a,b,c,LorentzIndex[d]]/OptionValue[Eps,PreFactor]*DiracChain[GA[d],GA[5]],x2],Gamma5Scheme\[Rule]NaiveScheme,Chisholm2\[Rule]False])];*)*)
(*(**)
(*GA[\[Mu]1,\[Mu]2,\[Mu]3,\[Mu]4,\[Mu]5]//Chisholm//Contract//Expand;*)
(*sim=DiracSimplify[%/.DiracGamma[5]\[RuleDelayed]Module[{a,b,c,d},-I/24 Eps[LorentzIndex[a],LorentzIndex[b],LorentzIndex[c],LorentzIndex[d]]/OptionValue[Eps,PreFactor]*DiracChain[GA[a,b,c,d]]]//DiracSimplify//Contract,Order\[Rule]True]//Expand;*)
(**)
(*sol=Solve[sim\[Equal]GA[\[Mu]1,\[Mu]2,\[Mu]3,\[Mu]4,\[Mu]5],DiracChain[DiracGamma[LorentzIndex[\[Mu]1]],DiracGamma[LorentzIndex[\[Mu]2]],DiracGamma[LorentzIndex[\[Mu]3]],DiracGamma[LorentzIndex[\[Mu]4]],DiracGamma[LorentzIndex[\[Mu]5]]]];*)
(**)
(*Plus@@Apply[Times,SimplifyList[sol[[1,1,2]],DiracChain],{1}]/.LorentzIndex\[RuleDelayed]Identity/.DiracChain[r__]\[RuleDelayed]DiracChain[x,r,y]//StandardForm;*)
(**)
(*1001.4006:(2.21)*)
(**)*)


(*Chisholm2[exp_]:=DiracSimplify[exp,Gamma5Scheme->NaiveScheme,Chisholm2->False]//.
	DiracChain[x___,DiracGamma[\[Mu]1_],DiracGamma[\[Mu]2_],DiracGamma[\[Mu]3_],
		DiracGamma[\[Mu]4_],DiracGamma[\[Mu]5_],y___]/;\[Mu]1=!=5:> 
	Pair[\[Mu]1,\[Mu]2]DiracChain[x,DiracGamma[\[Mu]3],DiracGamma[\[Mu]4],DiracGamma[\[Mu]5],y]-
	Pair[\[Mu]1,\[Mu]3]DiracChain[x,DiracGamma[\[Mu]2],DiracGamma[\[Mu]4],DiracGamma[\[Mu]5],y] +
	Pair[\[Mu]1,\[Mu]4]DiracChain[x,DiracGamma[\[Mu]2],DiracGamma[\[Mu]3],DiracGamma[\[Mu]5],y] -
	Pair[\[Mu]1,\[Mu]5]DiracChain[x,DiracGamma[\[Mu]2],DiracGamma[\[Mu]3],DiracGamma[\[Mu]4],y] +
	Pair[\[Mu]2,\[Mu]3]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]4],DiracGamma[\[Mu]5],y] -
	Pair[\[Mu]2,\[Mu]4]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]3],DiracGamma[\[Mu]5],y] +
	Pair[\[Mu]2,\[Mu]5]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]3],DiracGamma[\[Mu]4],y] +
	Pair[\[Mu]3,\[Mu]4]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]2],DiracGamma[\[Mu]5],y] +
	Pair[\[Mu]3,\[Mu]5]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]2],DiracGamma[\[Mu]4],y] +
	Pair[\[Mu]4,\[Mu]5]DiracChain[x,DiracGamma[\[Mu]1],DiracGamma[\[Mu]2],DiracGamma[\[Mu]3],y] +
	(-Pair[\[Mu]1,\[Mu]2] Pair[\[Mu]3,\[Mu]4]+Pair[\[Mu]1,\[Mu]3] Pair[\[Mu]2,\[Mu]4]-Pair[\[Mu]1,\[Mu]4] Pair[\[Mu]2,\[Mu]3])*
		DiracChain[x,DiracGamma[\[Mu]5],y] -
	(+Pair[\[Mu]1,\[Mu]2] Pair[\[Mu]3,\[Mu]5]-Pair[\[Mu]1,\[Mu]3] Pair[\[Mu]2,\[Mu]5]+Pair[\[Mu]1,\[Mu]5] Pair[\[Mu]2,\[Mu]3])*
		DiracChain[x,DiracGamma[\[Mu]4],y] +
	(-Pair[\[Mu]1,\[Mu]2] Pair[\[Mu]4,\[Mu]5]+Pair[\[Mu]1,\[Mu]4] Pair[\[Mu]2,\[Mu]5]-Pair[\[Mu]1,\[Mu]5] Pair[\[Mu]2,\[Mu]4])*
		DiracChain[x,DiracGamma[\[Mu]3],y] +
	(+Pair[\[Mu]1,\[Mu]3] Pair[\[Mu]4,\[Mu]5]-Pair[\[Mu]1,\[Mu]4] Pair[\[Mu]3,\[Mu]5]+Pair[\[Mu]1,\[Mu]5] Pair[\[Mu]3,\[Mu]4])*
		DiracChain[x,DiracGamma[\[Mu]2],y] +
	(-Pair[\[Mu]2,\[Mu]3] Pair[\[Mu]4,\[Mu]5]+Pair[\[Mu]2,\[Mu]4] Pair[\[Mu]3,\[Mu]5]-Pair[\[Mu]2,\[Mu]5] Pair[\[Mu]3,\[Mu]4])*
		DiracChain[x,DiracGamma[\[Mu]1],y] ;*)


(* ::Section::Closed:: *)
(*sameDirac (not used)*)


(*Remove pairs of Dirac gamma matrixes*)
Attributes[sameDirac]={Listable};
sameDirac[exp_,opt:OptionsPattern[]]:=Module[
	{cluster,i,j,temp,res},
	
	If[FreeQ[exp,DiracChain],Return[exp]];
	
	If[Head@exp=!=DiracChain, (Head@exp)@@sameDirac[List@@exp,opt]//Return];
	
	temp=List@@exp;
	{i,j}={0,Length@temp};
	
	(*Find nearest lorentz index*)
	cluster=findTensorIndex@temp;
	cluster=clusterTensorIndex[cluster];
	cluster=Sort/@Select[cluster,Length@#===2&];
	If[Length@cluster>0,
		(*cluster=SortBy[cluster,Min[#[[2]]-#[[1]],Length@exp-(#[[2]]-#[[1]])]&];*)
		cluster=SortBy[cluster,#[[2]]-#[[1]]&];
		{i,j}=cluster[[1]];		
	];
	
	(*Find nearest momentum*)
	cluster=Cases[{#},DiracGamma[_Momentum],Infinity]&/@temp;
	cluster=clusterTensorIndex[cluster];
	cluster=Sort/@Select[cluster,Length@#===2&];
	If[Length@cluster>0,
		cluster=SortBy[cluster,#[[2]]-#[[1]]&];
		If[cluster[[1,2]]-cluster[[1,1]]<j-i,{i,j}=cluster[[1]]];		
	];
	
	If[i=!=0,
		res=diracAlgebra[exp[[i;;j]],opt];
		res=Separate[res,_DiracChain];
		res[[1]]=SimplifyList[res[[1]],_Pair,"Factoring"->Expand];
		res[[2]]=(DiracChain@@Flatten@{temp[[1;;(i-1)]],List@@#,temp[[j+1;;-1]]}&/@res[[2]]);
		res=Dot@@res//LorentzSimplify;
		SimplifyList[sameDirac[res,opt],_DiracChain,"Factoring"->(SimplifyList[#,_Pair,"Factoring"->Expand]&)]//Return
	];	
	exp
];


(* ::Section::Closed:: *)
(*diracAlgebra*)


Options[diracAlgebra]={"Gamma5Scheme"->"Anti-Commutative","OrderQ"->False,"ExpandQ"->False};


diracAlgebra[exp_,OptionsPattern[]]:=Module[
	{i,j,k,x,y,z,temp,tr1,tr2,scheme,sameLorentz,
	sameMomentum,diracEquation,orderMomentum,rotation=False},
	
	(*****Contract two same LorentzIndex*****)
	sameLorentz[x__,a_,a_,y__]:=Pair[a[[1]],a[[1]]]sameLorentz[x,y];
	
	sameLorentz[x__,a_,z_,a_,y__]/;FreeQ[{z},DiracGamma[5]]:=If[!FreeQ[a,LorentzIndex],
		(2-$D)sameLorentz[x,z,y],
		LorentzSimplify@(2Pair[a[[1]],z[[1]]]sameLorentz[x,a,y])-
			Pair[a[[1]],a[[1]]]sameLorentz[x,z,y]
		];
	
	sameLorentz[x__,a_,z1_,z2_,a_,y__]/;!FreeQ[a,LorentzIndex]&&z1=!=z2&&FreeQ[{z1,z2},DiracGamma[5]]:=
		4*Which[
			Head[z1[[1]]]===LorentzIndex&&!FreeQ[{x,y},z1[[1]]],
			sameLorentz[Sequence@@({x,y}/.z1[[1]]:>z2[[1]])],
			
			Head[z2[[1]]]===LorentzIndex&&!FreeQ[{x,y},z2[[1]]],
			sameLorentz[Sequence@@({x,y}/.z2[[1]]:>z1[[1]])],
			
			True,Pair[z1[[1]],z2[[1]]]sameLorentz[x,y]]+
		($D-4)sameLorentz@@Flatten[{x,z1,z2,y}];
	
	sameLorentz[x__,a_,z__,a_,y__]/;!FreeQ[a,LorentzIndex]&&FreeQ[{z},DiracGamma[5]]&&
		Length[{z}]>2&&Mod[Length[{z}],2]===1&&($D===4||Length[{z}]<5):=
		-2sameLorentz[x,Sequence@@Reverse[{z}],y]-($D-4)sameLorentz[x,z,y];
	
	sameLorentz[x__,a_,z__,a_,y__]/;!FreeQ[a,LorentzIndex]&&FreeQ[{z},DiracGamma[5]]&&
		Length[{z}]>2&&Mod[Length[{z}],2]===0&&($D===4||Length[{z}]<5):=
		2sameLorentz[x,{z}[[-1]],Sequence@@{z}[[1;;-2]],y]+
		2sameLorentz[x,Sequence@@Reverse@{z}[[1;;-2]],{z}[[-1]],y]+($D-4)sameLorentz[x,z,y];
	
	sameLorentz[x__,a_,z__,a_,y__]/;!FreeQ[a,LorentzIndex]&&FreeQ[{z},DiracGamma[5]]&&5<=Length[{z}]:=
		Sum[(-1)^(i-1)*2*sameLorentz[x,Sequence@@Drop[{z},{i}],{z}[[i]],y],{i,Length[{z}]-4}]+
		(-1)^(Length[{z}]-4) sameLorentz[x,Sequence@@Insert[{z},a,-5],a,y];
	(***************************End**********************************)
	
	(*******Reduce two same Momenta*******)
	sameMomentum[x__,a_,z___,a_,y__]/;!FreeQ[a,Momentum]&&FreeQ[{z},a|DiracGamma[5]]:=
		Sum[(-1)^(i-1)*2*Pair[a[[1]],{z}[[i,1]]]*
			sameMomentum[x,Sequence@@Drop[{z},{i}],a,y],{i,Length[{z}]}]+
		(-1)^Length[{z}] Pair[a[[1]],a[[1]]]sameMomentum[x,z,y];
	
	(*******Using DiracEquation*******)
	(*Dealing with 3 cases:
	1) No Gamma5; 2) Only one gamma5 at the second place; 3) Exists gamma5 at other places.
	The case 3) corresponding non-commutative gamma5 scheme, and the case 2) needs to judge.
	*)
	diracEquation[x:DiracSpinor[{p_, sgn_}, m_],DiracGamma[Momentum[p_]],y___]:=sgn*m*diracEquation[x,y];
	diracEquation[x___,DiracGamma[Momentum[p_]],y:DiracSpinor[{p_, sgn_}, m_]]:=sgn*m*diracEquation[x,y];
	
	diracEquation[x:DiracSpinor[{p_, sgn_}, m_],a:DiracGamma[5],DiracGamma[Momentum[p_]],y__]/;
		OptionValue["Gamma5Scheme"]==="Anti-Commutative":=-sgn*m*diracEquation[x,a,y];
		
	diracEquation[x:DiracSpinor[{p_, sgn_}, m_],y___,a_,b:DiracGamma[Momentum[p_]],z__]/;a[[1]]=!=5:=
		2Pair[a[[1]],Momentum[p]]diracEquation[x,y,z]-diracEquation[x,y,b,a,z];
	diracEquation[x__,a:DiracGamma[Momentum[p_]],b_,y___,z:DiracSpinor[{p_, sgn_}, m_]]/;
		b[[1]]=!=5&&(Head[x]=!=DiracSpinor||x[[1,1]]=!=p):=
		2Pair[b[[1]],Momentum[p]]diracEquation[x,y,z]-diracEquation[x,b,a,y,z];
	
	(*******Ordering DiracMatrix*******)
	orderMomentum[x__,a_,b_,y__]/;a=!=DiracGamma[5]&&b=!=DiracGamma[5]&&!OrderedQ[{a,b}]:=
		2Pair[a[[1]],b[[1]]]orderMomentum[x,y]-orderMomentum[x,b,a,y];
	(***************************End**********************************)
	
	temp=exp/.
		DiracChain:>sameLorentz/.
		sameLorentz:>sameMomentum/.
		sameMomentum:>zero/.
		zero:>diracEquation/.
		diracEquation:>DiracChain;
	
	If[OptionValue["OrderQ"],temp=temp/.DiracChain:>orderMomentum/.orderMomentum:>DiracChain];
	
	(*temp=temp/.DiracChain[0,x___,0]\[RuleDelayed]DiracTrace[x]/.x_DiracTrace/;
	If[FreeQ[x,DiracGamma[5]],Mod[Length[x],2]===1,Length[x]<5||Mod[Length[x],2]===0]\[RuleDelayed]0*);
	
	temp=temp/.Pair[x_LorentzIndex,x_LorentzIndex]:>$D;
	
	(*temp=SimplifyList[temp,_DiracChain,"Factoring"\[Rule](SimplifyList[#,_Pair|_Eps,"Factoring"\[Rule]Expand]&)];*)
	
	temp
];


(* ::Section::Closed:: *)
(*diracTrace*)


(*Calculate and define a FUNCTION of trace with n Dirac gammas*)
pi=Table["p"<>ToString[i]//ToExpression,{i,100}];
savedTrace[]:=4;
savedTrace0[n_]:=savedTrace0[n]=Module[
	{var,string},
	var=pi[[1;;n]];
	string=Sum[
		(-1)^i*Pair[var[[1]],var[[i]]]*savedTrace[Sequence@@Delete[var,{{1},{i}}]]/.
		savedTrace[x___]:>(savedTrace0[Length@{x}];savedTrace[x])
		,{i,2,Length[var]}
	];
	string=ToString@string;
	var=StringJoin[ToString[#]<>"_,"&/@var];
	string=ToString@savedTrace<>"["<>StringTake[var,{1,-2}]<>"]:="<>string<>";";
	string//ToExpression
];


diracTrace[exp_]:=Module[
	{temp,fch,rep,tr},
	
	tr[{}]=4;
	tr[ls_List]/;ls[[1]]=!=DiracGamma[5]:=If[Length@ls//OddQ,
		0,
		savedTrace0[Length@ls];
		savedTrace@@ls[[All,1]]
	]; 
	
	tr[ls_]/;ls[[1]]===DiracGamma[5]:=Module[
		{all,num,res},
		all=ls[[2;;-1,1]];
		num=Range@Length@all;
		num={#,Complement[num,#]}&/@Subsets[num,{4}];
		res=(Signature[Flatten[#]]*(-I)*Eps@@(all[[#[[1]]]])*
				tr[DiracGamma/@(all[[#[[2]]]])])&/@num;
		Plus@@res
	];
	
	fch=Cases[{exp},DiracChain[0,___,0],Infinity]//Union;
	fch=Select[fch,Union@(List@@#[[2;;-2,0]])==={DiracGamma}&&
		FreeQ[#[[3;;-1]],DiracGamma[5]]&];
	PrependTo[fch,DiracChain[0,0]];
	
	rep=fch/.DiracChain[0,x___,0]:>tr[{x}];
	
	Return[exp/.Dispatch@Thread[fch->rep]];
];


(* ::Section::Closed:: *)
(*End*)


End[];
