zSub = 1/2*(1 - u + v - Sqrt[-4 v + (1 - u + v)^2]);
zS = Series[zSub /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, 2}, Assumptions -> Y > 0];
Print["zS with assumption: ", InputForm[zS]];
