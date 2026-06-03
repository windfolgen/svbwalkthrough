term = Import["allsvlistmpl_fourloop_invzze1.m"][[200]];
zrep1 = Get["fourloop_zrep_e1uv.m"];
preSub = {-1 + z -> z1, -1 + zz -> zz1};
logSub = {I[z, 1, 0] -> Log[u/v]};
zetaSub = {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]};
postSub1 = {Power[z1, a_ /; a < 0] :> Power[(zz1)*v/u, -a]};
postSub2 = {
  z1 -> (1 - u - Sqrt[(-1 + u - v)^2 - 4*v] - v)/(2*v),
  zz1 -> (1 - u + Sqrt[(-1 + u - v)^2 - 4*v] - v)/(2*v)
};
vSub = {v -> 1 - Y};

term1 = term /. preSub /. logSub /. zetaSub /. {zz1 -> u/v/z1} // Expand;
term2 = term1 /. postSub1;
term3 = Collect[term2, {z1, zz1}, Factor];
term4 = term3 /. zrep1;
term5 = term4 /. postSub2 /. vSub // Expand;
Print["ByteCount of exact term5: ", ByteCount[term5]];

testSer = Series[term5 /. {Log[u] -> logU}, {u, 0, 1}, {Y, 0, 7}, Assumptions -> {Y > 0}] // Normal;
Print["ByteCount of Series to u^1: ", ByteCount[testSer]];
