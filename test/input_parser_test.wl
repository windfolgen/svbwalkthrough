ExtractPole[expr_] := Module[{den, pOrder, primaryPoleOrder, pref, cType},
  den = Denominator[Cancel[expr]];
  pOrder = Exponent[den, z-zz];
  
  primaryPoleOrder = If[pOrder == 2, 2, 1];
  
  cType = If[primaryPoleOrder == 2, "double", "simple"];
  pref = Simplify[expr * (z-zz)^primaryPoleOrder];
  
  {cType, pref}
];

Print[ExtractPole[1/(z-zz)^2]];
Print[ExtractPole[v/(z-zz)^3]];
Print[ExtractPole[1/(z-zz)/(1-u)]];
