s1 = Series[u^(-3) * Y^14 + u^0 * Y^20, {u, 0, 0}, {Y, 0, 15}];
s2 = Series[u^(-1) * Y^10 + u^0 * Y^12, {u, 0, 0}, {Y, 0, 11}];

res = s1 + s2;
Print["s1 = ", InputForm[s1]];
Print["s2 = ", InputForm[s2]];
Print["s1 + s2 = ", InputForm[res]];
