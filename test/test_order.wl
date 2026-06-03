expr = Sqrt[u^2 - 4u + Y^2 + 2uY];
Print["Y first, u second: ", InputForm[Series[expr, {u, 0, 0}, {Y, 0, 2}]]];
Print["u first, Y second: ", InputForm[Series[expr, {Y, 0, 2}, {u, 0, 0}]]];
