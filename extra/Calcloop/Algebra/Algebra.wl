(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


(* ::Subsection::Closed:: *)
(*Global symbols*)


RationalMod::"usage"="RationalMod[exp_,p_] applies to a rational express 'exp' \
and replaces all rational numbers by their images in the finite field of \
a nonzero integer 'p'.";


Separate::nonpoly="Failed to get coefficients in Separate. Please check input variables.";
Separate::usage="Separate[exp_,cases_] = {coes, bases}, where 'bases' is a list \
of monomials of variables, and 'coes' is the list of corresponding coefficients. \
Variables are found by applying Cases. \
E.g., if variables are x1, x2, y1, y2 and all expressions with Head=t, \
one can define 'cases'={x1,x2,y1,y2,_t}.
If OptionValue[\"FreeForm\"] is True, variables are selected from Variables['exp'] \
by demanding that they are not free of 'cases'. E.g., if 'cases'={x,_t}, variables \
are t[___] and all terms in Variables['exp'] that depend on x.
Separate has Listable attribute for the first argument.";


SimplifyList::usage="SimplifyList[exp_,cases_] expands 'exp' as \
summation of monomials of variables, and each monomial is simplified by \
OptionValue[\"Factoring\"]. E.g., if variables are x1, x2, y1, y2 and all \
expressions with Head=t, one can define 'cases'={x1,x2,y1,y2,_t}.
If OptionValue[\"FreeForm\"] is True, variables are selected from Variables['exp'] \
by demanding that they are not free of 'cases'. E.g., if 'cases'={x,_t}, variables \
are t[___] and all terms in Variables['exp'] that depend on x.
SimplifyList has Listable attribute for the first argument.";


PowerSeriesFit::usage="PowerSeriesFit[data,eps] is similar to Fit, but mainly with the following \
two differences. 1) It only applies for truncated power series functions of 'eps', where \
'eps' is assumed to be a small number, and thus bases are suppressed. \
2) For given values of 'eps', the 'data' can be any function of other variables.
'data' can be either an association, with Keys being samplings of 'eps', or a matrix.
If the option \"LeadingPower\" is Automatic, the leading power of 'eps' will be \
determined automatically.
Values of \"MinimalTerms\" and \"MaximalTerms\" can be integers or Max, determining the number of \
terms in the fit. Here Max means as many as possible terms.
If \"EstimateAccuracy\" is True, estimated accuracy of each fitted value will be shown in the \
final result.";


MMAGroebnerBasis::usage="It fixes a bug of GroebnerBasis.";


GeneralizedApart::usage="GeneralizedApart[exp_,vars_List] performs partial fraction for 'exp' \
with variables 'vars'.
GeneralizedApart[exp_]=GeneralizedApart[exp,Variables[exp]//Sort].
{fun,explicit}=OptionValue[\"DenominatorFunction\"]. If 'fun' is not Automatic, \
it denotes the function name of denominator (such as GPD) and 'explicit' is a \
function to translate 'fun' to polynomials.
OptionValue[\"Factoring\"] (<- Automatic) is the option how to simplify the final expression.
OptionValue[\"CancelQ\"] (<-False) is the option for whether trying to cancel each denominator.";


PolynomialRowReduce::usage="PolynomialRowReduce[eqs_?MatrixQ,zs_List,OptionsPattern[]] \
is similar to RowReduce, but only linear combinations of 'lines' with \
constant (independent of 'zs') coefficients are allowed. 'lines' must be \
combinations of polynomials of 'zs'. The reduction process terminates \
when all lines are minimized. Monomial ordering is defined by BlockdpMatrix of 'zs', \
with OptionValue[\"PositionOverTerm\"] (default value is False) defining \
the relative importance of positions and terms. Coefficients of all leading terms \
are normalized to 1.
PolynomialRowReduce[eqs_,opt:OptionsPattern[]]:=\
PolynomialRowReduce[eqs,Variables[eqs]//Sort,opt].
If p=OptionValue[\"Modulus\"] is nonzero, final results will be given in \
arithmetic modulo of 'p'.
SparseRowReduce (RowReduce) is used for numerical reduction if \
OptionValue[\"Sparse\"] is True (False).
For SparseRowReduce, OptionValue[\"Blocks\"] (default value is 1) will be \
used to divide the 'lines' to many groups (see SparseRowReduce for more details). \
In each group, once a line is linear dependent on previous lines, all rest lines \
in the same group will be ignored.
If \"LeadingTerm\" is True, each line is expressed as {line, leadingterm}.";


FindStablePoints::usage="FindStablePoints[poly_,vars_] calculates stable points \
of the polynomial 'poly' with respect to variables 'vars'. Final result is a \
list of solutions. Each solution is in the form {sp,{b0,b1,b2,...},vars}, \
where 'sp' is the stable point, and '{b0,b1,b2,...}' are obtained by \
expanding the polynomial 'poly' near 'sp' by changing variables vars\[Rule]sp+x*vars \
with an infinitesimal quantity 'x'.
OptionValue[WorkingPrecision] controls the precision of solutions. \
If it is set to Infinity, it will try to fit solutions using rational numbers.";


(* ::Subsection::Closed:: *)
(*Private symbols*)


Begin["`Private`"];


BlockdpMatrix::usage="BlockdpMatrix[{n1,n2,...}] returns a weighting matrix \
for n1+n2+... variables. The block ordering (>) of variables is assumed, \
and DegreeReverseLexicographic is used within each block.
BlockdpMatrix[n] is replaced by BlockdpMatrix[{n}].
BlockdpMatrix[varlist_List] is replaced by BlockdpMatrix[{n1,n2,...}] with \
corresponding number of variables.";


SparseRowReduce::usage="SparseRowReduce[eqs_List,OptionsPattern[]] does \
row reduce of equations 'eqs'. Each equation is expressed in a sparse form: \
{{pos_1, value_1},...,{pos_n, value_n}}, where pos_i's are nonzero positions \
of the row and value_i's are corresponding values. If 'eqs' are in normal \
dense form (each equation is a list, but not a matrix), \
they will be changed to sparse form automatically.
OptionValue[\"Blocks\"] looks like {n1,n2,n3,...} (If it is a single number n, \
it will be replaced by {n,n,...}. If the summation of 'ni' is smaller than \
Length@'eqs', certain number of 1 will be appended). It is used to divide \
the 'eqs' to many groups, which respectively have n1, n2, ... lines. In each \
group, once a line is linearly dependent on previous lines, all rest lines \
in the same group will be ignored. 
If p=OptionValue[\"Modulus\"] is nonzero, final result in arithmetic modulo \
of 'p' will be given.
SparseRowReduce is useful when the system can be basically solved by the \
algorithm with: O(N^2)<= complexity < O(N^3).";


MonomialExtension::usage="MonomialExtension[n_,varList_,monoList_,OptionsPattern[]]. \
If 'n' is an integer, it returns a list of monomials of 'varList' with degree <= 'n'. \
Other wise if 'n' is a monomial (or a list of monomials), it returns 'n'. In any case, \
if a monomial can be divided by any one in 'monoList', the monomial will be Framed.";


PolynomialAnsatz::usage="PolynomialAnsatz[vars_List,dgr,cname] returns a polynomial \
of Flatten['vars'] with degree='dgr'. The head of coefficient of each monomial is 'cname'.
OptionValue[\"MonomialBasis\"] is a list of monomials, which forms the allowed \
polynomial space.
OptionValue[\"DegreeBound\"] is a list of terms like: \
{{n1,...,nk}->max,{m1,...,ml}->{dlist}}, which removes monomials whose degree \
of Flatten@vars[[{n1,...,nk}]] is larger than 'max' or is not in the list {'dlist'}.
OptionValue[\"IndependentVariables\"]={indvars,pows} or {indvars} is a list \
of external variables as while as their degrees (nonnegative). If 'pows' is empty, \
it is replaced by {0,...,0}.";


VecMul::usage="VecMul[v1_List,v2_List] calculates the multiplication of two polynomials \
c0+c1*\[Delta]+...+cn*\[Delta]^n and d0+d1*\[Delta]+...+dm*\[Delta]^m, denoted by 'v1'={c0,c1,...,cn} \
'v2'={d0,d1,...,dm}, respectively. Here, n>=m and \[Delta] is an infinitesimal quantity. \
Final result is a list with length n. That is, higher-order terms in \[Delta] are ignored.
OptionValue[\"Simplify\"] is used to simplify intermediate expresssions.";


VecDiv::usage="VecDiv[v1_List,v2_List] calculates the quotient of polynomial \
c0+c1*\[Delta]+...+cn*\[Delta]^n over d0+d1*\[Delta]+...+dm*\[Delta]^m, denoted by 'v1'={c0,c1,...,cn} \
'v2'={d0,d1,...,dm}, respectively. Here, n>=m, d0=!=0 and \[Delta] is an infinitesimal quantity. \
Final result is a list with length n. That is, higher-order terms in \[Delta] are ignored.
OptionValue[\"Simplify\"] is used to simplify intermediate expresssions.";


SymmetricDecomposition::usage="SymmetricDecomposition[Mat]={mat,trans,order} \
decomposes a symmetric matrix 'Mat' into a diagonal matrix 'mat' together the \
transformation matrix 'trans', satisfying 'Mat'=Transpose['trans'].'mat'.'trans'. \
Here, 'order' looks like {{i1},{i2,i3},{i4},...}, \
denoting the order to blockly diagonalize the matrix.
OptionValue[\"Preference\"] is a list of numbers (can be {}), denoting the \
prefered order of block diagonalization.
If OptionValue[\"MinBlock\"] is True, blocks will be chosen as small as possible.
If input are floating numbers, OptionValue[\"WorkingPrecision\"] controls the precision.";


End[];


Begin["`Algebra`"];


(* ::Section::Closed:: *)
(*RationalMod*)


Options[RationalMod]={};


RationalMod[exp_,p_]/;p===0||!IntegerQ[p]:=exp;


RationalMod[exp_,p_]:=Switch[Head@exp,
	Plus|Times|List,
		Return[RationalMod[#,p]&/@exp],
	Integer,
		Return[Mod[exp,p]],
	Rational,
		Return[Mod[Numerator[exp]*ModularInverse[Denominator[exp],p],p]],
	Power,
		Return[RationalMod[exp[[1]],p]^exp[[2]]],
	_,(*Unknow head*)
		Return[exp]
];


(* ::Section::Closed:: *)
(*Separate*)


Options[Separate]={"FreeForm"->False};


Separate[exp_,cases_,opt:OptionsPattern[]]:=Separate0[exp,"Cases"->cases,opt];


Attributes[Separate0]={Listable};
Options[Separate0]={"FreeForm"->False,"Cases"->{}};


Separate0[exp_,opt:OptionsPattern[]]:=Module[
	{cases,vars,vars10,vars1,vars2,nfreeQ,temp,coe,multi,res},
	
	If[exp===0,{{},{}}//Return];
	cases=Flatten@{OptionValue["Cases"]};
	
	(*Explicit variables*)
	vars10=Select[cases,FreeQ[#,Blank|BlankSequence|BlankNullSequence]&];
	(*If "FreeForm" is True, find out all depending variables*)
	vars1=If[OptionValue["FreeForm"],
		nfreeQ[var_]:=!And@@(FreeQ[var,#]&/@vars10);
		vars1=Select[Variables[{exp}],nfreeQ],
		vars10
	];
	
	(*Variables with given cases*)
	vars2=Select[cases,!FreeQ[#,Blank|BlankSequence|BlankNullSequence]&];
	If[vars2=!={},
		vars2=Cases[{exp}(*{} to fix the bug when 'exp' is a single variable*),
		Alternatives@@vars2,Infinity]//Union
	];
	
	(*All variables*)
	vars=vars1~Join~vars2;
	
	If[Length[vars]===0,Return[{{exp},{1}}]];
	
	(*Coefficients*)
	coe=CoefficientArrays[exp,vars];
	
	(*Return if failed to get coefficients*)
	If[Head[coe]===CoefficientArrays,
		Message[Separate::nonpoly];
		Return[{{exp},{1}}]
	];
	
	(*Present results in the form: {coe, vars} *)
	multi[{v__}]:=Times@@(vars[[#]]&/@{v});
	res=(ArrayRules/@coe[[2;;-1]])[[All,1;;-2]]/.(x_->y_):>{y,multi[x]};
	
	(*Add constant term*)
	If[Length[coe]>0&&coe[[1]]=!=0,res=Prepend[res,{{coe[[1]],1}}]];
	
	res=Flatten[res,1];
	res=SortBy[res,Last];
	res={res[[All,1]],res[[All,2]]};
	
	res
];


(* ::Section::Closed:: *)
(*SimplifyList*)


Options[SimplifyList]={"Factoring"->Factor,"FreeForm"->False};


SimplifyList[exp_,cases_,opt:OptionsPattern[]]:=
	SimplifyList0[exp,"Cases"->cases,opt];


Attributes[SimplifyList0]={Listable};
Options[SimplifyList0]={"Factoring"->Factor,"FreeForm"->False,"Cases"->{}};


SimplifyList0[exp_,opt:OptionsPattern[]]:=Module[
	{cases,factor,sep},
	
	cases=OptionValue["Cases"];
	factor=OptionValue["Factoring"];
	
	sep=Separate[exp,cases,"FreeForm"->OptionValue["FreeForm"]];
	sep[[1]]=sep[[1]]//factor;
	Dot@@sep
];


(* ::Section::Closed:: *)
(*PowerSeriesFit*)


Options[PowerSeriesFit]={"LeadingPower"->Automatic,"MinimalTerms"->2,
	"MaximalTerms"->Max,"EstimateAccuracy"->True};
PowerSeriesFit[data_,eps_,opts:OptionsPattern[]]/;Head@data===Association||MatrixQ[data]:=Module[
	{one,fit,epslist,values,pos,dataAll,ii},
	
	{epslist,values}=Which[
		Head@data===Association, {Keys@data,Values@data},
		Length@data[[1]]===2,{data[[All,1]],data[[All,2]]}, (*fit one expression*)
		True,{data[[All,1]],data[[All,2;;-1]]}(*fit a list of expression*)
	];
	If[Union[NumberQ/@epslist]=!={True},
		Print["PowerSeriesFit: non-number encountered."];
		Return[data,Module]
	];
	
	values=Table[values[[i]]/.eps->epslist[[i]],{i,Length@epslist}]//Expand;
	(*one=1,ii=I*)
	values=one*values/.Complex[a_,b_]:>a+b*ii;
	(*replace 0's by the exact form*)
	values=values/.x_Real/;x==0:>0;
	
	(*find out all numbers*)
	pos=Position[#,_?NumberQ]&/@values;
	If[Union@pos=!=pos[[1;;1]],Print["Incorrect input for PowerSeriesFit."]; Return[data,Module]];
	pos=pos[[1]];
	dataAll=Extract[#,pos]&/@values//Transpose;
	
	dataAll=powerSeriesFit0[{epslist,#}//Transpose,eps,opts]&/@dataAll;
	Expand@ReplacePart[values[[1]],pos->dataAll//Thread]/.{one->1,ii->I}
];


Options[powerSeriesFit0]={"LeadingPower"->Automatic,"MinimalTerms"->2,
	"MaximalTerms"->Max,"EstimateAccuracy"->True};
powerSeriesFit0[data_,eps_,OptionsPattern[]]:=Module[
	{n,bases,pow,i,fit,NaN,diff,res,current,min,max},
	If[Length@Union@data[[All,2]]===1,Return[data[[1,2]]]];
	
	n=Length@data;
	
	(*find out leading power*)
	pow=OptionValue@"LeadingPower";
	If[!NumberQ[pow],
		bases=Prepend[eps^(Range[n-1]-1),Log[eps]];
		pow=Infinity;
		diff=Infinity;
		For[i=2,i<=n,i++,
			fit=Fit[{#[[1]],Log@#[[2]]}&/@data,bases[[1;;i]],eps,"BestFitParameters"][[1]];
			If[Abs[pow-fit]>Abs[diff],Break[],diff=fit-pow;pow=fit];
			If[Abs@diff<10^-5,Break[]]
			(*Print[{fit,diff}];*)
		];
		If[#>0.1,
			Print["Warning: power is not sufficiently close to an integer. Leading power = ",#];
			Print[{pow,data}];
		]&@Abs@N[pow-Round@pow,10];
	];
	
	(*determine minimal/maximal number of bases*)
	max=OptionValue@"MaximalTerms";
	If[!IntegerQ@max||max>n||max<1,max=n];
	min=OptionValue@"MinimalTerms";
	If[min===Max,min=n];
	If[!IntegerQ@min||min<1,min=1];
	If[min>max,min=max];
	
	(*fits with different number of bases*)
	bases=eps^(Round@pow+Range[n]-1);
	res=ConstantArray[NaN[0],n];
	diff=ConstantArray[Infinity,n];
	For[i=min,i<=max,i++,
		fit=PadRight[Fit[data,bases[[1;;i]],eps,"BestFitParameters"],n,NaN[i]];
		current=Abs[fit-res]/.x_Abs/;!FreeQ[x,NaN]->Infinity;
		If[current[[1]]>diff[[1]],
			Break[]
			,
			diff=current;res=fit
		];
	];
	
	If[i<=2,Print["Error: PowerSeriesFit failed: ",Short@data];Abort[]];
	If[OptionValue@"EstimateAccuracy",
		(*(i-1)th fit as final result, and (i-2)th fit as reference to estimate error*)	
		fit=PadRight[Fit[data,bases[[1;;i-2]],eps,"BestFitParameters"],n,NaN[i-2]];
		res=Table[
			If[!FreeQ[{res[[i]],fit[[i]]},NaN],0,
				SetAccuracy[res[[i]],Round[Log[10,data[[-1,1]](fit[[i]]-res[[i]])//Abs]//Abs]]]
			,{i,Length@res}
		];
	];
	res . bases/._NaN->0
];


(* ::Section::Closed:: *)
(*BlockdpMatrix*)


(*For symbolic variables, count their numbers*)
BlockdpMatrix[varlist_List]/;Variables[varlist]=!={}:=
	If[Flatten[varlist]===varlist||Length@varlist===1,
		BlockdpMatrix[Length@Flatten[varlist]], 
		BlockdpMatrix[Length@Flatten@List[#]&/@varlist]
	];
BlockdpMatrix[nvars_?IntegerQ]:=BlockdpMatrix[{nvars}];
BlockdpMatrix[{a___,0,b___}]:=BlockdpMatrix[{a,b}];
BlockdpMatrix[{}]:={};
(*For a list of positive integers*)
BlockdpMatrix[nvars_List]/;And@@(Element[#,PositiveIntegers]&/@nvars):=Module[
	{wei,i,n},
	
	n=Plus@@nvars;
	wei=Join@@Table[
		{Table[If[Plus@@nvars[[1;;i-1]]<k<=Plus@@nvars[[1;;i]],1,0],{k,1,n}],
		  Sequence@@Table[
			If[k===(Plus@@nvars[[1;;i]]-j+1),-1,0],{j,1,nvars[[i]]-1},{k,1,n}
		]}, 
		{i,1,Length[nvars]}
	];
	wei
];


(* ::Section::Closed:: *)
(*MMAGroebnerBasis*)


(*** 
GroebnerBasis gets wrong results, but MMAGroebnerBasis gets correct results.
MMAGroebnerBasis[{-1 + (y^2 - x)*d[1], -1 + x*d[2]}, {d[2], d[1], x}]
MMAGroebnerBasis[{-1 + (yy - x)*d[1], -1 + x*d[2]}, {d[2], d[1], x}]/.yy\[Rule]y^2
GroebnerBasis[{-1 + (y^2 - x)*d[1], -1 + x*d[2]}, {d[2], d[1], x}, MonomialOrder -> DegreeReverseLexicographic]
GroebnerBasis[{-1 + (yy - x)*d[1], -1 + x*d[2]}, {d[2], d[1], x}, MonomialOrder -> DegreeReverseLexicographic]/.yy\[Rule]y^2
***)


MMAGroebnerBasis[ideal_,varorder0_List]:=Module[
	{varorder},
	
	(*** append variables that has not been claimed ***)	
	varorder=Complement[Variables[ideal],varorder0//Flatten];
	varorder=If[varorder==={},varorder0,Append[varorder0,varorder]];
	
	GroebnerBasis[ideal,varorder//Flatten,MonomialOrder->SparseArray@BlockdpMatrix[varorder]]
];


(* ::Section::Closed:: *)
(*GeneralizedApart*)


(*Using the algorithm in 2101.08283 by Matthias Heller and Andreas von Manteuffel*)


Options[GeneralizedApart]={"DenominatorFunction"->{Automatic,Automatic},
	"Factoring"->Automatic,"CancelQ"->False};
GeneralizedApart[exp0_,opts:OptionsPattern[]]/;!MemberQ[{opts},{}]:=
	GeneralizedApart[exp0,Variables@exp0//Sort,opts];
GeneralizedApart[exp0_,{},opts:OptionsPattern[]]:=exp0;
GeneralizedApart[exp0_,vars_List,OptionsPattern[]]:=Module[
	{exp=exp0,fun,explict,densEx,dens,dd,list,i,flag},

	{fun,explict}=OptionValue["DenominatorFunction"];
	
	If[fun===Automatic,
		(*Remove possible rational expressions in denominators*)
		exp=exp//.a_^b_/;b<0&&!FreeQ[a,Alternatives@@vars]:>Factor[a^b];
		exp=exp/.a_^b_/;b<0&&!FreeQ[a,Alternatives@@vars]:>dd[a]^-b;
		
		(*Find out relevant denominators*)
		dens=Cases[{exp},_dd,Infinity]//Union;
		dens=Reverse@Sort[dens,polynomialOrderedQ[{#1,#2}/.dd->Identity,vars]&];
		densEx=dens/.dd->Identity,
		
		dens=Cases[{exp},_fun,Infinity]//Union;
		dens=Reverse@Sort[dens,polynomialOrderedQ[{#1,#2}/.a_fun:>explict[a],vars]&];
		densEx=explict[dens]
	];
	
	If[OptionValue["CancelQ"]===True,
		(*Try to cancel each denominator*)
		i=1;
		While[i<=Length@dens,
			{flag,exp}=generalizedApart[exp,dens,densEx,vars,{i},"Factoring"->Automatic];
			If[!MemberQ[flag,i],i++];
			dens=Delete[dens,List/@flag];
			densEx=Delete[densEx,List/@flag]
		];
		exp=generalizedApart[exp,dens,densEx,vars,{},"Factoring"->OptionValue["Factoring"]][[2]];	
		,
		exp=generalizedApart[exp,dens,densEx,vars,{},"Factoring"->OptionValue["Factoring"]][[2]]
	];
	
	exp/.dd[x_]:>1/x
];


Options[generalizedApart]={"Factoring"->Automatic};
generalizedApart[exp0_,dens_,densEx_,vars0_List,cancellist_List,OptionsPattern[]]:=Module[
	{exp=exp0,vars,n,factoring,d,coe,rest,repDen,gb,dd},
	
	(*Print[exp0,dens,dens[[cancellist]],vars0];*)
	
	n=Length@dens;
	
	(*Use d[i] to denote the i'th denominator*)
	(*Ordering of variables*)
	vars={d/@cancellist,d/@Complement[Range[n],cancellist],vars0};
	(*e.g., {{d[2]},{d[1],d[3],d[4],d[5]},{x,y,z}};*)
	
	(*Calculate groebner basis*)
	gb=MMAGroebnerBasis[Table[densEx[[i]]*d[i]-1,{i,1,n}],vars];
	(*Print[gb];*)
	
	repDen=Table[dens[[i]]->d[i],{i,1,Length@dens}]/.Rule->RuleDelayed;
	(*Polynomial reduce*)
	exp=exp/.repDen;
	exp=polynomialReduceBlockDP[exp,"data"->{gb,vars}];

	(*Simplify final result*)
	If[OptionValue["Factoring"]===Automatic,
		Attributes[factoring]={Listable};
		factoring[tt_]:=Module[
			{temp},
			temp=Together[tt];
			temp=If[Head@temp===Times,List@@temp,{temp}];
			Times@@(SimplifyList[#,vars0,"Factoring"->Expand]&/@temp)
		]
		,
		factoring=OptionValue["Factoring"]
	];
	exp=SimplifyList[exp,_d,"Factoring"->factoring];
	
	{Table[If[FreeQ[exp,d[i]],i,Nothing],{i,Length@dens}],exp/.d[i_]:>dens[[i]]}
];


polynomialOrderedQ[{poly1_,poly2_},vars_List,ordering_:"DegreeReverseLexicographic"]:=Module[
	{a,b,list},
	list=MonomialList[poly1*a+poly2*b,vars,ordering];
	list=Select[list,FreeQ[#,a]||FreeQ[#,b]&];
	If[Length@list>0,
		If[FreeQ[list[[1]],a],True,False],
		If[LeafCount[poly1]<LeafCount[poly2],True,False]
	]
]


(* ::Section::Closed:: *)
(*polynomialReduceBlockDP*)


Attributes[polynomialReduceBlockDP]={Listable};
Options[polynomialReduceBlockDP]={"data"->{{},{}}};
polynomialReduceBlockDP[exp_,opt:OptionsPattern[]]:=Module[
	{head,gb,vars,varsFlatten,factor,res},
	{gb,vars}=OptionValue["data"];
	varsFlatten=Flatten@vars;
	head=Head@exp;
	
	If[head===Plus,Plus@@polynomialReduceBlockDP[List@@exp,opt]//Return];
	
	If[head===Times,
		factor=Select[exp,FreeQ[#,Alternatives@@varsFlatten]&];
		If[factor=!=1,
			factor*polynomialReduceBlockDP[exp/factor,opt]//Return
		]
	];

	res=PolynomialReduce[exp,gb,varsFlatten,MonomialOrder->SparseArray@BlockdpMatrix[vars]][[-1]];

	SimplifyList[res,vars[[1]],"Factoring"->Expand]
];


(* ::Section::Closed:: *)
(*PolynomialRowReduce*)


Options[PolynomialRowReduce]={"PositionOverTerm"->False,"MonomialOrdering"->BlockdpMatrix,
	"Modulus"->0,"Blocks"->1,"Sparse"->True,"LeadingTerm"->False,"LearnQ"->False};


PolynomialRowReduce[eqsIn_List,opts:OptionsPattern[]]:=Module[
	{vs=Variables[eqsIn]//Sort},
	(*Fix the bug: if vs={}, Mathematica recognizes it as no input at this position.*)
	If[vs==={},vs={1}];
	PolynomialRowReduce[eqsIn,vs,opts]
];


PolynomialRowReduce[eqsIn_List,vs_List,opts:OptionsPattern[]]/;Head@eqsIn[[1]]=!=List:=
		PolynomialRowReduce[List/@eqsIn,vs,opts];


PolynomialRowReduce[eqsIn0_?MatrixQ,zs00_List,opts:OptionsPattern[]]:=Module[
	{learnQ,eqsIn=eqsIn0,zs0=zs00,dens,e,n,en,p,mod,ordering,zs,z,Int,toInt,eqs,base,
	sparse2dense,i,j,rep1,rep2,row,vec,var,varRep,subs,mat,res,Plus2List,hold,LTs},
	
	learnQ=OptionValue["LearnQ"];
	
	(*** eqsIn=Select[eqsIn0,#=!={0}&]; ***)
	eqsIn=eqsIn0;
	
	If[Union@Flatten@eqsIn==={},
		If[OptionValue["LeadingTerm"],Return[{{},{}},Module],Return[{},Module]]
	];
	(*
	check if it is a polynomial. but cost too much time ???
	If[zs0==={1},zs0={}];
	dens=If[Head@#===Plus,1,Denominator@#]&/@eqsIn//Flatten//Union;
	dens=Table[FreeQ[dens,z],{z,Flatten@zs0}];
	Print[12,LeafCount@dens];
	If[!And@@dens,
		ErrorPrint["Wrong input for PolynomialRowReduce: not combinations of polynomials.",
			Short[eqsIn]
		];
		Return[eqsIn0,Module]
	];
	*)
	sparse2dense[vs_List,l_]:=Module[
		{v},
		v=ConstantArray[0,l];
		v[[vs[[All,1]]]]+=vs[[All,2]];
		v
	];
	
	(*Change vectors to polynomials. Positions are denoted as independent variables e[i].*)
	n=Length@eqsIn[[1]];
	en=Array[e,n];
	eqsIn=Map[# . en&,eqsIn,{1}];
	(****************************)
	
	p=OptionValue["Modulus"];
	mod[nums_]:=RationalMod[nums,p];
	
	(*Construct block ordering*)
	zs0=If[!MemberQ[Head/@zs0,List],{zs0},zs0];
	zs0=If[OptionValue["PositionOverTerm"],Prepend[zs0,en],Append[zs0,en]];
	ordering=If[OptionValue@"MonomialOrdering"===BlockdpMatrix,
					SparseArray@BlockdpMatrix[zs0],
					OptionValue@"MonomialOrdering"
			];
	
	(*Express any monomial 'mono' as Int[mono] so that they can be easily replaced*)
	Attributes[toInt]={Listable};
	toInt[exp_]:=Dot@@({#[[1]],Int/@#[[2]]}&@Separate[exp//Expand,_z]);
	
	(*Use new variables z[1], ..., z[N]*)
	zs=Array[z,Length@Flatten[zs0]];
	eqs=eqsIn/.Dispatch@Thread[Flatten[zs0]->zs]//toInt;
	
	(*Find the complete list of ordered monomials. Replace them by Int[1], Int[2], ...*)
	base=(Cases[eqs,_Int,Infinity]//Union);
	base=Int/@MonomialList[Plus@@base/.Int->Identity,zs,ordering];
	(*WriteMessage[{"# of equations=",Length@Flatten@eqs,
		", # of bases=",Length@base,", density=",
		(Length/@Flatten@eqs//Mean)/Length@base//N}
	];*)
	
	(*rep1: from original variables to new variables. 
	  rep2: from new variables to original variables.*)
	{rep1,rep2}={#,(Reverse/@#)}&@Table[base[[i]]->Int[i],{i,Length@base}];
	rep2[[All,2]]=rep2[[All,2]]/.Dispatch@Thread[zs->Flatten@zs0];
	
	
	eqs=SimplifyList[eqs/.Dispatch@rep1,_Int,"Factoring"->Expand];
	
	(*generate a sparse list for each line, in the form: hold[{{i1,v1},{i2,v2},...}]*)
	Attributes[Plus2List]=Listable;
	Plus2List[exp_]:=If[Head@exp===Plus,hold[List@@exp],hold[List@exp]]/.
								(v_:1)*Int[i_]:>{i,v}/.{0}:>{};
	eqs=eqs//Plus2List;
	(*eqs=(Flatten@List[#]&/@eqs);*)
	
	If[OptionValue["Sparse"]===True||learnQ===True,
		(*****Sparse linear solve*****)
		mat=SparseRowReduce2[eqs/.hold->Identity,"Modulus"->p,
			"Blocks"->OptionValue["Blocks"],"LearnQ"->learnQ
			];
		(*** return positions of independent relations as well as leading terms, 
				if the purpose is to learn  ***)
		If[learnQ,
			mat={#[[1]],Int@#[[2]]}&/@mat/.Dispatch@rep2/.Int->Identity;
			mat[[All,2]]=sparse2dense[Transpose@Reverse@Separate[#,_e]/.e[x_]:>x,n]&/@mat[[All,2]];
			Return[mat,Module]
		];
		,
		(*****Dense linear solve*****)
		mat=RowReduce[eqs/.hold[x_]:>sparse2dense[x,Length@base],Modulus->p];
		mat=Select[mat,Norm[#]=!=0&]		
	];
	
	(*From coefficients to polynomials*)
	res=mat . Array[Int,Length@base]/.Dispatch@rep2/.Int->Identity;
	
	(*From express to sparse form, and then to dense form*)
	res=sparse2dense[Transpose@Reverse@Separate[#,_e]/.e[x_]:>x,n]&/@res;
	
	If[OptionValue["LeadingTerm"],
		LTs=Table[
			For[j=1,j<=Length@mat[[i]],j++,If[mat[[i,j]]=!=0,Break[]]];
			Int[j]
			,{i,Length@mat}
		]/.Dispatch@rep2/.Int->Identity;
		LTs=sparse2dense[Transpose@Reverse@Separate[#,_e]/.e[x_]:>x,n]&/@LTs;
		{res,LTs}//Transpose
		,
		res
	]
];


(* ::Section::Closed:: *)
(*SparseRowReduce*)


(* ::Subsection::Closed:: *)
(*SparseRowReduce*)


Options[SparseRowReduce]={"Modulus"->0,"Blocks"->1,"LearnQ"->False,
	"MaxNumberOfEquations"->Infinity,"Grained"->Automatic,"MonitorQ"->False};
SparseRowReduce[fun_,n_,OptionsPattern[]]:=Module[
	{monitor,timing,p,mod,max,mat,LT,ctr,total,totali,grained,ng,ngi,neqs,neweqs,pool,
	matpool,eqNos,key,mati,keys,
	col,rows,i,fac},
	
	If[OptionValue["MonitorQ"]===True,
		monitor=Monitor;
		timing=CLTiming;
		,
		monitor=List;
		timing=Identity
	];
	
	p=OptionValue["Modulus"];
	mod[nums_]:=factor@RationalMod[nums,p];
	
	max=OptionValue["MaxNumberOfEquations"];
	
	(********************************)
	(*Forward elimination*)
	mat=Association[];
	LT=Association[];
	pool=Association[];
	matpool=Association[];
	ctr=0; (*** counter for independent relations ***)
	total=0; (*** total relations used ***)
	
	grained=OptionValue["Grained"];
	If[grained===Automatic,grained={Max[n/30//Ceiling,100]}];
	ng=Length@grained;
	ngi=0;
	
	monitor[
	While[total<n&&ctr<max,
	
		If[ngi<ng,ngi++];
		neqs=If[grained[[ngi]]===All,n-total,grained[[ngi]]];
		If[neqs<0,neqs=1];(*In case of incorrect input*)
		totali=total+1;
		total=Min[total+neqs,n];
		neweqs=Association@@Table[i->fun[i],{i,totali,total}];
		
		(*Find out nonzero terms*)
		keys=Keys@pool;
		pool=Join@@Table[{i,#}&/@Keys@neweqs[i],{i,totali,total}];
		pool=#[[1,2]]->Association@@Thread[#[[All,1]]->True]&/@GatherBy[pool,Last];
		pool=Association@@pool;
		(*Do[If[!KeyExistsQ[pool,key],pool[key]=Association[]],{key,keys}];*)
		
		backSub[mat,matpool];
		
		eqNos=Join[Keys@mat,Keys@neweqs];
		Do[
			
			If[i>totali-1,
				neweqs[i]=DeleteCases[neweqs[i],0];
				key=Min@Keys@neweqs[i];
				
				If[key//NumberQ,
					LT[i]={key,++ctr};
					mat[i]=Association@@Sort@Normal[neweqs[i]/neweqs[i,key]];
					Do[If[!KeyExistsQ[matpool,key],matpool[key]=Association[]];
						matpool[key][i]=True
						,{key,Keys@mat[i]}
					];
					,
					Continue[]
				];
			];
			
			If[ctr===max,Break[]];
			mati=mat[i];
			keys=Keys@mati;
			col=LT[i][[1]];
			
			rows=Lookup[pool,col,Association[]]//Keys;
			
			Do[
				If[j<=i||neweqs[j,col]==0,Continue[]];
				fac=neweqs[j,col];
				Do[
					neweqs[j,key]=Lookup[neweqs[j],key,0]-fac*mati[key];			
					If[!KeyExistsQ[pool,key],pool[key]=Association[]];
					pool[key][j]=True;
					,{key,keys}]
				,{j,rows}
			];
			,
			{i,eqNos}
		];
	]//timing;
	mat
	,"Forward elimination: "<>ToString[{totali,total},InputForm]<>" out of "<>ToString@n<>
	" lines.\n"<>ToString@ctr<>" out of up to "<>ToString@max<>
	" constraints are found."
	];
	
	LT=SortBy[LT,#[[1]]&];
	
	(*** return positions of independent relations as well as leading terms, if the purpose is to learn  ***)
	If[OptionValue["LearnQ"],Return[LT,Module]];

	(*Backward substitute for all relations*)

	backSub[mat,matpool]//timing;
	
	Association@@Thread[Keys@LT->Lookup[mat,Keys@LT]]
];


(* ::Subsection::Closed:: *)
(*backSub*)


Attributes[backSub]={HoldAll};


(*********Backward substitute**********)
backSub[mat_,matpool_]:=Module[
		{lines,i,j,row,pos,keys,fac,i1},

		lines=Keys@mat;
		
		Do[
			(*Find out nonzero terms*)
			row=mat@lines[[i]];
			keys=Keys@row;
			pos=keys[[1]];
			(*Substitute to former lines*)
			
			Do[
				If[jc<lines[[i]]&&mat[jc,pos]=!=0,
				
				fac=mat[jc,pos];
				Do[mat[jc,key]=Lookup[mat[jc],key,0]-fac*row[key];
					matpool[key][jc]=True
					,{key,keys}];
				]
			,{jc,matpool[pos]//Keys}
			];
			
			i1=lines[[i-1]];

			Do[If[mat[i1,key]===0,
				mat[i1,key]=.;
				matpool[key,i1]=.]
				,{key,Keys@mat@i1}
			];
			,
			{i,Length@lines,2,-1}
		];
		mat
	];


(*********Backward substitute**********)
backSub[mat_]:=Module[
		{lines,i,j,row,pos,keys,fac},
		lines=Keys@mat;
		Do[
			(*Find out nonzero terms*)
			row=mat@lines[[i]];
			keys=Keys@row;
			pos=keys[[1]];
			(*Substitute to former lines*)
			Do[
				If[KeyExistsQ[mat[jc],pos],
				fac=mat[jc,pos];
				Table[mat[jc,key]=Lookup[mat[jc],key,0]-fac*row[key]
					,{key,keys}];
				]
			,{jc,lines[[1;;i-1]]//Reverse}
			];
			mat@lines[[i-1]]=DeleteCases[mat@lines[[i-1]],0];
			,
			{i,Length@lines,2,-1}
		];
		mat
	];


(* ::Subsection::Closed:: *)
(*SparseRowReduce2*)


Options[SparseRowReduce2]={"Modulus"->0,"Blocks"->1,"LearnQ"->False};
SparseRowReduce2[eqs00_List,OptionsPattern[]]:=Module[
	{factor,eqs0=eqs00,eqsTest,blocks,sum,p,mod,x,eq,pair,dense2sparse,BackSub,eqs,
	k,i,j,ii,b,m,n,ctr,ctr0,row,list,pos,mat,LT,vec,mat2,max,total},
	
	dense2sparse[row_]:=Module[
		{jc,listc},
		listc={};
		For[jc=1,jc<=Length@row,jc++,If[row[[jc]]=!=0,AppendTo[listc,jc]]];
		{listc,row[[listc]]}//Transpose
	];
	
	factor=If[Union[NumberQ/@Flatten[eqs0]]==={True},Identity,Factor];
		
	p=OptionValue["Modulus"];
	mod[nums_]:=factor@RationalMod[nums,p];
	
	eqsTest=Select[eqs0,#=!={}&];
	If[!MatrixQ@eqsTest[[1]],
		(*Change normal dense form to sparse form*)
		eqs0=dense2sparse/@eqs0;
	];
	
	(**Test if it is a matrix in sparse form**)
	eqsTest=Select[eqs0,#=!={}&];
	If[And@@(MatrixQ/@eqsTest)&&Union[Length/@eqsTest[[All,1]]]==={2}&&
		Union@(IntegerQ[#]&&#>0&/@Flatten@eqsTest[[All,All,1]])==={True},
		Null,
		ErrorPrint["Incorrect input for SparseRowReduce: not a (sparse) matrix."]; 
		Return[eqs00,Module]
	];
	
	(*Calculate blocks*)
	blocks=OptionValue["Blocks"];
	If[NumberQ@blocks,blocks=ConstantArray[blocks,Length@eqs0/blocks//Ceiling]];
	blocks=Flatten@blocks;
	If[!And@@(IntegerQ/@blocks),
		ErrorPrint["Incorrect option value for \"Blocks\" in SparseRowReduce."]; 
		blocks={}
	];
	
	(*Remove irrelevant blocks or append 1's to blocks*)
	sum=Length@eqs0;
	For[i=1,i<=Length@blocks,i++,  sum-=blocks[[i]];If[sum<=0,Break[]];];
	If[i<=Length@blocks,
		blocks[[i]]+=sum;
		blocks=blocks[[1;;i]],
		blocks=Join[blocks,ConstantArray[1,sum]]
	];
	
	(*Change to block form*)
	eqs0=TakeList[eqs0,blocks];
	
	b=Length@eqs0;
	n=eqs0[[All,All,All,1]]//Max;
	
	(*********Backward substitute**********)
	BackSub[matc0_,nc_]:=Module[
		{matc=matc0,mc,ic,jc},
		
		(*Change from sparse form to dense form*)
		mc=Length@matc;
		matc=Table[
			row=matc[[ic]];
			vec=ConstantArray[0,nc];
			vec[[row[[All,1]]]]+=row[[All,2]];
			vec,{ic,1,mc}
		];
		
		For[ic=mc,ic>1,ic--,
			(*Find out nonzero terms*)
			row=matc[[ic]];
			list={};
			For[jc=1,jc<=nc,jc++,If[row[[jc]]=!=0,AppendTo[list,jc]]];
			pos=list[[1]];
			row=row[[list]];
			
			(*Substitute to former lines*)
			Do[
				If[matc[[jc,pos]]=!=0,
					matc[[jc,list]]=matc[[jc,list]]-matc[[jc,pos]]*row//mod
				]
			,{jc,1,ic-1}
			];
		  ];
		  matc
	];
	(********************************)

	(*Forward elimination*)
	mat={};
	LT={};
	ctr=0; (*** counter for independent relations ***)
	total=0; (*** total relations used ***)
	max=1;

	CLMonitor[
		For[k=1,k<=b,k++,
		(*For each block k*)
		total+=If[k===1,0,blocks[[k-1]]];
		eqs=eqs0[[k]];
		m=Length@eqs;
		ctr0=ctr;
		For[i=1,i<=m,i++,
		(*For each relation i in block k.*)
		row=ConstantArray[0,n];
		row[[eqs[[i,All,1]]]]+=eqs[[i,All,2]]//mod;
		
		(*Simplify the relation using previous ones*)
		Do[
		pos=LT[[j,2]];
		If[row[[pos]]=!=0,
		row[[mat[[j,All,1]]]]=row[[mat[[j,All,1]]]]-row[[pos]]*mat[[j,All,2]]//mod]
		,{j,1,ctr}
		];

		(*Find out nonzero terms*)
		list={};
		For[j=1,j<=n,j++,If[row[[j]]=!=0,AppendTo[list,j]]];
		If[list==={},
		(*Linear independent. All later relations are discarded*)
		Break[],
		ctr++
		];
		
		(*Save the new relation*)
		row=row*mod[1/row[[list[[1]]]]]//mod;
		(*** leading term and position of the independent relation ***)
		AppendTo[LT,{i+total,list[[1]]}];
		AppendTo[mat,{list,row[[list]]}//Transpose];
		If[ctr===n,Break[]];
		];
		(*Maximial relaitons used in each block*)
		max=Max[max,i-1];
		
		(*Backward substitute for each block*)
		mat[[ctr0+1;;ctr]]=BackSub[mat[[ctr0+1;;ctr]],n];
		
		(*Expressed in sparse form*)
		mat[[ctr0+1;;ctr]]=dense2sparse/@mat[[ctr0+1;;ctr]];
		
		If[ctr===n,Break[]];
		];
		mat
		,"Forward elimination: "<>ToString@k<>" out of "<>ToString@b<>
		" blocks."<>ToString@i<>" out of "<>ToString@m<>
		" lines.\n"<>ToString@ctr<>" out of up to "<>ToString@n<>
		" constraints are found."
	];
	
	If[OptionValue["Blocks"]=!=1,
		WriteMessage["Maximal number of independent relations used in each block: ",max]
	];
	
	(*** return positions of independent relations as well as leading terms, if the purpose is to learn  ***)
	If[OptionValue["LearnQ"],Return[LT,Module]];
	
	(*Backward substitute for all relations*)
	mat=BackSub[mat,n];
	
	mat//Sort//Reverse
];


(* ::Section::Closed:: *)
(*MonomialExtension*)


Options[MonomialExtension]={};


MonomialExtension[exp_,varList0_List,monoList_List,opt:OptionsPattern[]]:=Module[
	{i,j,nv,varList,nm=Length@monoList,monos,reducibleQ},
	
	varList=varList0//Flatten;
	nv=Length@varList;
	
	monos=If[IntegerQ[exp]&&exp>=0,
		Table[
			Times@@(varList^#)&/@FrobeniusSolve[ConstantArray[1,nv],i],{i,exp,0,-1}
		],
		exp
	];
	
	Attributes[reducibleQ]={Listable};
	reducibleQ[mono_]:=Module[{},
		For[i=1,i<=nm,i++,
			If[Denominator[mono/monoList[[i]]//Factor]===1,Return[mono]]
		];
		Return[Framed[mono]];
	];
	monos//reducibleQ
];


(* ::Section::Closed:: *)
(*PolynomialAnsatz*)


Options[PolynomialAnsatz]={"DegreeBound"->{},"MonomialBasis"->{1},
"IndependentVariables"->{}};


PolynomialAnsatz[vars0_List,dgr_?IntegerQ,cname_,opt:OptionsPattern[]]:=Module[
	{vars,indvars,pows,i,e,degree,gen,bases,pwList,bounds,tempv,dlist,zeros},
	
	If[dgr<0,Return[0]];
	
	
	bases=OptionValue["MonomialBasis"];
	bounds=OptionValue["DegreeBound"];
	indvars=OptionValue["IndependentVariables"];
	
	vars=Flatten[vars0];
	
	{indvars,pows}=If[Flatten[indvars]===indvars,
		{indvars,ConstantArray[0,Length@indvars]},
		indvars
	];
	
	degree[exp_,vs_List]:=Module[
		{\[Lambda]},Exponent[exp/.Thread[vs->vs*\[Lambda]]/.Thread[indvars->indvars*\[Lambda]^pows],\[Lambda]]
	];
	gen[dg_]:=gen[dg]=(cname[#]*Times@@(vars^#)&/@
			FrobeniusSolve[ConstantArray[1,Length@vars],dg]);
	
	(*Generate a polynomial with correct degree.*)
	pwList=Table[
	e=bases[[i]];
	(gen[dgr-degree[e,vars]]/.cname[x_]:>cname[i,x])*e,
	{i,Length@bases}
	]//Flatten;
	pwList=Plus@@pwList;
	
	(*For each term, check whether "DegreeBound" is satisfied.*)
	pwList=MonomialList[pwList,Join[vars,indvars]];
	
	zeros={};
	Do[
		tempv={vars0[[sel[[1]]]]}//Flatten;
		dlist=sel[[2]];
		If[Head@dlist=!=List,dlist=Table[i,{i,0,dlist}]];
		Do[
			If[!MemberQ[dlist,degree[pwList[[i]],tempv]],AppendTo[zeros,i]],
			{i,Length@pwList}
		];
		,{sel,bounds}
	];

	pwList=pwList[[Complement[Range@Length@pwList,zeros//Union]]];
	
	Plus@@pwList
];


(* ::Section::Closed:: *)
(*VecMul & VecDiv*)


Options[VecMul]={"Simplify"->Expand};
Options[VecDiv]={"Simplify"->Expand};


(*{c0,c1,...,cn} denotes c0+c1*\[Delta]+...+cn*\[Delta]^n, where \[Delta] is an infinitesimal quantity*)


VecMul[v1_List,v2_List,OptionsPattern[]]/;Length@v1>=Length@v2:=Module[
	{i,j},
	Table[
		Sum[v2[[j]]*v1[[i-j+1]]//OptionValue["Simplify"],{j,Min[i,Length@v2]}],
		{i,Length@v1}
	]
];


VecDiv[v1_List,v2_List,OptionsPattern[]]/;Length@v1>=Length@v2:=Module[
	{vec=v1,i,j},
	If[v2[[1]]===0,ErrorPrint["Wrong input for VecDiv: ", v2]];
	For[i=1,i<=Length@v1,i++,
		vec[[i]]=(v1[[i]]-Sum[v2[[j]]*vec[[i-j+1]],{j,2,Min[i,Length@v2]}])/
			v2[[1]]//OptionValue["Simplify"]
	];
	vec
];


(* ::Section::Closed:: *)
(*SymmetricDecomposition*)


Options[SymmetricDecomposition]={"Preference"->{},"MinBlock"->True,WorkingPrecision->300};
SymmetricDecomposition[Mat_?SymmetricMatrixQ,OptionsPattern[]]:=Module[
	{precision=OptionValue[WorkingPrecision],chop,zeroQ,decomposeOne,
	n=Length@Mat,pos,order,i,j,mat,trans,transi},
	
	chop[exp_]:=Chop[exp,10^(-1/2*precision)];
	zeroQ[num_]:=chop[num]===0;
	
	(*Function to decompose one line with nonzero diagonal element*)
	decomposeOne[mat1_,pos1_]:=Module[
		{trans1},
		trans1=IdentityMatrix[n];
		trans1[[pos1]]= mat1[[pos1]]/mat1[[pos1,pos1]];
		trans1[[pos1,pos1]]=1;
		{Transpose@Inverse@trans1 . mat1 . Inverse@trans1,trans1}
	];
	
	(*set preference*)
	pos=OptionValue["Preference"];
	If[Length@pos=!=n,pos=Range@n];
	
	mat=Mat;
	trans=IdentityMatrix@n;
	order={};
	While[Length@pos>0,
		
		(*To get minimal blocks, first deal with lines with nonzero diagonal element*)
		If[OptionValue["MinBlock"],
			For[i=1,i<=Length@pos,i++,
				If[!zeroQ@mat[[pos[[i]],pos[[i]]]],Break[]]
			];
			If[i<=Length@pos,
				{mat,transi}=decomposeOne[mat,pos[[i]]];
				trans=transi . trans;
				AppendTo[order,{pos[[i]]}];
				pos=Drop[pos,{i}];
				Continue[]
			]
		];
		
		For[i=1,i<=Length@pos,i++,
			If[!zeroQ@mat[[pos[[1]],pos[[i]]]],Break[]]
		];
		
		(*Remove a line if there is no nonzero element*)
		If[i>Length@pos,
			AppendTo[order,{pos[[1]]}];
			pos=Drop[pos,{1}];
			Continue[];
		];
	
		(*Balance between two lines*)
		transi=IdentityMatrix[n];
		transi[[pos[[i]],pos[[1]]]]=1;
		trans=transi . trans;
		mat=Transpose@Inverse@transi . mat . Inverse@transi;
		
		(*Diagnonalize the two lines in order*)
		{mat,transi}=decomposeOne[mat,pos[[1]]];
		trans=transi . trans;
		{mat,transi}=decomposeOne[mat,pos[[i]]];
		trans=transi . trans;
			
		AppendTo[order,{pos[[1]],pos[[i]]}];
		pos=Drop[pos,{1,i}];
	];
	
	{mat,trans,order}//chop
];


(* ::Section::Closed:: *)
(*FindStablePoints*)


Options[FindStablePoints]={WorkingPrecision->Infinity};


FindStablePoints[poly_,vars_List,OptionsPattern[]]:=Module[
	{recons,precision,Dpoly,sols,soli,x,i,zi},
	
	precision=OptionValue[WorkingPrecision];
	(*Using 300 to fit exact result. This value is changeable.*)
	If[OptionValue[WorkingPrecision]===Infinity,precision=300];
	
	(*Numerically solve state points equations*)
	Dpoly=Table[D[poly,zi],{zi,vars}];
	
	sols=NSolve[Thread[Dpoly==0],vars,WorkingPrecision->precision];
	
	(*Fit rational numbers. *)
	If[OptionValue[WorkingPrecision]===Infinity,
		Attributes[recons]={Listable};
		recons[var_->num_]:=Module[{temp},
			temp=Rationalize[num,10^(30-precision)];
			var->If[Chop[temp-num,10^(10-precision)]===0,temp,var]
		];
		sols=recons[sols]
	];
	
	Table[
		soli=sols[[i]];
		(*Expansion of the polynomial near a stable point 'sp' by changing 
		variables vars\[Rule]sp+x*vars, where 'x' is an infinitesimal quantity. 
		In the form {sp,{b0,b1,b2,...},vars}*)
		{soli[[All,2]],CoefficientList[poly/.Thread[vars->soli[[All,2]]+x*vars],x],vars}
		,{i,Length@sols}
	]
];


(* ::Section::Closed:: *)
(*End*)


End[];
