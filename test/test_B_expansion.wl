add = -1/Y;
expTerm = Y^2 - 4*u + 2*u*Y + u^2;
Bterm = add * (-Sqrt[expTerm]) / expTerm;
Print[Series[Bterm, {u, 0, 3}]];
