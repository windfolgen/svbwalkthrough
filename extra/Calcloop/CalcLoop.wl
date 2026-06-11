(* ::Package:: *)

(*
Package name: CalcLoop
Copyright: 2023 Yan-Qing Ma
Description: tools to calculate Feynman amplitudes with any number of loops
*)

(*
If you find any bugs, or want to make suggestions, 
please contact Yan-Qing Ma at yqma@pku.edu.cn. 
*)


If[MemberQ[Contexts[],"CalcLoop`"],
	Unprotect["CalcLoop`*"];
	Remove["CalcLoop`*`*"];
	(*leaving Names["CalcLoop`*"] unchanged*)
	"ClearAll["~~#~~"]"&/@Names["CalcLoop`*"]//ToExpression; 
];
WriteString["stdout", "CalcLoop: a tool for automated multiloop calculation in quantum field theory.
Version 2023/05/31.\n"];
BeginPackage["CalcLoop`"];
$CalcLoopDirectory;
CLmonitor;


(*All files to be loaded*)
filesOfCalcLoop=FileNames["*.wl",FileNameJoin[{$InputFileName//DirectoryName,#}],Infinity]&/@
	{"General","Algebra","FeynmanAmplitude","LoopIntegralReduction","AddOns"}//Flatten;
	
(*First time of load: figure out global symbols and `Private` symbols*)
Get/@filesOfCalcLoop;

(*Claim global symbols and `Private` symbols, but clear their definitions*)
"ClearAll["~~#~~"]"&/@Select[Names["CalcLoop`*"],
	!MemberQ[{"filesOfCalcLoop"},#]&]//ToExpression;
"ClearAll["~~#~~"]"&/@Names["CalcLoop`Private`*"]//ToExpression;
(*Remove symbols in other Contexts*)
Remove@Evaluate[#<>"*"]&/@Complement[Contexts["CalcLoop`*"],
	{"CalcLoop`","CalcLoop`Private`"}];

(*Allow `Private` symbols used in any sub-constexts*)	
AppendTo[$ContextPath,"CalcLoop`Private`"];

(*load files*)
CalcLoopOptions=Association[];
CalcLoopOptions["CalcLoopLocation"]=$InputFileName;
Get/@filesOfCalcLoop;

Remove[filesOfCalcLoop];


EndPackage[];
Protect["CalcLoop`*"];
Unprotect[$CLVerbose,SUNN,$CLDefinedForm,Pair,$MomentumRelation,CLmonitor,$D,
	CalcLoopSymbol,CalcLoopOptions,FeynArtsParticles];
$CLVerbose=3;
WriteString["stdout","Number of defined symbols="<>
	ToString@Length@Names["CalcLoop`*"]<>
	". Please see ?CalcLoop`* for help.\n"
];

If[Length@FileNames["wolframscript*",$LaunchDirectory]=!=1,
	WriteString["stdout", "***Warning:*** wolframscript not found in the directory $LaunchDirectory! \
Some third-party packages may not work. See ?CalcLoopOptions for more details.\n"]
];
