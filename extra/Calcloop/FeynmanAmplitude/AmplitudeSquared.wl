(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


ComplexConjugate::usage="ComplexConjugate[amp] gives the complex conjugate of 'amp'. \
Dummy Lorentz indexes, color indexes and loop momenta are relabeled.";


FermionSpinSum::usage="FermionSpinSum[exp_] sums spins of fermions in 'exp'. \
As a result, pairs of DiracSpinors are replaced by Dirac gamma matrices.
hs=OptionValue[\"Helicity\"] defines helicity (more precisely, chirality) of each fermion. \
'hs' can be a list of rules like {p1->h1,p2->h2,...}, which sets the \
helicity of the particle with momentum pi as hi, \
a rule like {p1,p2,...}->{h1, h2,...} with the same meaning, \
or a single value for all particles. 'hi' must be chosen from the set {All, +1, -1}.";


BosonSpinSum::usage="BosonSpinSum[exp] sums spins of bosons in 'exp'. \
As a result, pairs of PolarizationVectors are replaced by corresponding Lorentz tensors.
hs=OptionValue[\"Helicity\"] defines helicity of each boson. \
'hs' can be a list of rules like {p1->h1,p2->h2,...}, which sets the \
helicity of the particle with momentum pi as hi, \
a rule like {p1,p2,...}->{h1, h2,...} with the same meaning, \
or a single value for all particles. 'hi' must be chosen from the set {All, +1, -1, \"T\", \"L\"}, \
where \"T\" means transverse (summation over +1 and -1) and \"L\" means longitudinal ('hi=0').
ns=OptionValue[\"ReferenceMomentum\"] defines reference momentum of each boson. \
'ns' can be a list of rules like {p1->n1,p2->n2,...}, which sets the \
reference momentum of the particle with momentum pi as ni, \
a rule like {p1,p2,...}->{n1, n2,...} with the same meaning, \
or a single momentum for all particles. 
1) In the case 'hi'===All: \
If p.n===0, then polarization sum will be -MT[\[Mu],\[Nu]]. \
Otherwise, d[p,n,\[Mu],\[Nu]]=-MT[\[Mu],\[Nu]]+(LV[p,\[Mu]]LV[n,\[Nu]]+LV[p,\[Nu]]LV[n,\[Mu]])/p.n-\
n^2 LV[p,\[Mu]]LV[p,\[Nu]]/SP[p,n]^2 is used.
2) In the case 'hi'===-1 or +1 && p.n=!=0: \
(d[p,n,\[Mu],\[Nu]]+I hi*Eps[mu,nu][p,n]/SP[p,n])/2 is used.
3) In the case 'hi'===\"T\" && p.n=!=0: d[p,n,\[Mu],\[Nu]] is used.
4) In the case 'hi'===\"L\" && p.p=!=p.n: d[p,p,\[Mu],\[Nu]]-d[p,n,\[Mu],\[Nu]] is used.
5) Other cases are not allowed."


