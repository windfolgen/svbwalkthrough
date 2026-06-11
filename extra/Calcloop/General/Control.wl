(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


CalcLoopOptions::usage="CalcLoopOptions is an association containing current options.
The value of \"RunProcess\" is a function that is used to run a file in a newly launched Mathematica kernel.
The value of \"FeynArtsDirectory\" is the directory (either the full path or the relative path \
which can be found by Get) containing the file \"FeynArts.m\".
The value of \"AMFlowDirectory\" is the directory (either the full path or the relative path \
which can be found by Get) containing the file \"AMFlow.m\".";

CalcLoopSymbol::usage="CalcLoopSymbol[symb_String] denotes a symbol 'symb' defined in CalcLoop.";

$CLVerbose::usage="$CLVerbose is a parameter to control the depth of messages to be printed.";

WriteMessage::usage="WriteMessage[exp__] prints 'exp' as a string.";

CLTiming::usage="CLTiming[exp] evaluates 'exp' and prints the wall-time used.";

RemoveLocalSymbols::usage="RemoveLocalSymbols[pkg] removes all local symbols in the context 'pkg'.";

$CLDefinedForm={TraditionalForm};


Begin["`Private`"];

JString::usage="JString[exp__] generats a string based on input 'exp'.";

TDBox::usage="TDBox[x] is MakeBoxes[x,TraditionalForm].
TDBox[x_,y__] is RowBox@(TDBox/@{x,y}).";

$GlobalSpace::"usage"="$GlobalSpace is a parameter to control the current indentation.";
$GlobalSpace=0;

$GlobalSpaceN::"usage"="$GlobalSpaceN is a parameter to control the encrease of indentation at each step.";
$GlobalSpaceN=6;

CLMonitor::"usage"="CLMonitor[exp,i] is the same as Monitor but it is active only if $CLVerbose>0&&$CLVerbose\[GreaterEqual]($GlobalSpace/$GlobalSpaceN) (when CLTiming is active).";

DebugPrint::"usage"="DebugPrint[exp] prints 'exp' if OptionValue[\"DebugQ\"] is True. Or else, it does nothing.";

ErrorPrint::"usage"="ErrorPrint[exp] prints 'exp' and then pause OptionValue[Pause] seconds.";

End[];


Begin["`Control`"];


CalcLoopSymbol/:MakeBoxes[CalcLoopSymbol[x_],f_]/;MemberQ[$CLDefinedForm,f]:=TDBox[x];


(* ::Section:: *)
(*CalcLoopOptions*)


CalcLoopOptions["RunProcess"]=(RunProcess[{FileNameJoin[{$LaunchDirectory,"wolframscript"}],
				"-noprompt","-noicon","-file",#}]&);


(* ::Section::Closed:: *)
(*JString*)


JString[a_Symbol|a_Integer|a_Rational|a_Real|a_String|a_Times|a_Plus]:=
	StringReplace[ToString@a,"-"->"m"];
JString[a_Symbol|a_String,b_Symbol|b_String|b_Integer]:=
	StringReplace[ToString[a]<>ToString[b],"-"->"m"];
JString[a_,b_,c__]:=JString[JString[a,b],c];
JString[x___,a_[b___],y___]:=JString[x,a,b,y];


(* ::Section::Closed:: *)
(*TDBox*)


TDBox[x_]:=MakeBoxes[x,TraditionalForm];
TDBox[x_,y__]:=RowBox@(TDBox/@{x,y});


(* ::Section::Closed:: *)
(*WriteMessage*)


Options[WriteMessage]={"Length"->40,"Spacings":>$GlobalSpace};
WriteMessage[exps___,OptionsPattern[]]:=If[$CLVerbose>0&&$CLVerbose>=($GlobalSpace/$GlobalSpaceN),
	WriteString["stdout",
		StringJoin@Table[" ", {OptionValue["Spacings"]}],
		If[Head@#===String,#,ToString[#,InputForm]]&/@({exps})//StringJoin,"\n"
	]
];


(* ::Section::Closed:: *)
(*CLTiming*)


Attributes[CLTiming]={HoldAll};
Options[CLTiming]={"Print"->True};
CLTiming[exp_,opt:OptionsPattern[]]:=Module[
	{name},
	name=Hold[exp][[1,0]]//ToString;
	CLTiming[exp,name//Evaluate,opt]
];
CLTiming[exp_,name_,OptionsPattern[]]:=Module[
	{time,res,temp=$GlobalSpace,DateDifference2},
	DateDifference2[x___]:=DateDifference[x][[1]];
	
	If[OptionValue["Print"]===False||$CLVerbose<=($GlobalSpace/$GlobalSpaceN),
		$GlobalSpace+=$GlobalSpaceN;
		res=exp;
		$GlobalSpace-=$GlobalSpaceN;
		Return[res]
	];
	
	Block[
		{$GlobalSpace=temp},
		WriteMessage["Begin "<>name<>"  ..."];
		$GlobalSpace+=$GlobalSpaceN;
		time=DateList[];
		res=exp;
		$GlobalSpace-=$GlobalSpaceN;
		
		WriteMessage["      "<>name<>" use time : ",
			(StringInsert[#,".",-4]&)@(If[StringLength@#<4,StringPadLeft[#,4,"0"],#]&)@
			ToString@Round[DateDifference2[time,DateList[]]*24*3600*10^3],"s,   LeafCount = ",
			Which[StringLength@#<=3,#,
			StringLength@#<=6,StringPart[#,1;;-4]<>"."<>StringPart[#,-3;;-1]<>"K",
			True,StringPart[#,1;;-7]<>"."<>StringPart[#,-6;;-4]<>"M"
			]&@ToString@LeafCount@res
		];
	];
	
	Return[res];
];


(* ::Section::Closed:: *)
(*CLMonitor*)


Attributes[CLMonitor]={HoldAll};
CLMonitor[exp_,i_]:=If[$CLVerbose>0&&$CLVerbose>=($GlobalSpace/$GlobalSpaceN),Monitor[exp,i],exp];


(* ::Section::Closed:: *)
(*DebugPrint*)


Options[DebugPrint]={"DebugQ"->False};
DebugPrint[x_,OptionsPattern[]]:=If[OptionValue["DebugQ"]&&$CLVerbose>0&&$CLVerbose>=($GlobalSpace/$GlobalSpaceN),Print[x];Pause[0.1]];


(* ::Section::Closed:: *)
(*ErrorPrint*)


Options[ErrorPrint]={Pause->0.1};
ErrorPrint[exp___,OptionsPattern[]]:=(Print[exp//Short];Pause[OptionValue[Pause]]);


(* ::Section::Closed:: *)
(*RemoveLocalSymbols*)


RemoveLocalSymbols[pkg_]:=(Remove@@Evaluate@Names[pkg~~"`"~~__~~"$"~~DigitCharacter..];ClearSystemCache[];)


(* ::Section::Closed:: *)
(*End*)


End[];
