s1 = Series[u^(-3) * Y^14, {u, 0, -3}, {Y, 0, 15}];
s2 = Series[u^(-1) * Y^10, {u, 0, -1}, {Y, 0, 11}];

res = s1 + s2;
Print["s1 = ", InputForm[s1]];
Print["s2 = ", InputForm[s2]];
Print["s1 + s2 = ", InputForm[res]];

s1Normal = Normal[s1];
s2Normal = Normal[s2];
resNormal = s1Normal + s2Normal;
Print["Normal[s1] + Normal[s2] = ", InputForm[resNormal]];
