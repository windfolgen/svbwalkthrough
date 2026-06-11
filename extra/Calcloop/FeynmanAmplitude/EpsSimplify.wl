(* ::Package:: *)

(* ::Section:: *)
(*Begin*)


EpsSimplify::"usage"="EpsSimplify[exp] calculates products of Levi Civita tensors by averaging \
over all possible pairs of combinations. Each pair is expressed as a determinant of a matrix. \
Remained Levi Civita tensors are expressed in a standard form.";


Eps::"usage"="Eps[a1_,a2_,a3_,a4_] is a Levi Civita tensor. Head of 'ai' can be either \
LorentzIndex or Momentum.
Eps[mu1,mu2,...][p1,p2,...] with Length@{mu,p}===4 is a shortcut for \
Eps[LorentzIndex@mu1,LorentzIndex@mu2,...,Momentum@p1,Momentum@p2,...].";


Begin["`Private`"];
End[];


Begin["`EpsSimplify`"];


Eps/:MakeBoxes[Eps[a___],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox["\[Epsilon]",TDBox[a]];


(* ::Section:: *)
(*EpsSimplify*)


Attributes[EpsSimplify]={Listable};
Options[EpsSimplify]={"SpacetimeDimension"->$D};
EpsSimplify[exp_,OptionsPattern[]]:=Module[
	{epsOrder,epsTimes,sep,opt},
	
	epsOrder[x__]/;!OrderedQ[{x}]:=Signature@{x}*epsOrder@@Sort@{x};
	epsOrder[___,x_,___,x_,___]:=0;
	
	(*Average over all possible pairs of combinations*)
	epsTimes[a_]/;Length@a>1:=Sum[
		-Det@Outer[Pair[#1,#2]&,List@@a[[1]],List@@a[[i]]]*epsTimes@Drop[a,{1,i,i-1}]
		,{i,2,Length@a}]/(Length@a-1);
		
	sep=Separate[exp/.Eps->epsOrder/.epsOrder->Eps,_Eps];
	
	sep[[2]]=clTimesForm[sep[[2]],"PowerExpand"->True]/.
		clTimes[1,a___]:>clTimes[a]/.
		clTimes[a___]:>epsTimes[{a}]/.
		epsTimes[{a___}]:>Times[a];
		
			
	opt=OptionValue[LorentzSimplify,"SpacetimeDimension"];(*store the original value*)
	SetOptions[LorentzSimplify,"SpacetimeDimension"->OptionValue["SpacetimeDimension"]];	
	sep[[2]]=sep[[2]]//LorentzSimplify;
	sep[[2]]=sep[[2]]/.Eps->epsOrder/.epsOrder->Eps;
	SetOptions[LorentzSimplify,"SpacetimeDimension"->opt];(*restore the original value*)

	Return[Dot@@sep];
];


(* ::Section::Closed:: *)
(*End*)


End[];
