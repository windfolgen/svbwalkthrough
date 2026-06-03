$HistoryLength = 0;
Get["config.wl"];
Get["workflow_engine.wl"];
Get["input_parser.wl"];
Get["series_agent/series_agent.wl"];

yOrder = 4;
prefix = "data/allsvlistmpl_fourloop_invzz";

(* e0 Limits *)
fullBasisMPL = Import[prefix <> "e0.m"];
poleType = "simple"; add = 1;
radical = Sqrt[(-1 + u + Y)^2 - 4*u]; expTerm = (-1 + u + Y)^2 - 4*u;
sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
ptr = 0; uRule = u->u/v; vRule = v->1/v; F = 1; i = 1;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "e0_inuv.txt", ToString[InputForm[res]], "String"];
i = 2;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "e0_inuvp.txt", ToString[InputForm[res]], "String"];
Print["e0 done"];

(* e1 Limits *)
fullBasisMPL = Import[prefix <> "e1.m"];
radical = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)]; expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
ptr = 1; i = 1;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "e1_inuv.txt", ToString[InputForm[res]], "String"];
i = 2;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "e1_inuvp.txt", ToString[InputForm[res]], "String"];
Print["e1 done"];

(* einf Limits *)
fullBasisMPL = Import[prefix <> "einf.m"];
radical = Sqrt[Y^2 - 4*u]; expTerm = Y^2 - 4*u;
sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
ptr = 2; i = 1;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "einf_inuv.txt", ToString[InputForm[res]], "String"];
i = 2;
res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
Export[prefix <> "einf_inuvp.txt", ToString[InputForm[res]], "String"];
Print["einf done"];
