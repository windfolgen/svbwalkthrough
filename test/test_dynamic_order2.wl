term = Import["allsvlistmpl_fourloop_invzze1.m"][[3]];
preSub = {-1 + z -> z1, -1 + zz -> zz1};
logSub = {I[z, 1, 0] -> Log[u/v]};
zetaSub = {f[a_] :> Zeta[a], f[3, 3] -> Zeta[3]^2/2, f[3, 5] -> Zeta[3]*Zeta[5] - f[5, 3]};
postSub1 = {Power[z1, a_ /; a < 0] :> Power[(zz1)*v/u, -a]};
term1 = term /. preSub /. logSub /. zetaSub /. {zz1 -> u/v/z1} // Expand;
term2 = term1 /. postSub1;
term3 = Collect[term2, {z1, zz1}, Factor];

z1S0 = Series[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, 1}];
zz1S0 = Series[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, 1}];
vS0 = Series[1 - Y, {u, 0, 0}, {Y, 0, 1}];

temp = term3 /. {z1 -> z1S0, zz1 -> zz1S0, v -> vS0};
tempNorm = Normal[temp /. {Log[u] -> 1, Zeta[_] -> 1}];
uPole = Max[0, -Exponent[tempNorm, u, Min]];

(* The user wants u^0, Y^7 final result. The conformal factor has 1/Y^(2*uPole+2). 
So the required order is 7 + (2*uPole+2) = 2*uPole + 9. *)
yOrderReq = 7 + 2*uPole + 2;

z1S = Series[(1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, yOrderReq}];
zz1S = Series[(1 - u + Sqrt[(-1 + u - v)^2 - 4 v] - v)/(2 v) /. {v -> 1 - Y}, {u, 0, 0}, {Y, 0, yOrderReq}];
vS = Series[1 - Y, {u, 0, 0}, {Y, 0, yOrderReq}];

term5Series = term3 /. {z1 -> z1S, zz1 -> zz1S, v -> vS};
term5Series = Normal[Series[term5Series /. {Log[u] -> logU}, {u, 0, 0}, {Y, 0, yOrderReq}]] /. {logU -> Log[u]};

Print["Size of term5 series string: ", StringLength[ToString[InputForm[term5Series]]]];
