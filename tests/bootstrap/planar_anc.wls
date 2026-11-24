(* Run with wolframscript -file tests/bootstrap/planar_anc.wls *)
$HistoryLength = 0;
root = Nest[ParentDirectory, DirectoryName[$InputFileName], 2];
anc = FileNameJoin[{root, "anc"}];
read[name_,ext_] := Get[FileNameJoin[{anc,"fourloop"<>name<>"."<>ext}]];
assert[label_, test_] := If[!TrueQ[test], Print["FAILED ",label]; Exit[1]];
canonical[expr_] := expr /. Inactive[Integrate][arg_,{s_,lo_,hi_}] :>
  Inactive[Integrate][arg /. s->integrationVariable, {integrationVariable,lo,hi}];
archive = Get[FileNameJoin[{anc,"4Loop_integral_results_by_hyperlog.m"}]];
qa = (2+I)/5; qb = Conjugate[qa];
uu = qa*qb; vv = (1-qa)*(1-qb);
(* Read the finite sum from the independently fitted Maple benchmark. Its
   arithmetic and indexed words have the same syntax in Wolfram Language. *)
maple = Import[FileNameJoin[{anc,"fourloopI26.mpl"}],"Text"];
p7 = ToExpression["("<>First[StringSplit[Last[StringSplit[maple,"I26P7SV :=",2]],":",2]]<>")"];
rho = uu/vv^2;
lower = 4/(1+Sqrt[1+4*Sqrt[rho]])^2;
y = Sqrt[(1+integrationVariable-rho*integrationVariable^2)^2-4*integrationVariable];
mid = 1-integrationVariable+rho*integrationVariable^2;
nativeIntegrand = (p7 /. {z->(mid+y)/2,zz->(mid-y)/2})/y;
expected = {175,173,208,181,174,176,233,140,187,214,246,212,144,260,49,3,
            5,39,38,21,37,27,49,160,167,162,163,164,133,168,169,126};
Do[
  rows = Check[read["Planar32",ext],$Failed];
  assert["row order", (#["Basis"]& /@ rows) === expected];
  assert["multipliers", (#["Multiplier"]& /@ rows) ===
    {1,1,1,1,1,1,1/u,v,1,1/v,1,1,u,u/v,v^2/u,1,1,1,v,1,1,v/u,v/u,
     1,1,1,1,1,u/v,1,u,u/v}];
  assert["conditional row", Select[rows,#["Status"]==="Candidate"&][[All,"Row"]] === {14}];
  Do[
    n = row["Basis"];
    actual = Check[row["BasisFunction"][qa,qb],$Failed];
    assert[{"basis function",n}, FreeQ[actual,$Failed|FAIL|_Function|z|zz] && !NumberQ[actual]];
    If[archive[[n]]=!=FAIL,
      assert[{"direct integration",n},actual === (archive[[n]] /. {z->qa,zz->qb})]],
    {row,rows}];
  finite = read["R168",ext] /. {z->qa,zz->qb};
  scalar = read["I26",ext];
  i168 = rows[[30,"BasisFunction"]];
  value = canonical[scalar[qa,qb]];
  assert["onefold", Count[value,Inactive[Integrate][__],Infinity]===1];
  expectedIntegral = Inactive[Integrate][nativeIntegrand, {integrationVariable,lower,vv}];
  assert["I26 integrand, limits and normalization", Length[p7]===54 &&
    value===expectedIntegral/(vv*(qa-qb))];
  assert["inversion", canonical[scalar[1/qb,1/qa]]===uu^2*value];
  assert["diagonal inversion",scalar[2,2]===scalar[1/2,1/2]/16];
  assert["I168",Expand[canonical[i168[qa,qb]]-2*vv*value-finite]===0];
  assert["I112", Expand[canonical[read["I112",ext][qa,qb]]-value-
      (read["J112",ext] /. {z->qa,zz->qb})]===0];
  i212 = read["I212",ext];
  assert["I212 chart",rows[[12,"BasisFunction"]][qa,qb]===i212[1-qa,1-qb]];
  signed = read["R260",ext][qa,qb];
  assert["I260", Expand[canonical[uu*rows[[14,"BasisFunction"]][qa,qb]-signed
      -i168[qa/(qa-1),qb/(qb-1)]-vv*i168[1-qa,1-qb]]]===0];
  Print["Verified 32 rows, the I26 onefold and the basis assemblies in .",ext],
  {ext,{"m","txt"}}];
