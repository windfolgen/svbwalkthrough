(* =================================================================== *)
(*  Fixed Workflow Configuration                                       *)
(*                                                                     *)
(*  This file defines fixed paths, names, and parameters that do not   *)
(*  change across topological bootstrap runs (e.g., fourloop vs threeloop). *)
(* =================================================================== *)

(* The data directory for all SV/MPL basis and series expansion files *)
$DataDir = FileNameJoin[{rootDir, "data"}];

(* The directory to store IBP reduction files (caching for LiteRed2) *)
$IBPDir = FileNameJoin[{rootDir, "IBPReduction"}];

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

(* Mirror limits: which limits to compute in mirror steps *)
$MirrorLimits = {1, 6, 2, 3, 4, 5};

(* Mirror: whether to multiply the leading-singularity factor (addInZZ) into
   the ansatz during mirror expansion. True = multiply (default); False = the
   factor is already accounted for in the input ansatz, so skip multiplication. *)
$MirrorMultiplyLSFactor = False;

(* Mirror input files: maps ext type to a list of per-LS input files.
   None = mirror stage disabled (set in run.wl to enable).
   The list length per ext must match the number of leading singularities. *)
$MirrorInputFiles = None;

(* Max parallel subkernels for mirror agents *)
$MaxParallelKernels = 6;
