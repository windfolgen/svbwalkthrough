(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


ClearScalarProducts::usage="ClearScalarProducts[] clears all set values of Pair.
ClearScalarProducts[k__] clears all set values of Pair that depend on 'k'.";


GenerateScalarProducts::usage="GenerateScalarProducts[head_] generates all \
scalar products of a process defined by 'head' and sets corresponding values for Pair. \
All existed set values of Pair will be cleared.
OptionValue[\"ScalarProductsName\"] defines names of scalar products.
OptionValue[\"DeleteNumber\"] determines the number of momentum which will \
be deleted by using momentum conservation.";


CompleteScalarProducts::usage="CompleteScalarProducts[moms0_,sps0_List,relation0_] \
returns a complete list of replacement rules for scalar products with partial input. \
Here 'moms0' is a list of external momenta, e.g., {k1,k2},  \
'sps0' is a list of replacement rules for some scalar products, e.g., {k1 k2->s12/2} \
and 'relation0' is  in the form of moms1->moms2, which represents possible relation \
due to momentum conservation.";


$MomentumRelation::usage="$MomentumRelation stores relations between momenta.";


Begin["`Private`"];
End[];


Begin["`ScalarProducts`"];


$MomentumRelation={};


(* ::Section::Closed:: *)
(*ClearScalarProducts*)


ClearScalarProducts[k___]:=Module[
	{eqs},
	
	eqs=DownValues[Pair][[All,1]];
	
	If[{k}==={},
		eqs/.HoldPattern[x_Pair]:>Unset@x,
		eqs/.HoldPattern[Pair[x__]]:>Unset@Pair[x]/;
			(!FreeQ[{x},Alternatives[k]])
	]//ReleaseHold
	
];


(* ::Section:: *)
(*GenerateScalarProducts*)


Options[GenerateScalarProducts]={"DeleteNumber"->-1};


GenerateScalarProducts[head0_,opt:OptionsPattern[]]:=Module[
	{Sp,sp,No,head,onshell,relation,sps},
	
	Sp=SP;
	No=OptionValue["DeleteNumber"];
	
	(*clear current definition of scalar products*)
	ClearScalarProducts[];
	
	head=Join@@head0;
	onshell=#[[2]]^2->#[[3]]^2&/@head;
	
	(*find momentum conservation relation*)
	relation=Plus@@head0[[1,All,2]]-Plus@@head0[[2,All,2]];
	relation=Solve[relation==0,Evaluate@head[[No,2]]][[1]];
	$MomentumRelation=relation;
	
	(*Delete one momentum*)
	head=Delete[head,No];
	
	(*generate a list of replacement rules*)
	sps=Join@@Table[head[[i,2]]*head[[j,2]]->sp[i,j],
		{i,Length@head},{j,i+1,Length@head}];
	sps=Join[If[sps==={},{},sps[[1;;-2]]],onshell];
	
	(*generate complete replacement rules*)
	sps=CompleteScalarProducts[head[[All,2]],sps,relation,opt]/.
		sp[i_,j_]:>Sp[head[[i,2]],head[[j,2]]];
	
	(*Define Pair[_,_]*)
	If[Head@#[[1]]===Power,Pair[Momentum@#[[1,1]],Momentum@#[[1,1]]]=#[[2]],
		Pair[Momentum@#[[1,1]],Momentum@#[[1,2]]]=#[[2]]]&/@sps;
	
	sps
];


(* ::Section::Closed:: *)
(*CompleteScalarProducts*)


CompleteScalarProducts[moms0_,sps0_List,relation0_,OptionsPattern[]]:=Module[
	{moms,n,sps,relation,k,rep,sp,sol},
	
	(*List of momenta*)
	moms=Variables[{moms0,relation0/.Rule->List}];
	n=Length@moms;
	(*n(n-1)/2 conditions are needed*)
	If[Length@sps0<n (n-1)/2,
		Print["Incorrect input for FullScalarProducts!" ,{sps0,n}];
		Return[]
	];
	
	(*Use new variables*)
	rep=Thread[moms->Array[k,n]];
	{sps,relation}={sps0,relation0}/.rep;
	
	(*Momentum conservation*)
	relation=Solve[relation/.Rule->Equal,k[n]][[1]];
	
	(*Scalar products are put in 'sp'*)
	sps=Expand[sps/.relation]/.k[a_]*k[b_]:>sp[a,b]/.k[a_]^2:>sp[a,a];
	
	(*Some replacement rules*)
	sol=Solve[sps/.Rule->Equal,Cases[sps,_sp,Infinity]//Union][[1]];
	
	(*A complete list of replacement rules*)
	sol=(#->(Expand[#/.relation]/.k[a_]*k[b_]:>
				sp[a,b]/.k[a_]^2:>sp[a,a]/.sol//Expand)&/@
		Flatten@Table[k[i]k[j],{i,n},{j,i,n}])/.(Reverse/@rep);
	
	sol
	
];


(* ::Section::Closed:: *)
(*End*)


End[];
