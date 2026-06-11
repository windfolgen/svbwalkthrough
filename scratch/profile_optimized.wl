(* profile_optimized.wl *)
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

exprSum = Total[localTest];
exprA = exprSum /. gtransform;
exprB = exprA /. {D -> 4 - 2 ep};
exprC = exprB /. Grep;
exprD = Collect[exprC, _G];
exprE = exprD /. basischange;
exprECollected = Collect[exprE, _G];

glistUnique = Cases[exprECollected, _G, Infinity] // DeleteDuplicates;
gExpRules = Table[
  g -> Series[g /. Gmasterrep, {u, 0, 0}]
, {g, glistUnique}];

exprDist = Distribute[exprECollected, Plus];
termList = If[Head[exprDist] === Plus, List @@ exprDist, {exprDist}];

Print["Number of terms to expand: ", Length[termList]];

(* Count how many coefficients depend on u *)
hasUCount = 0;
noUCount = 0;
Do[
  Block[{gVar, g, coeff},
    gVar = Cases[term, _G, {0, Infinity}];
    If[gVar === {},
      g = 1; coeff = term;
    ,
      g = gVar[[1]]; coeff = term / g;
    ];
    If[FreeQ[coeff, u],
      noUCount++,
      hasUCount++
    ];
  ];
, {term, termList}];

Print["Number of coeffs that contain u: ", hasUCount];
Print["Number of coeffs that do NOT contain u: ", noUCount];

(* Profile original Series vs FreeQ Series *)
t0 = AbsoluteTime[];
optTermsOrig = Table[
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
tOrig = AbsoluteTime[] - t0;
Print["Original term expansion took: ", tOrig, "s"];

t0 = AbsoluteTime[];
optTermsNew = Table[
  Block[{gVar, g, coeff, coeffExp, gExp},
    gVar = Cases[term, _G, {0, Infinity}];
    If[gVar === {},
      g = 1; coeff = term;
    ,
      g = gVar[[1]]; coeff = term / g;
    ];
    coeffExp = If[FreeQ[coeff, u], coeff, Series[coeff, {u, 0, 0}]];
    gExp = If[g === 1, 1, g /. gExpRules];
    coeffExp * gExp
  ]
, {term, termList}];
tNew = AbsoluteTime[] - t0;
Print["New term expansion took: ", tNew, "s"];
Print["Verification that results are identical: ", optTermsOrig === optTermsNew];
