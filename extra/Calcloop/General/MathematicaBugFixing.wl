(* ::Package:: *)

(* ::Section:: *)
(*Begin*)


Begin["`Private`"];
MMATranspose;
End[];


Begin["`CLAuxiliary`"];


MMATranspose[{}]={};
MMATranspose[exp_]/;exp=!={}:=Transpose[exp];


(* ::Section::Closed:: *)
(*End*)


End[];
