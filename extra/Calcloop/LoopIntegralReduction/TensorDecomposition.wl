(* ::Package:: *)

(* ::Section::Closed:: *)
(*Begin*)


TensorDecomposition::usage="TensorDecomposition[llist,plist,int] performs tensor integral decomposition \
for the integrand 'int' with loop momenta 'llist' and external momenta 'plist'.";


Begin["`Private`"];
End[];


Begin["`TensorDecomposition`"];


(* ::Section::Closed:: *)
(*TensorDecomposition*)


TensorDecomposition[llist_List,plist_List,int0_,opt:OptionsPattern[]]:=Module[
	{exp,one,uni,lor,times,i,L=Length@llist,E=Length@plist,p,c,int,power,qlist,\[Kappa],f,vlist,sol,res,orthp},
	
	If[FreeQ[int0,Alternatives@@llist],Return[int0,Module]];
	
	(*Mapping*)
	If[Head@int0===Plus||Head@int0===List,
		Return[TensorDecomposition[llist,plist,#,opt]&/@int0,Module]
	];
	
	(*Extrac factor*)
	exp=one*int0/.Pair[Momentum[a_],Momentum[b_]]/;SubsetQ[Join[llist,plist],Variables@{a,b}]:>uni[a,b];
	exp=Select[exp,FreeQ[Cases[{#},_Momentum,Infinity],Alternatives@@llist]&]/.
		uni[a_,b_]:>Pair[Momentum[a],Momentum[b]];
	exp=exp/one;
	If[exp=!=1,Return[exp*TensorDecomposition[llist,plist,int0/exp,opt],Module]];
	
	(*Expand*)
	exp=Expand@int0;
	If[exp=!=int0,Return[TensorDecomposition[llist,plist,exp,opt],Module]];
	
	(*Expand Momenta*)
	exp=MomentumSimplify@int0;
	If[exp=!=int0,Return[TensorDecomposition[llist,plist,exp,opt],Module]];
	
	(*Extract tensor integrals*)
	uni:=LorentzIndex@Unique[lor];
	If[!FreeQ[int0,DiracChain|Eps],
		exp=int0/.Power[a_,n_]/;IntegerQ[n]&&n>0:>times@@ConstantArray[a,n];
		exp=exp/.DiracChain[a___,DiracGamma[b_Momentum],c___]/;MemberQ[llist,b[[1]]]:>
			(DiracChain[a,DiracGamma[#],c]Pair[#,b]&@uni)/.
			Eps[a___,b_Momentum,c___]/;MemberQ[llist,b[[1]]]:>(Eps[a,#,c]Pair[#,b]&@uni)/.
			times:>Times;
		If[exp===int0,ErrorPrint["Unknown structure for TensorDecomposition: ", int0];
			Return[int0,Module]
		];
		Return[TensorDecomposition[llist,plist,exp,opt]//LorentzSimplify,Module]
	];
	
	If[!FreeQ[int0,DiracChain|Eps],
		ErrorPrint["Unknown structure for TensorDecomposition: ", int0];
		Return[int0,Module]
	];
	
	int=int0/.Pair[a_,b_]^(n_:1):>power[a,b,n]/.power[a_,b_,n_]/;MemberQ[llist,b[[1]]]:>power[b,a,n];
	int=If[Head@#===power,{#},List@@#]&@int;
	qlist=int[[All,2]]//Union;
	
	\[Kappa]=Table[Plus@@Select[int,#[[1,1]]===llist[[i]]&&#[[2]]===qlist[[j]]&],
		{i,Length@llist},{j,Length@qlist}]/.power[__,n_]:>n;	
	
	(*using orthogonal basis, so spacetime dim is $D-E*)
	{vlist,sol}=tensorDecomposition0[llist,Array[p,E],Plus@@@\[Kappa],$D-E,c];
	
	(**)
	res=Sum[c[j]tensorProductQ[L,vlist[[j]],\[Kappa],Momentum/@Array[p,E],qlist],{j,Length@vlist}]/.sol;
	
	If[E===0,Return[res,Module]];
	
	(*DownValues of Pair: to ensure the saved values can be used.*)
	orthp=orthogonalize[plist,Pair//DownValues];
	
	Factor/@(res/.Pair[a_,Momentum[p[i_]]]:>Sum[orthp[[i,j]]Pair[a,Momentum@plist[[j]]],{j,E}])
	
];


(* ::Section::Closed:: *)
(*orthogonalize*)


(*DownValues of Pair: to ensure the saved values can be used.*)
orthogonalize[plist_,pairs_]:=orthogonalize[plist,pairs]=Module[
	{i,E=Length@plist,orthp},
	
	For[i=1,i<=E,i++,If[MomentumSimplify@CLForm@SP[plist[[i]]]=!=0,Break[]]];
	
	If[i>E&&E===1,Print["Incorrect input for TensorDecomposition: ",plist];Return[Null,Module]];
	
	orthp=If[i<=E,
		{plist[[i]],Sequence@@plist[[1;;i-1]],Sequence@@plist[[i+1;;-1]]},
		{plist[[1]]+plist[[2]],Sequence@@plist[[2;;-1]]}
	];
	orthp=Orthogonalize[Momentum/@orthp,Pair/*MomentumSimplify/*Factor]//MomentumSimplify;
	
	orthp=Table[Coefficient[orthp[[i]],#]&/@(Momentum/@plist),{i,E}]//Factor
];


(* ::Section::Closed:: *)
(*tensorDecomposition0*)


tensorDecomposition0//ClearAll;
tensorDecomposition0[llist_List,plist_List,\[Beta]_,d_,c_]:=Module[
	{L,E,sps,power,qlist,vlist,eqs,sol,res},
	
	L=Length@llist;
	E=Length@plist;
	sps=gens[L,E];
	sps=Module[{p1,p2},
		 (p1=llist[[#[[1]]]];
		 If[#[[2]]<0,SP[p1,plist[[-#[[2]]]]],
		      p2=llist[[#[[2]]]];
		      SP[p1,p2]-Sum[SP[p1,plist[[i]]]SP[plist[[i]],p2],{i,Length@plist}]
		 ])&/@sps//CLForm
	];
	
	vlist=findSymTensors[\[Beta],E];

	(*tensor decomposition with unknown coefficients c[j]*)
	eqs=Table[
		calcNv[L,vlist[[i]]]*Times@@(sps^vlist[[i]])==Sum[c[j]*
			tensorProduct[L,vlist[[i]],vlist[[j]],d],{j,Length@vlist}]
		,{i,Length@vlist}
	];
(*Print[Table[
		{calcNv2[L,vlist[[i]]],Times@@(sps^vlist[[i]]),tensorProduct2[L,vlist[[i]],vlist[[i]],d]}
		,{i,Length@vlist}
	]];*)
	
	sol=Solve[And@@eqs,Array[c,Length@vlist]][[1]];

	{vlist,sol}
	
];


(* ::Section::Closed:: *)
(*tensorProductQ*)


(*tensor product between a symetric tensor (with momenta p_i) and an external tensor of product of momenta q_i^\mu*)
tensorProductQ[L_,v1_,\[Kappa]_,p_,q_]/;Min[v1,\[Kappa]]<0:=0;
tensorProductQ[L_,v1_,\[Kappa]_,p_,q_]/;Min[v1,\[Kappa]]>=0:=Module[
	{E,K,s,e,vec,vec\[Kappa],l,r,Pair2},
	If[Max[\[Kappa]]===0,Return[1,Module]];
	
	E=(Length@v1-L (L+1)/2)/L;
	K=Length@\[Kappa][[1]];
	
	s=gens[L,E];
	e[i_]:=e[i]=UnitVector[Length@s,i];
	Attributes[vec]=Orderless;
	vec[a_,b_]:=vec[a,b]=Position[s,Sort@{a,b}/.{x_,y_}/;x<0:>{y,x}][[1,1]]//e;
	
	vec\[Kappa][a_,b_]:=vec\[Kappa][a,b]=Normal[SparseArray[{a,b}->1,{L,K}]];
	
	(*a.Overscript[g, ^].b*)
	Pair2[a_,b_]:=Pair2[a,b]=Pair[a,b]-Sum[Pair[a,p[[i]]]*Pair[p[[i]],b],{i,Length@p}];
	
	Do[If[\[Kappa][[i,j]]=!=0,l=i;r=j;Break[]],{i,1,L},{j,1,K}];

	Sum[Pair[p[[i]],q[[r]]]*tensorProductQ[L,v1-vec[l,-i],\[Kappa]-vec\[Kappa][l,r],p,q],{i,E}]+
	Sum[Pair2[q[[j]],q[[r]]](\[Kappa][[l,j]]-If[r===j,1,0])*
		tensorProductQ[L,v1-vec[l,l],\[Kappa]-vec\[Kappa][l,r]-vec\[Kappa][l,j],p,q],{j,1,K}]+
	Sum[If[i===l,0,Pair2[q[[j]],q[[r]]]\[Kappa][[i,j]]*
		tensorProductQ[L,v1-vec[l,i],\[Kappa]-vec\[Kappa][l,r]-vec\[Kappa][i,j],p,q]],{i,1,L},{j,1,K}]//Expand
];


(* ::Section::Closed:: *)
(*tensorProduct*)


tensorProduct[L_,v1_List,v2_List,d_]/;Length@v1===Length@v2:=Module[
	{E,s,qlist,noq},
	
	If[Plus@@v1===0,Return[1,Module]];
	
	E=(Length@v1-L (L+1)/2)/L;
	If[!IntegerQ[E]||E<0,Print["Incorrect input for tensorProduct:", {L,v1,v2}];Return[Null]];
	
	s=gens[L,E];
	qlist=Table[If[s[[i,2]]<0,i,Nothing],{i,Length@s}];	
	noq=Complement[Range[Length@s],qlist];
	
	If[v1[[qlist]]=!=v2[[qlist]],Return[0]];
	
	If[v1[[qlist]]===0,1,calcNv[L,v1]/calcNv[L,v1[[noq]]]]*
		tensorProductG[L,v1[[noq]],v2[[noq]],d]
];


(* ::Section::Closed:: *)
(*findSymTensors*)


findSymTensors[\[Beta]0_List,E_?IntegerQ]:=Module[
	{L=\[Beta]0//Length,s,N,end,rec,asso=Association[],v0,eh,e},
	
	s=gens[L,E];
	N=Length@s;
	end=If[E>0,-E,L];
	eh[i_]:=eh[i]=UnitVector[L,i];
	e[i_]:=e[i]=UnitVector[Length@s,i];
	
	(*
	\[Beta] is the current list of numbers of li;
	v is the current list of constructed vector;
	n is the current position.
	*)
	(*end of recursion*)
	rec[\[Beta]_List,v_List,n_]/;n>N:=(asso[v]=True);
	
	rec[\[Beta]_List,v_List,n_]/;n<=N:=Module[
		{r0=0,r,sn,i,j},
		
		sn=s[[n]];
		Which[
			sn[[1]]===sn[[2]](*li.li*),
				i=sn[[1]];
				If[i===end,r0=Ceiling[\[Beta][[i]]/2]];
				Do[rec[\[Beta]-2r eh[i],v+r e[n],n+1],{r,r0,Floor[\[Beta][[i]]/2]}],
			sn[[2]]>0(*li.lj*),
				{i,j}=sn;
				If[j===end,r0=\[Beta][[i]]];
				Do[rec[\[Beta]-r eh[i]-r eh[j],v+r e[n],n+1],{r,r0,Min[\[Beta][[i]],\[Beta][[j]]]}],
			True(*li.pj*),
				i=sn[[1]];
				If[sn[[2]]===end,r0=\[Beta][[i]]];
				Do[rec[\[Beta]-r eh[i],v+r e[n],n+1],{r,r0,\[Beta][[i]]}]
		]
	];
	
	rec[\[Beta]0,ConstantArray[0,Length@s],1];
	
	asso//Keys
	
];


(* ::Section::Closed:: *)
(*gens*)


(*li\[Rule]i, pi\[Rule]-i
-i must be at the end.
if i<j, lj must be after li
*)
gens[L_?IntegerQ,E_?IntegerQ]:=gens[L,E]=Module[
	{tab,ends},
	tab=Table[{i,If[j<=L,j,L-j]},{i,L},{j,i,L+E}];
	Join@@tab
];


(*gens[L_?IntegerQ,E_?IntegerQ]:=gens[L,E]=Module[
	{tab1,tab2},
	tab1=Join@@Table[{i,j},{j,L},{i,1,j}];
	tab2=Join@@Outer[List,Range[L],-Range[E]];
	Join[tab1,tab2]
];*)


(* ::Section::Closed:: *)
(* calcNv*)


ClearAll[calcNv];
calcNv[L_?IntegerQ,v_List]/;Min[v]<0:=zero;
calcNv[L_?IntegerQ,v_List]/;Min[v]>=0:=calcNv[L,v]=Module[
	{E,s,n,sn,r,v0,i,j,\[Beta]i,\[Beta]j},
	
	If[Plus@@v===0,Return[1,Module]];
	
	E=(Length@v-L (L+1)/2)/L;
	If[!IntegerQ[E]||E<0,Print["Error input for calcNv:", {L,v}];Return[Null]];
	s=gens[L,E];
	
	For[n=Length@v,n>0,n--,If[v[[n]]=!=0,Break[]]];
	
	(*The current power*)
	r=v[[n]];
	(*The current momenta*)
	{i,j}=s[[n]];
	
	(*Powers of loop momenta*)
	\[Beta]i=0;
	\[Beta]j=0;
	Do[
		If[s[[k,1]]===i,\[Beta]i+=v[[k]]];
		If[s[[k,2]]===i,\[Beta]i+=v[[k]]];
		If[s[[k,1]]===j,\[Beta]j+=v[[k]]];
		If[s[[k,2]]===j,\[Beta]j+=v[[k]]],
		{k,1,n}
	];
	
	v0=v;
	v0[[n]]=0;

	Which[
		i===j(*li.li*),Binomial[\[Beta]i,2r]*(2r-1)!!*calcNv[L,v0],
		j>0(*li.lj*),Binomial[\[Beta]i,r]*Binomial[\[Beta]j,r]*r!*calcNv[L,v0],
		True(*li.pj*),Binomial[\[Beta]i,r]*calcNv[L,v0]
	]
	
];


(* ::Section::Closed:: *)
(*tensorProductG*)


tensorProductG//ClearAll;
tensorProductG[L_,v1_List,v2_List,d_]/;Min[v1,v2]<0:=0;
tensorProductG[L_,v1_List,v2_List,d_]/;Min[v1,v2]>=0:=tensorProductG[L,v1,v2,d]=Module[
	{E,s,\[Beta],\[Beta]2,pos,e,vec,C,l,k,res,temp},
	
	If[Max[v1,v2]===0,Return[1,Module]];
	
	If[Max[v1]*Max[v2]===0,Return[0,Module]];
	
	E=(Length@v1-L (L+1)/2)/L;
	s=gens[L,E];
	
	e[i_]:=e[i]=UnitVector[Length@s,i];
	Attributes[vec]=Orderless;
	vec[a_,b_]:=vec[a,b]=Position[s,{a,b}//Sort][[1,1]]//e;
	
	(*Powers of loop momenta*)
	\[Beta]=ConstantArray[0,L];
	\[Beta]2=\[Beta];
	Do[
		pos=s[[k,1]];
		\[Beta][[pos]]+=v1[[k]];
		\[Beta]2[[pos]]+=v2[[k]];
		pos=s[[k,2]];
		If[pos>0,\[Beta][[pos]]+=v1[[k]];\[Beta]2[[pos]]+=v2[[k]]],
		{k,1,Length@s}
	];
	If[\[Beta]=!=\[Beta]2,Return[0,Module]];
	C[a_,b_,c_,dd_]:=(\[Beta][[c]]-Count[{a,b},c])(\[Beta][[dd]]-Count[{a,b,c},dd]);
	
	(*l is the first exist l_i.l_i*)
	For[l=1,l<=Length@s,l++,If[s[[l,1]]===s[[l,2]]&&v1[[l]]+v2[[l]]=!=0,Break[]]];
	(*exchange v1 and v2 so that there are less possibility*)
	If[l<=Length@s&&v1[[l]]===0,Return[tensorProductG[L,v2,v1,d],Module]];
	If[l<=Length@s,
		l=s[[l,1]];
		res=d*calcNv[L,v1]/calcNv[L,v1-vec[l,l]] tensorProductG[L,v1-vec[l,l],v2-vec[l,l],d]+
		Sum[
			temp=C[l,l,i,j]*calcNv[L,v1]*calcNv[L,v2-vec[l,i]-vec[l,j]]/.zero->0;
			If[temp===0,0,temp*tensorProductG[L,v1-vec[l,l],v2-vec[l,i]-vec[l,j]+vec[i,j],d]/(calcNv[L,v1-vec[l,l]]*calcNv[L,v2-vec[l,i]-vec[l,j]+vec[i,j]])]	
			,{i,1,L},{j,1,L}
		]//Factor;
		Return[res,Module]
	];
	
	(*l is the first exist l_l.l_l*)
	For[l=1,l<=Length@s,l++,If[v1[[l]]+v2[[l]]=!=0,Break[]]];
	(*exchange v1 and v2*)
	If[v1[[l]]===0,Return[tensorProductG[L,v2,v1,d],Module]];
	{l,k}=s[[l]];
	
	d*calcNv[L,v1]/calcNv[L,v1-vec[l,k]] tensorProductG[L,v1-vec[l,k],v2-vec[l,k],d]+
		Sum[
			temp=C[l,k,i,j]*calcNv[L,v1]*calcNv[L,v2-vec[l,i]-vec[k,j]]/.zero->0;
			If[temp===0,0,temp*tensorProductG[L,v1-vec[l,k],v2-vec[l,i]-vec[k,j]+vec[i,j],d]/(calcNv[L,v1-vec[l,k]]*calcNv[L,v2-vec[l,i]-vec[k,j]+vec[i,j]])]
			,{i,1,L},{j,1,L}
		]//Factor
	
];


(* ::Section::Closed:: *)
(*End*)


End[];
