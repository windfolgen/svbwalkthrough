(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


RemoveZeroSector::usage="RemoveZeroSector[exp_,momE_List,loopM_List,SPRep_] \
find vanishing integrals in exp and set them to zero. \
loopM is the list of loop momenta.";


ZeroSectorQ::usage="";


GPD::usage="";
GPDSplit::usage="";
GPDCombine::usage="";
GPDExplicit::usage="";


LoopMomentum::usage="LoopMomentum[i] is a loop momentum in the amplitudes if i>0, and \
it is a loop momentum in the complex conjugate amplitudes if i<0."


Begin["`Private`"];
SPExpand;
End[];


Begin["`ZeroSector`"];


LoopMomentum/:MakeBoxes[LoopMomentum[i_],f_]/;MemberQ[$CLDefinedForm,f]/;i>0:=SubscriptBox["l",i];
LoopMomentum/:MakeBoxes[LoopMomentum[i_],f_]/;MemberQ[$CLDefinedForm,f]/;i<0:=SubsuperscriptBox["l",-i,"\[Prime]"];


GPD/:MakeBoxes[GPD[a__],f_]/;MemberQ[$CLDefinedForm,f]:=
	FractionBox[gPDinverse@@({1,1,1,-1}*#&/@Select[{a},#[[-1]]<0&])//TDBox,
	gPDinverse@@Select[{a},#[[-1]]>0&]//TDBox];
gPDinverse/:MakeBoxes[gPDinverse[],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[1];
gPDinverse/:MakeBoxes[gPDinverse[{p1_,p2_,m2_,1}],f_]/;MemberQ[$CLDefinedForm,f]:=
	RowBox[{If[p1===p2,TDBox[p1^2],TDBox[p1,"\[CenterDot]",p2]],If[m2===0,{},{"-",TDBox[-m2]}]}//Flatten];
gPDinverse/:MakeBoxes[gPDinverse[{p1_,p2_,m2_,n_}],f_]/;MemberQ[$CLDefinedForm,f]&&n>1:=
	SuperscriptBox[TDBox["(",gPDinverse[{p1,p2,m2,1}],")"],TDBox@n];
gPDinverse/:MakeBoxes[gPDinverse[a1_,a2__],f_]/;MemberQ[$CLDefinedForm,f]:=
	TDBox[Times@@gPDinverse/@{a1,a2}];


(* ::Section::Closed:: *)
(*Manipulate GPD*)


GPDSplit[exp_]:=exp/.x_GPD:>(x/.GPD[a_,b__]:>Times@@GPD/@{a,b}/.
	GPD[{p1_,p2_,m_,n_}]/;n=!=1:>GPD[{p1,p2,m,1}]^n);

Attributes[GPDCombine]={Listable};
GPDCombine[exp_]:=Module[
	{head,sep,factor,GPDinv},
	
	head=Head@exp;
	
	If[FreeQ[exp,GPD], Return@exp];
	
	If[head===Plus,Plus@@GPDCombine@(List@@exp)//Return];
	
	If[head===Times,
		factor=Select[exp,FreeQ[#,GPD]&];
		sep=If[factor===1,
			exp,
			Select[exp,!FreeQ[#,GPD]&]
		],
		factor=1;
		sep=exp
	];
	
	sep=Separate[GPDSplit@sep/.GPD[a_]^n_/;n<0:>GPDinv[a]^-n,_GPD|_GPDinv];
	sep[[2]]=sep[[2]]/.GPDinv[a_]:>GPD[a]^-1/.GPD[]^n_:>GPD[]/.
		GPD[{p1_,p2_,m_,n1_}]^n2_:>GPD[{p1,p2,m,n1*n2}]//.
		GPD[a___]*GPD[b___]:>GPD[a,b]/.GPD[a__]:>GPD@@Sort@{a};
		
	factor*Dot@@sep
];

(*Definition of General Propagator Denominators: GPD[{p1,p2,m2,pow}]=(p1.p2+m2)^-pow *)
GPDExplicit[exp_]:=GPDSplit[exp]/.
	GPD[{p1_,p2_,m2_,pow_}]:>Expand@MomentumSimplify@CLForm[(SP[p1,p2]+m2)^-pow];
GPDExplicit[exp_,SPRep_]:=Block[
	{},
	GPDSplit[exp]/.
		GPD[{p1_,p2_,m2_,pow_}]:>SPExpand[SP[p1,p2]+m2,SPRep]^-pow
];


SPExpand[exp_,SPRep_]:=exp/.SP[p1_,p2_]:>Expand[Distribute@SP[Expand@p1,Expand@p2]//.
		SP[a_?NumberQ*pi_,pj_]:>a*SP[pi,pj]/.SPRep]


(* ::Section::Closed:: *)
(*ZeroSectorQ*)


ZeroSectorQ[pdlist_List,loopmom_,SPRep_]:=Module[
	{i,pos,n=Length@pdlist,flag,G,x,k,xprod,eq,eqlist,terms,mat,redmat},
	
	If[Length@loopmom===0, Return[False,Module]];
	If[n===0,Return[True,Module]];	
		
	(*calculate G=U+F*)
	G=Plus@@SymanzikPolynomials[x,pdlist,loopmom,SPRep];
	
	(*Eq.(16) of 1310.1145: Criterion is Sum[k[i]x[i]D[G,x[i]],{i,n}] = G with G=F+U*)	
	eq=Sum[k[i]*x[i]*D[G,x[i]],{i,n}]-G//Expand;
	If[eq===0,Return[True]];

	(*As k's are independent of x's, coefficients of x's must vanish*)
	eqlist=Separate[eq,_x][[1]];
	
	(*change equations to matrix form*)
	mat=Append[Coefficient[eqlist,#]&/@Array[k,n],eqlist/._k->0]//MMATranspose;
	(*solve equations*)
	redmat=RowReduce[mat];
	
	(*If no solution, there must be a line {0,...,0,1}*)
	If[Select[redmat,#[[-1]]=!=0&&Union@#[[1;;-2]]==={0}&]==={},
		True,
		False
	]
];


(* ::Section::Closed:: *)
(*RemoveZeroSector*)


Options[RemoveZeroSector]={};
RemoveZeroSector[exp_,loopM_List,SPRep_,OptionsPattern[]]:=Module[
	{GPDToSector,res,gpds,reps,i,dens},
	
	GPDToSector[gpd_GPD]:=Module[
	{ressec},
	ressec=Select[List@@gpd,#[[-1]]>0&];
	ressec=GPD/@(Append[#[[1;;-2]],-1]&)/@ressec;
	ressec=GPDExplicit[ressec,SPRep]/.SP[a_,b_]:>a*b;
	ressec
	];
	
	res=exp//GPDCombine;
	
	gpds=Cases[{res},_GPD,Infinity]//Union;
	
	reps=gpds;
	Do[
		(*Test if cut propagators appear in numerator*)
		dens=GPDExplicit[gpds[[i]],SPRep];
		If[dens===0,
			reps[[i]]=0;
			Continue[]
		];

		(*Test it by linear transformation*)
		dens=GPDToSector@gpds[[i]];
		dens=Select[dens,!FreeQ[#,Alternatives@@loopM]&];
		If[ZeroSectorQ[dens,loopM,SPRep],reps[[i]]=0]
		,{i,Length@gpds}
	];
	res=res/.Dispatch@Thread[gpds->reps];
	res
];


(* ::Section::Closed:: *)
(*End*)


End[];


(***  
""" 
README
CHANGELOG v1.0.7
1. change option 'IncomingMomenta' to 'TotalInMom'.
2. sort the resulting set of propagators (similar to the applied sorting method, but using the explicit algebraic form of propagators).

CHANGELOG v1.0.6
1. fix problems for cut diagrams: 
a) cut propagators don't come first in fullLB, 
which makes sorting in level-2 (only changing order in set {1,...,nc}, {(nc+1),...,nl} respectively) useless.
b) the constructing of transformation matrix in level-2 was using full permutation.

CHANGELOG v1.0.5
1. Problem with the previous version about Branch-Reduced loop basis: it used cut of the full propagator set. 
This problem is fixed by defining and evaluating 'reducut' and evaluating 'ReduLB' with option
 'Cut->reducut' but not 'Cut->cut'.
2. The feature of v1.0.4 is redesigned as an option 'AllTransRules' with default value 'False'.
When this option is True, one can get the full set of transformation rules that make the propagator set into the same canonical form.
(one particular rule multiplied by any automorphism)

CHANGELOG v1.0.4
In this version, the output transformation rules are all that can make the propagator sets into the canonical one. 
In other word, these rules are a specific rule multiplied by automorphisms.

CHANGELOG v1.0.3:
Fixed bugs in level 3 sorting: the program only takes the first one in 'LBrulesstd2list'.
Add options for canonization of loop momenta with cut.

CHANGELOG v1.0.2:
Sorting in each branch with 'propshape' to make symmetry smaller.

CHANGELOG v1.0.1:
Solved the problems occuring at factorizable diagrams: 
a)Handling empty matrices 'extedgmat' in function 'SortInBranch[branches_,extedgmat_,extmomlist_]';
b)For identical propagators in the same branch due to the appearance of factorizing vertices, 
choose the first (unsorted given order) of the identical propagators in each direction.
Now we can apply the program on factorizable diagrams with no barriers.



DESCRIPTION OF v1.0.0: 

1. Classify propagators in different branches and sort each branch in advance (as in v0.1.1)
a) classify propagators according to branches (inherited from v0.1.1):
This procedure is completed by find identical columns in the loop-propagator matrix. 
To deal with arbitrary orientation of the propagators, we multiply one column by '-1' to make its first non-zero element '1' if necessary.   

b) sort propagators in each branches (inherited from v0.2.0):
Here we no longer sort propagtors in opposite orientation respectively.
Instead we sort propagator sets generated from 2 orientations in a single list, and use the first one and its opposite in later steps.
When branch length >= 3, there is no ambiguity. Branch length == 1 is also a trivial case. 
The ambiguity occurs when branch length == 2. Here the first two propagator sets in the sorted list may be identical, and we take both: each with its opposite.

2. Sorting propagator sets at 3 levels:
1) orientation&order-generic level: 
We map a propagator e.g. {a1 l1 + a2 l2 + p1} to {Abs[a1]+Abs[a2], SymbAbs[p1], PropShape}, 
where 'SymbAbs' is a canonical orientation of p1 and 'Propshape' marks other informations of the propagator like masses.
We also introduce an extra Loop-Length label 'LoopLen[ll1,ll2,...]' in the list of propagators. (This removes the ambiguity in v2.0)
This form will almost fix all topologically equivalent spanning trees and empirically there is no ambiguity in the following sorting. 
Even when we consider branch structure and external legs, the symmatry can only become smaller and the ambiguity is thus removed. 
Then we sort all equivalence class represented by the form above, and take the first several identical ones (equivalence classes) for sorting in lower level.

The sorting ambiguity coming from topologically equivalent spanning trees can be understood and thus resolved in terms of Edge-Cycle matrix:
Different topologically equivalent spanning tree (embedded in a vacuum diagram) can be transformed into each other by automorphism of the graph 
which is also a subgroup of the full premutation group of all internal lines. 
So equivalent Spanning Trees (and equivalent propagator sets in orientation&order-generic level, ignoring branch structure and external legs)
 can be represented by an equivalent class of Edge-Cycle Matrices with 0 or 1-valued entries 
which can be transformed to each other by row or column permutations. 
These equivalent classes can be further characterized by non-isomorphic bipartite graphs whose vertices 'n' correspond to row numbers and column numbers 
and whose directed edges '(n,m)' correspond to 1-valued entries with row and column indices (n,m). 
To determine the representative form used to sort, we only need a pair of unordered lists of vertex degrees corresponding to the rows and columns.
This pair of lists will unambigously determine the bipartite graph up to isomorphisms.
These are also lists of the numbers of 1-valued entries in each row and column of the Edge-Cycle Matrix.
In physical terms, this includes the number of internal lines through which each loop momentum flows (LoopLen[...]), 
and the number of loop momenta flowing through each internal line. 
Combining this representative form, branches structure and propagator shapes, our sorting process in orientation & order-generic level can be very efficient.

2) orientation-generic & order-specific level, explained along with 3) orientation-specific level:
In the original plan of v2.0, we decide to deal with order after orientation, with a mapping to equivalence class:
{a1 l1 + a2 l2 + p1} -> {{a1,a2}//Sort, p1, ...} 
But the order-changing l1<->l2 will affect the sign of p1. So we have to exchange the priority of step 2) and 3) so that they don't interfere with each other.
In these level there are no ambiguity with the first element in the sorted list.
"""
***)
