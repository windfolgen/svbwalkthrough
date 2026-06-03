Get["original_series_agent.wl"]; 
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough";
svlisteinf = Import[FileNameJoin[{rootDir, "allsvlisteinf_uptow8.txt"}], "String"] // StringTrim[#, "["|"]"] & // "{" <> # <> "}" & // ToExpression;
temp = svlisteinf[[1;;5]];

resOld = SeriesExpansionInf[temp, zrepInf, "Yorder" -> 3];

ClearAll[SeriesExpansionInfNew];
Options[SeriesExpansionInfNew] = {"additional" -> 1, "Yorder" -> 5, "uorder" -> 0};
SeriesExpansionInfNew[temp_, zrep_, OptionsPattern[]] := Module[
  {result, testList, zVal, zzVal, prefVal, zSer, zzSer, zrepSer, prefSer, addSer, uOrder = OptionValue["uorder"], yOrder = OptionValue["Yorder"], expOrder = 8},
  zVal = (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2]) / (2 u) /. {v -> 1 - Y};
  zzVal = (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2]) / (2 u) /. {v -> 1 - Y};
  prefVal = 1 / -Sqrt[-4 u + (-1 - u + v)^2] /. {v -> 1 - Y};
  
  zSer = Series[zVal, {u, 0, expOrder + uOrder}, {Y, 0, yOrder}, Assumptions -> Y > 0];
  zzSer = Series[zzVal, {u, 0, expOrder + uOrder}, {Y, 0, yOrder}, Assumptions -> Y > 0];
  
  zrepSer = Table[
    With[{pow = i},
      {
        Power[z, pow]  -> Power[zSer, pow],
        Power[zz, pow] -> Power[zzSer, pow]
      }
    ],
    {i, 1, 10}
  ] // Flatten;
  
  prefSer = Series[prefVal, {u, 0, expOrder + uOrder}, {Y, 0, yOrder}, Assumptions -> Y > 0];
  addSer = Series[OptionValue["additional"] /. {v -> 1 - Y}, {u, 0, expOrder + uOrder}, {Y, 0, yOrder}, Assumptions -> Y > 0];
  
  testList = temp /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]};
  testList = testList /. {zz -> 1/u/z};
  testList = testList /. {Power[z, a_ /; (a < 0)] :> Power[zz * u, -a]};
  testList = testList /. zrepSer;
  testList = testList * addSer * prefSer;
  
  result = Series[testList, {u, 0, uOrder}, {Y, 0, yOrder}, Assumptions -> Y > 0] // Normal // Expand;
  Return[result];
];

resNew = SeriesExpansionInfNew[temp, zrepInf, "Yorder" -> 3];

diff = Expand[resOld - resNew];
Print[diff];
