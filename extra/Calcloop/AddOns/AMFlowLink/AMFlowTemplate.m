(* ::Package:: *)

(*load the package*)
current = `WorkingDirectory`;
amflow=`AMFlowLocation`;
If[FindFile[amflow]===$Failed,Print["Cannot find AMFlow."];Quit[]];
Get@amflow;


SetReductionOptions["IBPReducer" -> `IBPReducer`,"BlackBoxRank" -> `BlackBoxRank`,
	"BlackBoxDot" -> `BlackBoxDot`];
SetAMFOptions["AMFMode" -> `AMFMode`];


(*if there is no preferred master integrals, preferred={}*)
preferred = `PreferredMIs`;
(*psPoint is a given regular phasespace point, which serves as the boundary of s-DEs*)
psPoint=`PhaseSpacePoint`;
precision=`PrecisionGoal`//N//Round;
epsorder=`EpsOrder`//N//Round;
{epslist, workingpre, xorder} = {`EpsList`,`WorkingPrecision`,`XOrder`};


(*Generate epslist, working precision and xorder*)
numOfeps=2*epsorder+1;
epsmin=Min[10^(-2*precision/numOfeps),10^-3]//N;
epsmin=1/Round[1/epsmin];
If[epslist===Automatic,
	epslist=Table[3^i,{i,0,1,1/(numOfeps-1)}]*epsmin;
	epslist=Round[#,10^(Round[Log[10,#]]-4)]&/@epslist
];
If[workingpre===Automatic,workingpre=10*precision];
If[xorder===Automatic,xorder=3*precision*10/3//N//Round];


(*set configuration*)
AMFlowInfo["NThread"] = `NThread`;
AMFlowInfo["Numeric"] = `Numeric`;


(*read inputdata*)
info=Association@@Get[FileNameJoin[{current, "amplitudeData"}]];

(*non-symbol momenta cannot be dealt by some reducers*)
repMom={info@"IntegratedMomenta",info@"FixedMomenta"}//Flatten;
repMom=Thread[repMom->Table["autop"<>ToString@i//Symbol,{i,Length@repMom}]];
repMom//Print;
(*non-symbol variables cannot be dealt by some reducers*)
repSP={psPoint[[All,1]],info["SPRules"][[All,2]]}/.repMom//Variables;
repSP=Thread[repSP->Table["autos"<>ToString@i//Symbol,{i,Length@repSP}]];
repSP//Print;

{info,psPoint,AMFlowInfo["Numeric"]}={info,psPoint,AMFlowInfo["Numeric"]}/.
	Dispatch@repMom/.Dispatch@repSP;


AMFlowInfo["Family"] = "fam"<>ToString@info@"Family"//Symbol;
AMFlowInfo["Loop"] = info@"IntegratedMomenta";
AMFlowInfo["Prescription"] = info@"Prescription";
AMFlowInfo["Leg"] = info@"FixedMomenta";
AMFlowInfo["Conservation"] = info@"Conservation";
AMFlowInfo["Replacement"] = info@"SPRules";
AMFlowInfo["Propagator"] = info@"Propagators";
AMFlowInfo["Cut"] = info@"Cut";
Definition[AMFlowInfo]//Print;


(*Translate integrals in LoopCalc to AMFlow*)
repFI=FI[n_,nus_]:>j["fam"<>ToString@n//Symbol,Sequence@@nus];


integrals = info@"Integrals"/.repFI;
coefficients = info@"Coefficients";


(*replace back*)
repMom=Reverse/@repMom;
repSP=Reverse/@repSP;
repFI=j[fam_,nus___]:>FI[ToExpression@StringDrop[ToString@fam,3],{nus}];
replaceBack[exp_]:=exp/.Dispatch@repSP/.Dispatch@repMom/.repFI;


(*reduce target integrals to preferred master integrals*)
{masters, rules} = If[AMFlowInfo["Loop"]==={}&&Length@integrals===1,
	{integrals,{integrals[[1]]->integrals[[1]]}}
	,
	BlackBoxReduce[integrals, preferred]
];
reduction = Thread[Keys[rules] -> Values[rules] . masters];
Put[reduction//replaceBack, FileNameJoin[{current, "ReductionTable"}]];
Put[coefficients . (integrals/.reduction)/.AMFlowInfo["Numeric"]//replaceBack,
	FileNameJoin[{current, "AnalyticalResult"}]];


(*construct differential equations for master integrals*)
If[Length@psPoint>0,
	{mastersde, vars, diffeq} = BlackBoxDiffeq[masters, psPoint[[All,1]]];
	Put[{mastersde,vars, diffeq}//replaceBack, FileNameJoin[{current, "DifferentialEqs"}]];
];


(*perform auxiliary mass flow to obtain boundary conditions*)
SetAMFOptions["WorkingPre" -> workingpre, "XOrder" -> xorder];
AMFlowInfo["Numeric"] = Join[AMFlowInfo["Numeric"],psPoint];
sol = If[AMFlowInfo["Loop"]==={}&&Length@masters===1,
	{masters[[1]]->ConstantArray[1,Length@epslist]}
	,
	BlackBoxAMFlow[masters, epslist]
];
sol=sol//replaceBack;
sol=Association@@Table[epslist[[i]]->Association@@Thread[Keys@sol->sol[[All,2,i]]],
	{i,Length@epslist}];
Put[{replaceBack@psPoint,sol}, FileNameJoin[{current, "BoundaryValue"}]];


(*multiply integrals with coefficients*)
{coefficients,integrals,reduction}={coefficients,integrals,reduction}/.
	AMFlowInfo["Numeric"]//replaceBack;
res=Association@@Table[
	reductioni=reduction[[All,1]]->(reduction[[All,2]]/.Dispatch@Normal@sol[[i]]);
	integralsi=integrals/.Dispatch@Thread@reductioni;
	epslist[[i]]->(integralsi . coefficients/.eps->epslist[[i]]),
	{i,Length@epslist}
];
Put[res, FileNameJoin[{current, "NumericalResult"}]];


Quit[];
