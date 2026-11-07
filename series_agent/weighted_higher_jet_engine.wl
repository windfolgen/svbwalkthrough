(* =================================================================== *)
(* Weighted jets for a rational leading singularity.                    *)
(*                                                                     *)
(* The caller supplies prefactor/(z-zz)^pole and the certified lowest u  *)
(* power. Retain u^(minimum+r) Y^b with 2 r+b <= regionOrder.             *)
(* Exact root series replace fixed N4/N6 Taylor formulas, so increasing  *)
(* the order only requires deeper input data, not another algorithm.    *)
(* =================================================================== *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "weighted_jet_engine.wl"}]];
ClearAll[HigherJetSetup, HigherJetPhi, HigherAtomJet, HigherJetRules];
HigherJetSetup[prefactor_, channel_Integer, pole_Integer?Positive,
    minimum_Integer, regionOrder_Integer : 4] := Module[
  {vp = 1-Y, uv, factor, root, discriminant, g},
  Clear[HigherJetPhi];
  If[regionOrder < 0, Return[Failure["InvalidOrder", <||>]]];
  If[!Between[channel, {1,6}], Return[Failure["InvalidChannel", <||>]]];
  $HigherOrder = regionOrder;
  $HigherDepth = Quotient[regionOrder, 2];
  $HigherMin = minimum;
  $HigherMax = minimum + $HigherDepth;

  (* This branch has z -> Y and zbar -> 0. The small root is u/z.
     Keep the original z,zbar convention when preparing ordered input jets. *)
  discriminant = 1 + 2 (Y-2) u/Y^2 + u^2/Y^2;
  root = (Y + u + Y Sqrt[discriminant])/2;
  $HigherS = Switch[channel, 1|3, root, 2|4, root/(root-1),
    5, root/(1-root), 6, -root];
  $HigherQ = If[MemberQ[{2,4,5}, channel], 1/vp, 1];
  $HigherH = If[MemberQ[{2,4,5}, channel], ell-Log[vp], ell];
  uv = Switch[channel, 1, {u,vp}, 2, {u/vp,1/vp}, 3, {1/u,vp/u},
    4, {vp/u,1/u}, 5, {1/vp,u/vp}, 6, {vp,u}];
  factor = Switch[channel, 1|6, 1, 2|5, vp, 3|4, u];
  g = Cancel[(prefactor /. {u -> uv[[1]], v -> uv[[2]]}) *
    factor^(pole-1) If[MemberQ[{3,4}, channel], (-1)^pole, 1] /
    If[OddQ[channel], Y, -Y]^pole];
  $HigherG = Normal[Series[g discriminant^(-pole/2)/u^minimum,
    {u, 0, $HigherDepth}]];
  If[!PolynomialQ[$HigherG, u],
    Return[Failure["UnexpectedLeadingPower", <|"Minimum" -> minimum|>]]];

  (* A bare monomial s^a t^b h^k becomes (u Q)^b s^(a-b) H^k.
     Expand in u first; each subsequent u power reduces the allowed Y
     order by two. Memoization is reset for every prefactor/channel. *)
  HigherJetPhi[a_Integer, b_Integer?NonNegative, k_Integer?NonNegative] :=
    HigherJetPhi[a,b,k] = Module[{product, coefficient, answer = 0},
      If[b > $HigherDepth, Return[0]];
      product = Normal[Series[$HigherQ^b $HigherS^(a-b) $HigherG,
        {u, 0, $HigherDepth-b}]];
      Do[
        coefficient = Together[Coefficient[product, u, r-b]];
        If[coefficient =!= 0,
          answer += u^($HigherMin+r) Normal[Series[coefficient $HigherH^k,
            {Y, 0, $HigherOrder-2r}]]],
        {r, b, $HigherDepth}];
      Expand[answer]
    ];
  Null
];
HigherAtomJet[record_List] := Total[(#[[2]] (HigherJetPhi @@ #[[1]])) & /@ record];
HigherJetRules[expression_] := JetRules[expression];
