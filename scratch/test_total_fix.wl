(* test_total_fix.wl *)
$HistoryLength = 0;

filepath = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/";
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/";

Get[FileNameJoin[{filepath, "asym_test.wl"}]];

order = 4;
name = "fourloopI42_comp1_1234";

Print["Loading results file..."];
testData = Import[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"];
{top, top1, top2} = testData[[1]];
localTest = testData[[2]];

Print["Running ClassifyGs..."];
{grep, glist} = ClassifyGs[localTest, top1];
gtransform = Join[grep /. {G[a__] :> G[1, {a}]}, grep /. {G[a__] :> G[2, {a}]}] // Dispatch;

Print["Loading basischange..."];
basischange = Import[filepath <> "asym4LbasisChange.m"] // Dispatch;

Print["Loading Grep (reduced results)..."];
trep = Import[filepath <> "tmp/targetIntegrals_reduced.m"];
trep1 = trep /. {j[_, a__] :> G[1, {a}], G[1, a__] :> G[1, {a}]} /. {d -> 4 - 2 ep};
trep2 = trep /. {j[_, a__] :> G[2, {a}], G[1, a__] :> G[2, {a}]} /. {u -> 1} /. {d -> 4 - 2 ep};
Grep = Join[trep1, trep2] // Dispatch;

Print["Loading Gmasterrep..."];
$GmaterrepFiles = {"Gmaterrep4L.m", "Gmaterrep3L.m", "Gmaterrep2L.m", "Gmaterrep1L.m"};
Gmasterrep = Join @@ (Import[FileNameJoin[{filepath, #}]] & /@ $GmaterrepFiles) // Dispatch;

Print["Preparing exprE..."];
exprSum = Total[localTest];
exprA = exprSum /. gtransform;
exprB = exprA /. {D -> 4 - 2 ep};
exprC = exprB /. Grep;
exprD = Collect[exprC, _G];
exprE = exprD /. basischange;
exprECollected = Collect[exprE, _G];

Print["Expanding unique G master representations..."];
glistUnique = Cases[exprECollected, _G, Infinity] // DeleteDuplicates;
gExpRules = Table[
  g -> Series[g /. Gmasterrep, {u, 0, 0}]
, {g, glistUnique}];

Print["Distributing over Plus..."];
exprDist = Distribute[exprECollected, Plus];
termList = If[Head[exprDist] === Plus, List @@ exprDist, {exprDist}];

Print["Expanding terms..."];
optTerms = Table[
  Block[{gVar, g, coeff, coeffExp, gExp},
    gVar = Cases[term, _G, {0, Infinity}];
    If[gVar === {},
      g = 1; coeff = term;
    ,
      g = gVar[[1]]; coeff = term / g;
    ];
    coeffExp = Series[coeff, {u, 0, 0}];
    gExp = If[g === 1, 1, g /. gExpRules];
    coeffExp * gExp
  ]
, {term, termList}];

fresultOpt = Total[optTerms];

Print["With Total[fresultOpt]:"];
fresWithTotal = Series[((fresultOpt // Total) + O[ep]) // Normal // Expand, {Y, 0, order}] // ExpandAll;
Print[fresWithTotal];

Print["Without Total[fresultOpt]:"];
fresWithoutTotal = Series[(fresultOpt + O[ep]) // Normal // Expand, {Y, 0, order}] // ExpandAll;
Print[Short[fresWithoutTotal, 5]];
