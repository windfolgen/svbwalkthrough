file = "allsvlistmpl_fourloop_invzze1_inuv.txt";
If[FileExistsQ[file],
  bm = Get[file];
  uPole[expr_] := Exponent[expr /. {Log[u] -> 1, Zeta[_] -> 1, Pi -> 1, Y -> 1}, u, Min];
  minPoles = Map[uPole, bm];
  Print["Min u pole: ", Min[minPoles]];
,
  Print["File not found"];
]
