testReap[sowList_] := Module[{temp},
  temp = Reap[Do[Sow[x], {x, sowList}]][[2]];
  temp = If[temp === {}, {}, temp[[1]]];
  temp
];

Print["Empty case: ", testReap[{}]];
Print["Non-empty case: ", testReap[{a, b, c}]];
