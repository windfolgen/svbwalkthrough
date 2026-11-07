(* Reusable exact constraints. Matrices describe functions, never saved solutions. *)
ClearAll[SVBConstraintBlock, SVBBoundaryBlock, SVBZeroGeneratorGauge];
SVBConstraintBlock[name_String, matrix_, rhs_List] := Module[{dims = Dimensions[matrix]},
  If[matrix === {} && rhs === {},
    Return[<|"Name" -> name, "Matrix" -> {}, "RHS" -> {}|>]];
  If[Length[dims] =!= 2 || First[dims] =!= Length[rhs] ||
      !AllTrue[Join[SparseArray[matrix]["NonzeroValues"], rhs], MatchQ[#, _Integer | _Rational] &],
    Return[Failure["InvalidConstraintBlock", <|"Stage" -> name|>]]];
  <|"Name" -> name, "Matrix" -> SparseArray[matrix], "RHS" -> rhs|>
];
SVBBoundaryBlock[name_String, matrix_, keys_List, boundary_, variables_List,
    shift_, tagger_] := Module[{rules, lookup, strings, extra, rhs, a = matrix},
  rules = CoefficientRules[Expand[shift tagger[boundary /. Log[u] -> ell]], variables];
  If[!AllTrue[Last /@ rules, MatchQ[#, _Integer | _Rational] &],
    Return[Failure["UnresolvedBoundaryPeriods", <|"Stage" -> name|>]]];
  If[Length[keys] =!= First[Dimensions[a]] || !DuplicateFreeQ[keys],
    Return[Failure["InvalidMonomialKeys", <|"Stage" -> name|>]]];
  lookup = Association[(ToString[First[#], InputForm] -> Last[#]) & /@ rules];
  strings = ToString[#, InputForm] & /@ keys;
  rhs = Lookup[lookup, strings, 0]; extra = Complement[Keys[lookup], strings];
  (* An unsupported nonzero target monomial is a contradiction, not discarded. *)
  If[extra =!= {}, a = Join[SparseArray[a], SparseArray[{}, {Length[extra], Last[Dimensions[a]]}]];
    rhs = Join[rhs, Lookup[lookup, extra]]];
  SVBConstraintBlock[name, a, rhs]
];
SVBZeroGeneratorGauge[nullDirections_, blocks_List] := Module[{n, red, pivots, gauge},
  If[Length[Dimensions[nullDirections]] =!= 2,
    Return[Failure["NullDirectionDimensions", <||>]]];
  n = First[Dimensions[nullDirections]];
  (* A nonredundant basis needs no gauge; it follows the same solver path. *)
  If[Last[Dimensions[nullDirections]] === 0,
    Return[SVBConstraintBlock["remove_exact_zero_generators", SparseArray[{}, {0,n}], {}]]];
  If[!AllTrue[blocks, Last[Dimensions[#["Matrix"]]] === n &&
      SVBExactZeroQ[#["Matrix"].nullDirections] &],
    Return[Failure["NullDirectionChangesConstraints", <||>]]];
  (* Whole-function nullity is part of the profile's mathematical certificate;
     annihilation by finite jets alone is not used as a proof of nullity. *)
  red = SparseArray[RowReduce[Transpose[nullDirections]]];
  pivots = (Min[#[[All, 2]]] &) /@ GatherBy[red["NonzeroPositions"], First];
  If[Length[pivots] =!= Last[Dimensions[nullDirections]],
    Return[Failure["DependentNullDirections", <||>]]];
  gauge = SparseArray[Table[{j, pivots[[j]]} -> 1, {j, Length[pivots]}], {Length[pivots], n}];
  SVBConstraintBlock["remove_exact_zero_generators", gauge, ConstantArray[0, Length[pivots]]]
];
