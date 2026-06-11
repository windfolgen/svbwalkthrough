(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


ReadStringAndSymbol::usage="ReadStringAndSymbol[str_String,name] translates a string 'str' to an expression, \
by keeping symbols in the form 'name[\"symb\"]'. 
Therefore, the expression involves no other symbols except 'name'.";


CountIndexes::usage="CountIndexes[exp_,index_] returns the maximal number of each index appeared in 'exp'. \
If OptionValue[\"CheckQ\"]===True], it will also check whether summands have the same structure of \
non-dummy indexes.";


Begin["`Private`"];


writeFileName::usage="writeFileName[filename] changes the 'filename' to a string form.";


clTimes::usage="clTimes is similar to Times, but it does not express multiplication of same terms \
as Powers.";
clTimesForm::usage="clTimesForm changes multiplication to clTimes.
If OptionValue[\"PowerExpand\"] is True, positive powers are expressed as multiplications.";

clPlus::usage="clPlus is similar to Plus, but it does not express summation of same terms \
as Times.";
clPlusForm::usage="clPlusForm changes summation to clTimes.";

inputString::usage="inputString[exp_] change 'exp' to string with InputForm.";


associationPlus
associationAddTo


End[];


Begin["`CLAuxiliary`"];


inputString[exp_]:=ToString[exp,InputForm];


(* ::Section::Closed:: *)
(*ReadStringAndSymbol*)


ReadStringAndSymbol[str_String,name_]:=Module[
	{chcode,new,left,right,i,A,Z,a,z,n0,n9,quo,flag,ch},
	
	left=ToCharacterCode[ToString@name<>"[\""];
	right=ToCharacterCode["\"]"];
	{A,Z,a,z,n0,n9,quo}=ToCharacterCode["AZaz09\""];
	
	new=Join[ToCharacterCode[str],ToCharacterCode@" "];
	chcode=Table[Which[n0<=codei<=n9,1,A<=codei<=Z||a<=codei<=z,2,codei===quo,3,True,4],{codei,new}];
	
	flag=1;
	Do[
		Switch[chcode[[i]],
			4,If[flag==0,flag=1;new[[i-1]]={new[[i-1]],right}],
			3,If[flag==0,flag=1;new[[i-1]]={new[[i-1]],right}];flag=-flag,
			2,If[flag==1,flag=0;new[[i]]={left,new[[i]]}]
		]
		,{i,Length@chcode}
	];

	ToExpression@FromCharacterCode@Flatten@new
];


(* ::Section::Closed:: *)
(*writeFileName*)


writeFileName[filename_]:="FileNameJoin["<>ToString["\""<>#<>"\""&/@FileNameSplit@filename]<>"]";


(* ::Section::Closed:: *)
(*clTimes/clTimesForm*)


Attributes[clTimes]={Orderless};
clTimes[clTimes[a___],b___]:=clTimes[a,b];
clTimes[a_*clTimes[b___],c___]:=a*clTimes[b,c];


Attributes[clTimesForm]={Listable};
Options[clTimesForm]={"PowerExpand"->False};
clTimesForm[exp_,OptionsPattern[]]:=If[OptionValue["PowerExpand"]===True,
	#//.clTimes[a_^n_?IntegerQ,b___]/;n>0:>clTimes[Sequence@@ConstantArray[a,n],b],
	#]&@If[
		Head@exp===Times,
		clTimes@@exp,
		clTimes@exp
	];


(* ::Section::Closed:: *)
(*clPlus/clPlusForm*)


Attributes[clPlus]={Orderless};
clPlus[clPlus[a___],b___]:=clPlus[a,b];
clPlus[a_+clPlus[b___],c___]:=a+clPlus[b,c];


Attributes[clPlusForm]={Listable};
clPlusForm[exp_]:=If[Head@exp===Plus,clPlus@@exp,clPlus@exp];


(* ::Section::Closed:: *)
(*CountIndexes*)


Options[CountIndexes]={"CheckQ"->True};


CountIndexes[exp_,index_,opt:OptionsPattern[]]:=Module[
	{checkQ,list},
	
	checkQ=OptionValue["CheckQ"];
	
	If[FreeQ[exp,index],Return[{}]];
	
	Switch[Head@exp,
		index,{{exp,1}},
		Plus, list=CountIndexes[#,index,opt]&/@List@@exp;
			  If[checkQ&&(Length@Union[Select[#,##[[2]]===1&]&/@list])>1,
			  	Print["Inhomogeneous ",index," detected: ",{exp//Short, list}];
			  	Abort[];
			  ];
			  list=SplitBy[Join@@list//Sort,First];
			  Return[{#[[1,1]],Max@#[[All,2]]}&/@list],
		Power, list=CountIndexes[exp[[1]],index,opt];
			   Return[{#[[1]],exp[[2]]*#[[2]]}&/@list],
		_, list=CountIndexes[#,index,opt]&/@List@@exp;
			  list=SplitBy[Join@@list//Sort,First];
			  Return[{#[[1,1]],Plus@@#[[All,2]]}&/@list];
	]
];


(* ::Section::Closed:: *)
(*associationPlus*)


Attributes[associationPlus]={};


associationPlus[{}]:=Association[];
associationPlus[x:{asso1_,___}]/;Head@asso1=!=Association:=Plus@@x;
associationPlus[assoList:{_Association..}]:=Module[
	{keys,asso},
	
	keys=Union[Join@@(Keys/@assoList)];
	
	asso=Association@@Thread[keys->Association[]];
	
	Do[
		Do[
			asso[key][i]=assoList[[i]][key]
			,{key,Keys@assoList[[i]]}
		]
		,{i,Length@assoList}
	];
	
	(*** add elements recursively ***)
	Do[asso[key]=associationPlus[Values@asso@key],{key,keys}];
	
	asso
];


(* ::Section::Closed:: *)
(*associationAddTo*)


Attributes[associationAddTo]={HoldAll};


associationAddTo[asso_@key_,value_]:=Module[
	{exi},
	exi=Lookup[asso,Key@key,0];
	asso[key]=exi+value;
];


associationAddTo[asso_@asso1_@key_,value_]:=Module[
	{exi},
	If[!KeyExistsQ[asso,asso1],asso[asso1]=Association[]];
	exi=Lookup[asso[asso1],Key@key,0];
	asso[asso1][key]=exi+value;
];


associationAddTo[asso_@asso1_@asso2_@key_,value_]:=Module[
	{exi},
	If[!KeyExistsQ[asso,asso1],asso[asso1]=Association[]];
	If[!KeyExistsQ[asso[asso1],asso2],asso[asso1][asso2]=Association[]];
	exi=Lookup[asso[asso1][asso2],Key@key,0];
	asso[asso1][asso2][key]=exi+value;
];


(* ::Section::Closed:: *)
(*End*)


End[];
