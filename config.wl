(* =================================================================== *)
(*  Fixed Workflow Configuration                                       *)
(*                                                                     *)
(*  This file defines fixed paths, names, and parameters that do not   *)
(*  change across topological bootstrap runs (e.g., fourloop vs threeloop). *)
(* =================================================================== *)

(* The data directory for all SV/MPL basis and series expansion files *)
$DataDir = FileNameJoin[{rootDir, "data"}];

(* LiteRed topology bases loaded by boundary_agent *)
$LiteRedBases = {"asym", "asym3L", "asym2L", "asym1L"};

(* G-matrix representation files loaded by series_agent *)
$GmaterrepFiles = {"Gmaterrep4L.m", "Gmaterrep3L.m", "Gmaterrep2L.m", "Gmaterrep1L.m"};

(* Global S4 Permutations *)
$Perms = {{1, 2, 3, 4}, {2, 1, 3, 4}, {1, 3, 2, 4}, {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}};

(* Limit points corresponding to conformal cross ratios (0, 1, infinity) *)
$Limits = {"e0", "e1", "einf"};
$LimitSuffixes = {"_inuv", "_inuvp"};

(* SVHPL Basis and Text formatting *)
$SVBasisFile = FileNameJoin[{$DataDir, "allsvlist_fourloop.m"}];
$SVTextPrefix = "allsvlist";
$SVTextSuffixes = {"_uptow8_inuv.txt", "_uptow8_inuvp.txt"};

(* MPL text formatting for series substitutions *)
$MPLTextPrefix = "allsvlistmpl_";
$MPLTextSuffixes = {"_inuv.txt", "_inuvp.txt"};
