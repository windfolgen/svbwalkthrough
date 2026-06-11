(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


LoopSymmetry::mass="Warning: nonzero mass term in linear propagator(s) detected. The result may be not unique. \n
Please make sure that the mass term cannot be expressed as scalar products of external momenta.\n
The propagators are: `1`";
LoopSymmetry::usage="LoopSymmetry[props_List,loopmoms_List,SPRep_] explores the symmetry of \
linear transformation of loop momenta 'loopmoms' for Feynman integrals defined by \
propagators 'props'. A unique (canonical) form of propagators will be returned together \
with a list of linear transition rules, like {standardprops,{{l1->-l1+l2+p, l2->-l2+q,...},...}}, \
which means the substitution l1 = -l1'+l2'+p, ..., where {l1,l2} are the old variables, \
and {l1',l2'} are the new variables. 

Options[\"CutInformation\"] looks like {{{p2-p1,p1},{p3,p5},...},{p1,p2,...}}. The second part \
is a list of momenta to be integrated in phase space integration. The first part is a list of lists of \
symmetric cut momenta, with condition that exchanging cut momenta within each list does not change \
the final integrated result. In this example, {p1, p2, ...} are momenta to be integrated; \
the exchange of p2-p1 and p1 (or p3 and p5) does not change the final integrated result.

The input format of each element of props should be: \
Quadratic propagator with momentum 'q' and mass 'm': {q,q,m,pow}; \
Linear propagator with momentum 'q' and 'n' and mass 'm': {q,n,m,pow}. \
Here, 'q' must depend on loop momenta, and 'n' must be independent of loop momenta. \
For linear propagator, result may be not unique if 'm' can be removed by redefinition of 'q' and 'n'.
'loops', like {{la,lb},{lA},...} or {l1, l2,...} (equivalent to {{l1, l2,...}}), represents blocks of \
loop momenta, with condition that exchange of momenta within each block does not change final integrated result.
'SPRep', like {SP[p1,p2]->s12,...}, is a list of replacement rules for scalar products.

";


Begin["`Private`"];
End[];


Begin["`LoopSymmetry`"];


(* ::Section:: *)
(*LoopSymmetry*)


Options[LoopSymmetry]={"CutInformation"->{{},{}}};


LoopSymmetry[props0_List,loopmoms00_List,SPRep_,opts:OptionsPattern[]]:=Module[
	{loopmoms0,props,loopmoms,cutmoms,psmoms,
		moms,sym,f,loopSymmetry,rules,looprules,final,deni,numbers},
	
	(*** loopmoms0 must be in the form {l11,l12,...} or {{l11,l12,...},{l21,l22,...},...}. ***)
	loopmoms0=If[Union[Head/@loopmoms00]=!={List}, List@Flatten@loopmoms00, loopmoms00];
	loopmoms=Select[Flatten/@loopmoms0,#=!={}&];
	
	(*** cluster propagators according to dependence on loop momenta ***)
	props=Table[
		Select[props0,!FreeQ[#,Alternatives@@loopmoms[[i]]]&]		
		,{i,Length@loopmoms}
	];
	If[Length@props>1&&Intersection@@props=!={},
		Print["Incorrect input for LoopSymmetry: ",{props0,loopmoms0}]; Abort[]
	];
	
	(*** add propagators that are independent of loop momenta ***)
	If[Length@props0>Length@Flatten@props,
		AppendTo[loopmoms,{}];
		AppendTo[props,Select[props0,FreeQ[#,Alternatives@@Flatten@loopmoms]&]];
	];

	(*** cut momenta and momenta of phase space integration***)
	{cutmoms,psmoms}=OptionValue["CutInformation"];
	
	moms={loopmoms,psmoms}//Flatten;
	
	(***return 0 if it belongs to a zero sector***)
	If[Or@@Table[ZeroSectorQ[(#1*#2+#3&)@@@props[[i]],loopmoms[[i]],SPRep],{i,Length@props}],
		Return[{0,{Thread[moms->moms]}},Module]
	];

	(*Generate replacement rules for symmetric cut momenta.*)
	sym=Permutations/@cutmoms;
	sym=Flatten/@Tuples[sym];
	(***For each i, find rules of momenta replacement to change sym[[1]] to sym[[i]].
		'sym' looks like {{p1\[Rule]p1,p2\[Rule]p2,p3\[Rule]p3,...,q1\[Rule]q1,q2\[Rule]q2},{p1\[Rule]p2,p2\[Rule]p1,p3\[Rule]p3,...,q1\[Rule]q1,q2\[Rule]q2},...}.***)
	sym=Table[Solve[Thread[(sym[[i]])==(sym[[1]]/.Thread[psmoms->(f/@psmoms)])],(f/@psmoms)]//
		If[#=!={},#[[1]],Nothing]&,{i,Length@sym}]/.f->Identity;
	(***If there is no loop momentum, or if there is no denominators, return input denominators 
		with identical replacement. Or else, use function loopSymmetryNoPS to find out replacement rules to 
		transfer input denominators to standard form. Final result looks like {denominators, replacementrules}***)
	loopSymmetry[dens0_,momL0_]:=If[Length@dens0===0||Length@momL0===0,
	{dens0,Thread[momL0->momL0]},loopSymmetryNoPS[dens0,momL0]][[2]];
	
	(*For each permutation of cut momenta with rules given in sym[[i]], use loopSymmetryNoPS to find unique 
		choice of loop momenta. The result is a list of rules={l1\[Rule]..., l2\[Rule]..., k1\[Rule]...,...}*)
	rules=Join@@Table[
		looprules=Table[loopSymmetry[props[[j]]/.sym[[i]],loopmoms[[j]]],{j,Length@props}];
		looprules=Flatten/@Tuples@looprules;
		(*In case no loop momentum*)
		If[looprules==={},looprules={{}}];
		Join[#,sym[[i]]]&/@looprules
		,{i,Length@sym}
	];

	(*Find the unique form for each replacement rules[[i]]*)
	final=Table[
		(*Modified denominators with the replacement rules[[i]]*)
		deni=props0/.rules[[i]]//Expand;
		
		(*Integral is unchanged by mulipling all momenta by -1, or by sorting the denominators*)
		deni[[All,1;;2]]=branchClassify[deni,Flatten@loopmoms0,{}][[1]]*deni[[All,1;;2]]//Expand;
		deni=SortBy[deni,{Table[Coefficient[#[[1]],moms[[-i]]],{i,Length@moms}],LeafCount@#[[1]]}&];
		{i,deni}
		,{i,Length@rules}
	];

	(*Sort and find out an unique choice*)
	numbers=findShortestUnique[final];
	
	{final[[numbers[[1]],2]],rules[[numbers]]}
];


(* ::Section:: *)
(*loopSymmetryNoPS*)


loopSymmetryNoPS::usage=
"loopSymmetryNoPhase[props_List,loopmoms_List] explores the symmetry of \
linear transformation of loop momenta 'loopmoms' for Feynman integrals defined by \
propagators 'props'. A unique (canonical) form of propagators will be returned together \
with a list of linear transition rules, like {standardprops,{{l1->-l1+l2+p, l2->-l2+q,...},...}}, \
which means the substitution l1 = -l1'+l2'+p, ..., where {l1,l2} are the old variables, \
and {l1',l2'} are the new variables.

The input format of each element of props should be: \
Quadratic propagator with momentum 'q' and mass 'm': {q,q,m,pow}; \
Linear propagator with momentum 'q' and 'n' and mass 'm': {q,n,m,pow}. \
Here, 'q' must depend on loop momenta, and 'n' must be independent of loop momenta. \
For linear propagator, result may be not unique if 'm' can be removed by redefinition of 'q' and 'n'.
'loops', like {{la,lb},{lA},...} or {l1, l2,...} (equivalent to {{l1, l2,...}}), represents blocks of \
loop momenta, with condition that exchange of momenta within each block does not change final integrated result.";


(*** 
Originally, there are infinite degrees of freedom to do linear transformation of loop momenta in a Feynman integral.
By requiring that pure loop momenta (l1, ..., lL) must appear in some denominators, there remains a finite symmetry.
There are four kinds of freedom (L: #loops, B: #branches, P: #propagators, P_i: #propagators in the i'th branch): 
. Permutate loop momenta, which amounts to L! operations;
. Reverse directions of some loop momenta, which amounts to 2^L operations; 
. Choose branches to insert pure loop momenta, operations of which is smaller than C_B^L; 
. In each chosen branch, where to insert the pure loop momenta, which amounts to P_i1*...*P_iL operations; 
. For each propagator, one can reverse all momenta, which amounts to 2^P operations.

As the symmetry group is usually very big, to explore it and find an unique (canonical) form of propagators,
we use the following steps (choices in one step always inherit choices in previous steps, and the chosen 
special class should have minimal elements to have a better efficiency) :
1) For each propagator, sort its {-external momenta, external momenta}, and choose the last one. 
   Then we can classify propagators into branches. Loop momenta are irrelevant at this step.
2) For each branch, try all possible positions to insert pure loop momenta, and sort all results to find out
   a class of special choices (one or two). Loop momenta are irrelevant at this step.
3) Use Symanzik polynomial to determine all possible choices to insert pure loop momenta, and sort all results
   to find out a class of special choices. Label and orientation of loop momenta are irrelevant in the sort. 
5) Run over all orientations of loop momenta, and sort all results to find out a class of special choices. 
   Lable of loop momenta is irrelevant in the sort.
4) Permutate all loop momenta, and sort all results to find out a class of special choices. 

Final result is in the form: {{prop1, prop2,...}, {{l1\[Rule]..., l2\[Rule]..., ...},{l1\[Rule]..., l2\[Rule]..., ...},...}}.
***)


Options[loopSymmetryNoPS]={"PrintLog"->False};
loopSymmetryNoPS[props0_List,loopmoms_List,OptionsPattern[]]:=Module[
	{props,nl,extmoms,ne,x,propshape,sgns,cycextedg,branches,reducycedg,branchpropstd,reduLB,fullLB,
		LBrules,propsnew,sgns2,canonicalProps,ruleList},
	
	props=props0//Expand;
	nl=Length@loopmoms;
	
	(*** find out external momenta ***)
	extmoms=Select[Variables@props[[All,1]],MomentumQ[#]=!=False&];
	(*** check ***)
	If[Union@Exponent[#,x]=!={1}||Union[#/.x->0]=!={0},
		Print["Propagators are not  homogeneous linear in momenta: ", props0];
		Abort[];
	]&@(props[[All,1]]/.Thread[extmoms->x*extmoms]);
	extmoms=Complement[extmoms,loopmoms];
	ne=Length@extmoms;
	
	(*** shape of each propagator: {0, mass} or {n,mass}, where n can be the gauge link direction ***)
	propshape=If[#[[1]]===#[[2]],{0,#[[3]]},{#[[2]],#[[3]]}]&/@props;
	
	(*** check mass terms in linear propagators ***)
	If[Plus@@Times@@@propshape=!=0,Message[LoopSymmetry::mass,props0]];
	(*** check loop momenta dependence ***)
	If[Or@@(FreeQ[#[[1]],Alternatives@@loopmoms]||#[[1]]=!=#[[2]]&&!FreeQ[#[[2]],Alternatives@@loopmoms]&/@props),
		Print["Incorrect input for LoopSymmetry. Please check loop momenta dependence."]; 
		Print["Propagators are given by: ", {props0,loopmoms}];
		Abort[];
	];
	
	(*** Step 1: find a canonical form for each propagator and then classify propagators into branches: 
		 sgns: a list of sign (+1 or -1), denotes the sign difference between props and their unique form;
		 cycextedg: a matrix satisfies sgn*props[[All,1]]=cycextedg.Join[loopmoms,extmoms]; 
		 branches: {{i1,i2,...},{j1,j2,..},}, each list (a set of numbers) denotes a branch;
		 reducycedge: a sub-matrix of cycextedg, keep only information of loop momenta defining each branch ***)
	{sgns,cycextedg,branches,reducycedg}=branchClassify[props,loopmoms,extmoms];
	If[OptionValue["PrintLog"]==True,
		Print["cycextedg=",cycextedg];
		Print["sgns=",sgns];
	];	
	
	(*** Step 2: for each branch, find one (or two, if only two equal-mass propagators) special propagator ***)
	(*** branchpropstd[[i]]: {i1} or {i1,i2}, i1 (i2) is the propagator number ***)
	branchpropstd=sortInBranch[#,cycextedg[[#,-ne;;-1]],propshape[[#]]]&/@branches;
	(*** branchpropstd[[i]]: {i1,...,i#branches} is a possible choice of special-propagator sets ***)
	branchpropstd=Tuples[branchpropstd];
	If[OptionValue["PrintLog"]==True,
		Print["Step 2: possible choices of special propagator sets:\n",branchpropstd]
	];
	
	(*** the set of special propagators form a reduced vacuum diagram. Find all possible choices 
		 of loop bases (LB, where to insert loop momenta l1, ..., lL) in the reduced diagram ***)
	(*** reduLB[[i]]: {b1,...,bL}, bi means the bi'th branck, (not the b1'th propagator in the orginal diagram). ***)
	reduLB=loopBasis[reducycedg];
	If[OptionValue["PrintLog"]==True,
		Print["{reducycedg,reduLB}=",{reducycedg,reduLB}]
	];
	
	(*** Step 3: find all equivalent propagator sets to insert pure loop momenta, with generic orientation and order ***)
	(***fullLB[[i]]: {i1,i2,...,iL} ***)
	fullLB=sortLoopBasis[branchpropstd,reduLB,cycextedg,propshape];
	If[OptionValue["PrintLog"]==True,
		Print["Step 3: propagator sets with generic orientation&order."" fullLB=",fullLB]
	];
	
	(*** Step 4: find all equivalent propagator sets to insert pure loop momenta, with full orientations but generic ordering ***)
	(***fullLB[[i]]: {-i1,+i2,...,-iL} ***)
	fullLB=sortOrientation[fullLB,cycextedg,propshape];
	If[OptionValue["PrintLog"]==True,
		Print["Step 4: propagator sets with full orientation&order, LBrules=",{Length@#,Short@#}&@fullLB]
	];
	
	(*** Step 5: find all equivalent propagator sets to insert pure loop momenta, with full orders and orientations specified ***)
	(***fullLB[[i]]: {-i1,+i2,...,-iL} ***)
	LBrules=sortPermutation[fullLB,cycextedg,propshape];
	If[OptionValue["PrintLog"]==True,
		Print["Step 5: propagator sets with full perumations but generic orientation, fullLB=",{Length@#,#[[1;;Min[4,Length@#]]]}&@LBrules]
	];	
	
	(*** calculate standard propagators results ***)
	(*** standard form of propagators: {prop1, prop2,...}  ***)
	cycextedg=cycextedg . LBrules[[1]];
	sgns2=If[OrderedQ[{-#,#}],1,-1]&/@cycextedg;
	propsnew=cycextedg . Join[loopmoms,extmoms];
	canonicalProps=Table[
		If[propshape[[i,1]]===0,
			(*** quadratic propagator ***)
			{sgns2[[i]]*propsnew[[i]],sgns2[[i]]*propsnew[[i]],propshape[[i,2]],Sequence@@props0[[i,4;;-1]]},
			(*** linear propagator ***)
			{sgns2[[i]]*propsnew[[i]],sgns2[[i]]*sgns[[i]]*propshape[[i,1]],propshape[[i,2]],Sequence@@props0[[i,4;;-1]]}
		],{i,Length@propsnew} 
	]//Expand//SortBy[#,LeafCount]&;
		
	(*If[OptionValue["AllTransRules"]===False,LBrules=LBrules[[1;;1]]];*)
	
	ruleList=Thread[loopmoms->(#[[1;;nl]] . Join[loopmoms,extmoms])]&/@LBrules;
	
	{canonicalProps,ruleList}
];


(* ::Section::Closed:: *)
(*branchClassify*)


Options[branchClassify]={};
branchClassify[props_,loopmoms_,extmoms_,OptionsPattern[]]:=Module[
	{nl,cycextedgmat,sgns,cycextedgmatstd,mat,propclass,cycedgmatred},
	
	nl=Length@loopmoms;
	
	(*** cycextedgmat is a matrix: each line corresponds to a propagator, and each colomn 
		 corresponds to a momentum in the list Join[loopmoms,extmoms] ***)
	cycextedgmat=Coefficient[props[[All,1]],#]&/@Join[loopmoms,extmoms]//MMATranspose;
	(*In case of no loopmoms and extmoms*)
	If[cycextedgmat==={},cycextedgmat=ConstantArray[{},Length@props]];
	
	(*** align orientation of propagator momenta in an unique way, so that loop momenta in 
		 all propagators in the same branch are the same ***)
	sgns=If[OrderedQ[{-#,#}//Expand],1,-1]&/@cycextedgmat;
	(*** note for linear propagator: no problem, because final result is a replacement rule ***)
	cycextedgmatstd=sgns*cycextedgmat;
	
	(*** classify prop momenta into branches, by their dependences on loop momenta ***)
	mat=Table[{i,cycextedgmatstd[[i,1;;nl]]},{i,Length@cycextedgmatstd}];
	mat=GatherBy[mat,#[[2]]&];
	propclass=#[[All,1]]&/@mat;
	cycedgmatred=#[[1,2]]&/@mat;
	
	{sgns,cycextedgmatstd,propclass,cycedgmatred}
];


(* ::Section::Closed:: *)
(*loopBasis*)


(*** Find all loop bases from symanzik polynomial of loop-internal momenta matrix. 
	Each basis is a possible choice of {l1, l2, ...}***)
loopBasis[cycedgmat_]:=Module[
	{symanzik1,x,res},
	symanzik1=(MMATranspose@cycedgmat . DiagonalMatrix[Array[x,Length@cycedgmat]] . cycedgmat)//Det//Expand;
	res=If[Head@symanzik1===Plus,List@@symanzik1,List@symanzik1];
	res=(If[Head@#===Times,List@@#,List@#]&)/@res;
	res/.x->Identity
];


(* ::Section::Closed:: *)
(*lbTransform*)


(*** the transformation for a single choice of loop basis ***)
lbTransform[cycextedg_,loopbasis0_]:=Module[
	{loopbasis,orient,nl,ne,old,new,T1,T2,tranMat,cycextedgnew,identityMatrix},
	
	loopbasis=loopbasis0//Abs;
	orient=loopbasis0//Sign;
	
	nl=Length@loopbasis;
	ne=Length@cycextedg[[1]]-nl;
	
	identityMatrix[0]={};
	identityMatrix[n_]:=IdentityMatrix[n];
	
	(*** old and new loop basis props. only loop parts are kept in new props ***)
	old=cycextedg[[loopbasis]];
	new=DiagonalMatrix@orient;
	
	(*** {loop-old,ext-old}.tranMat=={loop-new,0}, let tranMat={{T1,T2},{0,1}} ***)
	{T1,T2}=Inverse@old[[All,1;;nl]] . #&/@{new,-old[[All,nl+1;;-1]]};
	tranMat=Join[Join[T1,Table[0,{ne},{nl}]],Join[T2,identityMatrix[ne]],2];
	
	tranMat
];


(* ::Section::Closed:: *)
(*findShortestUnique*)


(*** sort according to the later values, and return the first value ***)
(*** x,y,z: use to distinguish 0, 1, -1 ***)
findShortestUnique[choices0_]:=Module[
	{choices,x,y,z,minlen},
	choices=SortBy[choices0,{#[[2;;-2]],(x+y)*Abs@#[[-1]]//LeafCount,(x)*#[[-1]]//LeafCount,#[[-1]]}&];
	
	choices=SplitBy[choices,Last];
	
	minlen=Min[Length/@choices];
	choices=Select[choices,Length@#===minlen&][[1]];
	choices[[All,1]]
];


(* ::Section::Closed:: *)
(*sortInBranch*)


sortInBranch[branch_,extedgbranch_,propshape_]:=Module[
	{propnew,propchoices,propstd,propstdlist},
	
	If[Length@branch===1,Return[branch,Module]];
	
	(*** choose one propagator as a baseline (together with different orientation), 
		 and then calculate relative part of all other propagators ***)
	propchoices=Join@@Table[
		propnew=orient(#-extedgbranch[[i]])&/@extedgbranch//Expand;
		{branch[[i]],Join[propnew,propshape,2]//Sort}
		,{orient,1,-1,-2},{i,Length@branch}
	];
	
	(*** sort all possible choices, and return the unique one 
		 (maybe two if the branch has and only has two equal-mass propagators)  ***)
		 
	propchoices=findShortestUnique[propchoices];
	(*propchoices=SortBy[propchoices,#[[2]]&];
	propchoices=Select[propchoices,#[[2]]===propchoices[[1,2]]&];*)
	
	propchoices

];


(* ::Section::Closed:: *)
(*sortLoopBasis*)


sortLoopBasis[branchpropstd_,reduLB_,cycextedgold_,propshape_,OptionsPattern[]]:=Module[
	{fullLB,np,nl,ne,LBrules,cycextedg,temp,loopInf,extInf,projMatAll,projMat1},
	
	np=Length@cycextedgold;
	nl=Length@reduLB[[1]];
	ne=Length@cycextedgold[[1]]-nl;
	
	(***  list all choices of loop bases, including choices of special propagators 
		 and choices of loop bases of reduced diagram ***)
	(***  fullLB[[i]]:  {i1,...,iL}, denotes prop number ***)
	fullLB=Join@@Table[branchpropstd[[All,reduLB[[j]]]],{j,Length@reduLB}]//DeleteDuplicates;
	
	(*** calculate transformation matrix for each choice of loop basis. An arbitrary choice 
		 of the permutation group between l1, ..., lL is made. And an arbitrary choice of orientation
		 of each li is made. Will be fixed later. ***)
	(*** LBrules[[i]]: cycexted=cycextedgold.LBrules[[i]] ***)
	LBrules=lbTransform[cycextedgold,#]&/@fullLB;
	
	(*** projected matrix for all loop basis choices ***)
	projMatAll=Table[
		cycextedg=cycextedgold . LBrules[[j]];
		(*** projected matrix for each loop basis choice ***)
		projMat1=Table[
			temp=cycextedg[[i]]; (*** the i'th propagator ***)
			loopInf=Plus@@Abs@temp[[1;;nl]]; (*** total number of loop momenta ***)
			extInf=Sort[{temp[[-ne;;-1]],-temp[[-ne;;-1]]}][[-1]]; (*** unique choice of external momenta ***)
			{loopInf,extInf,propshape[[i]]}
			,{i,np}
		];
		loopInf=Plus@@Abs@cycextedg[[All,1;;nl]]; (*** total number of each loop momentum in all propagators***)
		{j,Plus@@loopInf,Sort@loopInf,Sort@projMat1}
		,{j,Length@fullLB}
	];
	
	projMatAll=findShortestUnique[projMatAll];
	
	fullLB[[projMatAll]]
];


(* ::Section::Closed:: *)
(*sortOrientation*)


sortOrientation[fullLB0_,cycextedgold_,propshape_,OptionsPattern[]]:=Module[
	{np,nl,ne,fullLB,hold,nlb,LBrules,cycextedg,temp,loopInf,extInf,projMatAll,projMat1},
	
	np=Length@cycextedgold;
	nl=Length@fullLB0[[1]];
	ne=Length@cycextedgold[[1]]-nl;
	
	fullLB=Join@@Outer[Times,hold/@fullLB0,hold/@Tuples[{1,-1},nl]]/.hold->Identity;
	
	nlb=Length@fullLB;
	
	(*** calculate transformation matrix for each choice of loop basis, with orderless for loop momenta. 
		Will be fixed at the later step.***)
	(*** LBrules[[i]]: cycexted=cycextedgold.LBrules[[i]] ***)
	LBrules=lbTransform[cycextedgold,#]&/@fullLB;
	
	(*** projected matrix for all loop basis choices ***)
	projMatAll=Table[
		cycextedg=cycextedgold . LBrules[[j]];
		(*** projected matrix for each loop basis choice ***)
		projMat1=Table[
			{Sort[{-#,#}][[-1]]&@cycextedg[[i]],propshape[[i]]}
			,{i,np}
		];
		{j,Sort@projMat1}
		,{j,nlb}
	];
	
	(*** projected matrix for all loop basis choices ***)
	projMatAll=Table[
		cycextedg=cycextedgold . LBrules[[j]];
		(*** projected matrix for each loop basis choice ***)
		projMat1=Table[
			temp=cycextedg[[i]]; (*** the i'th propagator ***)
			(*** orderless loop momenta. unique choice of a sign***)
			Sort[{Sort@#[[1;;nl]],#[[-ne;;-1]],propshape[[i]]}&/@{temp,-temp}][[-1]]
			,{i,np}
		];
		{j,Sort@projMat1}
		,{j,nlb}
	];
	
	projMatAll=findShortestUnique[projMatAll];
	
	fullLB[[projMatAll]]
];


(* ::Section::Closed:: *)
(*sortPermutation*)


sortPermutation[fullLB0_,cycextedgold_,propshape_,OptionsPattern[]]:=Module[
	{np,nl,ne,fullLB2,nlb,LBrules,cycextedg,temp,loopInf,extInf,projMatAll,permu,cycextedgi,rulei},
	
	np=Length@cycextedgold;
	nl=Length@fullLB0[[1]];
	ne=Length@cycextedgold[[1]]-nl;
	
	permu=Permutations[Range[nl]];
	
	(*** calculate transformation matrix for each choice of loop basis.***)
	(*** LBrules[[i]]: cycexted=cycextedgold.LBrules[[i]] ***)
	LBrules=lbTransform[cycextedgold,#]&/@fullLB0;
	nlb=Length@fullLB0;
	
	(*** projected matrix for all loop basis choices ***)
	projMatAll=Table[
		cycextedgi=cycextedgold . LBrules[[i]];
		(*** try all possible permutations ***)
		Table[
			cycextedg=Join[cycextedgi[[All,permu[[j]]]],cycextedgi[[All,-ne;;-1]],2];
			(*** projected matrix for each loop basis choice ***)
			{{i,j},Sort@Table[{Sort[{-#,#}][[-1]]&@cycextedg[[k]],propshape[[k]]},{k,np}]}
			,{j,Length@permu}
		]	
		,{i,nlb}
	];
	
	projMatAll=Flatten[projMatAll,1];
	
	projMatAll=findShortestUnique[projMatAll];
	
	(*** remained LBrules with permutation ***)
	Table[
		rulei=LBrules[[projMatAll[[i,1]]]];
		Join[rulei[[All,permu[[projMatAll[[i,2]]]]]],rulei[[All,-ne;;-1]],2]
	,{i,Length@projMatAll}]
];


(* ::Section::Closed:: *)
(*End*)


End[];
