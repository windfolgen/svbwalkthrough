(* ::Package:: *)

If[FindFile[feynarts]===$Failed,
	Print["Cannot find FeynArts. Try SetOptions[CreateFeynArtsAmp,\"FeynArtsFileName\"->\"feynartspath\"]"<>
			" to provide the full path of FeynArts package."];
	Quit[]
];
Get@feynarts;


(*** User defined options and configurations ***)
config=Get[FileNameJoin[{dir,"config.wl"}]];


ampDir=dir//DirectoryName;
file=ampDir//FileBaseName;
config=Delete[config,"FileName"];


config=config/.x_String:>ToExpression@x;


looporder=config@"LoopOrder";
process =config@"Process";


(*** Default options ***)
SetOptions[CreateTopologies,Adjacencies->{3,4}, StartingTopologies->All, CTOrder->0,
	ExcludeTopologies->{Tadpoles,TadpoleCTs,WFCorrections,WFCorrectionCTs}];
	
SetOptions[InsertFields,Model->"SMQCD",GenericModel->"Lorentz",InsertionLevel->{Particles}];

SetOptions[Paint,PaintLevel->{Particles},ColumnsXRows->3,AutoEdit->True,SheetHeader->Automatic,
	Numbering->Full,FieldNumbers->True,DisplayFunction:>(Export[ToFileName[dir, "diagrams.ps"], #]&)];

SetOptions[CreateFeynAmp,AmplitudeLevel->{Particles}, GaugeRules->_GaugeXi->1,
	PreFactor->1,Truncated->False,MomentumConservation->True,GraphInfoFunction->(1&)];


options=config@"Options";
Do[SetOptions[ToExpression@fun,Sequence@@Flatten@{options[fun]}],{fun,Keys@options}];


(*** create topologies ***)
createTopologies[order_,rule_]:=Which[
	order>=0,CreateTopologies[order, rule],
	order<0,CreateCTTopologies[-order, rule]
];

tops = createTopologies[looporder, Length@process[[1]] -> Length@process[[2]]];


ins = InsertFields[tops, process];
Paint[ins];


amp = CreateFeynAmp[ins];
Put[amp,FileNameJoin[{ampDir,file<>"-amplitude.FAs"}]]


Quit[];
