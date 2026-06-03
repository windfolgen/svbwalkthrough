bm = Get["allsvlistmpl_fourloop_invzze1_inuv.txt"];
uPole[expr_] := Exponent[expr /. {Log[u] -> 1, Zeta[_] -> 1, Pi -> 1, Y -> 1}, u, Min];
Print["u pole of element 1: ", uPole[bm[[1]]]];
Print["u pole of element 2: ", uPole[bm[[2]]]];
Print["u pole of element 3: ", uPole[bm[[3]]]];
