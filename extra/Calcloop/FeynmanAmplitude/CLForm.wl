(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


CLForm::"usage"="CLForm changes shortcut expression to formal expression used in CalcLoop. \
It also partially checks the correctness of input expressions.";


MT::"usage"="MT[mu,nu] is a shortcut for the metric tensor \!\(\*SuperscriptBox[\(g\), \(mu\\\ nu\)]\)";
LV::"usage"="LV[p,mu] is a shortcut for the Lorentz vector \!\(\*SuperscriptBox[\(p\), \(mu\)]\).";


GA::"usage"="GA[mu,nu,...] is a shortcut for \!\(\*SuperscriptBox[\(\[Gamma]\), \(mu\)]\)\[CenterDot]\
\!\(\*SuperscriptBox[\(\[Gamma]\), \(nu\)]\)....";

GS::"usage"="GS[p,q,...] is a shortcut for \
(\!\(\*SubscriptBox[\(p\), \(mu\)]\)\!\(\*SuperscriptBox[\(\[Gamma]\), \(mu\)]\))\[CenterDot]\
(\!\(\*SubscriptBox[\(q\), \(nu\)]\)\!\(\*SuperscriptBox[\(\[Gamma]\), \(nu\)]\))....";

TR::"usage"="TR[x___] is a shortcut for Dirac trace of 'x'.";


Begin["`Private`"];
End[];


Begin["`CLForm`"];


(* ::Section::Closed:: *)
(*CLForm*)


Attributes[CLForm]={Listable};
Options[CLForm]={"CheckQ"->True};
CLForm[exp_,OptionsPattern[]]:=Module[
	{ga,gs,tr,lv,mt,sp,eps,vars,funs,res,indexes},
	
	ga[x__]:=DiracGamma[LorentzIndex[#]]&/@DiracChain[x]/.LorentzIndex[5]:>5;
	
	gs[x__]:=DiracGamma[Momentum[#]]&/@DiracChain[x];
	
	tr[x__]:=DiracChain[0,x,0];
	
	lv[x_,y_]:=Pair[Momentum[x],LorentzIndex[y]];
	
	mt[x_,y_]:=Pair[LorentzIndex[x],LorentzIndex[y]];
	
	sp[a_]:=sp[a,a];
	sp[x_,y_]:=Pair[Momentum[x],Momentum[y]];
	
	eps[mu___][p___]/;Length@{mu,p}===4:=Eps[Sequence@@(LorentzIndex/@{mu}),Sequence@@(Momentum/@{p})];

	vars={GA,GS,TR,LV,MT,SP,Eps};
	funs={ga,gs,tr,lv,mt,sp,eps};
	
	res=exp/.Dispatch@Thread[vars->funs]/.eps->Eps;
	
	res=res/.x_/;MemberQ[$SUNFunctions,Head@x]:>SUNIndex/@(x/.SUNIndex:>Identity)/.
		SUNT[SUNIndex@0,x___,SUNIndex@0]:>SUNT[0,x,0];
		
	If[OptionValue["CheckQ"], 
		indexes=CountIndexes[res,LorentzIndex,"CheckQ"->True];
		If[Max@indexes[[All,2]]>2,
			ErrorPrint["More than 2 dummy indexes detected: ",{res//Short, indexes}];
			Abort[]
		];
		indexes=CountIndexes[res,SUNIndex,"CheckQ"->True];
		If[MemberQ[indexes[[All,1]],SUNIndex@0],
			ErrorPrint["SUNIndex[0] detected: ",{res//Short, indexes}];
			Abort[]
		];
		If[Max@indexes[[All,2]]>2,
			ErrorPrint["More than 2 dummy indexes detected: ",{res//Short, indexes}];
			Abort[]
		];
		
	];
	
	res
]


(* ::Section::Closed:: *)
(*End*)


End[];
