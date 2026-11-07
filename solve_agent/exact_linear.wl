(* Rational affine elimination shared by standard and weighted bootstrap paths.
   The state is x = Point + Kernel.t; large symbolic c[i] expressions are avoided. *)
ClearAll[SVBExactZeroQ, SVBExactState, SVBExactRefine, SVBExactSolve,
  SVBSolveRationalEquations];
SVBExactZeroQ[e_] := If[Head[e] === SparseArray,
  AllTrue[e["NonzeroValues"], # === 0 &], AllTrue[Flatten[{e}], # === 0 &]];
SVBExactState[n_Integer] := <|"Point" -> ConstantArray[0, n],
  "Kernel" -> IdentityMatrix[n, SparseArray], "FreeColumns" -> Range[n], "History" -> {}|>;
Options[SVBExactRefine] = {"VerifyAffineResidual" -> True};
SVBExactRefine[state_Association, matrix_, rhs_List, name_String, OptionsPattern[]] := Module[
  {point = state["Point"], kernel = state["Kernel"], free = state["FreeColumns"],
   a, b, rows, red, pivots, remaining, step, map, newPoint, newKernel, elapsed, history},
  (* An optional condition may contribute no rows. Preserve the affine state
     explicitly: zero-row Dot/Join operations otherwise lose matrix dimensions. *)
  If[matrix === {} && rhs === {}, Return[Append[state, "History" -> Append[state["History"],
    <|"Stage" -> name, "Free" -> Length[free], "Seconds" -> 0, "Exact" -> True|>]]]];
  If[Dimensions[matrix] =!= {Length[rhs], Length[point]},
    Return[Failure["Dimensions", <|"Stage" -> name|>]]];
  If[!AllTrue[Join[SparseArray[matrix]["NonzeroValues"], rhs], MatchQ[#, _Integer | _Rational] &],
    Return[Failure["NonRationalSystem", <|"Stage" -> name|>]]];
  b = rhs - matrix.point;
  If[free === {},
    If[!SVBExactZeroQ[b], Return[Failure["Inconsistent", <|"Stage" -> name|>]]];
    Return[Append[state, "History" -> Append[state["History"],
      <|"Stage" -> name, "Free" -> 0, "Seconds" -> 0, "Exact" -> True|>]]]
  ];
  a = matrix.kernel;
  rows = DeleteDuplicates[Join[Normal[a], List /@ Normal[b], 2]];
  {elapsed, red} = AbsoluteTiming[RowReduce[rows]];
  red = Select[red, !SVBExactZeroQ[#] &];
  pivots = (First@FirstPosition[#, Except[0], Missing["None"], {1}, Heads -> False] &) /@ red;
  If[MemberQ[pivots, Length[free] + 1], Return[Failure["Inconsistent", <|"Stage" -> name|>]]];
  remaining = Complement[Range[Length[free]], pivots];
  step = ConstantArray[0, Length[free]];
  If[pivots =!= {}, step[[pivots]] = red[[All, -1]]];
  map = SparseArray[Join[Table[{remaining[[j]], j} -> 1, {j, Length[remaining]}],
    Flatten[Table[{pivots[[i]], j} -> -red[[i, remaining[[j]]]],
      {i, Length[pivots]}, {j, Length[remaining]}], 1]], {Length[free], Length[remaining]}];
  If[TrueQ[OptionValue["VerifyAffineResidual"]] &&
      (!SVBExactZeroQ[a.step - b] || (remaining =!= {} && !SVBExactZeroQ[a.map])),
    Return[Failure["ExactResidual", <|"Stage" -> name|>]]];
  newPoint = Normal[point + kernel.step];
  newKernel = If[remaining === {}, SparseArray[{}, {Length[point], 0}], SparseArray[kernel.map]];
  history = Append[state["History"], <|"Stage" -> name, "Free" -> Length[remaining],
    "Seconds" -> elapsed, "Exact" -> True,
    "IntermediateAffineResidualChecked" -> TrueQ[OptionValue["VerifyAffineResidual"]]|>];
  <|"Point" -> newPoint, "Kernel" -> newKernel, "FreeColumns" -> free[[remaining]], "History" -> history|>
];
SVBExactSolve[blocks_List, n_Integer] := Catch[Module[{state = SVBExactState[n]},
  (* One complete final check replaces repeated large intermediate kernel
     products. It checks the entire affine family when parameters remain. *)
  Do[state = SVBExactRefine[state, b["Matrix"], b["RHS"], b["Name"], "VerifyAffineResidual" -> False];
    If[FailureQ[state], Throw[state, "ExactSolve"]];
    Print["  ", b["Name"], ": ", Length[state["FreeColumns"]], " free coefficients after rational elimination"],
    {b, blocks}];
  Do[If[b["RHS"] === {}, Continue[]];
    If[!SVBExactZeroQ[b["Matrix"].state["Point"] - b["RHS"]] ||
      (state["FreeColumns"] =!= {} && !SVBExactZeroQ[b["Matrix"].state["Kernel"]]),
    Throw[Failure["FinalResidual", <|"Stage" -> b["Name"]|>], "ExactSolve"]], {b, blocks}];
  state
], "ExactSolve"];
SVBSolveRationalEquations[equations_List, variables_List] := Module[{expr, arrays, state, result, pivots},
  If[MemberQ[equations, False], Return[{}]];
  expr = DeleteCases[equations, True] /. Equal[l_, r_] :> l-r;
  If[expr === {}, Return[{{}}]];
  arrays = CoefficientArrays[expr, variables];
  If[Length[arrays] > 2 || !AllTrue[Flatten[Normal /@ arrays], MatchQ[#, _Integer | _Rational] &],
    Return[Solve[equations, variables]]];
  If[Length[arrays] === 1, Return[If[SVBExactZeroQ[arrays[[1]]], {{}}, {}]]];
  state = SVBExactRefine[SVBExactState[Length[variables]], arrays[[2]], Normal[-arrays[[1]]], "standard"];
  If[FailureQ[state], Return[{}]];
  result = state["Point"] + If[state["FreeColumns"] === {}, 0,
    state["Kernel"].variables[[state["FreeColumns"]]]];
  pivots = Complement[Range[Length[variables]], state["FreeColumns"]];
  {Thread[variables[[pivots]] -> result[[pivots]]]}
];
