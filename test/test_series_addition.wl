s1 = Series[u^(-1) * Y^5 + u^(-1) * Y^6, {u, 0, -1}, {Y, 0, 10}];
s2 = Series[u^1 * Y^4, {u, 0, 1}, {Y, 0, 4}];
res = s1 + s2;
Print["s1 = ", InputForm[s1]];
Print["s2 = ", InputForm[s2]];
Print["s1 + s2 = ", InputForm[res]];
