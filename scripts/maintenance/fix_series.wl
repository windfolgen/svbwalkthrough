$HistoryLength = 0;
path = "series_agent/series_agent.wl";
code = Import[path, "Text"];

oldSub = "      ExpandInuvList[basisList_, sqrtSer_, expT_] := ParallelTable[
        Module[{test, test2, seriesY},
          test = If[poleType === \"simple\",
            basisList[[j]] * add * (-sqrtSer) / expT,
            basisList[[j]] * add / expT
          ];
          test2 = (test /. {Log[u] -> logU});
          seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {Y > 0}] // Normal;
          (seriesY /. {logU -> Log[u]}) // Expand
        ],
        {j, 1, Length[basisList]}
      ];";

newSub = "      ExpandInuvList[basisList_, sqrtSer_, expT_] := ParallelTable[
        Module[{test, test2, seriesY},
          test = If[poleType === \"simple\",
            basisList[[j]] * add * (-sqrtSer) / expT,
            basisList[[j]] * add / expT
          ];
          
          (* Apply limit-specific algebraic rules for MPL/SVHPL elements before expanding *)
          Switch[ptr,
            0, If[OddQ[i],
                 test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u]} /. {zz->u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz/u, -a]};
                 test = test /. zrep0 /. {z -> 1/2 (1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), zz -> 1/2 (1 + u - Sqrt[-4 u + (1 + u - v)^2] - v)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], I[z,0,0]->Log[u/v]} /. {zz->u/z/v} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*v/u, -a]};
                 test = test /. zrep0P /. {z -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 v), zz -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 v)} /. {v -> 1 - Y} // Expand;
               ],
            1, If[OddQ[i],
                 test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1 -> u/v/(z1)} // Expand;
                 test = test /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)*v/u, -a]};
                 test = test /. zrep1 /. {z1 -> (1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), zz1 -> (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {-1 + z -> z1, -1 + zz -> zz1} /. {I[z,1,0]->Log[u], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1 -> u/(z1)} // Expand;
                 test = test /. {Power[z1, a_ /; (a < 0)] :> Power[(zz1)/u, -a]};
                 test = test /. zrep1P /. {z1 -> 1/2 (-1 - u + v + Sqrt[-4 v + (1 - u + v)^2]), zz1 -> 1/2 (-1 - u + v - Sqrt[-4 v + (1 - u + v)^2])} /. {v -> 1 - Y} // Expand;
               ],
            2, If[OddQ[i],
                 test = test /. {zz -> 1/u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*u, -a]};
                 test = test /. zrepInf /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u]} /. {z -> (1 + u - v - Sqrt[-4 u + (-1 - u + v)^2])/(2 u), zz -> (1 + u - v + Sqrt[-4 u + (-1 - u + v)^2])/(2 u)} /. {v -> 1 - Y} // Expand;
               ,
                 test = test /. {zz -> v/u/z} // Expand;
                 test = test /. {Power[z, a_ /; (a < 0)] :> Power[zz*u/v, -a]};
                 test = test /. zrepInfP /. {f[5]->Zeta[5], f[7]->Zeta[7], f[3]->Zeta[3], P[0]->-Log[u/v]} /. {z -> (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2])/(2 u), zz -> (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2])/(2 u)} /. {v -> 1 - Y} // Expand;
               ]
          ];
          
          test2 = (test /. {Log[u] -> logU});
          seriesY = Series[test2, {u, 0, 0}, {Y, 0, yOrder}, Assumptions -> {Y > 0}] // Normal;
          (seriesY /. {logU -> Log[u]}) // Expand
        ],
        {j, 1, Length[basisList]}
      ];";

newCode = StringReplace[code, oldSub -> newSub];
Export[path, newCode, "Text"];
