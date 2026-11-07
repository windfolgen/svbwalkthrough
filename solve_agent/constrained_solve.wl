(* Additional exact solve and standard multi-LS output. The legacy solver
   retains its original implementation and signature. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "exact_linear.wl"}]];
ClearAll[RunConstrainedCoefficientSolving];
RunConstrainedCoefficientSolving[root_, label_, config_, blocks_List, parameterMap_:Automatic] := Module[
  {ansatz, dims, state, values, offsets, coefficients, result, ls, report, dir,
   elapsed, rules, map, n},
  ansatz = config["LeadingSingularities"][[All, 3]] /. I0constant -> 1;
  dims = Length /@ ansatz; dir = FileNameJoin[{root, "runs", label}];
  map = If[parameterMap === Automatic, IdentityMatrix[Total[dims], SparseArray], SparseArray[parameterMap]];
  If[Length[Dimensions[map]] =!= 2 || First[Dimensions[map]] =!= Total[dims] ||
      !AllTrue[map["NonzeroValues"], MatchQ[#, _Integer | _Rational] &],
    Return[Failure["ParameterMapDimensions", <||>]]];
  n = Last[Dimensions[map]];
  {elapsed, state} = AbsoluteTiming[SVBExactSolve[blocks, n]];
  If[FailureQ[state], Return[state]];
  If[state["FreeColumns"] =!= {},
    Put[{c /@ state["FreeColumns"], c /@ state["FreeColumns"]},
      FileNameJoin[{root, "solve_agent", label <> "_freevars.m"}]];
    Return[Failure["Underdetermined", <|"FreeColumns" -> state["FreeColumns"]|>]]];
  values = Normal[map.state["Point"]];
  offsets = Prepend[Accumulate[dims], 0];
  coefficients = Table[values[[offsets[[k]]+1 ;; offsets[[k+1]]]], {k, Length[dims]}];
  result = MapThread[Expand[#1.#2] &, {coefficients, ansatz}];
  ls = (#[[2]]/(z-zz)^If[#[[1]] === "double", 2, 1] &) /@ config["LeadingSingularities"];
  If[!FreeQ[result, _c | Indeterminate | ComplexInfinity | $Failed],
    Return[Failure["InvalidResult", <||>]]];
  Put[coefficients, FileNameJoin[{dir, "coeff_sol.m"}]];
  Put[result, FileNameJoin[{dir, "result.m"}]];
  Export[FileNameJoin[{dir, label <> ".txt"}],
    ToString[ls.result /. {u -> z zz, v -> (1-z)(1-zz)}, InputForm], "Text"];
  rules = Thread[(c /@ Range[Length[values]]) -> values];
  Put[rules, FileNameJoin[{root, "solve_agent", label <> "_sol.m"}]];
  Put[{{}, {}}, FileNameJoin[{root, "solve_agent", label <> "_freevars.m"}]];
  If[parameterMap =!= Automatic,
    Put[state["Point"], FileNameJoin[{dir, "generator_coeff_sol.m"}]]];
  report = <|"Status" -> "Complete", "OutputsValidForThisRun" -> True,
    "Method" -> Lookup[config, "BootstrapMethod", "Constrained"], "Dimensions" -> dims,
    "GeneratorCount" -> n, "RemainingFree" -> 0, "AllOriginalRowsSatisfied" -> True,
    "SolveSeconds" -> elapsed, "Stages" -> state["History"]|>;
  Export[FileNameJoin[{dir, "workflow_validation.json"}], report, "RawJSON"];
  report
];
