(* Conformal Weight Calculator for SVB Walkthrough *)
(*
  Usage: ConformalWeight[integrand, point]
  
  The conformal weight of a point 'p' is computed as:
  1. Expand the numerator into a sum of monomials.
  2. For each monomial, count how many x[a,b] factors contain 'p'.
  3. Check that all monomials have the same count (required for DCI integrands).
  4. The numerator weight is this common count.
  5. Count how many x[a,b] factors in the denominator contain 'p'.
  6. Total weight = numerator_weight - denominator_weight.
  
  Note: x[a,b]^n counts as n copies.
         Uses Variables + Exponent to avoid double-counting Power bases.
*)

ClearAll[ConformalWeight];
ConformalWeight[integrand_, point_] := Module[
  {num, den, monomials, monoWeights, numWeight, denWeight, weight},
  
  (* Helper: count total exponent of x[point,_] and x[_,point] in expr *)
  countX[expr_, p_] := Plus @@ Cases[Variables[expr],
    x[a_, b_] /; (a === p || b === p) :> Exponent[expr, x[a, b]]
  ];
  
  (* Separate numerator and denominator *)
  num = Numerator[integrand];
  den = Denominator[integrand];
  
  (* Expand numerator into monomials *)
  monomials = MonomialList[num];
  If[monomials === {}, monomials = {num}];
  
  (* For each monomial, count x[a,b] factors containing the point *)
  monoWeights = Table[countX[mono, point], {mono, monomials}];
  
  (* Check that all monomials have the same weight *)
  If[Length[Union[monoWeights]] > 1,
    Print["Warning: Monomials have different conformal weights for point ", point, ": ", monoWeights];
  ];
  
  (* Numerator weight is the common weight (take the first one) *)
  numWeight = monoWeights[[1]];
  
  (* Count x[a,b] factors in denominator containing the point *)
  denWeight = countX[den, point];
  
  (* Total conformal weight *)
  weight = numWeight - denWeight;
  
  Return[weight];
];

(* Convenience function: compute all conformal weights for a list of points *)
ClearAll[ExternalConformalWeights];
ExternalConformalWeights[integrand_, points_List] := Module[
  {weights},
  weights = Table[
    {p, ConformalWeight[integrand, p]},
    {p, points}
  ];
  Return[weights];
];

(* Check if external points have the expected normalized weight (-1) *)
ClearAll[IsNormalized];
IsNormalized[integrand_] := Module[
  {weights},
  weights = ExternalConformalWeights[integrand, {1, 2, 3, 4}];
  (* Check if all external points have weight -1 *)
  Return[AllTrue[weights[[All, 2]], # == -1 &]];
];

(* Determine the appropriate additional prefactor based on normalization *)
ClearAll[GetAdditionalPrefactor];
GetAdditionalPrefactor[integrand_, basePrefactor_] := Module[
  {normalized},
  normalized = IsNormalized[integrand];
  If[normalized,
    (* If normalized with x[1,3]x[2,4], the v factor is already absorbed *)
    Return[1],
    (* Otherwise, use the base prefactor from leading singularity analysis *)
    Return[basePrefactor]
  ];
];
