(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


FI


FamilyDecomposition::usage="FamilyDecomposition[dir_,ampAssoc_,OptionsPattern[]]
FamilyDecomposition[exp_,{momC_,denC_},{momL_,momR_,momE_}] \
decomposes all Feynman integrals in 'exp' to certain families. 'momC' denotes cut momenta; \
'denC' denotes cut denominators; 'momL' denotes loop momenta on the lhs of the cut; \
'momR' denotes loop momenta on the rhs of the cut; and 'momE' denotes independent external momenta.";


GPDApart::usage="GPDApart[exp_,vars_List] reduces linear dependence of \
denominators in 'exp', where 'vars' is a list of scalar products containing loop momenta. \
Each denominator is expressed as GPD[{p1,q1,m1,power1},...,{pn,qn,mn,powern}].";


DefineFamilies::usage="DefineFamilies[gpds_List,loops_List,extmoms_List] ={familyInf,sectorInf,famRep} \
defines families and sectors of Feynman integrals based on the input list of propagator denominators. \
Symmetries between sectors, or within a sector, are explored. Zero sectors are identified. 

'gpds' is a list, with each element being a set of propagator denominators in the form of GPD.
'loops', like {{la,lb},{lA},...} or {l1, l2,...} (equivalent to {{l1, l2,...}}), represents blocks of \
loop momenta, with condition that exchange of momenta within each block does not change final integrated result.
'extmoms' is a list of unintegrated external momenta.
Options[\"CutInformation\"] looks like {{{p2-p1,p1},{p3,p5},...},{p1,p2,...}}. The second part \
is a list of momenta to be integrated in phase space integration. The first part is a list of lists of \
symmetric cut momenta, with condition that exchanging cut momenta within each list does not change \
the final integrated result. In this example, {p1, p2, ...} are momenta to be integrated; \
the exchange of p2-p1 and p1 (or p3 and p5) does not change the final integrated result.

'famRep' is a list of lists of replacements. Each list looks like {l1\[Rule]l1+p1,l2\[Rule]-l2+l1,...}, \
which changes the corresponding element of 'gpds' to the standard form defined by LoopSymmetry.

'sectorInf' is an Association with each element denoting an unique sector. \
Each unique sector is in the form of \
standardDens->Association[\"No\"->secNo, \"Family\"->gpds, \"Sector\"->sec, \
\"Mom.Stan2Curr\"->momStan2Fam, \"Mom.Syms\"->momSyms, \"Den.Syms\"->denSyms], where 
'standardDens' like {{p1,q1,m1,1},{p2,q2,m2,1},...} is the standard form of denominators after \
applying the LoopSymmetry, 
'secNo' is a number denoting the sector ordinal, 
'gpds' is similar to 'standardDens' but containing a complete set of denominators defining a family, 
'sec' like {1,0,1,1,0,...} represents the current sector in the family, 
'momStan2Fam' like {l1\[Rule]l1+p1,l2\[Rule]-l2+l1,...} replaces 'standardDens' to denominators in 'gpds', 
'momSyms' like {{l1\[Rule]l1,l2\[Rule]l2,...},{l1\[Rule]l1-p1,l2\[Rule]l1+l2,...},...} represents replacement rules \
which do not change denominators in this sector.
'denSyms' has the same meaning as 'symRep', but with replacement rules of denominators, like \
{{\"Den\"[famNo]\[InvisibleApplication][1]\[Rule]\"Den\"[famNo][2]+\"Den\"[famNo]\[InvisibleApplication][6]+ Sp12, ...},...}.

'familyInf' is an Association with each element denoting a family. \
Each family is in the form of \
standardDens->Association[\"No\"->famNo, \"SP2Den\"->sp2Den, sec1->sec1inf, sec2->sec2inf,...], \ 
where 
'standardDens', like {{p1,q1,m1,1},{p2,q2,m2,1},...}, is the standard form of propagator \
denominators after applying LoopSymmetry,
'famNo' is an integer, denoting the family ordinal,
'sp2Den', like {l1^2\[Rule]Den[famNo][1],l1*l2\[Rule]Den[famNo][1]+Den[famNo][2]-Den[famNo][3],...}, \
gives rules to change scalar products to denominators in the current family.
'seci', like {1,0,1,1,0,...}, represents one of the complete set of sectors in the family,
'seciinf'=0 or n or Association[\"No\"->secNo, \"Den.Curr2Uniq\"->den2Uniq, \"Mom.Curr2Stan\"->mom2Stan], \
where 
0 means a zero sector, 
'n' means the current sector is the definition of the unique sector 'n',
'secNo' is an integer denoting the unique sector number which the current sector can be mapped to,
'den2Uniq' like {\"Den\"[famNo]\[InvisibleApplication][1]\[Rule]\"Den\"[famNo2][1],\"Den\"[famNo]\[InvisibleApplication][2]\[Rule]\"Den\"[famNo2]\[InvisibleApplication][4]+\"Den\"[famNo2]\[InvisibleApplication][6]+ Sp12, ...} \
are rules to change denominators in the current family 'famNo' to denominators in family 'famNo2'.
'mom2Stan', like {l1\[Rule]l1+p1,l2\[Rule]-l2+l1,...}, changes denominators in the current sector to the standard form.";


Begin["`Private`"];
stringToTemplate;
End[];


Begin["`Family`"];


stringToTemplate[list_]:=StringTemplate[StringJoin[Riffle[list,"\n"]]];


(* ::Section:: *)
(*FamilyDecomposition*)


Options[FamilyDecomposition]={"Parallelize"->False,"MonitorQ"->True,
	"NumeratorSymmetry"->False,"ReadSaved"->False,"CutMomenta"->Automatic,"PhaseSpaceMomenta"->Automatic};
FamilyDecomposition[dir_String,ampFile_String,OptionsPattern[]]:=Module[
	{ampAssoc,exp,loopmoms,momE,conservation,SPRep,paraQ,monitor,timing,i,cutmoms,psmoms,table,
	loopMs,vars,
	sep,gpds,familyInf,sectorInf,famRep,pool,asso,sectors,coes,
	integrals,familyKeys,verbose,cn,date,optionsOfParallelTable,files},
	
	(*** Return if final result has already been calculated ***)
	If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{dir,"Integrals"}],
		Return[FileNameJoin[{dir,"Integrals"}]//Get,Module]
	];
	If[FileNames[dir]==={},CreateDirectory@dir];
	
	If[FileExistsQ@ampFile,
		ampAssoc=Get[ampFile],
		ErrorPrint[ampFile, "does not exist."];
		Return[0,Module]
	];
	If[OptionValue["CutMomenta"]=!=Automatic,
		ampAssoc["CutMomenta"]=OptionValue["CutMomenta"]
	];
	If[OptionValue["PhaseSpaceMomenta"]=!=Automatic,
		ampAssoc["PhaseSpaceMomenta"]=OptionValue["PhaseSpaceMomenta"]
	];


	exp=ampAssoc["Expression"];
	loopmoms=ampAssoc["LoopMomenta"];
	momE=ampAssoc["ExternalMomenta"];
	conservation=ampAssoc["Conservation"];
	SPRep=ampAssoc["SPRules"];	
	cutmoms=ampAssoc["CutMomenta"];
	psmoms=ampAssoc["PhaseSpaceMomenta"];
	
	
	momE=momE/.conservation//Variables;
	
	If[OptionValue["MonitorQ"]===True,
		monitor=Monitor;
		timing=CLTiming;
		,
		monitor=List;
		timing=Identity
	];
	
	paraQ=OptionValue["Parallelize"];
	(*Option of parallization*)
	table=If[paraQ===True,
		verbose=0;
		optionsOfParallelTable=Options[ParallelTable];
		SetOptions[ParallelTable,Method->"FinestGrained",DistributedContexts->All];
		ParallelTable
		,
		verbose=$CLVerbose;
		optionsOfParallelTable={};
		Table
	];
	
	loopMs=Flatten[{loopmoms,psmoms}];
	vars=Outer[SP,Join[loopMs,momE],Join[loopMs,momE]]/.SPRep//Variables;
	vars=Select[vars,!FreeQ[#,Alternatives@@loopMs]&];
	
	exp=exp/.Pair[Momentum[a_],Momentum[b_]]:>SP[a,b]//GPDSplit;
	gpds=Cases[exp,_GPD,Infinity]//Union;
	(*** give explicit form for denominators independent of integrated variables ***)
	gpds=Table[If[FreeQ[#,Alternatives@@vars],gpd->#,Nothing]&@GPDExplicit[gpd,SPRep],
		{gpd,gpds}];
	
	If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{dir,"temp_GPDAparted"}],
		WriteMessage["Read GPDAparted..."];
		exp=FileNameJoin[{dir,"temp_GPDAparted"}]//Get
		,
		exp=GPDApart[exp/.gpds,vars,SPRep]//timing;
		Put[exp,FileNameJoin[{dir,"temp_GPDAparted"}]];
	];
	
	exp=Separate[Plus@@exp,_GPD];
	
	If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{dir,"temp_FamilyInf"}]&&
		FileExistsQ@FileNameJoin[{dir,"temp_SectorInf"}]&&
		FileExistsQ@FileNameJoin[{dir,"temp_FamilyRep"}]
		,
		WriteMessage["Read FamilyInf, SectorInf, and FamilyRep..."];
		familyInf=FileNameJoin[{dir,"temp_FamilyInf"}]//Get;
		sectorInf=FileNameJoin[{dir,"temp_SectorInf"}]//Get;
		famRep=FileNameJoin[{dir,"temp_FamilyRep"}]//Get;
		,
		{familyInf,sectorInf,famRep}=DefineFamilies[exp[[2]],loopmoms,momE,SPRep,
			"Parallelize"->paraQ,"CutInformation"->{cutmoms,psmoms}]//timing;
		Put[familyInf,FileNameJoin[{dir,"temp_FamilyInf"}]];
		Put[sectorInf,FileNameJoin[{dir,"temp_SectorInf"}]];
		Put[famRep,FileNameJoin[{dir,"temp_FamilyRep"}]];
	];
	
	exp[[2]]=GPDExplicit[#,SPRep]&/@exp[[2]];
	
	WriteMessage["Average terms per kernel = ",Length[exp[[2]]],"/",$ProcessorCount," = ",
		Round[Length[exp[[2]]]/$ProcessorCount,1]];
	cn=1;
	date=DateList[];
	pool=table[Block[
		{$CLVerbose,file,familyi},
		If[$KernelID<2,
			Print[cn++,"(",i,"-th) ",": ",
				DateDifference[date,DateList[],"Second"]," used."];
			$CLVerbose=verbose
			,
			$CLVerbose=0
		];
		file=FileNameJoin[{dir,"temp_MappedFamily"<>ToString[i]}];
		If[OptionValue@"ReadSaved"===True&&FileExistsQ@file,
			familyi=file//Get
			,
			familyi=mapSingleFamily[familyInf,sectorInf,famRep[[i]],exp[[1,i]],exp[[2,i]],
				"NumeratorSymmetry"->OptionValue@"NumeratorSymmetry"];
			Put[familyi,file];
		];
		familyi
		],{i,Length@exp[[2]]}
	]//timing;

	asso=associationPlus@pool;
	asso=DeleteCases[DeleteCases[#,0]&/@asso,<||>];
	sectors=Keys@asso;
	asso=Values@asso//Normal//Flatten;
	asso=SortBy[asso,orderingFI@#[[1]]&];
	integrals=asso[[All,1]];
	coes=GeneralizedApart[asso[[All,2]],"Factoring"->Factor]//timing;
	
	(*** SP[0,0] appears in tadpole***)
	coes=coes/.SP[0,0]->0;
	
	asso=Select[Thread[integrals->coes],#[[2]]=!=0&];
	familyKeys=familyInf//Keys;
	asso=familyKeys[[#[[1,1,1]]]]->Association@@#&/@GatherBy[asso,#[[1,1]]&];
	
	WriteMessage[Length@integrals," FIs obtained in ",Length@sectors," sectors."];
	
	files=writeResult[dir,asso,Delete[ampAssoc,"Expression"]];
	Put[files,FileNameJoin[{dir,"Families"}]];
	(*Put[asso,FileNameJoin[{dir,"Integrals"}]];*)	
	SetOptions[ParallelTable,Sequence@@optionsOfParallelTable];
	
	FileNameJoin[{dir,"Families"}]
	
];


(* ::Section::Closed:: *)
(*DefineFamilies*)


Options[DefineFamilies]={"Parallelize"->False,"CutInformation"->{{},{}},"DefineSectorQ"->True,
"KnownFamilies"->Association[],"KnownSectors"->Association[],"MonitorQ"->True,"ISP"->2}; 


DefineFamilies[gpds_List,loopmoms_List,momE_List,SPRep_,OptionsPattern[]]:=Module[
	{monitor,timing,cutmoms,psmoms,loopMs,vars,adds,$FamilyInf,$SectorInf,table,gpdlist,nd,
	i,j,famNo,secNo,den2SP,sp2Den,Di,denCur2Uni,denUni2Cur,secInf,n,list,rep,symRep,dens,denj,sec,
	famInf,X,uniqueMom,uniqueMomSort,uniqueMomSec,repInv,symRep2,$FamilyInfi,$SectorInfi},
	
	If[OptionValue["MonitorQ"]===True,
		monitor=Monitor;
		timing=CLTiming;
		,
		monitor=List;
		timing=Identity
	];
	
	(*** cut momenta and momenta of phase space integration***)
	{cutmoms,psmoms}=OptionValue["CutInformation"];
	
	loopMs=Flatten[{loopmoms,psmoms}];
	vars=Outer[SP,Join[loopMs,momE],Join[loopMs,momE]]/.SPRep//Variables;
	vars=Select[vars,!FreeQ[#,Alternatives@@loopMs]&];
	
	$FamilyInf=OptionValue["KnownFamilies"];
	$SectorInf=OptionValue["KnownSectors"];

	table=If[OptionValue["Parallelize"],
		SetOptions[ParallelTable,DistributedContexts->All];ParallelTable,
		Table
	];
		
	
	gpdlist=GPDCombine[#]/.{a_,b_,c_,d_}/;d>0:>{a,b,c,1}/.GPD->List&/@gpds;
	nd=Length@gpdlist;
	
	uniqueMom=table[
		denj=gpdlist[[j]];
		If[denj===1,denj={}];
		LoopSymmetry[denj,loopmoms,SPRep,"CutInformation"->{cutmoms,psmoms}],{j,1,nd}
	];	
	
	(*Integrals with more denominators are on the left*)
	uniqueMomSort=Sort[uniqueMom,Length[#1[[1]]]>Length[#2[[1]]]&];
	
	monitor[For[i=1,i<=nd,i++,
		
		{dens,rep}=uniqueMomSort[[i]];		
		n=dens//Length;
		
		(*If the corresponding sector has not been defined, define a new family.*)
		If[dens===0||KeyExistsQ[$SectorInf,dens],Continue[]];
		famNo=Length@$FamilyInf+1;	
		$FamilyInfi=Association["No"->famNo];
		
		(*Add new denominators to make it complete; Linear or quardratic*)
		adds=If[OptionValue@"ISP"===1,vars,vars/.SP[a_,b_]:>SP[a+b,a+b]];
		adds=adds[[linearCompletion[GPDExplicit[GPD[{#1,#2,#3,-1}]&@@@dens,SPRep],SPExpand[adds,SPRep],vars]]];
		dens=Join[dens,adds]/.SP[a_,b_]:>{a,b,0,0};
		
		(*Define rules*)
		den2SP=Thread[Array["Den"[famNo],Length@dens]->GPDExplicit[GPD[{#1,#2,#3,-1}]&@@@dens,SPRep]];
		sp2Den=Solve[den2SP/.Rule->Equal,vars];
		If[Length@sp2Den=!=1,Print["Error in define Families: sol. ",den2SP,vars,dens,gpds];Abort[]];
		$FamilyInfi["SP2Den"]=sp2Den[[1]]//Expand;
		
		
		(*Explore all sectors in the family.*)
		list=SortBy[Table[PadLeft[IntegerDigits[j,2],n],{j,0,2^n-1}],Total]//Reverse;
		
		(*** continue if no sector information is required ***)
		If[OptionValue["DefineSectorQ"]===False,
			$FamilyInf[dens]=$FamilyInfi;
			Continue[]
		];
		
		uniqueMomSec=table[
			denj=dens[[Position[list[[j]],1]//Flatten]];
			LoopSymmetry[denj,loopmoms,SPRep,"CutInformation"->{cutmoms,psmoms}],{j,1,Length@list}
		];
		
		For[j=1,j<=Length@list,j++,
			sec=PadRight[list[[j]],Length@vars];
			{denj,rep}=uniqueMomSec[[j]];
			If[denj===0,$FamilyInfi[sec]=0;Continue[]];
			
			(*If the corresponding sector has been defined, relate it to the defined one.*)
			If[KeyExistsQ[$SectorInf,denj],
				secInf=$SectorInf[denj];
				denCur2Uni=SPExpand[den2SP/.rep[[1]]/.secInf["Mom.Stan2Curr"],SPRep]/.
					Lookup[$FamilyInf,Key@secInf@"Family",$FamilyInfi]["SP2Den"]//Expand;
				(*** calculate inverse mapping ***)
				denUni2Cur=Solve[Table["den"[k]==denCur2Uni[[k,2]],{k,Length@denCur2Uni}]/.Rule->Equal,
					Union@Cases[denCur2Uni[[All,2]],"Den"[_][_],Infinity]][[1]]/.
					Thread[Array["den",Length@denCur2Uni]->denCur2Uni[[All,1]]]//Expand;
				$FamilyInfi[sec]=Association["No"->secInf@"No","Den.Curr2Uniq"->denCur2Uni,
					"Den.Uniq2Curr"->denUni2Cur,"Mom.Curr2Stan"->rep[[1]]];
				Continue[]
			];
			
			(*If the corresponding sector has not been defined, define a new sector.*)
			secNo=Length@$SectorInf+1;
			$FamilyInfi[sec]=secNo;
			(*** change standard denominators to current denominators ***)
			repInv=Solve[Thread[Array[X,Length@loopMs]==(loopMs/.rep[[1]])],loopMs][[1]]/.
				Thread[Array[X,Length@loopMs]->loopMs];
			(*** symmetries of denominators: from replacements of loop momenta ***)
			symRep=Thread[#[[All,1]]->Expand[#[[All,2]]/.repInv]]&/@rep[[2;;-1]];
			(*** symmetries of denominators: from replacements of denominators and ISPs ***)
			symRep2=Expand[SPExpand[den2SP/.#,SPRep]/.sp2Den[[1]]]&/@symRep;
			$SectorInf[denj]=Association["No"->secNo,"Family"->dens,"Sector"->sec,
									"Mom.Stan2Curr"->repInv,"Mom.Syms"->symRep,"Den.Syms"->symRep2];
		];
		$FamilyInf[dens]=$FamilyInfi;
	],{i,"out of",nd}];
	
	WriteMessage["Number of Families = ",Length@$FamilyInf,
		". Number of Sectors = ",Length@$SectorInf,"."];
	
	(*** define replacement rule for each input ***)
	
	{$FamilyInf,$SectorInf,Table[
		{dens,rep}=uniqueMom[[i]];
		If[dens===0,0,
		secInf=$SectorInf[{#1,#2,#3,1}&@@@dens];
		Thread[vars->(SPExpand[vars/.rep[[1]]/.secInf["Mom.Stan2Curr"],SPRep]/.
				Lookup[$FamilyInf,Key@secInf@"Family",$FamilyInfi]["SP2Den"]//Expand)]
		]
		,{i,Length@uniqueMom}
	]}
];


(* ::Section::Closed:: *)
(*GPDApart*)


GPDApart[exp_List,vars_,SPRep_,opts:OptionsPattern[]]:=GPDApart[#,vars,SPRep,opts]&/@exp;


GPDApart[exp_,vars_,SPRep_,opts:OptionsPattern[]]/;Head@exp=!=List:=Module[
	{sep,lcm},
	
	If[Flatten@vars==={},Return[exp,Module]];
	
	sep=Separate[exp//GPDSplit,_GPD];
	
	sep[[2]]=GeneralizedApart[#,vars,"DenominatorFunction"->{GPD,1/GPDExplicit[##,SPRep]&}]&/@sep[[2]];
	
	sep=Separate[Dot@@sep,_GPD];
	Do[
		Do[
			If[#[[1]]===#[[2]]||#[[1]]===#[[3]],
				lcm=PolynomialLCM[sep[[2,j]],sep[[2,i]]];
				sep[[1,j]]=sep[[1,j]]*GPDExplicit[sep[[2,j]]/lcm,SPRep]+sep[[1,i]]*GPDExplicit[sep[[2,i]]/lcm,SPRep];
				sep[[1,i]]=0;
				sep[[2,j]]=lcm
			]&@({sep[[2,i]]*sep[[2,j]],sep[[2,i]],sep[[2,j]]}/.GPD[x_]^n_:>GPD[x])
		,{j,i+1,Length@sep[[1]]}
		],{i,Length@sep[[1]]}
	];
	sep[[1]]=sep[[1]]//Together;
	sep[[2]]=sep[[2]]//GPDCombine;
	Dot@@sep
];


(* ::Section::Closed:: *)
(*FIJoin / FISplit*)


(*** Change FIs from FI[famNo,pow] form to "Den"[_][_] form ***)
FISplit[exp_]:=exp/.FI[famNo_,pow_List]:>Times@@(Array["Den"[famNo],Length@pow]^-pow);


(*** Change FIs from "Den"[_][_] form to FI[famNo,pow] form ***)
Options[FIJoin]={};
FIJoin[a_,famNo_,n_,opts:OptionsPattern[]]:=fiJoin[Expand[a],famNo,n,opts];
Attributes[fiJoin]={Listable};
Options[fiJoin]={};
fiJoin[a_Plus,famNo_,n_,opts:OptionsPattern[]]:=Plus@@fiJoin[List@@a,famNo,n,opts];
fiJoin[a_Rule,famNo_,n_,opts:OptionsPattern[]]:=Rule@@fiJoin[List@@a,famNo,n,opts];
fiJoin[a_,famNo_,n_,opts:OptionsPattern[]]:=Module[
	{asso,fac,f},
	f["Den"[i_][j_]^(pow_:1)]:=(asso[j]=-pow;1);
	asso=Association[];
	fac=If[Head@a===Times,f/@a,f@a]/.f->Identity;
	fac*FI[famNo,Lookup[asso,Range[n],0]]
];
fiJoin[0,famNo_,n_,OptionsPattern[]]=0;


(* ::Section:: *)
(*writeResult*)


Options[writeResult]={"FamilyName"->Automatic,"Target"->{}};


writeResult[dir_,exp_List,info_Association,opts:OptionsPattern[]]:=Module[
	{template,cutmoms,psmoms,loopMs,prescription,exclude,extMs,replacement,cut0,cut,propagator,factor,
		integral,coefficient,famNo,rule},
	
	If[exp==={},Return[{},Module]];
	
	template=stringToTemplate[{
	"{\"Family\"->`family`,",
	"\"IntegratedMomenta\"->`loop`,",
	"\"Prescription\"->`prescription`,",
	"\"FixedMomenta\"->`leg`,",
	"\"Conservation\"->{},",
	"\"SPRules\"->`replacement`,",
	"\"Propagators\"->`propagator`,",
	"\"Cut\"->`cut`,",
	"\"Integrals\"->`integral`,",
	"\"Coefficients\"->`coefficient`}"
	}];
	
	{cutmoms,psmoms}=info/@{"CutMomenta","PhaseSpaceMomenta"};
	
	loopMs=Flatten[{info@"LoopMomenta",psmoms}];
	prescription=Switch[#,LoopMomentum[n_]/;n<0,-1,LoopMomentum[n_]/;n>0,1,_,0]&/@loopMs;
	
	cutmoms=#^2-SPExpand[SP[#,#],info@"SPRules"]&/@Flatten@cutmoms;
	(*** remove delta functions independent of loop momenta and phasespace momenta ***)
	factor=(2\[Pi])CalcLoopSymbol["DiracDelta"[#]]&/@Select[cutmoms,FreeQ[#,Alternatives@@loopMs]&];
	cutmoms=Select[cutmoms,!FreeQ[#,Alternatives@@loopMs]&];
	
	
	exclude=Join[loopMs,info["Conservation"][[All,1]]];
	extMs=Complement[info@"ExternalMomenta",exclude];
	
	replacement=Select[info@"SPRules",FreeQ[#[[1]],Alternatives@@exclude]&];
	replacement[[All,1]]=replacement[[All,1]]/.SP->Times;
	
	
	cut0=ConstantArray[1,Length@cutmoms];
	cut=Join[cut0,ConstantArray[0,Length@exp[[1,1]]]];
	
	Table[
		propagator=#[[1]]*#[[2]]+#[[3]]&/@exp[[i,1]];
		propagator=Join[cutmoms,propagator];
		integral=Keys@exp[[i,2]]/.FI[n_,nus_]:>FI[n,Join[cut0,nus]];
		coefficient=Times@@factor*Values@exp[[i,2]];
		famNo=integral[[1,1]];
		
		
		rule=ToString[#,InputForm]&/@<|
			"family"->famNo,
			"loop"->loopMs,
			"prescription"->prescription,
			"leg"->extMs,
			"replacement"->replacement,
			"propagator"->propagator,
			"cut"->cut,
			"integral"->integral,
			"coefficient"->coefficient
		|>;
		
		If[FileNames[#]==={},CreateDirectory@#]&@FileNameJoin[{dir,ToString[famNo]}];
		FileTemplateApply[template,rule,FileNameJoin[{dir,ToString[famNo],"amplitudeData"}]];
		FileNameJoin[{dir,ToString[famNo],"amplitudeData"}]
		,{i,Length@exp}
	]
];


(* ::Section::Closed:: *)
(*linearCompletion*)


linearCompletion::usage="linearCompletion[part_List,all_List,vars_List] gives a sub-set of 'all' (positions), \
which combining with 'part' form a complete set to linearly expand all elements in 'vars'. ";


linearCompletion[part_List,all_List,vars_List]:=Module[
	{trans,matrix,i,j,temp,add,var},
	(***all=trans.vars,part=matrix.vars=matrix.trans^-1.all***)
	trans=Coefficient[all,#]&/@vars//MMATranspose;
	matrix=Coefficient[part,#]&/@vars//MMATranspose;
	matrix=If[part==={},{},matrix . Inverse@trans];
	add={};
	Do[
		For[i=1,i<=Length@matrix,i++,
			If[matrix[[i,j]]=!=0,Break[]]
		];
		
		If[i>Length@matrix,
			PrependTo[add,j],
			Do[If[matrix[[k,j]]=!=0&&k=!=i,matrix[[k]]-=matrix[[k,j]]/matrix[[i,j]]*matrix[[i]]],{k,Length@matrix}];
			matrix=Drop[matrix,{i}];
		];
		
		,{j,Length@all,1,-1}
	];
	
	add
];


(* ::Section::Closed:: *)
(*mapSingleFamily*)


Options[mapSingleFamily]={"NumeratorSymmetry"->True};
mapSingleFamily[familyInf_,sectorInf_,sp2Fam_,coe0_,den0_,OptionsPattern[]]:=Module[
	{symQ,famNo,familyInfi,len,den,coe,factor,sep,asso,pool,maxes,dots,rank,sec,secNo,
	curr2Uniq,uniq2Curr,uniSecInf,uniFamNo,sol,uniInts,curInts,currDenSym,solCurr,rec},
	
	If[sp2Fam===0,Return[Association[],Module]];
	
	symQ="NumeratorSymmetry"//OptionValue;
	
	famNo=If[Length@familyInf===1,familyInf[[1]]@"No",Cases[sp2Fam,"Den"[_][_],Infinity][[1,0,1]]];
	familyInfi=familyInf[[famNo]];
	
	len=Length@sp2Fam;
	
	den=den0/.sp2Fam//Factor;
	If[Head@coe0===Times,
		coe=Select[coe0,!FreeQ[#,Alternatives@@sp2Fam[[All,1]]]&];
		factor=Select[coe0,FreeQ[#,Alternatives@@sp2Fam[[All,1]]]&]
		,
		coe=coe0;
		factor=1
	];
	
	asso=coe*den/.sp2Fam;
	
	asso=Separate[asso//FIJoin[#,famNo,len]&,_FI];
	
	If[!FreeQ[asso,"Den"],
		Print["mapSingleFamily: Denominators cannot be combined to form Feynman integrals. ",
			Short@asso,Short@Union@Cases[asso,"Den"[_][_],Infinity]
		];
		Abort[]
	];
	
	asso=Association@@Thread[asso[[2]]->asso[[1]]];
	pool=Association[];
	rec=0;
	
	While[Length@asso>0,
		
		maxes=MaximalBy[Keys@asso,orderingFI];
		If[orderingFI@maxes[[1]]===orderingFI@rec,
			Print["Deadloop detected in mapSingleFamily: ",
			{rec,maxes,Table[asso[int],{int,maxes}]}];
			Abort[]
			,
			rec=maxes[[1]]
		];
		
		dots=Plus@@(Select[maxes[[1,2]],#>1&]-1);
		rank=-Plus@@Select[maxes[[1,2]],#<0&];
		sec=UnitStep/@(maxes[[1,2]]-1/2);
		secNo=familyInfi[sec];
		
		(*** zero sector ***)
		If[secNo===0,
		Do[asso@maxes[[j]]//Unset,{j,Length@maxes}];
		Continue[]];
		(*** the unique sector itself ***)
		If[IntegerQ@secNo,
			If[symQ===True,
				currDenSym=sectorInf[[secNo]]@"Den.Syms";
				currDenSym=symFullReduce[currDenSym,sec,dots,rank];
				curInts=(#/.currDenSym)-#&@(maxes . Table[asso[int],{int,maxes}]);
				curInts=Separate[curInts,_FI]//Expand;
				Do[If[#=!=0,associationAddTo[asso@curInts[[2,j]],#]]&@curInts[[1,j]]
					,{j,Length@curInts[[1]]}];
				(*** newly obtained most complicated FIs after applying symmetry ***)
				maxes=MaximalBy[Keys@asso,orderingFI];	
			];
			Do[associationAddTo[pool@secNo@int,asso@int]; asso@int//Unset,{int,maxes}];
			Continue[]
		];
		
		(*** mapping to an unique sector, with 'secNo'***)
		{secNo,curr2Uniq,uniq2Curr}=secNo/@{"No","Den.Curr2Uniq","Den.Uniq2Curr"};
		uniSecInf=sectorInf[[secNo]];
		uniFamNo=familyInf[uniSecInf@"Family"]@"No";
	
		(*** reduction of most complicated FIs in unique sector using symmetries ***)
		sol=If[symQ===True,symTopReduce[Collect[#,Alternatives@@Array["Den"[uniFamNo],Length@#],
			Together]&/@uniSecInf@"Den.Syms",uniSecInf@"Sector",dots,rank],{}];
		(*add Collect[#,Alternatives@@Array["Den"[uniFamNo],Length@#],Together]&/@*)
		
		(*** generate and add most complicated FIs in unique sector ***)
		uniInts=FIJoin[FISplit@maxes/.(Collect[#,Alternatives@@Array["Den"[uniFamNo],Length@#],
			Together]&/@symTopRule[sec,curr2Uniq]),uniFamNo,len]/.sol//Expand;
		(*add Collect[#,Alternatives@@Array["Den"[uniFamNo],Length@#],Together]&/@*)
		uniInts=Separate[uniInts . Table[asso[int],{int,maxes}],_FI]//Expand;
		Do[
			If[#=!=0,associationAddTo[pool@secNo@uniInts[[2,j]],#]]&@uniInts[[1,j]]
			,{j,Length@uniInts[[1]]}
		];
		
		(*** reduce complicated FIs in current sector using symmetries ***)
		If[symQ===True,
			currDenSym=Thread[curr2Uniq[[All,1]]->(curr2Uniq[[All,2]]/.#/.uniq2Curr//Expand)]&/@
				uniSecInf["Den.Syms"];
			currDenSym=symFullReduce[currDenSym,sec,dots,rank];
			
			,
			currDenSym={}
		];
		
		(*** subtract mapped FIs ***)
		curInts=Dot@@Separate[FISplit[Dot@@uniInts]/.uniq2Curr//FIJoin[#,famNo,len]&,_FI];
		curInts=maxes . Table[asso[int],{int,maxes}]-curInts/.currDenSym;
		curInts=Separate[curInts,_FI]//Expand;
		Do[If[Together[#]=!=0,associationAddTo[asso@curInts[[2,j]],#]]&@curInts[[1,j]],
			{j,Length@curInts[[1]]}];
		(*add Together*)
		
		Do[asso@maxes[[j]]//Unset,{j,Length@maxes}]
	];
	
	factor*Together[pool]
];


(* ::Section::Closed:: *)
(*symTopRule*)


(*** select terms in symmetry relations that result in most complicated FIs ***)
symTopRule[sec_,denrule_]:=Module[
	{dens,nums,newrule},
	dens=Position[sec,1]//Flatten;
	nums=Position[sec,0]//Flatten;
	newrule=denrule[[All,2]];
	newrule[[nums]]=newrule[[nums]]/.Thread[denrule[[dens,2]]->0];
	newrule[[nums]]=newrule[[nums]]-(newrule[[nums]]/."Den"[_][_]->0);
	newrule=Thread[denrule[[All,1]]->newrule]
];


(* ::Section::Closed:: *)
(*linearEqs2Sparse*)


Options[linearEqs2Sparse]={"Form"->Association};
linearEqs2Sparse[eqs0_List,vars_List,Fun_Symbol,OptionsPattern[]]:=Module[
	{eqs,map,res},
	
	(*Dealing with expressions like s*Fun[]+t*Fun[] *)
	eqs=Collect[eqs0,_Fun,Together];
	
	map=Association@@Thread[vars->Range[vars//Length]];
	
	res=Association@@Table[i->Association@@Sort[If[Head@#===Plus,List@@#,{#}]&@eqs[[i]]/.
		x_Fun*y_:1:>If[KeyExistsQ[map,x],(map[x]->y),Nothing]],{i,Length@eqs}]/.
		Association[0]->Association[];
	If[OptionValue["Form"]=!=Association,
		res=Join@@Table[({i,#1}->#2)&@@@Normal@res[i],{i,Keys@res}]//SparseArray
	];
	
	res
];


(* ::Section::Closed:: *)
(*symTopReduce*)


Options[symTopReduce]={"Solver"->SparseRowReduce};
symTopReduce[symRep_,sec_,dots_,rank_,OptionsPattern[]]:=Module[
	{famNo,length,ints,eqs,numRule,fis,map,sol,keys},
	If[Length@symRep===0,Return[{},Module]];
	famNo=FirstCase[symRep[[1]],"Den"[_][_],Missing[],Infinity][[0,1]];
	length=symRep[[1]]//Length;
	ints=FI[famNo,#]&/@generateSeeds[sec,dots,rank];
	eqs=Table[
		(*** select terms giving most complicated FIs ***)
		numRule=symTopRule[sec,symRep[[i]]];
		(*** FIJoin: spends about 1/4 time ***)
		ints->(FISplit@ints/.numRule//FIJoin[#,famNo,length]&)//Thread
		,{i,Length@symRep}
		]/.Rule[a_,b_]:>a-b//Flatten;

	(*** put most complicated FIs on the leftmost ***)
	fis=Reverse@SortBy[Union@Cases[eqs,_FI,Infinity],orderingFI];
	
	(*** Row reduce: spends about 3/4 time ***)
	If[OptionValue["Solver"]=!=RowReduce,
		eqs=linearEqs2Sparse[eqs,fis,FI];
		sol=SparseRowReduce[eqs,Length@eqs];
		,
		eqs=linearEqs2Sparse[eqs,fis,FI,"Form"->SparseArray];
		sol=RowReduce[eqs]//SparseArray//ArrayRules;
		sol=Association@@(#[[All,1,1]]->Association@@Thread[#[[All,1,2]]->#[[All,2]]]&/@
				GatherBy[DeleteCases[sol,Rule[{_Blank,_},_]],#[[1,1]]&]);
	];
	
	map=Association@@Thread[Range[fis//Length]->fis];
	
	Table[keys=Keys@sol[i];
			map@keys[[1]]->map@keys[[1]]-(map/@keys) . Values@sol[i]//Expand,{i,Keys@sol}]
]


symTopReduceOld[symRep_,sec_,dots_,rank_]:=Module[
	{famNo,length,ints,eqs,numRule,sol},
	If[Length@symRep===0,Return[{},Module]];
	famNo=FirstCase[symRep[[1]],"Den"[_][_],Missing[],Infinity][[0,1]];
	length=symRep[[1]]//Length;
	ints=FI[famNo,#]&/@generateSeeds[sec,dots,rank];
	eqs=Table[
		(*** select terms giving most complicated FIs ***)
		numRule=symTopRule[sec,symRep[[i]]];
		ints->(FISplit@ints/.numRule//FIJoin[#,famNo,length]&)//Thread
		,{i,Length@symRep}
		]/.Rule[a_,b_]:>a-b//Flatten;
	
	sol=PolynomialRowReduce[eqs,Reverse@SortBy[Union@Cases[eqs,_FI,Infinity],orderingFI],"Sparse"->True,
		"LeadingTerm"->True,"LearnQ"->False,"MonomialOrdering"->"DegreeReverseLexicographic"];
	Flatten@Table[sol[[i,2]]->sol[[i,2]]-sol[[i,1]]//Thread//Expand,{i,Length@sol}]
];


(* ::Section::Closed:: *)
(*generateSymmetryEqs2*)


(*** for each Feynman integral int[[i]] (a list), generate a simplest equation covering 
	 int[[i]] due to 'symRep', like {d[1]\[Rule]d'[3],d[2]\[Rule]d'[1]-d'[2]+d'[4]+a,...}.
***)
Options[generateSymmetryEqs2]={"FamilyDecomposition"->False};
generateSymmetryEqs2[fis_List,symRep_List,OptionsPattern[]]:=Module[
	{head,hold,repRule,maxterms,minterms,minformL,powTotal,choice,intnew},
		
	(*** collect terms independent of Denominators ***)
	head=Select[symRep[[All,2]],Head@#=!=Plus&][[1,0]];
	(*** hold terms independent of 'head' ***)
	hold[0]=0;
	hold[a_head*(b_:1)+c_:0]:=a*b+hold[c];	
	repRule=Thread[symRep[[All,1]]->(hold/@symRep[[All,2]])]/.hold->Hold;

	{maxterms,minterms,minformL}=generateSymmetryInf2[repRule,head];
		
	Table[
	intnew=If[OptionValue["FamilyDecomposition"],
		Times@@(minformL^-fis[[i,2]])
		,
		powTotal=-(fis[[i,2]]/._?Positive:>0);
		choice=findMinTerms[powTotal,maxterms,minterms][[1]];
		Times@@(minformL^choice)*Times@@(symRep[[All,1]]^(powTotal-choice-(fis[[i,2]]/._?Negative:>0)))
	];
	intnew->(intnew/.repRule)
	,{i,Length@fis}]
];


(* ::Section::Closed:: *)
(*generateSymmetryInf2*)


Options[generateSymmetryInf2]={"AllNumerators"->False};
(*** find {maxterms,minterms,minformL} of equations generated by relations 'repRule',
	 which looks like {d[1]\[Rule]d'[3],d[2]\[Rule]d'[1]-d'[2]+d'[4]+a,...}
 	maxterms: maximal terms for each element on the r.h.s. of the equation
 	minterms: minimal required terms for each element on the r.h.s. of the equation
 	minformL: terms on the l.h.s. when terms on the r.h.s. are minimized
***)
generateSymmetryInf2[repRule_List,head_,OptionsPattern[]]/;MatchQ[repRule,{Rule[_,_]..}]:=Module[
	{maxformR,singles,excl,maxterms,minterms,minformR,minformL},
	
	maxformR=repRule[[All,2]];
	
	(*** replacement rules with only one term on the right. exlude them in counting terms ***)
	singles=Reverse/@Select[repRule,Head@#[[2]]=!=Plus&]/.Rule[a_*b_head,c_]:>Rule[b,c/a];
	excl=Cases[singles[[All,1]],_head,Infinity];
	maxterms=Length/@repRule[[All,2]];
	minterms=Length@Complement[Cases[#,_head,Infinity],excl]&/@repRule[[All,2]]/.(0->1);
	
	(*** generate replacement with minimal terms on the right. Holded terms are ignored. ***)
	minformR=maxformR/.Thread[excl->0]/._Hold->0;
	minformL=repRule[[All,1]]-(maxformR-minformR/.singles)//Expand;
	Do[If[minformL[[i]]===0,minformL[[i]]=repRule[[i,1]]],{i,Length@minformL}];
	
	{maxterms,minterms,minformL}
];


(* ::Section::Closed:: *)
(*findMinTerms*)


(*** find an equation with (estimated) minimal terms after expansion.
	 The equation is generated by replacements like {d[1]\[Rule]d'[3],d[2]\[Rule]d'[1]-d'[2]+d'[4]+a,...}
	 powTotal: total powers for each element (each d[i])
 	maxterms: maximal terms for each element on the r.h.s. of the equation
 	minterms: minimal required terms for each element on the r.h.s. of the equation
***)
findMinTerms[powTotal_,maxterms_,minterms_]:=Module[
	{f,pows,costs,temp,pos},
	pows=Flatten@Outer[f,Sequence@@(Range/@(powTotal+1)-1)]/.f->List;
	costs=Table[
		temp=pows[[j]];
		(*** temp[[i]]: from 0 to powTotal[[i]], denotes the power to choose minimal terms ***)
		Product[Binomial[minterms[[i]]-1+temp[[i]],temp[[i]]]*
				Binomial[maxterms[[i]]-1+powTotal[[i]]-temp[[i]],powTotal[[i]]-temp[[i]]],{i,Length@powTotal}]+
			Product[Binomial[maxterms[[i]]-minterms[[i]]+temp[[i]],temp[[i]]],{i,Length@powTotal}]
	,{j,Length@pows}];
	(*Print[costs//Sort];*)
	pos=Position[costs,Min@costs][[1,1]];
	{List@@pows[[pos]],costs[[pos]]}
];


(* ::Section::Closed:: *)
(*findSymmetryPairs*)


(*** 
	For the given set of rules of symmetries (forming a symmetry group if identity is added), 
	find pairs of indexes. Elements corresponding to each pair are inverse to each other.
***)
findSymmetryPairs[{}]={};
findSymmetryPairs[rules_?MatrixQ]:=Module[
	{n,list,pairs,i,j,temp,tempi},
	list=Range@Length@rules;
	pairs={};
	n=Length@rules[[1]];
	While[Length@list>0,
		(*If[Length@list===1,AppendTo[pairs,{list[[1]],list[[1]]}];Break[]];*)
		temp=rules[[list[[1]]]];
		For[i=1,i<=Length@list,i++,
			tempi=rules[[list[[i]]]];
			For[j=1,j<=n,j++,
				If[temp[[j,1]]=!=Together[temp[[j,2]]/.tempi],Break[]](*change Expand to Together*)
			];
			If[j===n+1,Break[]]
		];
		If[i>Length@list,ErrorPrint["findSymmetryPairs: Incorrect input for symmetries: ",
			{rules,list}];Abort[]
		];
		AppendTo[pairs,{list[[1]],list[[i]]}];
		list=Complement[list,{list[[1]],list[[i]]}];
	];

	pairs
];


(* ::Section::Closed:: *)
(*symFullReduce*)


symFullReduce//ClearAll;
Options[symFullReduce]={"SolveQ"->True,"Solver"->SparseRowReduce};
symFullReduce[symRep0_,sec_,dots_,rank_,OptionsPattern[]]:=Module[
	{symRep,head,hold,famNo,length,pairRep,ints,eqs,fis,map,eqFun,dens,eqsLearn,sol,keys},
	
	symRep=Expand//@symRep0;
	If[Length@symRep===0||symRep==={{}},Return[{},Module]];
	head=FirstCase[symRep[[1]],"Den"[_][_],Missing[],Infinity][[0]];
	famNo=head[[1]];
	length=symRep[[1]]//Length;
	
	(*** hold terms independent of 'head' ***)
	Attributes[hold]=Listable;
	hold[0]=0;
	hold[a_->b_]:=hold[a]->hold[b];	
	hold[a_head*(b_:1)+c_:0]:=a*b+hold[c];
	
	(*** find pairs of replacements, each one is the inverse of the other one ***)
	pairRep=findSymmetryPairs@symRep;
	
	pairRep=Join[symRep[[#[[1]]]],Complement[Reverse/@symRep[[#[[2]]]],symRep[[#[[1]]]]]]&/@pairRep;
	pairRep=hold[Collect[#,_head,Together]&/@pairRep];(*add Collect[#,_head,Together]&/@ to simplify the expression*)
	
	eqs=Join@@Table[
		ints=generateSeeds[PadRight[sec,Length@pairRep[[i]]],dots,rank];
		ints=eqsWithCost[pairRep[[i]],ints]
	,{i,Length@pairRep}];
	
	eqs=Select[eqs,#[[1,1]]=!=#[[1,2]]&];
	eqs=SortBy[eqs,Last];	
	
	eqs=eqs[[All,1]]/.Rule[a_,b_]:>a-b;
	
	(*** By reducing partial equations and introducing only the most complicated FIs, 
		 reducible FIs can be identified ***)
	fis=symTopReduce[symRep,sec,dots,rank](*//CLTiming*);
	fis=fis[[All,1]];
	
	(*** By reducing all equations but introducing only the most complicated FIs, 
		 relevant equations (ordered by complexity) can be identified ***)
	dens=DeleteCases[symRep[[1,All,1]]sec,0];
	map=Association@@Thread[fis->Range[fis//Length]];
	eqFun[i_]:=Module[
		{eqsi},
		eqsi=eqs[[i]]/.Thread[dens->dens^-1]/.Thread[dens^_?Negative->0]/.Thread[dens->dens^-1]/.
				_hold->0//FIJoin[#,famNo,length]&//Expand;
		eqsi=Association@@Sort[If[Head@#===Plus,List@@#,{#}]&@eqsi/.
				x_FI*y_:1:>If[KeyExistsQ[map,x],(map[x]->y),Nothing]]/.
				Association[0]->Association[]
	];
	eqsLearn=SparseRowReduce[eqFun,Length@eqs,"MaxNumberOfEquations"->(Length@fis)](*//CLTiming*);
	
	(*** Generate relevant equations with all FIs ***)
	eqs=eqs[[eqsLearn//Keys//Sort]];
	eqs=FIJoin[eqs,famNo,length]/.hold->Identity(*//CLTiming*);

	If[OptionValue["SolveQ"]===False,Return[eqs,Module]];
	
	(*** put most complicated FIs on the leftmost ***)
	fis=Reverse@SortBy[Union@Cases[eqs,_FI,Infinity],orderingFI];
	
	(*** Solve the useful equations ***)
	If[OptionValue["Solver"]=!=RowReduce,
		eqs=linearEqs2Sparse[eqs,fis,FI];
		outt=eqs;
		sol=SparseRowReduce[eqs,Length@eqs](*//CLTiming*);
		,
		eqs=linearEqs2Sparse[eqs,fis,FI,"Form"->SparseArray];
		sol=RowReduce[eqs]//SparseArray//ArrayRules(*//CLTiming*);
		sol=Association@@(#[[All,1,1]]->Association@@Thread[#[[All,1,2]]->#[[All,2]]]&/@
				GatherBy[DeleteCases[sol,Rule[{_Blank,_},_]],#[[1,1]]&]);
	];
	
	map=Association@@Thread[Range[fis//Length]->fis];
	
	Table[keys=Keys@sol[i];
			map@keys[[1]]->map@keys[[1]]-(map/@keys) . Values@sol[i]//Expand,{i,Keys@sol}]
];


(* ::Section::Closed:: *)
(*eqsWithCost*)


(*** find an equation with (estimated) minimal terms after expansion.
	 The equation is generated by replacements like {d[1]\[Rule]d'[3],d[2]\[Rule]d'[1]-d'[2]+d'[4]+a,...}
	 powTotal: total powers for each element (each d[i])
 	maxterms: maximal terms for each element on the r.h.s. of the equation
 	minterms: minimal required terms for each element on the r.h.s. of the equation
***)
eqsWithCost[rules_List,pows_?MatrixQ]:=Module[
	{lenL,lenR,costs},
	
	lenL=Length/@rules[[All,1]];
	lenR=Length/@rules[[All,2]];
	(*** temp[[i]]: from 0 to powTotal[[i]], denotes the power to choose minimal terms ***)
	costs=Table[
		{Times@@(rules[[All,1]]^-pows[[i]])->Times@@(rules[[All,2]]^-pows[[i]]),
			Product[Binomial[lenL[[j]]-1+Abs@pows[[i,j]],Abs@pows[[i,j]]],{j,Length@pows[[i]]}]+
			Product[Binomial[lenR[[j]]-1+Abs@pows[[i,j]],Abs@pows[[i,j]]],{j,Length@pows[[i]]}]}
	,{i,Length@pows}];
	
	costs
];


(* ::Section::Closed:: *)
(*orderingFI*)


(*** definine ordering of Feynman integrals ***)
orderingFI[FI[famNo_,int_List]]:=Module[
	{n,dots,rank,sec,rs,r},
	n=Length@int;
	dots=Sum[If[int[[i]]>1,int[[i]]-1,0],{i,n}];
	rank=-Total@Select[int,#<0&];
	sec=Table[If[int[[i]]>0,1,0],{i,n}];
	{dots,rank,Plus@@sec,sec}
];


(* ::Section::Closed:: *)
(*generateSeeds*)


(*** generate all lists in sector 'sector' with fixed 'dots' and 'rank' ***)
generateSeeds[sector_List,dots_?IntegerQ,rank_?IntegerQ]:=Module[
	{frobeniusSolve,dens,nums,denlist,numlist,int,Fun},
	
	frobeniusSolve[{},0]:={};
	frobeniusSolve[a_,b_]:=FrobeniusSolve[a,b];
	
	dens=Position[sector,1]//Flatten;
	nums=Position[sector,0]//Flatten;
	denlist=frobeniusSolve[ConstantArray[1,Length@dens],dots]+1;
	numlist=-frobeniusSolve[ConstantArray[1,Length@nums],rank];
	int=sector;
	
	If[Length@dens===0,Return[numlist,Module]];
	If[Length@nums===0,Return[denlist,Module]];
	
	Join@@Table[
		int[[dens]]=denlist[[i]];
		Table[
			int[[nums]]=numlist[[j]];
			int
		,{j,Length@numlist}
		]
	,{i,Length@denlist}]
];


(* ::Section::Closed:: *)
(*End*)


End[];