AmplitudeSquared::usage="AmplitudeSquared[file1,file2] calculates the amplitude in 'file1' times \
ComplexConjugate of the amplitude in 'file2'. Spin and color of all particles are summed.
OptionValue[\"GaugeXi\"] is applied for the amplitudes.
OptionValue[\"Helicity\"] and OptionValue[\"ReferenceMomentum\"] are used for spin sum.";


Begin["`Private`"];
End[];


Begin["`AmplitudeSquared`"];


(* ::Section::Closed:: *)
(*ComplexConjugate*)


Attributes[ComplexConjugate]={Listable};
ComplexConjugate[exp_]:=Module[{RVS,dummyLorentz,dummySUN,temp},
	
	(*change dummy SUN index*)
	dummySUN=CountIndexes[exp,SUNIndex];
	dummySUN=Select[dummySUN,#[[2]]>1&][[All,1]];
	dummySUN=Dispatch@Thread[dummySUN->(dummySUN/.SUNIndex[i_]:>SUNIndex[-i])];
	
	(*change dummy lorentz index*)
	dummyLorentz=CountIndexes[exp,LorentzIndex];
	dummyLorentz=Select[dummyLorentz,#[[2]]>1&][[All,1]];
	dummyLorentz=Dispatch@Thread[dummyLorentz->(dummyLorentz/.LorentzIndex[i_]:>LorentzIndex[-i])];

	
	(*replacements*)
	exp/.Complex[a_,b_]:>Complex[a,-b]/.SUNT[i_,a___,j_]:>SUNT[j,Sequence@@Reverse[{a}],i]//.
		x_DiracChain:>RVS@@Reverse[x]/.RVS:>DiracChain/.DiracGamma[5]:>-DiracGamma[5]/.
		PolarizationVector[{a_,b_},c_]:>PolarizationVector[{a,-b},c]/.
		dummyLorentz/.dummySUN/.{LoopMomentum[i_]:>LoopMomentum[-i]}
];


(* ::Section::Closed:: *)
(*FermionSpinSum*)


(* fermion polarization sums *)
Attributes[FermionSpinSum]={Listable};
Options[FermionSpinSum]={"Helicity"->All};
FermionSpinSum[exp_,OptionsPattern[]]:=Module[
	{rule,spinSum,hel,rep,temp,contractSpinor},
	
	rule=OptionValue@"Helicity";
	If[Head@rule===Rule,rule=Thread@rule];
	
	spinSum[{p_,sgn_},m_]:=spinSum[{p,sgn},m]=Sequence@@If[Head@rule=!=List,
			{DiracGamma[Momentum[p]] +sgn*m},
			hel=(p/.rule);
			If[hel===1||hel===-1,
				{1/2+hel*sgn*DiracGamma[5]/2,DiracGamma[Momentum[p]] +sgn*m},
				{DiracGamma[Momentum[p]] +sgn*m}
			]
		];
	
	rep= {DiracChain[dots1__ ,DiracSpinor[{p_,sgn_}, m_] ]*
			  DiracChain[DiracSpinor[{p_,sgn_}, m_] , dots2__ ]:>
		  	DiracChain[dots1 ,spinSum[{p,sgn},m], dots2],
		  DiracChain[DiracSpinor[{p_,sgn_}, m_] , dots___ ,DiracSpinor[{p_,sgn_}, m_]] :>
		      DiracChain[0,dots,spinSum[{p,sgn},m], 0]		  
	};
	
	temp=Separate[exp,DiracChain[_DiracSpinor,__]];
	temp[[2]]=temp[[2]]//.rep;
	
	(*Print[spinSum//DownValues];*)
		
	Dot@@temp
];


(* ::Section::Closed:: *)
(*BosonSpinSum*)


Attributes[BosonSpinSum]={Listable};
Options[BosonSpinSum]={"Helicity"->All,"ReferenceMomentum"->{}};
BosonSpinSum[exp_,OptionsPattern[]]:=Module[
	{sep,hel,mom,polarTensor,spinSum,sp,lightQ},
	
	sp[p1_,p2_]:=GPD[{p1,p2,0,1}]^-1;
	
	lightQ[p_,n_]:=Expand@MomentumSimplify@CLForm@SP[p,n]===0;
	
	(*Find rules for helicity*)
	hel=OptionValue@"Helicity";
	hel=Which[
		Head@hel===Rule,Thread@hel,
		Head@hel=!=List,{_->hel},
		True,hel
	];
	hel=Flatten@{hel};
	If[!SubsetQ[{Rule,RuleDelayed},Union[Head/@hel]],
		ErrorPrint["Incorrect input \"Helicity\" for BosonSpinSum: ",
		 OptionValue@"Helicity"];
		Abort[]
	];
	
	(*Find rules for reference momentum*)
	mom=OptionValue@"ReferenceMomentum";
	mom=Which[
		mom==={},{_->0},
		Head@mom===Rule,Thread@mom, 
		Head@mom=!=List,{_->mom},
		True,mom
	];
	mom=Flatten@{mom};
	If[!SubsetQ[{Rule,RuleDelayed},Union[Head/@mom]],
		ErrorPrint["Incorrect input \"ReferenceMomentum\" for BosonSpinSum: ",
		 OptionValue@"ReferenceMomentum"];
		Abort[]
	];
	
	(*Feynman gauge or axial gauge*)
	polarTensor[p_,n_,mu_,nu_]:=If[lightQ[p,n],
		-MT[mu,nu],
		-MT[mu,nu]+(LV[p,mu]LV[n,nu]+LV[p,nu]LV[n,mu])/sp[p,n]-
							SP[n,n]LV[p,mu]LV[p,nu]/sp[p,n]^2
	];
	
	spinSum[p_,mu_,nu_]:=Module[
		{h,n},
		
		h=p/.hel;
		If[h===p,h=All];
		n=p/.mom;
		
		If[!MemberQ[{All,+1,-1},h],
			ErrorPrint["Incorrect input \"Helicity\" for BosonSpinSum: ", 
				{OptionValue@"Helicity",p}];
			Abort[]
		];
		
		Which[
			h===All, polarTensor[p,n,mu,nu],
			(*With fixed helicity*)
			Abs[h]===1&&!lightQ[p,n], (polarTensor[p,n,mu,nu]+I h*Eps[mu,nu][p,n]/sp[p,n])/2,
			h==="T"&&!lightQ[p,n],polarTensor[p,n,mu,nu],
			h==="L"&&!lightQ[p,p-n],polarTensor[p,p,mu,nu]-polarTensor[p,n,mu,nu],
			True, ErrorPrint["Incorrect input \"Helicity\" for BosonSpinSum: ", 
					{OptionValue@"Helicity",p}];
				Abort[]
		]		
	];
	
	sep=Separate[exp,_PolarizationVector];
	
	sep[[2]]=sep[[2]]//.
		PolarizationVector[{p_,1},LorentzIndex[mu_]]*PolarizationVector[{p_,-1},LorentzIndex[nu_]]:>
			CLForm@spinSum[p,mu,nu];
		
	Dot@@sep
];


(* ::Section::Closed:: *)
(*AmplitudeSquared*)


Options[AmplitudeSquared]={"GaugeXi"->("GaugeXi"[_]->1),"Helicity"->All,"ReferenceMomentum"->{},"Parallelize"->False,
	"Operation"->{Identity,Identity,Identity},"Offshellness"->{},"Replacement"->{},"ReadSaved"->False};
AmplitudeSquared[dir_String,file1_String,file2_:1,opts:OptionsPattern[]]:=Module[
	{head1,head2,amp1,amp2,list1,list2,factor,offshellness,loopMomenta,extMomenta,sq,all,i,
		table,verbose,factoring,
		spRules,cutMoms,ampAssoc,cn,date},
	
	(*** Return if it has been already calculated ***)
	If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{dir,"AmplitudeSquared"}],
		Return[FileNameJoin[{dir,"AmplitudeSquared"}]//Get,Module]
	];
	
	Attributes[factoring]=Listable;
	factoring[exp_Times]:=factoring/@exp;
	factoring[exp_]:=SimplifyList[exp,_Pair|_Eps|_GPD,"Factoring"->Together];
	
	{head1,amp1}=CLTiming[FeynArtsReadAmp[file1]/.
		CalcLoopSymbol["GaugeXi"][xi_]:>("GaugeXi"[xi]/.OptionValue["GaugeXi"]),"FeynArtsReadAmp"];
		
	Which[
		file2===file1,{head2,amp2}={head1,amp1},
		Head@file2===String, {head2,amp2}=CLTiming[FeynArtsReadAmp[file2]/.
			CalcLoopSymbol["GaugeXi"][xi_]:>OptionValue["GaugeXi"][xi],"FeynArtsReadAmp"];
		If[head1=!=head2,
			Print["The two amplitudes are not the same process: ", {file1,file2}];
			Abort[]
		],
		True,amp2={file2}//Flatten;
	];
	(*** select needed diagrams ***)
	amp1=OptionValue["Operation"][[1]]@amp1;
	amp2=OptionValue["Operation"][[2]]@amp2;
	
	
	(*** Change amplitudes generated from FeynArts to simpler form ***)
	{amp1,amp2,head1}={amp1,amp2,head1}/.OptionValue["Replacement"]/.
		a_(b_+1/2 c_)+a_(b_-1/2 c_):>2a*b//.a_SUNT*b_+a_*c_:>a(b+c);
		
	loopMomenta=Union@Cases[#,LoopMomentum[_],Infinity]&/@{amp1,ComplexConjugate@amp2};
	extMomenta=Flatten@{head1[[1,All,2]],head1[[2,All,2]]};
	
	offshellness=Flatten@{head1[[1,All,3]],head1[[2,All,3]]};
	offshellness=ReplacePart[offshellness,OptionValue@"Offshellness"];
	head1[[1,All,3]]=offshellness[[1;;Length@head1[[1]]]];
	head1[[2,All,3]]=offshellness[[-Length@head1[[2]];;-1]];
	
	head1=head1/.{CalcLoopSymbol["V"][a_,___]:>"V"[a],CalcLoopSymbol["U"][a_,___]:>"U"[a],
		CalcLoopSymbol["S"][a_,___]:>"S"[a],
		CalcLoopSymbol["F"][a_,{b_,___},___]:>"F"[a,b]};
	(*** factor for ghosts ***)
	factor=I^Length@Cases[head1,"U"[___],Infinity];
	(*** factor for identical particals ***)
	factor=factor/Times@@(Factorial/@Length/@Gather@head1[[2,All,1]]);
	
	WriteMessage["*** Process: ",head1[[1,All,1;;3]]/.CalcLoopSymbol[a_]:>a];
	WriteMessage["           ->",head1[[2,All,1;;3]]/.CalcLoopSymbol[a_]:>a];
	WriteMessage["*** Helicity=",OptionValue["Helicity"],",\t GaugeXi=",OptionValue["GaugeXi"],
		",\t Reference=",OptionValue["ReferenceMomentum"],""];
	WriteMessage["*** LooopMomenta, Length, LeafCount of amp1=",
			{loopMomenta[[1]],Length@amp1,LeafCount@amp1}];
	WriteMessage["*** LooopMomenta, Length, LeafCount of amp2=",
			{loopMomenta[[2]],Length@amp2,LeafCount@amp2}];
	WriteMessage["*** Diagrams list of amp1=",list1];
	WriteMessage["*** Diagrams list of amp2=",If[Head@list2===List,list2,Range[Length@amp2]]];
	WriteMessage["*** Symmetry factor=",factor];
	WriteMessage["Average terms per kernel = ",Length@amp1*Length@amp2,"/",$ProcessorCount," ~ ",
		Ceiling[Length@amp1*Length@amp2/$ProcessorCount,1]];
	
	GenerateScalarProducts[head1];
	
	all=factor*Flatten@Outer[Times,amp1,ComplexConjugate[amp2]];
	
	all=OptionValue["Operation"][[3]]@all;
	
	(*Option of parallization*)
	table=If[OptionValue["Parallelize"],
		SetOptions[ParallelTable,DistributedContexts->All];
			verbose=0;
			ParallelTable,
		all={all};
		verbose=$CLVerbose;
		Table
	];
	
	cn=1;
	date=DateList[];
	sq=table[Block[
		{$CLVerbose},
		If[$KernelID<2,
			Print[cn++,": ",DateDifference[date,DateList[],"Second"]," used."];
			$CLVerbose=verbose
			,
			$CLVerbose=0
		];
		
		CLTiming[
			sq=FermionSpinSum[all[[i]],"Helicity"->OptionValue["Helicity"]];
			sq=BosonSpinSum[sq,"Helicity"->OptionValue["Helicity"],
							"ReferenceMomentum"->OptionValue@"ReferenceMomentum"],
			"SpinSum"
		];
		
		(*sq=sq/.dc:DiracChain[___,_*(_DiracGamma|_DiracChain),___]\[RuleDelayed]
				(dc//.DiracChain[a___,b_*(c_DiracGamma|c_DiracChain),d___]\[RuleDelayed]b*DiracChain[a,c,d]);*)
		
		sq=sq//SUNSimplify//CLTiming;
		
		sq=sq//LorentzSimplify//CLTiming;
		
		sq=sq//DiracSimplify//CLTiming;
		
		(*Contract lorentz indexes due to DiracChain and Eps*)
		If[!FreeQ[sq,LorentzIndex|Eps],
			sq=sq//EpsSimplify//LorentzSimplify//CLTiming
		];
		
		sq=CLTiming[factoring@sq,"Collect Pair and Eps"];
		
		sq=CLTiming[sq//MomentumSimplify//EpsSimplify,"MomentumSimplify"];
			
		If[!FreeQ[sq,DiracGamma],
			sq=DiracSimplify[sq,"OrderQ"->True]//MomentumSimplify//EpsSimplify//CLTiming
		];
		
		sq=CLTiming[TensorDecomposition[loopMomenta//Flatten,extMomenta,sq]//EpsSimplify,
			"TensorDecomposition"];

		sq=CLTiming[factoring@sq,"Collect Pair and Eps"];
		
		(*sq=sq/.a_GPD/;FreeQ[a,LoopMomentum]:>GPDExplicit@a;*)
		sq=GPDSplit@sq/.gpd:GPD[{a_,b_,c_,d_}]:>
			Sort[Expand//@{GPD[{-a,-b,c,d}],GPD[{a,b,c,d}]}][[-1]];
					
		sq
	], {i,Length@all}]//CLTiming;
	
	spRules=DownValues@Pair/.Pair[a_,b_]:>SP[a[[1]],b[[1]]]/.RuleDelayed->Rule//ReleaseHold;
	cutMoms=#[[All,1]]&/@GatherBy[head1[[2,All,2;;3]],Last]/.$MomentumRelation;
	
	ampAssoc=Association[
		"Expression"->Flatten[sq],"LoopMomenta"->loopMomenta,"ExternalMomenta"->extMomenta,
		"Conservation"->$MomentumRelation,"SPRules"->spRules,"CutMomenta"->cutMoms,
		"PhaseSpaceMomenta"->Select[cutMoms//Flatten,Head@#=!=Plus&][[1;;Length@Flatten@cutMoms-1]]
	];
	
	If[FileNames[dir]==={},CreateDirectory@dir];
	Put[ampAssoc,FileNameJoin[{dir,"AmplitudeSquared"}]];
	
	FileNameJoin[{dir,"AmplitudeSquared"}]
];


(* ::Section::Closed:: *)
(*End*)


End[];
