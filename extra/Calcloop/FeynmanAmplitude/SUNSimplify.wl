(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


SUNSimplify::usage="SUNSimplify[exp] contracts indexes of SU(N) group and expresses the \
final result in a standard form.";


SUNT::"usage"="SUNT[i,\!\(\*SubscriptBox[\(a\), \(1\)]\),...,\!\(\*SubscriptBox[\(a\), \(n\)]\),j] \
stands for (\!\(\*SuperscriptBox[\(t\), SubscriptBox[\(a\), \(1\)]]\)...\!\(\*SuperscriptBox[\(t\), SubscriptBox[\(a\), \(n\)]]\)\!\(\*SubscriptBox[\()\), \(ij\)]\) of the SU(N) group.
SUNT[i,j]=\!\(\*SubsuperscriptBox[\(\[Delta]\), \(ij\), \(F\)]\) stands for the discrete delta function with \
indexes of fundamental representation of the SU(N) group.
SUNT[0,\!\(\*SubscriptBox[\(a\), \(1\)]\),...,\!\(\*SubscriptBox[\(a\), \(n\)]\),0] \
stands for trace of t matrixes \
\!\(\*SubscriptBox[\(tr\), \(c\)]\)(\!\(\*SuperscriptBox[\(t\), SubscriptBox[\(a\), \(1\)]]\)...\!\(\*SuperscriptBox[\(t\), SubscriptBox[\(a\), \(n\)]]\)).";

SUNF::"usage"="SUNF[\!\(\*SubscriptBox[\(a\), \(1\)]\),\!\(\*SubscriptBox[\(a\), \(2\)]\),...,\!\(\*SubscriptBox[\(a\), \(n\)]\)] \
stands for (\!\(\*SuperscriptBox[\(F\), SubscriptBox[\(a\), \(2\)]]\)\!\(\*SuperscriptBox[\(F\), SubscriptBox[\(a\), \(3\)]]\)...\!\(\*SuperscriptBox[\(F\), SubscriptBox[\(a\), \(n - 1\)]]\)\!\(\*SubscriptBox[\()\), \(\*SubscriptBox[\(a\), \(1\)] \*SubscriptBox[\(a\), \(n\)]\)]\) , where \
(\!\(\*SuperscriptBox[\(F\), \(b\)]\)\!\(\*SubscriptBox[\()\), \(ac\)]\)=\!\(\*SubscriptBox[\(f\), \(abc\)]\) \
is the structure constant of the SUN(N) group.";

SUND::"usage"="SUND[\!\(\*SubscriptBox[\(a\), \(1\)]\),\!\(\*SubscriptBox[\(a\), \(2\)]\),...,\!\(\*SubscriptBox[\(a\), \(n\)]\)] \
stands for (\!\(\*SuperscriptBox[\(D\), SubscriptBox[\(a\), \(2\)]]\)\!\(\*SuperscriptBox[\(D\), SubscriptBox[\(a\), \(3\)]]\)...\!\(\*SuperscriptBox[\(D\), SubscriptBox[\(a\), \(n - 1\)]]\)\!\(\*SubscriptBox[\()\), \(\*SubscriptBox[\(a\), \(1\)] \*SubscriptBox[\(a\), \(n\)]\)]\) , where \
(\!\(\*SuperscriptBox[\(D\), \(b\)]\)\!\(\*SubscriptBox[\()\), \(ac\)]\)=\!\(\*SubscriptBox[\(d\), \(abc\)]\) \
is the structure constant of the SUN(N) group."

SUNDelta::"usage"="SUNDelta[a,b]= \!\(\*SubsuperscriptBox[\(\[Delta]\), \(ab\), \(A\)]\) is the discrete delta function with \
indexes of adjoint representation of the SU(N) group.";

SUNIndex::"usage"="SUNIndex[x] indicates that 'x' is an index related to SU(N) group.";

SUNN::"usage"="SUNN stands N of SU(N) group.";


Begin["`Private`"];
$SUNFunctions={SUNT,SUNF,SUND,SUNDelta};
End[];


Begin["`SUNSimplify`"];


(*delta^ab*)
Attributes[SUNDelta]=Orderless;


(* ::Section::Closed:: *)
(*Typesetting*)


(*typesetting*)
SUNT/:MakeBoxes[SUNT[0,x__,0],f_]/;MemberQ[$CLDefinedForm,f]:=
	RowBox[{SubscriptBox["tr","c"],"(",Sequence@@(SuperscriptBox["T",TDBox@#]&/@{x}),")"}];
SUNT/:MakeBoxes[SUNT[i_,x__,j_]/;i=!=0,f_]/;MemberQ[$CLDefinedForm,f]:=
	SubscriptBox[RowBox[{"(",SuperscriptBox["T",TDBox@#]&/@{x},")"}//Flatten],
		RowBox[{TDBox[i],TDBox[j]}]]; 
SUNT/:MakeBoxes[SUNT[i_,j_],f_]/;MemberQ[$CLDefinedForm,f]:=
		SubsuperscriptBox["\[Delta]",TDBox[i,j],"F"];

SUNF/:MakeBoxes[SUNF[i__],f_]/;MemberQ[$CLDefinedForm,f]&&Length@{i}>=3:=SubscriptBox["f",TDBox[i]];

SUND/:MakeBoxes[SUND[i__],f_]/;MemberQ[$CLDefinedForm,f]:=SubscriptBox["d",TDBox[i]];

SUNDelta/:MakeBoxes[SUNDelta[a_,b_],f_]/;MemberQ[$CLDefinedForm,f]:=
	SubsuperscriptBox["\[Delta]",TDBox[a,b],"A"];
	
SUNIndex/:MakeBoxes[SUNIndex[-1*x_],f_]/;MemberQ[$CLDefinedForm,f]:=SuperscriptBox[TDBox[x],"\[Prime]"];
SUNIndex/:MakeBoxes[SUNIndex[x_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[x]/;Head@x=!=Times;

SUNN/:MakeBoxes[SUNN,f_]/;MemberQ[$CLDefinedForm,f]:=SubscriptBox["N","c"];



(*CA=SUNN;CF=(SUNN^2-1)/(2SUNN);Tf=1/2;*)


(* ::Section::Closed:: *)
(*sunExpand*)


Attributes[sunExpand]={Listable};
sunExpand[exp_]:=Module[
	{r,times,uni},
	uni:=SUNIndex@Unique[r];
	exp/.a_^2:>times[a,a]//.SUNF[a_,b_,c__,d_]:>(SUNF[a,b,#]*SUNF[#,c,d]&@uni)//.
		SUNF[a_,b_,c_]/;!OrderedQ[{a,b,c}]:>Signature[{a,b,c}]*SUNF@@Sort[{a,b,c}]/.
		SUNT[0,a___,0]:>(SUNT[#,a,#]&@uni)//.
		SUNT[i_,a_,b__,j_]/;i=!=0:>(SUNT[i,a,#]*SUNT[#,b,j]&@uni)/.times->Times
];

Attributes[sunExpand0]={Listable};
sunExpand0[exp_]:=Module[
	{r,times,uni},
	uni:=SUNIndex@Unique[r];
	exp/.a_^2:>times[a,a]/.SUNDelta[a_,b_]:>2SUNT[0,a,b,0]//.
		SUNF[a_,b_,c__,d_]:>(SUNF[a,b,#]*SUNF[#,c,d]&@uni)/.
		SUNF[a_,b_,c_]:>-2*I*(SUNT[0,a,b,c,0]-SUNT[0,a,c,b,0])//.
		SUND[a_,b_,c__,d_]:>(SUND[a,b,#]*SUND[#,c,d]&@uni)/.
		SUND[a_,b_,c_]:>2*(SUNT[0,a,b,c,0]+SUNT[0,a,c,b,0])/.times->Times
];


(* ::Section::Closed:: *)
(*sunSimplifyT*)


(*Calculate color factors by only using relations of SUNT*)
Attributes[sunSimplifyT]={Listable};
sunSimplifyT[exp_,opts:OptionsPattern[]]:=Module[
	{r,expand,temp,factor=1,sunT,sep,color,join,sunSaved},
	
	join=clTimes[SUNT[i_,a___,j_],SUNT[j_,b___,k_],x___]/;j=!=0:>clTimes[SUNT[i,a,b,k],x];

	(*calcaluate multiplications of SUNT and then save them*)
	sunSaved[aa_clTimes]:=sunSaved[aa]=aa/.{
		clTimes[SUNT[0,_,0],x___]:>0,
		clTimes[SUNT[0,0],x___]:>SUNN sunSaved@clTimes[x],
		clTimes[SUNT[a_,b_],SUNT[a_,b_],x___]:>SUNN sunSaved@clTimes[x],
		clTimes[SUNT[i__,a_,a_,j__],x___]:>CF*sunSaved@clTimes[SUNT[i,j],x],
		clTimes[SUNT[i__,a_,j_,a_,k__],x___]:>-sunSaved@clTimes[SUNT[i,j,k],x]/(2SUNN),
		clTimes[SUNT[i__,a_,jk__,a_,l__],x___]:>
			sunSaved@clTimes[SUNT[i,l],SUNT[0,jk,0],x]/2-
			sunSaved@clTimes[SUNT[i,jk,l],x]/(2SUNN),
		clTimes[SUNT[i1_,i___,a_,j___,j1_],SUNT[k1_,k___,a_,l___,l1_],x___]:>
			(sunSaved@clTimes[Sequence@@#,x]/2&)@Switch[{i1,k1},{0,_},{SUNT[k1,k,j,i,l,l1]},
				{_,0},{SUNT[i1,i,l,k,j,j1]},_,{SUNT[i1,i,l,l1],SUNT[k1,k,j,j1]}]-
			sunSaved@clTimes[SUNT[i1,i,j,j1],SUNT[k1,k,l,l1],x]/(2SUNN)
	}/.sunSaved->Identity/.clTimes->Times//SimplifyList[#,_SUNT,"Factoring"->Expand]&;
		
	sep=Separate[exp//sunExpand0,_SUNT];

	color=sep[[2]];
	
	color=clTimesForm[color,"PowerExpand"->True]//.join/.SUNT[i_,a___,i_]/;i=!=0:>SUNT[0,a,0];
	color=color/.a_clTimes:>sunSaved[a];
			
	color=color/.SUNT[i_,a__,i_]:>
			SUNT@@Flatten[{0,Sort[RotateLeft[{a},#]&/@Range[Length[{a}]]][[1]],0}];
	
	color=Plus@@(sep[[1]]*color)/.CF->(SUNN^2-1)/(2SUNN)/.{SUNT[0,a_,b_,0]:>SUNDelta[a,b]/2};
	
	If[!FreeQ[sep[[1]],SUNIndex],
		sep=Separate[color,SUNIndex,"FreeForm"->True];
		sep[[2]]=clTimesForm[sep[[2]]]//.
			clTimes[SUNDelta[a_,b_],c__]/;!FreeQ[{c},a]:>clTimes@@({c}/.a:>b)//.
			clTimes[SUNT[i_,j_],c__]/;!FreeQ[{c},i]:>clTimes@@({c}/.i:>j)//.
			clTimes[SUNT[i_,j_],c__]/;!FreeQ[{c},j]:>clTimes@@({c}/.j:>i)/.
			clTimes->Times;
		color=Dot@@sep;
	];
	
	color=SimplifyList[color,_SUNT|_SUNDelta,"Factoring"->Factor];

	
	Return[factor*color]
];


(* ::Section::Closed:: *)
(*SUNSimplify*)


(*Main function*)


Attributes[SUNSimplify]={Listable};
Options[SUNSimplify]={"OnlyT"->False,"CheckQ"->True};
SUNSimplify[exp_,opts:OptionsPattern[]]:=Module[
	{indexes,r,expand,temp,factor=1,sunt,sunT,sep,color,one,ff3,ff2,ff1,fttt,ftt,ft},
	
	(*check dummy indexes*)
	If[OptionValue["CheckQ"], 
		indexes=CountIndexes[exp,SUNIndex];
		If[Max@indexes[[All,2]]>2,
			Print["Error: More than 2 dummy indexes detected: ",{exp//Short, indexes}];
			Abort[];
		]
	];
	
	indexes=Cases[{exp},Blank/@Alternatives@@$SUNFunctions,Infinity]/.SUNT[0,x___,0]:>{x};
	indexes=List@@@indexes//Flatten//Union;
	indexes=Select[indexes,Head@#=!=SUNIndex&];
	If[indexes=!={},
		Print["Incorrect input for SUNSimplify: ",{exp//Short, indexes}];
		Abort[];
	];
	
	expand[x___,c_,y___]/;FreeQ[c,expand|DiracGamma|DiracSpinor]/;c=!=0:=c*expand[x,y];	
	expand[x___,z_*c_,y___]/;FreeQ[c,expand|DiracGamma|DiracSpinor]:=c*expand[x,z,y];
	expand[x___,z1_*z2_,y___]/;!FreeQ[z1,SUNIndex]&&!FreeQ[z2,SUNIndex]:=expand[x,z1,z2,y];
	expand[x___,z1_+z2_,y___]/;!FreeQ[{z1,z2},SUNIndex]:=expand[x,z1,y]+expand[x,z2,y];
	temp=exp/.DiracChain->expand/.expand->DiracChain;
	
	(**********************)
	
	If[Head[temp]===Plus,Plus@@SUNSimplify[
		List@@temp,"OnlyT"->OptionValue["OnlyT"],"CheckQ"->False]//Return];
	
	If[Head[temp]===Times,factor=Select[temp,FreeQ[#,SUNIndex]&];
		temp=Select[temp,!FreeQ[#,SUNIndex]&],factor=1];
	
	If[OptionValue["OnlyT"]||FreeQ[temp,SUNF],factor*sunSimplifyT@temp//Return];
		
	(*f^abc*f^abc*)
	ff3=_SUNF^2:>SUNN*(SUNN^2-1);
	(*f^abc*f^abd*)
	ff2={clTimes[SUNDelta[a_,b_],c__]/;!FreeQ[{c},a]:>clTimes@@({c}/.a:>b),
		 clTimes[SUNF[a_,b_,c_]|SUNF[c_,a_,b_]|SUNF[b_,c_,a_],
		  SUNF[a_,b_,d_]|SUNF[d_,a_,b_]|SUNF[b_,d_,a_],e___]:>SUNN*clTimes[SUNDelta[c,d],e],
		 clTimes[SUNF[a_,b_,c_]|SUNF[c_,a_,b_]|SUNF[b_,c_,a_],
		  SUNF[b_,a_,d_]|SUNF[d_,b_,a_]|SUNF[a_,d_,b_],e___]:>-SUNN*clTimes[SUNDelta[c,d],e]
		  };
	(*f^abe*f^cde*)
	ff1=clTimes[SUNF[a_,b_,e_]|SUNF[e_,a_,b_]|SUNF[b_,e_,a_],
		      SUNF[c_,d_,e_]|SUNF[e_,c_,d_]|SUNF[d_,e_,c_],f___]:> -
		      2 clTimes[clTimesForm@sunExpand@SUNT[0,a,b,c,d,0],f] +
		      2 clTimes[clTimesForm@sunExpand@SUNT[0,a,b,d,c,0],f]+
		      2 clTimes[clTimesForm@sunExpand@SUNT[0,a,c,d,b,0],f]-
		      2 clTimes[clTimesForm@sunExpand@SUNT[0,a,d,c,b,0],f];
  
	(*f^abc*t^a*t^b*t^c*)
	fttt=clTimes[SUNF[a_,b_,c_]|SUNF[c_,a_,b_]|SUNF[b_,c_,a_],
			SUNT[i_,a_,j_],SUNT[k_,b_,l_],SUNT[m_,c_,n_],d___]:>clTimes[d]*
			(I/4)*(SUNT[i, n]*SUNT[k, j]*SUNT[m, l]-SUNT[i, l]*SUNT[k, n]*SUNT[m, j]);
				
	(*f^abc*t^a*t^b*)
	ftt=clTimes[SUNF[a_,b_,c_]|SUNF[c_,a_,b_]|SUNF[b_,c_,a_],
			SUNT[i_,a_,j_],SUNT[k_,b_,l_],d___]:>(I/2)*SUNT[k, j]*clTimes[SUNT[i, c, l],d]-
			(I/2)*SUNT[i, l]*clTimes[SUNT[k, c, j],d];
	(*f^abc*t^a*)
	ft=clTimes[SUNF[a_,b_,c_]|SUNF[c_,a_,b_]|SUNF[b_,c_,a_],
			SUNT[i_,a_,j_],d___]:>(I*clTimes[SUNT[i, c, #],SUNT[#, b, j],d] - 
			I*clTimes[SUNT[i, b, #],SUNT[#, c, j],d]&)@SUNIndex@Unique[r];

	(*Remove SUND. Can be improved if there are too many SUND's*)
	temp=temp/.a_SUND:>sunExpand0@a;
	sep=Separate[temp,Blank/@Alternatives@@$SUNFunctions];
	
	(*Expand SUNT and SUNF*)
	color=sep[[2]]//sunExpand;

	color=clTimesForm[color]//.ff2/.clTimes->Times;
	
	color=sunExpand[color]//.ff3;
	
	color=clTimesForm[color]//.fttt//.{fttt,ftt}//.{fttt,ftt,ft}//.
			{ff1,fttt,ftt,ft}/.clTimes->Times;
	
	color=sunSimplifyT[Plus@@(sep[[1]]*color)]/.{SUNT[0,a_,b_,0]:>SUNDelta[a,b]/2};
	
	factor*color
];


(* ::Section::Closed:: *)
(*End*)


End[];
