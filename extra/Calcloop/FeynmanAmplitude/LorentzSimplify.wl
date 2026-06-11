(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


LorentzSimplify::usage="LorentzSimplify[exp] simplifies the expression by contracting \
as many as possible Lorentz indexes.
If OptionValue[\"NonPair\"] is not True, Lorentz contraction within Eps and DiracGamma \
will not be touched.
If OptionValue[\"SpacetimeDimension\"] is the spacetime dimention.";


$D::"usage"="$D is the general spacetime dimension.";


Pair::"usage"="Pair[mu_LorentzIndex,nu_LorentzIndex] is the metric tensor \
\!\(\*SuperscriptBox[\(g\), \(mu\\\ nu\)]\).
Pair[p_Momentum,mu_LorentzIndex] is the Lorentz vector \!\(\*SuperscriptBox[\(p\), \(mu\)]\).
Pair[p_Momentum,q_Momentum] is the scalar product p\[CenterDot]q.";

LorentzIndex::"usage"="LorentzIndex[mu] indicates that 'mu' is a Lorentz index.";

Momentum::"usage"="Momentum[p] indicates that 'p' is a Lorentz vector.";

MomentumQ::"usage"="MomentumQ[p] declares that 'p' is a Lorentz vector.";


SP::"usage"="SP[p,q] is a shortcut for the scalar product p\[CenterDot]q.
SP[p] is a shortcut for the scalar product p\[CenterDot]p.";


PolarizationVector::usage="PolarizationVector[{k,1},mu] is the polarization vector \
\!\(\*SuperscriptBox[\(\[Epsilon]\), \(mu\)]\)(k) of the vector \
particle with momentum 'k'.
PolarizationVector[{k,-1},mu] is ComplexConjugate ofPolarizationVector[{k,1},mu].";


Begin["`Private`"];
findTensorIndex::usage="findTensorIndex[exp] gives true Lorentz indexes of 'exp', \
which means Lorentz indexes that are not dummy.";

clusterTensorIndex::usage="clusterTensorIndex[indexes_List] clusters the list so that \
different clusters do not share common element. Result is a cluster of numbers.";
End[];


Begin["`LorentzSimplify`"];


(* ::Section::Closed:: *)
(*Typesetting*)


$D/:MakeBoxes[$D,f_]/;MemberQ[$CLDefinedForm,f]:=TDBox@"D";


Momentum/:MakeBoxes[Momentum[x_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[x];
LorentzIndex/:MakeBoxes[LorentzIndex[-1*x_],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox[TDBox[x],"\[Prime]"];
LorentzIndex/:MakeBoxes[LorentzIndex[x_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[x]/;Head@x=!=Times;

Attributes[Pair]={Orderless};
Pair/:MakeBoxes[Pair[a_LorentzIndex,b_LorentzIndex],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox["g",TDBox[a,b]];
Pair/:MakeBoxes[Pair[Momentum[a_]/;(Head[a]=!=Plus&&Head[a]=!=Times),b_LorentzIndex],f_]/;
	MemberQ[$CLDefinedForm,f]:=SuperscriptBox[TDBox@a,TDBox@b];
Pair/:MakeBoxes[Pair[Momentum[a_]/;(Head[a]===Plus||Head[a]===Times),b_LorentzIndex],f_]/;
	MemberQ[$CLDefinedForm,f]:=SuperscriptBox[RowBox[{"(",TDBox@a,")"}],TDBox@b];
Pair/:MakeBoxes[Pair[Momentum[a_],Momentum[a_]],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[Momentum[a]^2];
Pair/:MakeBoxes[Pair[Momentum[a_],Momentum[b_]],f_]/;MemberQ[$CLDefinedForm,f]&&a=!=b:=TDBox[a . b];


Attributes[SP]={Orderless};
SP/:MakeBoxes[SP[a_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[Momentum[a]^2];
SP/:MakeBoxes[SP[a_,a_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[Momentum[a]^2];
SP/:MakeBoxes[SP[a_,b_],f_]/;MemberQ[$CLDefinedForm,f]&&a=!=b:=TDBox[a . b];


PolarizationVector/:MakeBoxes[PolarizationVector[{k_,1},mu_],f_]/;MemberQ[$CLDefinedForm,f]:=
			SubsuperscriptBox["\[Epsilon]",TDBox[k],TDBox@LorentzIndex[mu]];
PolarizationVector/:MakeBoxes[PolarizationVector[{k_,-1},mu_],f_]/;MemberQ[$CLDefinedForm,f]:=
			SubsuperscriptBox["\[Epsilon]",TDBox[k],RowBox@{"*",TDBox@LorentzIndex[mu]}];


(* ::Section::Closed:: *)
(*tools*)


(* ::Subsection::Closed:: *)
(*clusterTensorIndex*)


clusterTensorIndex[index0_List]:=Module[
	{i,j,n,indexes,list,num},
	
	indexes=index0;
	n=Length@indexes;
	list={};
	num=Table[{i},{i,n}];
	
	Do[
		If[indexes[[i]]==={},AppendTo[list,num[[i]]];Continue[]];
		For[j=i+1,j<=n,j++,
			If[Intersection[indexes[[i]],indexes[[j]]]=!={},
				indexes[[j]]=indexes[[{i,j}]]//Flatten//Union;
				num[[j]]=num[[{i,j}]]//Flatten//Union;
				Break[];
			]
		];
		If[j>n,AppendTo[list,num[[i]]]];
		,{i,n}
	];
	
	list	
];


(* ::Subsection::Closed:: *)
(*findTensorIndex*)


Attributes[findTensorIndex]={Listable};
Options[findTensorIndex]={};


findTensorIndex[exp_,OptionsPattern[]]:=Module[
	{name,indexes,union},
	
	name=LorentzIndex;
	
	If[FreeQ[exp,name],Return[{}]];
	
	Switch[Head@exp,
		Power, {},
		name,{exp},
		Plus, findTensorIndex@exp[[1]],
		_, indexes=Flatten@findTensorIndex@(List@@exp);
			Select[Union@indexes,Count[indexes,#]===1&]
	]	
];


(* ::Subsection::Closed:: *)
(*lorentzIndexHold *)


lorentzIndexHold::usage="Hold the LorentzIndex temporarily.";


(* ::Section:: *)
(*contractPair*)


(* ::Subsection:: *)
(*contractPair*)


contractPair::usage="";


Attributes[contractPair]={Listable};
Options[contractPair]={"TensorIndex"->Automatic};


contractPair[exp_,OptionsPattern[]]/;FreeQ[exp,LorentzIndex]:=exp;


contractPair[exp_,OptionsPattern[]]/;!MemberQ[{Plus,Times,Power},Head@exp]:=exp/.
	Pair[x:_LorentzIndex,x:_]:>OptionValue[LorentzSimplify,"SpacetimeDimension"]/.
	Eps[___,x_,___,x_,___]:>0;


contractPair[exp_Plus,OptionsPattern[]]:=Module[
	{tsIndex=OptionValue["TensorIndex"]},
	
	If[tsIndex===Automatic, tsIndex=exp[[1]]//findTensorIndex];
	
	Plus@@contractPair[List@@exp,"TensorIndex"->tsIndex]	
];


contractPair[exp_^2,OptionsPattern[]]:=Module[
	{coe,base,res},
	
	{coe,base}=Separate[exp,Pair[_LorentzIndex,_]|Eps[___,_LorentzIndex,___]];
	
	If[!FreeQ[coe,LorentzIndex],{coe,base}=Separate[exp,LorentzIndex,"FreeForm"->True]];
	
	If[coe==={1}, contractOverallPair[exp^2]/.
			LorentzIndex->lorentzIndexHold//Return
	];
	
	res=contractPair[base*exp];
	Plus@@(coe*res)//Return	
];


contractPair[exp_Times,opt:OptionsPattern[]]:=Module[
	{i,tsIndex=OptionValue["TensorIndex"],cluster,lorentz,rep,expList,
	factor,factori,coeList,baseList,leafList0,nList,leafList,ordering,flag,res},
	
	(*cluster terms if possible*)
	res=List@@exp;
	cluster=findTensorIndex@res;
	cluster=clusterTensorIndex[cluster];
	If[Length@cluster>1, Times@@(contractPair[Times@@res[[#]],opt]&/@cluster)//Return];
	
	(*Suppress tensor indexes and then Contract each factor*)
	If[tsIndex===Automatic, tsIndex=findTensorIndex@exp];
	rep=Dispatch@Thread[tsIndex->(tsIndex/.LorentzIndex->lorentz)];
	expList=exp/.rep;
	
	(*Do the following repeatedly until no index-dependent overall factor*)
	flag=True;
	While[flag,
		(*contract simple factors*)
		
		expList=expList//contractOverallPair;
		
		(*contract each factor individually*)
		expList=If[Head@#===Times,List@@#,{#}]&@expList//contractPair;
		
		factor=Times@@Select[expList,FreeQ[#,LorentzIndex]&];
		expList=Select[expList,!FreeQ[#,LorentzIndex]&];
		
		(*Return if no multiplication*)
		If[Length@expList<2,
			factor*contractPair[Times@@expList]/.lorentz->LorentzIndex//Return
		];
		
		(*Separate coefficients from indexes*)
		{coeList,baseList}=Separate[expList,
				Pair[_LorentzIndex,_]|Eps[___,_LorentzIndex,___]]//Transpose;
		Do[If[!FreeQ[coeList[[i]],LorentzIndex],
			{coeList[[i]],baseList[[i]]}=Separate[expList[[i]],LorentzIndex,"FreeForm"->True]
			]
			,{i,Length@baseList}
		];
		
		(*Find out overall factors*)
		flag=False;
		Do[
			factori=PolynomialGCD@@baseList[[i]];
			If[factori=!=1&&coeList[[i]]=!={1},
				flag=True; (*expression can be simplified*)
				factor*=factori;
				factori=If[Head@factori===Times,List@@factori,{factori}];
				{expList[[i]],baseList[[i]]}={expList[[i]],baseList[[i]]}/.Thread[factori->1]
			],
			{i,Length@expList}
		];
		
		If[flag===True,expList=contractPair[factor]*Times@@expList];
	];
		
	(*Find the factor with smallest value, defined by: only Pair < have Pair < no Pair, 
		then number of bases*)
	i=(Sort@Table[
		{Which[(#/._Pair->1)===1,1,!FreeQ[#,Pair],2,True,3],
			If[Length@#>1,Length@#,(*an unknown type*)Infinity],i}&@baseList[[i]]
		,{i,Length@baseList}
	])[[1,-1]];
	
	(*A case impossible to contract*)
	If[coeList[[i]]==={1}, factor*Times@@expList
		/.LorentzIndex->lorentzIndexHold/.lorentz->LorentzIndex//Return
	];
	
	(*Expand the obtained factor and contract*)
	res=contractPair[baseList[[i]]*Times@@Drop[expList,{i}]];
	res=factor*Plus@@(coeList[[i]]*res)/.lorentz->LorentzIndex;
	
	res//Return	
];


(* ::Subsection::Closed:: *)
(*contractOverallPair*)


contractOverallPair::usage="contractOverallPair[exp] contracts Pairs in overall factor.";


contractOverallPair[exp_]:=Module[
	{rep,D=OptionValue[LorentzSimplify,"SpacetimeDimension"],res,pairs,factor},
	
	rep={Pair[x_LorentzIndex,x_LorentzIndex]->D,
		 Pair[_LorentzIndex,_LorentzIndex]^2:>D,
		 Pair[_LorentzIndex,y_Momentum]^2:>Pair[y,y],
		 Pair[x_LorentzIndex,y_]*Pair[x_LorentzIndex,z_]:>Pair[y,z]
		 };
	
	res=If[Head@#===Times,List@@#,{#}]&@exp;
	
	(*find over all pairs*)
	pairs=1;
	factor=1;
	Do[
		If[MatchQ[res[[i]],_Pair|Pair[__]^2],pairs*=res[[i]],factor*=res[[i]]]
		,{i,Length@res}
	];
	
	pairs=pairs//.rep;
	
	factor*=pairs/.Pair[_LorentzIndex,_]:>1;
	
	pairs=Select[If[Head@#===Times,List@@#,{#}]&@pairs,!FreeQ[#,LorentzIndex]&];
	
	(*Pair[x_LorentzIndex,y]*z_->(z/.x->y)*)
	pairs=pairs/.Pair[x_LorentzIndex,y_]:>{x->y}//Flatten;
	factor/.pairs
	
];


(* ::Section:: *)
(*LorentzSimplify*)


(* ::Subsection:: *)
(*3.1 LorentzSimplify*)


Attributes[LorentzSimplify]={Listable};
Options[LorentzSimplify]={"NonPair"->False,"SpacetimeDimension"->$D,"CheckQ"->True};


LorentzSimplify[exp_,OptionsPattern[]]:=Module[
	{indexes,res},
	
	If[FreeQ[exp,LorentzIndex],Return@exp];
	
	If[OptionValue["CheckQ"], 
		indexes=CountIndexes[exp,LorentzIndex,"CheckQ"->True];
		If[Max@indexes[[All,2]]>2,
			Print["More than 2 dummy indexes detected: ",{exp//Short, indexes}];
			Abort[];
		]
	];
	
	res=contractPair@(exp/.PolarizationVector[a_,b_LorentzIndex]:>PolarizationVector[a,b[[1]]])/.
		PolarizationVector[a_,b_]:>PolarizationVector[a,LorentzIndex@b];
	
	If[OptionValue["NonPair"]=!=True, res/.lorentzIndexHold->LorentzIndex//Return];

	res
];


(* ::Section::Closed:: *)
(*End*)


End[];
