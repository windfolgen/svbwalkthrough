(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


FamilyInf::usage="FamilyInf[fname,tag] returns information of 'tag' of the family 'fname'. \
'tag' can be one of the following choices: \"LM\" means loop momenta, \"EM\" means \
external momenta, \"PD\" means propagator denominators, \"SP\" means scalar products, \
\"UF\" means Symanzik polynomials U and F, and \"Baikov\" means Baikov polynomial \
and solutions of syzygy equations.";


DefineFamily::usage="DefineFamily[fname,loopmom,extmom,conservation,pdlist,spsRep] \
defines information of the family 'fname' and the information are stored in FamilyInf. \
Here 'loopmom' is a list of loop momenta, 'extmom' is a list of external momenta, \
'conservation' can be {} or {moms1->moms2} representing possible relation due to \
momentum conservation, 'pdlist' is a list of propagator denominators, 'spsRep' is \
a list of replacement rules of scalar products.
OptionValue[\"Parameter\"] is the head of parameters in various representations.
";


SymanzikPolynomials::usage="SymanzikPolynomials[x_,gpds_List,loopmom_List,SPRep_:{}]={U,F} \
returns Symanzik polynomials U and F. Here 'x[i]' are variables in U and F, 'pdlist' is \
a list of propagator denominators, like {l1*l1-m^2, l2*p, ...},  'loopmom' is a list \
of loop momenta, and the replacement rule 'SPRep', like {p1*p2->s12,...}, is applied \
for final results.";


BaikovPolynomial::usage="\
{Bz,syzB}=BaikovPolynomial[z_,pdlist_,loopmom_,extmom0_,spsRep_,OptionsPattern[]] \
returns Baikov polynomial as while as solutions of syzygy equations among it and \
its derivatives, which satisifies #[[1;;-2]].Table[D[Bz,z[i]],{i,Length@pdlist}]+\
#[[-1]]*Bz&/@syzB=={0,...,0}. Syzygies are solved by using Laplace expansion. \
Here 'pdlist' is a list of propagator denominators, 'loopmom' is a list of loop \
momenta, 'extmom0' is a list of external momenta, 'spsRep' is a list of replacement \
rules of scalar products, and 'z[i]' are variables in Baikov representationl. \
The option \"Relation\" can be {} or {moms1->moms2}, which represents possible \
relation due to momentum conservation.";


StablePointExpansion::usage="{mat,trans,order}=SymmetricDecomposition[Mat] decomposes \
a symmetric matrix 'Mat' into a diagonal matrix 'mat' together the transformation \
matrix 'trans', satisfying 'Mat'=Transpose['trans'].'mat'.'trans'. 'order' looks \
like {{\!\(\*SubscriptBox[\(i\), \(1\)]\)},{\!\(\*SubscriptBox[\(i\), \(2\)]\),\
\!\(\*SubscriptBox[\(i\), \(3\)]\)},{\!\(\*SubscriptBox[\(i\), \(4\)]\)},...}, \
denoting the order of block diagonalization.
OptionValue[\"Preference\"] is a list of numbers, denoting the preference of the \
order of block diagonalization.
If OptionValue[\"MinBlock\"] is True, blocks will be chosen as small as possible.";

AuxiliaryMassExpansion::usage="";


Begin["`Private`"];
End[];


Begin["`IBP`"];


(* ::Section::Closed:: *)
(*DefineFamily*)


Options[DefineFamily]={"Parameter"->"x"};
DefineFamily[fname_,loopmom_List,extmom0_List,conservation_List,pdlist_List,spsRep0_List,OptionsPattern[]]:=Module[
{x,extmom,pp,relation,spsRep},
x=OptionValue["Parameter"];
(*extmom: indepenent external momenta*)
(*If only independent external momenta are involved, introduce an auxiliary momentum 'pp'*)
If[conservation==={},
extmom=extmom0;
relation={pp->Plus@@extmom0},
extmom=extmom0[[1;;-2]];
relation=conservation
];
spsRep=GenerateScalarProducts[extmom,spsRep0,relation];
(*Loop momenta*)
FamilyInf[fname,"LM"]=loopmom;
(*Independent external momenta*)
FamilyInf[fname,"EM"]=extmom;
(*Denominators*)
FamilyInf[fname,"PD"]=pdlist;
(*Complete list of scalar products*)
FamilyInf[fname,"SP"]=spsRep;
(*U and F in Feynman parameterization representation.*)
FamilyInf[fname,"UF"]:=FamilyInf[fname,"UF"]=EvaluateUF[loopmom,extmom,pdlist,spsRep,x];
(*Baikov polynomial and solutions of syzygy equations *)
FamilyInf[fname,"Baikov"]:=FamilyInf[fname,"Baikov"]=BaikovPolynomial[loopmom,extmom,pdlist,spsRep,x];
True
];


(* ::Section::Closed:: *)
(*SymanzikPolynomials*)


(*
After Feynman parametrization we have
\!\(
\*SubscriptBox[\(\[Sum]\), \(i\)]\(x[i]*denominator[\([i]\)]\)\)
=loopmom^T.A.loopmom-2loopmom.B+C
=(loopmom-A^-1.B)^T.A.(loopmom-A^-1.B)-(B^T.A^-1.B-C),
where A can always be chosen as a symmetric matrix. Thus, 
\[Integral](\!\(
\*SubscriptBox[\(\[Sum]\), \(i\)]\(x[i]*denominator[\([i]\)]\)\))^-N
=(B^T.A^-1.B-C)^(LD/2-N) \[Integral](loopmom'.A.loopmom'-1)^-N
=(B^T.A^-1.B-C)^(LD/2-N) \[Integral](\!\(
\*SubscriptBox[\(\[Sum]\), \(i\)]\(
\*SubscriptBox[\(\[Lambda]\), \(i\)]
\*SuperscriptBox[
SubscriptBox[\(l\), \(i\)], \(2\)]\)\)-1)^-N
=(B^T.A^-1.B-C)^(LD/2-N) (\!\(
\*SubscriptBox[\(\[Product]\), \(i\)]
\*SubscriptBox[\(\[Lambda]\), \(i\)]\))^(-D/2)\[Integral](\!\(
\*SubscriptBox[\(\[Sum]\), \(i\)]
\*SuperscriptBox[
SubscriptBox[\(l\), \(i\)], \(2\)]\)-1)^-N
=(F/U)^(LD/2-N) U^(-D/2)(-1)^NI^L\[Integral](\!\(
\*SubscriptBox[\(\[Sum]\), \(i\)]
\*SuperscriptBox[
SubscriptBox[\(L\), \(i\)], \(2\)]\)+1)^-N
=(F/U)^(LD/2-N) U^(-D/2)(-1)^N (I\[Pi]^(D/2))^L*(\[CapitalGamma](N-LD/2))/(\[CapitalGamma](N))
where U=Det[A]=\!\(
\*SubscriptBox[\(\[Product]\), \(i\)]\(
\*SubscriptBox[\(\[Lambda]\), \(i\)]\ and\ F\)\)= Det[A](B^T.A^-1.B-C);
*)
Options[SymanzikPolynomials]={};
SymanzikPolynomials[x_,gpds_List,loopmom_List,SPRep_:{}, OptionsPattern[]]:=Module[
	{denominator,n,l,\[Lambda],A,B,C,U,F},
	
	denominator=gpds//Expand;
	n=Length@gpds;
	l = Length@loopmom;
	
	denominator=Array[x,n] . denominator/.Thread[loopmom->\[Lambda]*loopmom];
	
	(* no quadratic propagator*)
	If[Exponent[denominator,\[Lambda]]<2,
		Return@{0,0}
	];
	
	(*unknown structure*)
	If[Exponent[denominator,\[Lambda]]>2,
		Print["Incorrect input for SymanzikPolynomials: {loopmom,gpds}=", {loopmom,gpds}];
		Abort[];
	];
	
	{C,B,A}=CoefficientList[denominator,\[Lambda]];
	B=-1/2 Coefficient[B,#]&/@loopmom;
	A=Table[
		If[i==j, Coefficient[A,loopmom[[i]]^2],
				1/2 Coefficient[A,loopmom[[i]]loopmom[[j]]]
		],
		{i,l},{j,l}
	];
(*SimplifyList[loopmom.A.loopmom-2loopmom.B+C-denominator/.\[Lambda]->1, _x]//Print;*)
	
	U = Det[A]//Expand;
	If[U===0,Return@{0,0}];(*singular case*)
	F = Expand[B . Cancel[U*Inverse[A]] . B - U* C]/.Thread[(SPRep[[All,1]]/.SP->Times)->SPRep[[All,2]]];
	{U,F}//Expand
];


(* ::Section::Closed:: *)
(*BaikovPolynomial*)


Options[BaikovPolynomial]={"ExternalMomenta"->{},"Relation"->{}};
BaikovPolynomial[z_,pdlist_,loopmom_,replacement_,OptionsPattern[]]:=Module[
	{relation,pp,extmom0,extmom,i,j,k,csp,mat,csp2prop,polyB,x,e,l=Length@loopmom,a,Bz,syzB},
	(*extmom: indepenent external momenta*)
	(*If only independent external momenta are involved, introduce an auxiliary momentum 'pp'*)
	extmom0=OptionValue["ExternalMomenta"];
	If[OptionValue["Relation"]==={},
		extmom=extmom0;
		relation={pp->Plus@@extmom0},
		extmom=extmom0[[1;;-2]];
		relation=OptionValue["Relation"]
	];
	(*replacement=GenerateScalarProducts[extmom,spsRep,relation[[1]]];*)
	
	(*csp: scalar products depending on loop momenta*)
	For[csp={};i=1,i<=l,i++,
		For[j=i,j<=l,j++,
			AppendTo[csp,loopmom[[i]]loopmom[[j]]]
		]
	];
	csp=csp~Join~(Join@@Outer[Times,loopmom,extmom]);
	
	mat=Coefficient[#,csp]&/@pdlist;
	(*Whether is it reversible*)
	If[MatrixRank[mat]<Length@mat||Length@mat=!=Length@mat[[1]],
		ErrorPrint["Wrong input for BaikovPolynomial: ",{pdlist,loopmom,extmom}];
		Return[];
	];
	
	csp2prop=Thread[csp->Inverse[mat] . Expand[mat . csp-pdlist+Array[z,Length@pdlist]]];
	
	polyB=Outer[Times,#,#]&@(extmom~Join~loopmom)//Expand;
	
	Bz=Det[polyB/.csp2prop/.replacement]//Expand;
	(*out2=polyB/.csp2prop/.replacement;*)
	
	(*Laplace expansion. Eq.(2.29) in 1805.01873*)
	e=Length@extmom;
	syzB=Table[
		Append[Table[Sum[If[i===k,2,1]Coefficient[pdlist[[a]],polyB[[i,k]]]*polyB[[j,k]],
			{k,1,e+l}],{a,Length@pdlist}],If[i===j,-2,0]]
		,{i,e+1,e+l},{j,1,e+l}
	];
	syzB=Flatten[syzB,1]/.csp2prop/.replacement//Expand;
	
	Return[{Bz,syzB}];
];


(* ::Section::Closed:: *)
(*StablePointExpansion*)


Options[StablePointExpansion]={"Preference"->{},"MinBlock"->True,WorkingPrecision->300};
StablePointExpansion[FIs_,SPInfo_,norder_,OptionsPattern[]]:=Module[
{precision=OptionValue[WorkingPrecision],chop,zeroQ,n,i,j,k,\[Kappa],vars,sp,blist,dens,b0,B2,bx,dia,trans,ordering,rep,bi,temp,save,int,zeros,res},
chop[exp_]:=Chop[exp,10^(-1/2*precision)];
zeroQ[num_]:=chop[num]===0;

n=2norder;
{sp,blist,vars}=SPInfo//chop;

(*\[Kappa]=\[Lambda]^(-1/2) is an infinitesimal quantity*)
dens=CoefficientList[#,\[Kappa]]&/@(sp+\[Kappa]*vars);
blist=-(1/\[Kappa]^2)blist;

b0=blist[[1]];
(*B2 is a \[Kappa]-independent symmetric matrix, with b2=vars.B2.vars*)
B2=Table[1/2 D[blist[[3]],i,j],{i,vars},{j,vars}]/.\[Kappa]->1;
bx=CoefficientList[Plus@@blist[[4;;-1]]/.Thread[vars->\[Kappa] vars],\[Kappa]];


(*Calculate transformation matrix*)
{dia,trans,ordering}=SymmetricDecomposition[B2,"Preference"->Automatic,WorkingPrecision->precision];

(*Ordering the denominators*)
dens=Table[dens[[ordering[[i,j]]]],{i,Length@ordering},{j,Length@ordering[[i]]}];
dia=Table[dia[[ordering[[i,j]],ordering[[i,j]]]],{i,Length@ordering},{j,Length@ordering[[i]]}];

(*use new variables, although name is not changed*)
rep=Thread[vars->Inverse@trans . vars];
{bx,dens}={bx,dens}/.rep//Expand//chop;

WriteMessage["point=",sp/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["ordering=",ordering];
WriteMessage["dens=",dens/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["bx=",bx/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["dia=",dia/.a_Real|a_Complex:> Round[a,10^-2.]];

(*expansion of E^bx*)
bi[0]=UnitVector[n+1,1];
For[i=1,i<=n,i++,
bi[i]=VecMul[bi[i-1],bx]
];
save[{{}}]=Sum[bi[i]/i!,{i,0,n}]//Expand//chop;

(*calculate expansion of denominators recursively*)
save[pows0_List]/;Length@pows0[[1]]>0:=save[pows0]=Module[
{pows,vec},

pows=pows0;
(*Integrate previous variables if there is no variable in the current list*)
If[pows[[-1]]==={},pows=pows[[1;;-2]];
vec=save[pows];
vec=CLTiming[int[vec,Length@pows],"Integrate "<>ToString@vars[[ordering[[Length@pows]]]]];
Return[vec//chop]];

(*Expand denominators one by one*)
Which[
pows[[-1,-1]]===0,pows[[-1]]=Drop[pows[[-1]],{-1}];
Return[save[pows]],
pows[[-1,-1]]>0,pows[[-1,-1]]-=1; vec=VecDiv[save[pows],dens[[Length@pows,Length@pows[[-1]]]]];
Return[vec//chop],
pows[[-1,-1]]<0,pows[[-1,-1]]+=1; vec=VecMul[save[pows],dens[[Length@pows,Length@pows[[-1]]]]];
Return[vec//chop]
]
];

(*Perform Gaussian integration*)
int[poly_,ni_]:=Module[
{ii,jj,kk,vs,b2,vec,f},

vs=vars[[ordering[[ni]]]];
b2=dia[[ni]];
WriteMessage["LeafCount before integration=",LeafCount@poly];
(* f[n_]=Integrate[x^nE^(a x^2),{x,-\[Infinity],\[Infinity]}], f[0,a]=Sqrt[\[Pi]]/Sqrt[-a] as an overall factor*)
f[0,a_]:=1;
f[1,a_]:=0;
f[i_,a_]/;i>1:=-((i-1)/(2 a)) f[i-2,a];
If[Length@vs===1,
vec=CoefficientList[poly,vs[[1]]]//CLTiming;
vec=Table[Sum[f[jj-1,b2[[1]]]*vec[[ii,jj]],{jj,1,Length@vec[[ii]],2}],{ii,Length@vec}]//CLTiming;
vec//chop//Return
];
If[Length@vs===2,
vec=CoefficientList[poly,vs]//CLTiming;
vec=Table[Sum[f[ii-1,b2[[1]]]*f[jj-1,b2[[2]]]*vec[[kk,ii,jj]],{ii,1,Length@vec[[kk]],2},{jj,1,Length@vec[[kk,ii]],2}],{kk,Length@vec}]//CLTiming;
vec//chop//Return
];
];

zeros=Flatten@Position[sp,0];

(*Final results*)
res=Table[
(*The {} is a flag of the end of the expansion*)
If[Max@FIs[[i,zeros]]>0,
(*Remove ill-defined integrals. ????*)
ConstantArray[0,n+1]
,
CLTiming[save[Append[FIs[[i,#]]&/@ordering,{}]],"Expansion of "<>ToString@FIs[[i]]]
]
,{i,Length@FIs}
];
(*even terms are always zero*)

{E^b0 Sqrt[\[Pi]]/Sqrt[Times@@(-Flatten@dia )]/.\[Kappa]->("\[Lambda]")^(-1/2),Take[#,{1,-1,2}]&/@res}

];


(* ::Section::Closed:: *)
(*AuxiliaryMassExpansion*)


Options[AuxiliaryMassExpansion]={"Preference"->{},"MinBlock"->True,WorkingPrecision->300};
AuxiliaryMassExpansion[FIs_,SPInfo_,norder_,OptionsPattern[]]:=Module[
{precision=OptionValue[WorkingPrecision],chop,zeroQ,n,i,j,k,\[Kappa],vars,sp,blist,dens,b0,B2,bx,dia,trans,ordering,rep,bi,temp,save,int,zeros,res},
chop[exp_]:=Chop[exp,10^(-1/2*precision)];
zeroQ[num_]:=chop[num]===0;

n=2norder;
{sp,blist,vars}=SPInfo//chop;

(*\[Kappa]=\[Lambda]^(-1/2) is an infinitesimal quantity*)
dens=CoefficientList[#,\[Kappa]]&/@(sp+\[Kappa]*vars);
blist=-(1/\[Kappa]^2)blist;

b0=blist[[1]];
(*B2 is a \[Kappa]-independent symmetric matrix, with b2=vars.B2.vars*)
B2=Table[1/2 D[blist[[3]],i,j],{i,vars},{j,vars}]/.\[Kappa]->1;
bx=CoefficientList[Plus@@blist[[4;;-1]]/.Thread[vars->\[Kappa] vars],\[Kappa]];


(*Calculate transformation matrix*)
{dia,trans,ordering}=SymmetricDecomposition[B2,"Preference"->Automatic,WorkingPrecision->precision];

(*Ordering the denominators*)
dens=Table[dens[[ordering[[i,j]]]],{i,Length@ordering},{j,Length@ordering[[i]]}];
dia=Table[dia[[ordering[[i,j]],ordering[[i,j]]]],{i,Length@ordering},{j,Length@ordering[[i]]}];

(*use new variables, although name is not changed*)
rep=Thread[vars->Inverse@trans . vars];
{bx,dens}={bx,dens}/.rep//Expand//chop;

WriteMessage["point=",sp/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["ordering=",ordering];
WriteMessage["dens=",dens/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["bx=",bx/.a_Real|a_Complex:> Round[a,10^-2.]];
WriteMessage["dia=",dia/.a_Real|a_Complex:> Round[a,10^-2.]];

(*expansion of E^bx*)
bi[0]=UnitVector[n+1,1];
For[i=1,i<=n,i++,
bi[i]=VecMul[bi[i-1],bx]
];
save[{{}}]=Sum[bi[i]/i!,{i,0,n}]//Expand//chop;

(*calculate expansion of denominators recursively*)
save[pows0_List]/;Length@pows0[[1]]>0:=save[pows0]=Module[
{pows,vec},

pows=pows0;
(*Integrate previous variables if there is no variable in the current list*)
If[pows[[-1]]==={},pows=pows[[1;;-2]];
vec=save[pows];
vec=CLTiming[int[vec,Length@pows],"Integrate "<>ToString@vars[[ordering[[Length@pows]]]]];
Return[vec//chop]];

(*Expand denominators one by one*)
Which[
pows[[-1,-1]]===0,pows[[-1]]=Drop[pows[[-1]],{-1}];
Return[save[pows]],
pows[[-1,-1]]>0,pows[[-1,-1]]-=1; vec=VecDiv[save[pows],dens[[Length@pows,Length@pows[[-1]]]]];
Return[vec//chop],
pows[[-1,-1]]<0,pows[[-1,-1]]+=1; vec=VecMul[save[pows],dens[[Length@pows,Length@pows[[-1]]]]];
Return[vec//chop]
]
];

(*Perform Gaussian integration*)
int[poly_,ni_]:=Module[
{ii,jj,kk,vs,b2,vec,f},

vs=vars[[ordering[[ni]]]];
b2=dia[[ni]];
WriteMessage["LeafCount before integration=",LeafCount@poly];
(* f[n_]=Integrate[x^nE^(a x^2),{x,-\[Infinity],\[Infinity]}], f[0,a]=Sqrt[\[Pi]]/Sqrt[-a] as an overall factor*)
f[0,a_]:=1;
f[1,a_]:=0;
f[i_,a_]/;i>1:=-((i-1)/(2 a)) f[i-2,a];
If[Length@vs===1,
vec=CoefficientList[poly,vs[[1]]]//CLTiming;
vec=Table[Sum[f[jj-1,b2[[1]]]*vec[[ii,jj]],{jj,1,Length@vec[[ii]],2}],{ii,Length@vec}]//CLTiming;
vec//chop//Return
];
If[Length@vs===2,
vec=CoefficientList[poly,vs]//CLTiming;
vec=Table[Sum[f[ii-1,b2[[1]]]*f[jj-1,b2[[2]]]*vec[[kk,ii,jj]],{ii,1,Length@vec[[kk]],2},{jj,1,Length@vec[[kk,ii]],2}],{kk,Length@vec}]//CLTiming;
vec//chop//Return
];
];

zeros=Flatten@Position[sp,0];

(*Final results*)
res=Table[
(*The {} is a flag of the end of the expansion*)
If[Max@FIs[[i,zeros]]>0,
(*Remove ill-defined integrals. ????*)
ConstantArray[0,n+1]
,
CLTiming[save[Append[FIs[[i,#]]&/@ordering,{}]],"Expansion of "<>ToString@FIs[[i]]]
]
,{i,Length@FIs}
];
(*even terms are always zero*)
Print[dia];
{E^b0 Sqrt[\[Pi]]/Sqrt[Times@@(-Flatten@dia )]/.\[Kappa]->("\[Lambda]")^(-1/2),Take[#,{1,-1,2}]&/@res}

];


(* ::Section::Closed:: *)
(*End*)


End[];
