(* profile_correct4.wl *)
$HistoryLength = 0;

filepath = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/asym/";
rootDir = "/Users/windfolgen/Documents/AntiGravity/svbwalkthrough/";

Get[FileNameJoin[{filepath, "asym_test.wl"}]];

order = 4;
name = "fourloopI42_comp1_1234";

testData = Import[filepath <> "tmp/tensor_" <> name <> "_order" <> ToString[order] <> "_results.m"];
{top, top1, top2} = testData[[1]];
localTest = testData[[2]];

{grep, glist} = ClassifyGs[localTest, top1];
gtransform = Join[grep /. {G[a__] :> G[1, {a}]}, grep /. {G[a__] :> G[2, {a}]}] // Dispatch;

basischange = Import[filepath <> "asym4LbasisChange.m"] // Dispatch;

trep = Import[filepath <> "tmp/targetIntegrals_reduced.m"];
trep1 = trep /. {j[_, a__] :> G[1, {a}], G[1, a__] :> G[1, {a}]} /. {d -> 4 - 2 ep};
trep2 = trep /. {j[_, a__] :> G[2, {a}], G[1, a__] :> G[2, {a}]} /. {u -> 1} /. {d -> 4 - 2 ep};
Grep = Join[trep1, trep2] // Dispatch;

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

(* Method A: Distribute each term over Plus first *)
Print["--- Method A: Distribute each term over Plus first ---"];
t0 = AbsoluteTime[];
expandedTerms = Flatten[Table[
  Block[{dist},
    dist = Distribute[term, Plus];
    If[Head[dist] === Plus, List @@ dist, {dist}]
  ]
, {term, termList}]];
Print["  Number of expanded terms: ", Length[expandedTerms]];
Print["  Distribution took: ", AbsoluteTime[] - t0, "s"];

t1 = AbsoluteTime[];
optTermsA = Table[
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
, {term, expandedTerms}];
Print["  Expanding took: ", AbsoluteTime[] - t1, "s"];
Print["  Total Method A took: ", AbsoluteTime[] - t0, "s"];
