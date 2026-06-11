(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


MomentumSimplify::usage="MomentumSimplify[exp_] expands all momenta and relevant functions, \
including Pair, Eps, and DiracGamma.";


Begin["`Private`"];
End[];


Begin["`MomentumSimplify`"];


(* ::Section:: *)
(*MomentumSimplify*)


MomentumSimplify[exp0_]:=Module[
	{exp,sp,momentum,pair,eps,gs,var,rep,res},
	
	sp[a_]:=sp[a,a];
	sp[x_,y_]:=Pair[Momentum[x],Momentum[y]];
	
	exp=exp0/.SP->sp/.$MomentumRelation;
	
	(*Momentum*)
	momentum[0]=0;
	momentum[x_*y_]/;NumberQ[x]||MomentumQ[y]:=x*momentum[y];
	momentum[x_Plus]:=momentum/@x;
	
	(*Pair*)
	Attributes[pair]={Orderless};
	pair[0,_]=0; 
	pair[a_,b_*(c_Momentum)]:=b*pair[a,c];
	pair[a_,b_*c_Plus]/;Head@b=!=Momentum:=pair[a,b*c//Expand];
	pair[a_,b_Plus]:=(pair[a,#]&)/@b;
	
	(*Levi-Civita tensor*)
	eps[a___,0,b___]=0;
	eps[x___,y0_*y1_Momentum,z___]:=y0*eps[x,y1,z];
	eps[x___,y_Plus,z___]:=(eps[x,#,z]&)/@y;
	
	(*Dirac gamma matrix*)
	gs[0]=0;
	gs[x_*(y_Momentum)]:=x*gs[y];
	gs[x_Plus]:=gs/@x;
	
	(*Find all momenta*)
	var=Cases[{exp},_Momentum,Infinity]//Union;
	rep=var/.x_Momentum:>(Expand//@x)
		/.Momentum->momentum/.momentum->Momentum;
	rep=Select[Thread[var->rep],#[[1]]=!=#[[2]]&];
	res=exp/.Dispatch[rep];
	
	(*Find all variables depending on momentum*)
	var=Cases[{res},_Pair|_Eps|_DiracChain,Infinity]//Union;
	rep=var/.Pair:>pair/.pair->Pair;
	rep=rep/.Eps:>eps/.eps->Eps;
	rep=rep/.DiracGamma:>gs/.gs->DiracGamma;
	rep=rep/.DiracChain:>diracChainExpand/.diracChainExpand->DiracChain;
	rep=Select[Thread[var->rep],#[[1]]=!=#[[2]]&];
	
	Return[res/.Dispatch[rep]];
];


(* ::Section::Closed:: *)
(*End*)


End[];
