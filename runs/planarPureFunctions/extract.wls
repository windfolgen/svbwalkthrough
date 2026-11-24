(* Extract the period-completed functions on the specified planar prefactors.
   Run from the repository root. PURE_OUTPUT names the working directory. *)
$HistoryLength = 0;
root = Directory[];
out = Environment["PURE_OUTPUT"];
If[!DirectoryQ[out], Print["Set PURE_OUTPUT to an existing directory."]; Exit[1]];
Clear[z, zz, f];
u = z zz; v = (1-z)(1-zz); d = z-zz;
one = {1/d}; simple = {1/d, 1/(d (u-1))}; vp = {1/d, 1/(d (v-1))};
v2 = {v/d^2}; u2 = {u/d^2}; vpol = {v/(d (v-1))}; pair = Join[vpol, v2];
rows = {
 {1,175,1,one},{2,173,1,{1/d,(u-v-1)/d^2}},{3,208,1,one},{4,181,1,simple},
 {5,174,1,one},{6,176,1,simple},{7,233,1/u,{1/(d(1-u)),1/(d(1-v)),1/(d(1-u-v)),1/d^2}},
 {8,140,v,v2},{9,187,1,vp},{10,214,1/v,{1/d,1/(d(u-1)),1/(d(v-1))}},
 {11,246,1,pair},{12,212,1,{1/d,(1+v)/(d(v-1)),(1-u+v)/d^2}},
 {13,144,u,{u/(d(1-u)),u/(d(1-u+v)),u/d^2}},{15,49,v^2/u,v2},
 {16,3,1,one},{17,5,1,one},{18,39,1,v2},{19,38,v,v2},{20,21,1,one},
 {21,37,1,vpol},{22,27,v/u,vpol},{23,49,v/u,{1/d^2}},{24,160,1,one},
 {25,167,1,pair},{26,162,1,vp},{27,163,1,Join[{1/d,1/(d(u-1)),u/(d(u-v)),1/(d(v-1))},{1,u,v}/d^2]},
 {28,164,1,one},{29,133,u/v,u2},{30,"R168",1,{v/d^2,1/d,v/(d(u-v)),v/(d(1-v))}},
 {31,169,u,pair},{32,126,u/v,u2}};
read[id_] := Get[FileNameJoin[{root,"anc","fourloop"<>If[StringQ[id],id,"I"<>ToString[id]]<>".m"}]];
fmt[x_] := StringReplace[ToString[x,InputForm]," "->""];
emit[label_,fn_] := (WriteString[stream,"slot[",label,"] := ",fmt[fn],":\n"];);
stream = OpenWrite[FileNameJoin[{out,"slots.mpl"}]];
points = Flatten[Table[{z->a,zz->b},{a,{2,3,4,5}},{b,{-2,-3,-4,-5,-7}}],1];
Do[
 {r,idx,mult,basis}=row;
 expr=read[idx];
 If[idx===212,expr=expr[1-z,1-zz]];
 If[idx===214,expr=expr/._Inactive[___]->0];
 words=DeleteDuplicates[Cases[expr,h:I[__]:>h,Infinity]];
 ids=AssociationThread[words,Array[w,Length[words]]];
 den=Factor[PolynomialLCM@@Append[Denominator[Together[#]]&/@basis,1]];
 poly=Expand[den*mult*(expr/.ids),_w];
 pieces=If[Head[poly]===Plus,List@@poly,{poly}];
 terms=GroupBy[pieces,(Times@@Select[If[Head[#]===Times,List@@#,{#}],!FreeQ[#,w|f]&])&,
                     Factor[Total[#/.{_w->1,_f->1}]]&];
 bas=(Cancel[den*#]&/@basis);
 mat=(bas/.#&/@points);
 piv=First/@(FirstPosition[#,Except[0],None,{1},Heads->False]&/@RowReduce[Transpose[mat]]);
 inv=Inverse[mat[[piv]]];
 solve[c_] := Module[{a=inv.(c/.#&/@points[[piv]])},If[Together[c-a.bas]=!=0,Print["Projection failed: ",r];Exit[1]];a];
 coeffs=AssociationMap[solve,DeleteDuplicates[Values[terms]]];
 projected=Transpose[Lookup[coeffs,Values[terms]]].Keys[terms];
 Do[fn=projected[[j]]/.w[k_]:>words[[k]];emit[ToString[r]<>","<>ToString[j],fn],{j,Length[basis]}];
 Print["Row ", r," projected"];
 ,{row,rows}];
gram=Get[FileNameJoin[{root,"anc","fourloopGramAuxiliaries.m"}]];
emit["0,1",gram["F"][z,zz]];
Close[stream];Exit[0];
