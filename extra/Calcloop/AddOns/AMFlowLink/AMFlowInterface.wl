(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


AMFlowCalculateFI


Begin["`Private`"];
End[];


Begin["`AMFlow`"];


(* ::Section:: *)
(*AMFlowCalculateFI*)


Options[AMFlowCalculateFI]={"ReadSaved"->False,"Parallelize"->False,"MonitorQ"->True,
	"PrecisionGoal"->30,"EpsOrder"->3,"NThread"->4,"IBPReducer"->"Blade","Numeric"->{},
	"BlackBoxRank"->3,"BlackBoxDot"->1,"AMFMode"->{"Prescription", "Mass", "Propagator"},
	"PreferredMIs"->{},"EpsList"->Automatic,"PhaseSpacePoint"->{},"WorkingPrecision"->Automatic,
	"XOrder"->Automatic,"FitQ"->True,"TemplateFileName":>FileNameJoin[{
	CalcLoopOptions["CalcLoopLocation"]//DirectoryName,"AddOns","AMFlowLink","AMFlowTemplate.m"}]};


AMFlowCalculateFI[dir_String,families_String,opts:OptionsPattern[]]:=Module[
	{i,diri,data,toString,toString2,monitor,timing,paraQ,table,files,
		template,rule,amffile,log,logfile,sum,date,eps},
	
	toString:=ToString[#,InputForm]&;
	
	toString2[exp_]:=StringReplace[ToString[exp,InputForm],"\""->""];
	
	(*** Return if it has been already calculated ***)
	If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{dir,"TotalNumericalResult"}],
		Return[FileNameJoin[{dir,"TotalNumericalResult"}]//Get,Module]
	];
	If[FileNames[dir]==={},CreateDirectory@dir];
	
	paraQ=OptionValue["Parallelize"];
	(*Option of parallization*)
	table=If[paraQ===True,
		SetOptions[ParallelTable,DistributedContexts->All];ParallelTable,
		Table
	];

	(*files=Select[FileNames["*",dir],DirectoryQ];*)
	(*files=FileNameJoin[{dir,#}]&/@Get@FileNameJoin[{dir,"Families"}];*)
	files=Get[families];
	
	WriteMessage["Total number of families = ",Length@files, "."];
	
	template=ReadString["TemplateFileName"//OptionValue];
	
	Table[
		diri=FileNameJoin[{dir,toString@i}];
		If[FileNames[diri]==={},CreateDirectory@diri];
		
		data=FileNameJoin[{diri,"amplitudeData"}];
		If[FileExistsQ@data,DeleteFile@data];
		CopyFile[files[[i]],data];
		
		If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{diri,"NumericalResult"}],
		Nothing
		,
	
		rule=<|
			"WorkingDirectory"->toString@diri,
			"AMFlowLocation"->toString@CalcLoopOptions["AMFlowLocation"],
			"IBPReducer"->toString@OptionValue@"IBPReducer",
			"BlackBoxRank"->toString@OptionValue@"BlackBoxRank",
			"BlackBoxDot"->toString@OptionValue@"BlackBoxDot",
			"AMFMode"->toString@OptionValue@"AMFMode",
			"PreferredMIs"->toString@OptionValue@"PreferredMIs",
			"PhaseSpacePoint"->toString@OptionValue@"PhaseSpacePoint",
			"PrecisionGoal"->toString@OptionValue["PrecisionGoal"],
			"EpsOrder"->toString@OptionValue["EpsOrder"],
			"EpsList"->toString@OptionValue@"EpsList",
			"WorkingPrecision"->toString@OptionValue@"WorkingPrecision",
			"XOrder"->toString@OptionValue@"XOrder",
			"NThread"->toString@OptionValue@"NThread",
			"Numeric"->toString@OptionValue@"Numeric"
		|>;
		amffile=FileNameJoin[{diri,"amfRun.wl"}];
		
		FileTemplateApply[template,rule,amffile];
	],{i,Length@files}];
	
	date=DateList[];
	table[
		diri=FileNameJoin[{dir,toString@i}];
		If[OptionValue@"ReadSaved"===True&&FileExistsQ@FileNameJoin[{diri,"NumericalResult"}],
			FileNameJoin[{diri,"NumericalResult"}]//Get
			,
			amffile=FileNameJoin[{diri,"amfRun.wl"}];		
			log=If[OptionValue["MonitorQ"]===True&&OptionValue["Parallelize"]===False,
					CLTiming[CalcLoopOptions["RunProcess"][amffile],"RunProcess"],
					CalcLoopOptions["RunProcess"][amffile]
			];
			If[log@"StandardOutput"==="Cannot find AMFlow.\n",
				Print["Fatal error: Cannot find AMFlow!"];
				Abort[]
			];
			
			log=StringRiffle[If[Head@#=!=String,ToString@#,#]&/@Values[log],
					"\n********************************************\n"];
			logfile=FileNameJoin[{diri,"AMFlow.log"}];
			If[FileExistsQ[logfile],DeleteFile[logfile]];
			WriteString[logfile,log];
			Close[logfile];
		];
		Print["Family #",i," finished in ",DateDifference[date,DateList[],"Second"],"."];
		,{i,1,Length@files}
	]//CLTiming;
	
	sum=Plus@@Table[
			FileNameJoin[{dir,toString@i,"AnalyticalResult"}]//Get
		,{i,Length@files}
	];
	Put[sum,FileNameJoin[{dir,"TotalAnalyticalResult"}]];
	
	sum=Plus@@Table[
			FileNameJoin[{dir,toString@i,"NumericalResult"}]//Get
		,{i,Length@files}
	];
	Put[sum,FileNameJoin[{dir,"TotalNumericalResult"}]];
	
	If[OptionValue["FitQ"],
		PowerSeriesFit[sum,eps]/.eps->CalcLoopSymbol["\[Epsilon]"],
		sum
	]
	
];


(* ::Section::Closed:: *)
(*End*)


End[];
