yMax = 5;
vSeries = Series[1 - Y, {u, 0, 0}, {Y, 0, yMax}];
expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
add = -1/Y;
Bterm = add * (-Sqrt[expTerm]) / expTerm;
Print["Bterm e1uv = ", Series[Bterm, {u, 0, 0}, {Y, 0, yMax}]];

add0 = 1/(1-u);
Bterm0 = add0 * (-Sqrt[expTerm]) / expTerm;
Print["Bterm e0uv = ", Series[Bterm0, {u, 0, 0}, {Y, 0, yMax}]];
