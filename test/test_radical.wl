radical = Sqrt[u^2 - 4u + Y^2 + 2uY];
res1 = Series[radical, {u, 0, 0}, {Y, 0, 3}] // Normal;
res2 = Series[radical, {u, 0, 0}, {Y, 0, 3}, Assumptions -> {Y > 0, u > 0}] // Normal;
Print["res1: ", InputForm[res1]];
Print["res2: ", InputForm[res2]];
