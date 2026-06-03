term = Import["allsvlistmpl_fourloop_invzze1.m"][[3]];

preSub = {-1 + z -> z1, -1 + zz -> zz1};
logSub = {I[z, 1, 0] -> Log[u/v]};
zetaSub = {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]};
postSub1 = {Power[z1, a_ /; a < 0] :> Power[(zz1)*v/u, -a]};

term1 = term /. preSub /. logSub /. zetaSub /. {zz1 -> u/v/z1} // Expand;
term2 = term1 /. postSub1;
term3 = Collect[term2, {z1, zz1}, Factor];

yMax = 25;
z1Series = Series[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, yMax}, Assumptions -> {Y > 0}];
zz1Series = Series[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, yMax}, Assumptions -> {Y > 0}];
vSeries = Series[1 - Y, {u, 0, 0}, {Y, 0, yMax}];

add = -1/Y;
expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
sqrtSeries = Sqrt[expTerm];
Bterm = add * (-sqrtSeries) / expTerm;
BtermSeries = Series[Bterm, {u, 0, 0}, {Y, 0, yMax}, Assumptions -> {Y > 0}];

testFinal = term3 * BtermSeries /. {z1 -> z1Series, zz1 -> zz1Series, v -> vSeries};
testFinal = Normal[Series[testFinal /. {Log[u] -> logU}, {u, 0, 0}, {Y, 0, 7}]] /. {logU -> Log[u]};

bm = Get["series_agent/fourloopI41_svlistmple1uv_benchmark.m"][[3]];
diff = Expand[testFinal - bm];
Print["Difference using Series substitution: ", diff];
