basisTerm = Series[u^(-1)*Y^10, {u, 0, 0}, {Y, 0, 15}];
add = -1/Y;
expTerm = (-2+u+Y)^2 - 4*(1-Y);
sqrtSeries = Series[Sqrt[expTerm], {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;

test = basisTerm * add * (-sqrtSeries) / expTerm;
test2 = test /. {Log[u] -> logU};
seriesY = Series[test2, {u, 0, 0}, {Y, 0, 5}, Assumptions -> {Y > 0}] // Normal;
res = (seriesY /. {logU -> Log[u]}) // Expand;

Print["Final res = ", InputForm[res]];
