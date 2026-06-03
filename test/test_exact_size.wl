evaluatedMPL1 = Import["allsvlistmpl_fourloop_invzze1.m"];
zrep1 = Table[{
  Power[z, i]    -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz, i]   -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] + v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[z1, i]   -> (Power[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i]  /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &),
  Power[zz1, i]  -> (Power[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v), i] /. {v -> 1 - Y} // Expand // Collect[#, Power[_, 1/2], Factor] &)
}, {i, 1, 10}] // Flatten;

term = evaluatedMPL1[[3]];
test = (((term /. {-1+z->z1, -1+zz->zz1} /. {I[z,1,0]->Log[u/v], f[a_]:>Zeta[a], f[3,3]->Zeta[3]^2/2, f[3,5]->Zeta[3]Zeta[5]-f[5,3]} /. {zz1->u/v/(z1)} // Expand) /. {Power[z1,a_/;(a<0)]:>Power[(zz1)*v/u,-a]}) /. zrep1 /. {z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)} /. {v->1-Y} // Expand);

str = ToString[InputForm[test]];
Print["Size of element 3 (bytes): ", StringLength[str]];
