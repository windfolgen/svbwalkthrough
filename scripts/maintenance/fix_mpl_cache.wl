$HistoryLength = 0;
Get["config.wl"];
Get["workflow_engine.wl"];
Get["input_parser.wl"];
Get["series_agent/series_agent.wl"];

yOrder = 4;

(* Re-run the expansion correctly for MPL files to fix the empty caches *)
mplFiles = FileNames["allsvlistmpl*.m", FileNameJoin[{Directory[], "data"}]];

Do[
  Print["Re-caching: ", mplF];
  fullBasisMPL = Import[mplF];
  
  (* Limit 0e0uv *)
  poleType = "simple";
  radical = Sqrt[(-1 + u + Y)^2 - 4*u]; expTerm = (-1 + u + Y)^2 - 4*u;
  sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  ptr = 0; uRule = u->u/v; vRule = v->1/v; F = 1; i = 1; (* odd i for e0uv *)
  add = 1;
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "e0_inuv.txt"], ToString[InputForm[res]], "String"];
  
  (* Limit 0e0uvp *)
  i = 2; (* even i for e0uvp *)
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "e0_inuvp.txt"], ToString[InputForm[res]], "String"];
  
  (* Limit e1uv *)
  radical = Sqrt[(-2 + u + Y)^2 - 4*(1 - Y)]; expTerm = (-2 + u + Y)^2 - 4*(1 - Y);
  sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  ptr = 1; i = 1; 
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "e1_inuv.txt"], ToString[InputForm[res]], "String"];
  
  (* Limit e1uvp *)
  i = 2;
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "e1_inuvp.txt"], ToString[InputForm[res]], "String"];
  
  (* Limit einfuv *)
  radical = Sqrt[Y^2 - 4*u]; expTerm = Y^2 - 4*u;
  sqrtSeries = Series[radical, {u, 0, 7}, {Y, 0, 7}] // Normal // Expand;
  ptr = 2; i = 1;
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "einf_inuv.txt"], ToString[InputForm[res]], "String"];
  
  (* Limit einfuvp *)
  i = 2;
  res = ExpandInuvList[fullBasisMPL, sqrtSeries, expTerm];
  Export[StringReplace[mplF, ".m" -> "einf_inuvp.txt"], ToString[InputForm[res]], "String"];
  
, {mplF, mplFiles}];
Print["All MPL caches re-generated successfully."];
