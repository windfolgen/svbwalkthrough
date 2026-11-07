(* Finite weighted symmetry orbits, with pure numerator outputs in the
   original leading-singularity basis. No integral labels are used here. *)
ClearAll[SVBRationalCoordinates, SVBOrbitAnsatz];
SVBRationalCoordinates[expression_, basis_List, variables_List] := Module[
  {a, coefficients, equations, solution, values},
  coefficients = Array[a, Length[basis]];
  equations = Thread[(Last /@ CoefficientRules[
    Numerator[Together[expression - coefficients.basis]], variables]) == 0];
  solution = Solve[equations, coefficients];
  If[Length[solution] =!= 1, Return[Failure["OrbitPrefactorSpan", <||>]]];
  values = coefficients /. First[solution];
  If[!AllTrue[values, MatchQ[#, _Integer | _Rational] &] ||
      Together[expression-values.basis] =!= 0,
    Return[Failure["OrbitPrefactorCoordinates", <||>]]];
  values
];

SVBOrbitAnsatz[sectors_List, seedMap_, images_List, weights_List,
    variables_List : {z, zz}] := Catch[Module[
  {prefactors, offsets, n, bases, maps, action, rules, columns, pieces,
   transformed, k, j, s, sector, result},
  If[Length[images] =!= Length[weights] || images === {},
    Throw[Failure["OrbitDimensions", <||>], "Orbit"]];
  prefactors = (#[[2]]/(z-zz)^If[#[[1]] === "double", 2, 1] &) /@ sectors;
  prefactors = prefactors /. {u -> z zz, v -> (1-z)(1-zz)};
  offsets = Prepend[Accumulate[Length /@ sectors[[All, 3]]], 0];
  If[Length[Dimensions[seedMap]] =!= 2 || First[Dimensions[seedMap]] =!= Last[offsets],
    Throw[Failure["SeedMapDimensions", <||>], "Orbit"]];
  n = Last[Dimensions[seedMap]];
  bases = Table[{}, {Length[sectors]}]; maps = Table[{}, {Length[sectors]}];
  Do[
    rules = images[[j]];
    Do[
      action = SVBRationalCoordinates[weights[[j]] (prefactors[[s]] /. rules), prefactors, variables];
      If[FailureQ[action], Throw[action, "Orbit"]];
      transformed = sectors[[s, 3]] /. rules;
      Do[If[action[[k]] =!= 0,
        bases[[k]] = Join[bases[[k]], transformed];
        AppendTo[maps[[k]], action[[k]]/Length[images] seedMap[[offsets[[s]]+1 ;; offsets[[s+1]]]]]]
      , {k, Length[sectors]}], {s, Length[sectors]}], {j, Length[images]}];
  If[MemberQ[bases, {}], Throw[Failure["EmptyOrbitSector", <||>], "Orbit"]];
  result = Table[{sectors[[k, 1]], sectors[[k, 2]], bases[[k]]}, {k, Length[sectors]}];
  <|"LeadingSingularities" -> result,
    "ParameterMap" -> SparseArray[Join @@ Flatten[maps, 1]],
    "GeneratorCount" -> n|>
], "Orbit"];
