filepath = DirectoryName[$InputFileName];

Get["LiteRed2`"];(*load package LiteRed2*)

(*kinematic settings*)
SetDim[d];
Declare[{l1, l2, l3, l4, p}, Vector, {u}, Number];
SetConstraints[{p}, sp[p, p] = u];

(*load bases*)
Get[filepath <> "Bases/asym/asym"];
Get[filepath <> "Bases/asym3L/asym3L"];
Get[filepath <> "Bases/asym2L/asym2L"];
Get[filepath <> "Bases/asym1L/asym1L"];

LaunchKernels[6];

Get["./asym_new.wl"];
ParallelEvaluate[Get["./asym_new.wl"]];

(* I3Lhard integrand *)
$I3LhardInt = (x[3, 6]*x[4, 5] + x[3, 5]*x[4, 6])/(x[1, 5]*x[1, 6]*x[2, 5]*x[2, 6]*x[3, 5]*x[3, 6]*x[3, 7]*x[4, 5]*x[4, 6]*x[4, 7]*x[5, 7]*x[6, 7]);

$PERMS = {{1, 2, 3, 4}, {1, 3, 2, 4}, {2, 1, 3, 4}, {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}};

RunAsymExpansionParallel["I3Lhard", $I3LhardInt, $PERMS, 3, {5, 6, 7}];
