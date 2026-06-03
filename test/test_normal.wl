s1 = Series[u^(-1) * Y^5 + u^(-1) * Y^6, {u, 0, -1}, {Y, 0, 10}];
s2 = Series[u^1 * Y^4, {u, 0, 1}, {Y, 0, 4}];
res = Normal[s1] + Normal[s2];
Print["Normal[s1] + Normal[s2] = ", InputForm[res]];
