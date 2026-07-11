(*===========================================================================*)
(*  Leading Singularity Package                                              *)
(*                                                                           *)
(*  PURPOSE                                                                  *)
(*  This package ASSISTS the user in analysing the leading singularities of  *)
(*  planar multi-loop integrands via the method of maximal cuts. It is NOT   *)
(*  a black box and does NOT replace human analysis.                         *)
(*                                                                           *)
(*  The algorithm prints a rich diagnostic trace (cut conditions, solving    *)
(*  order, Jacobians, double/higher poles, possible elliptic cuts, etc.).    *)
(*  These intermediate prints carry information that the final return value  *)
(*  alone does not capture. The user is expected to READ and CHECK them,     *)
(*  especially any warnings coloured Red (Error), Magenta (Serious), or      *)
(*  Pink (Mild), and any plain-text "higher pole" / "double pole" /          *)
(*  "elliptic cut" messages.                                                 *)
(*                                                                           *)
(*  TWO ENTRY POINTS                                                         *)
(*  - LeadingSingularities[integrand, opts]                                  *)
(*      The original human-facing driver. Prints a coloured trace to the      *)
(*      Mathematica front end for the user to inspect.                       *)
(*  - LeadingSingularityAssist[integrand, opts]                              *)
(*      An AI-friendly wrapper that runs the UNMODIFIED algorithm (only      *)
(*      Print is intercepted) and returns a structured Association with      *)
(*      classified warnings, higher-pole / elliptic-cut feature flags, and   *)
(*      the full plain-text log. Intended for automated/AI consumption.      *)
(*                                                                           *)
(*  The algorithm itself is identical in both entry points. The wrapper      *)
(*  only reorganises how diagnostics are presented; it never changes what     *)
(*  is computed.                                                             *)
(*===========================================================================*)

(*the position coordinates*)
Unprotect[x];
ClearAll[x];
x[a_, a_] := 0;
x /: x[a_] - x[b_] := x[a, b];
x /: x[a_, b_] - x[c_, b_] := x[a, c];
x /: x[a_, b_] - x[a_, c_] := x[c, b];
x /: x[a_, b_] + x[b_, c_] := x[a, c];
x /: x[a_, b_] + x[c_, a_] := x[c, b];
x[a_, b_] /; (! OrderedQ[{a, b}]) :=
Signature[{a, b}]*x[Sequence @@ (Sort[{a, b}])];
Protect[x];

Unprotect[V, VD, V2, SD];
ClearAll[V, VD, V2, SD];
SetAttributes[VD, Orderless];
V /: V[a_]*V[b_] := VD[a, b];
V /: Power[V[a_], n_ /; (EvenQ[n])] := Power[V2[a], n/2];
V[Times[n_, x[a__]]] := Times[n]*V[x[a]];
VD[0, a_] := 0;
VD[a_, a_] := V2[a];
VD[a_, b_] /; (b =!= a) :=
If[MatchQ[Evaluate[(a - b)],
        x[__] | -x[__]], -1/2*(V2[a - b] - V2[a] - V2[b]),
    If[MatchQ[Evaluate[(a + b)], x[__] | -x[__]],
        1/2*(V2[a + b] - V2[a] - V2[b]), SD[a, b]]];
V2[0] := 0;
V2[-a_] := V2[a];
Protect[V, VD, V2, SD];

ClearAll[ShowV2];
ShowV2[exp_] := exp /. {HoldPattern[V2[x[a_, b_]]] :>
    \!\(\*SubsuperscriptBox[\(x\), \(a, b\), \(2\)]\)};

ClearAll[
    PerfectSquareOut];(*split the perfect square out of a square root*)
PerfectSquareOut[expr_] := Module[{exp, list, sl = {}, nsl = {}},
    exp = expr // Factor;
    If[exp === 0, Return[{1, 0}]];
    If[Head[exp] === Power,
        If[MatchQ[exp, Power[_, _?EvenQ]],
            Return[{exp /. {Power[z_, n_] :> Power[z, n/2]}, 1}],
            Return[{exp /. {Power[z_, n_] :> Power[z, Quotient[n, 2]]},
                    exp /. {Power[z_, n_] :> z}}]]];
    If[Head[exp] === Times, list = List @@ exp, Return[{1, exp}]];
    Do[
        If[MatchQ[list[[i]], Power[_, _]],
            AppendTo[sl,
                list[[i]] /. {Power[z_, n_] :> Power[z, Quotient[n, 2]]}];
            AppendTo[nsl,
                list[[i]] /. {Power[z_, n_] :> Power[z, Mod[n, 2]]}],
            If[NumericQ[list[[i]]], AppendTo[sl, Sqrt[list[[i]]]],
                AppendTo[nsl, list[[i]]]]
        ], {i, 1, Length[list]}];
    Return[{Times @@ sl,
            Times @@ nsl}];(*sl is the perfect square after removing power,
    nsl is non-perfect square and it will remains in the square root*)
];

(*The Jacobian factor after cut for one loop momentum*)
ClearAll[Jacob];
Options[Jacob] = {"outputlevel" -> 1};
Jacob[list_, v_, OptionsPattern[]] :=
Module[{vlist, R, pow, rep, tem, jac, tag, y, sol, sim, result},
    If[OptionValue["outputlevel"] > 1,
        Print["        Calculating Jacobians for loop: ",
            Subscript[x, v]]];
    If[Length[list] =!= 4 || Count[FreeQ[#, v] & /@ list, False] =!= 4,
        Print["four conditions needed for cut of the loop: ", x[v]];
        Return[$Failed]];
    vlist =
    Cases[list, V2[a_ /; (! FreeQ[{a}, v])], Infinity] //
    DeleteDuplicates;
    If[OptionValue["outputlevel"] > 1,
        Print["        The four conditions are: ", list // ShowV2]];
    rep = Thread@Rule[vlist, R*vlist];
    pow = Exponent[#, R] & /@ (list /. rep);
    If[AnyTrue[pow, (# =!= 1) &],
        Print["        the Jacbian need to be calculated by hand: ",
            list]];
    rep =
    Thread@Rule[vlist,
        vlist /. {x -> y} /. {V2[y[a_, v]] :> -2 V[x[a, v]],
            V2[y[v, a_]] :> 2 V[x[v, a]]}];
    (*Print["rep: ",rep];(*take the derivative*)*)
    tem = list /. rep;
    (*Print["tem: ",tem];*)
    (*implement the cut condition*)
    sol = Solve[Thread@Equal[list, 0], vlist][[1]] // Quiet;
    (*Print["sol: ",sol];*)
    jac =
    Table[tem[[i]]*tem[[j]] // Expand, {i, 1, Length[tem]}, {j, 1,
            Length[tem]}] /. sol // Expand;
    sim = Det[jac - DiagonalMatrix[Diagonal[jac]]] // Factor;
    If[OptionValue["outputlevel"] > 1,
        Print["        The corresponding Jacobian matrix is: ",
            MatrixForm[jac // Factor // ShowV2]]];
    tag = ((Cases[#, HoldPattern[x[a_, v] | x[v, a_]] -> a, Infinity] //
            DeleteDuplicates) & /@ list) /. {{a_} :> a} //
    DeleteDuplicates;
    result = PerfectSquareOut[Det[jac] // Factor];
    If[FreeQ[result[[1]], V2],
        Return[{Subscript[\[Lambda], tag], {result[[1]],
                    Plus @@ {(sim/result[[1]]^2 //
                            Factor), -((sim - Det[jac])/result[[1]]^2 // Factor)}}}],
        Return[{Subscript[\[Lambda], tag], result}]];
];

ClearAll[AdmissibleCutQ];
Options[AdmissibleCutQ] = {deBug -> False};
AdmissibleCutQ[cut_, var_, replambda_, OptionsPattern[]] :=
Module[{temint, temhint, vlist, powint, powhint, rep, R},
    temint = DeleteCases[cut, _?(! FreeQ[#, \[Lambda]] &)];
    temhint = Complement[cut, temint] /. replambda;
    vlist =
    Cases[Join[temint, temhint],
        HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
        Infinity] // DeleteDuplicates;
    If[OptionValue[deBug], Print["temint: ", temint];
        Print["temhint: ", temhint]; Print["vlist: ", vlist]];
    If[Length[vlist] < 4,
        Return[False]];(*there are less than 4 variables,
    then this cannot be a complete cut*)
    rep = Thread@Rule[vlist, R*vlist];
    powint = Exponent[#, R] & /@ (temint /. rep);
    powhint = Floor[(Exponent[#, R]/2)] & /@ (temhint /. rep);
    If[Total[powint] + Total[powhint] < 4,
        Return[False]];(*the conditions are less than 4*)
    Return[True];
];

ClearAll[
    ResolveCondition];(*this is used to deal with quadratic polynomials \
in the intermediate steps*)
Options[ResolveCondition] = {"num" -> 1};
ResolveCondition[list_, var_, OptionsPattern[]] :=
Module[{pow, vlist, nvlist, R, rep, pos, result, dis, a, tem, tag,
        replam, sys, sol, exp},
    result = list;
    vlist =
    Cases[list,
        HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
        Infinity] // DeleteDuplicates;
    nvlist =
    Cases[{OptionValue["num"]},
        HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
        Infinity] // DeleteDuplicates;(*variables in the numerator*)
    rep = Thread@Rule[vlist, R*vlist];
    pow = Exponent[#, R] & /@ (list /. rep);
    If[Max[pow] < 2,
        Return[{result, {}, {}, 1}]];(*all linear polynomial,
    no need to resolve*)
    If[Count[pow, 2] == 1,
        (*only one quadratic polynomials present*)
        pos = Position[pow, 2][[1, 1]];
        (*this quadratic polynomial may need simplificatopn*)
        sys = Thread@Equal[Delete[list, pos], 0];
        sol = Solve[sys, vlist][[1]] // Quiet;
        exp = list[[pos]] /. sol // Factor;
        vlist =
        Cases[{exp},
            HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
            Infinity] // DeleteDuplicates;
        If[Intersection[nvlist, vlist] === {},
            Print[
                Style["        variabels do not exist in the numerator. solve \
                    either one: ", Magenta], vlist],
            vlist = Intersection[nvlist, vlist];
            Print[Style["        solve variable: ", Magenta], vlist];
        ];
        result[[pos]] =
        D[exp, vlist[[1]]];(*replace it with the derivative,
        but we need to balance the power with its discriminant*)
        a = Coefficient[exp, vlist[[1]], 2];
        dis = PerfectSquareOut[Discriminant[exp, vlist[[1]]]];
        tem =
        List @@ (Times @@ Join[result, {dis[[1]]}]) //
        DeleteCases[#, _?NumericQ] &;
        tag = {Cases[dis[[2]], HoldPattern[x[a_, b_]] -> {a, b},
                Infinity] // Flatten // DeleteDuplicates,
            Hash[dis[[2]], "Expression"]};
        replam = Rule[Subscript[\[Lambda], tag], dis[[2]]];
        tem =
        Append[tem, Subscript[\[Lambda], tag]] //
        GatherBy[#, (FreeQ[#,
                    HoldPattern[x[_, var]] | HoldPattern[x[var, _]]]) &] & //
        SortBy[#, (FreeQ[#,
                    HoldPattern[x[_, var]] | HoldPattern[x[var, _]]]) &] &;
        Return[{tem[[1]], Drop[tem, 1] // Flatten, {replam}, a}],
        Print[
            Style["        2 or more quadratic polynomials!", Red, " list: ",
                list]; Return[{result, {}, {}, 1}]]
    ]
];

ClearAll[ReOrganize];(*reorganize the square roots involved*)
ReOrganize[tem2_] := Module[{rl, sl, nsl},
    If[tem2 === {}, Return[{{}, {}}]];
    rl = tem2[[All, 1]];
    sl = tem2[[All, 2]];
    nsl = PerfectSquareOut[Times @@ sl];
    rl = Append[rl, nsl[[1]]];
    nsl = If[Head[nsl[[2]]] === Times, List @@ nsl[[2]], {nsl[[2]]}];
    Return[{rl, nsl // DeleteCases[#, _?NumericQ] &}];
];

ClearAll[CutOneLoop];
Options[CutOneLoop] = {deBug -> True};
CutOneLoop[cutlist_, numlist_, var_, replambda_, remain_,
    OptionsPattern[]] :=
Catch@Module[{select, subset, i, jacob, tem, temvar, tem1, tem2, tem22,
        tem3, temlist, den, num, sol, temsol, sys, const, j, k, l, s, tag,
        replam = {}, result, num1, den1, temsys, temsys1, temsys2, sqrt,
        mark, temmark, temnum, checksol = {}, checkps},
    Print["    cut ", cutlist, " for ", Subscript[x, var],
        ". numerator: ", Style[Times @@ numlist, RGBColor[0.4, 0.53, 1.]]];
    select = Select[cutlist, Not@FreeQ[#, var] &];
    subset =
    Select[Subsets[select, 4],
        AdmissibleCutQ[#, var,
            replambda] &];(*we choose proper subset that can contribute 4 \
    conditions, some lower sets can also contribute 4 conditions*)
    Print["    totally ", Length[subset], " cases:"];
    (*If[subset==={},Print["select: ",select];Print["replambda: ",
    replambda]];*)
    result = Reap[
        Do[
            Print[Style["        case ", Orange, 15], i, ": ",
                subset[[i]]];
            tem1 = DeleteCases[subset[[i]], _?(! FreeQ[#, \[Lambda]] &)];
            tem2 = (Cases[subset[[i]], _?(! FreeQ[#, \[Lambda]] &)]) /.
            replambda;(*terms related to square roots*)
            tem3 = (Cases[{#},
                    HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
                    Infinity] // DeleteDuplicates) & /@ Join[tem1, tem2];
            temvar =
            Flatten[tem3] //
            DeleteDuplicates;(*the variables involving loop momenta*)
            If[Length[temvar] < 4,
                Print["        variable not enough. temvar: ", temvar];
                Continue[]];(*variables less than 4, not solvable*)

            sys = tem1;(*initial cut system.
            cut terms which are not square roots*)
            If[OptionValue[deBug], Print["temvar: ", temvar];
                Print["initial sys: ", sys]];
            sol = Solve[Thread@Equal[sys, 0], temvar][[1]] // Quiet;
            k = 1;
            const = {};(*keep track of constant terms*)
            checksol = {};(*this solution can be used to check some \
            cancellation between numerator and denominator*)
            While[
                Length[sol] < 4 && k < 5,(*when the solution is not enough,
                we substitute the initial solution into remaining square \
                roots*)
                If[Length[subset[[i]]] >= 4 && tem2 === {},

                    Print[Style["        the conditions may be not enough for ",
                            Magenta], Subscript[x, var], ". cut list: ", cutlist,
                        " sublist: ", subset[[i]]]
                ];(*this is for the case where expression under square \
                roots are also used but the condition is still not enough*)


                tem22 = PerfectSquareOut /@ (tem2 /.
                    sol);(*take care of cases where the square root is 0 \
                under current solution*)

                If[MemberQ[tem22, {1, 0}],(*if the cut is 0,
                    then we add the expression with less cut to the system*)

                    Print[Style["        square root is 0", Magenta],
                        " need less cut for the polynomial under square root: ",
                        Short[tem2, 20]];
                    s = 1;
                    While[MemberQ[tem22, {1, 0}] && s < Length[sol],
                        tem22 = PerfectSquareOut /@ (tem2 /. Drop[sol, -s]);

                        checksol =
                        Drop[sol, -s];(*this solution can be used to check some \
                        cancellation between numerator and denominator*)
                        s = s + 1;
                    ];

                    If[MemberQ[tem22, {1, 0}],
                        Print[Style[
                                "        something is wrong! this square root is 0 from \
                                the beginning: ", Red], Complement[subset[[i]], tem1]]];
                    tem2 = tem22
                    ,
                    tem2 = tem22
                ];

                tem2 = ReOrganize[
                    tem22];(*in case two square roots coincide with each other,
                tem2 is reorganized that tem[[
                1]] is the rational list and tem[[2]] is the square roots*)

                checkps =
                Select[tem2[[1]],
                    IntersectingQ[
                        Cases[{#},
                            HoldPattern[V2[x[_, var]]] | HoldPattern[V2[x[var, _]]],
                            Infinity],
                        temvar] &];(*check whether double pole exist*)

                If[Not@FreeQ[Times @@ checkps // Factor,
                        Power[_, _?(# > 1 &)], {0, 1}] && checksol === {},

                    Print["        double pole find!", " checkps: ", checkps,
                        " sol: ", sol];
                    checksol = sol;];(*when there is a double pole,
                we record the solution before solve this double pole,
                since the numerator can cancel the pole after substituting \
                the solution recorded*)

                const = Join[const,
                    Select[tem2[[1]],
                        Not@
                        IntersectingQ[
                            Cases[{#},
                                HoldPattern[V2[x[_, var]]] |
                                HoldPattern[V2[x[var, _]]], Infinity], temvar] &]];

                If[Complement[tem2[[1]], const] === {}, tem2 = tem2[[2]];
                    Break[]];(*no new conditions*)
                sys = Join[sys, checkps];
                sol = Solve[Thread@Equal[sys, 0], temvar] // Quiet;

                If[sol === {},
                    Print[Style["        no solution! check the system: ", Red],
                        sys, " temvar: ", temvar],
                    If[Length[sol] > 1,
                        sol = (sol // SortBy[#, LeafCount] &)[[1]];

                        Print["        multiple solutions exist! pick up the \
                            simpler one: ", sol],
                        sol = sol[[1]]]];
                tem2 = tem2[[2]] // DeleteCases[#, _?NumericQ] &;
                k = k + 1;
            ];
            If[
                Length[sol] < 4 &&
                tem2 =!= {},(*if the solution is still not enough after \
                solving the square roots*)

                Print[Style["        the condition is not enough for ", Red],
                    Subscript[x, var], ". sys : ", sys];

                Print[Style["        original square root is: ", Cyan],
                    Complement[subset[[i]], tem1] /. replambda /. sol //
                    Factor];
                Print[Style["        the remaining square root is: ", Cyan],
                    tem2]; Print[
                    Style["        you may need to consider cutting two loops \
                        in the same time or this is a elliptic cut!", Cyan], " cut list: ",
                    cutlist];
                Continue[]
            ];
            replam = replambda;
            sys = Join[sys, const];
            If[OptionValue[deBug], Print["sys: ", sys]];
            If[tem2 =!= {},

                If[Not@FreeQ[tem2, HoldPattern[x[_, var]]] ||
                    Not@FreeQ[tem2, HoldPattern[x[var, _]]],

                    Print[Style["        this case need to be solved by hand!",
                            Red], " sys: ", sys, " square root: ", tem2];
                    Continue[]
                ];

                Print[Style["        additional square roots present: ",
                        RGBColor[0.52, 0.54, 1.]], Sqrt[ShowV2[tem2]]];

                tag = ({Cases[#, HoldPattern[x[a_, b_]] -> {a, b},
                            Infinity] // Flatten // DeleteDuplicates,
                        Hash[#, "Expression"]}) & /@ tem2;

                replam =
                Join[replam,
                    Thread@Rule[Subscript[\[Lambda], #] & /@ tag, tem2]];

                sys = Join[sys,
                    Subscript[\[Lambda], #] & /@
                    tag];(*add square root parts back!*)
            ];
            (*sometimes there are more conditions than 4 in the sys!(some \
            may be cancelled by numerator). in this case,
            we should split them and re-calculate*)
            num = Times @@ numlist;
            If[checksol =!= {},
                num = num /. checksol;

                If[num ===
                    0 && ((Times @@ (Complement[select, subset[[i]]]) /.
                            checksol) =!= 0),
                    Print[Style["        this cut is 0. check it: ", Magenta],
                        "sys: ", sys, " select: ", select, "numerator: ",
                        Times @@ numlist],

                    If[num === 0, num = Times @@ numlist,
                        Print["        numerator simplified from ",
                            Times @@ numlist, " to ", num]]]
            ];(*in this case,
            the denominator is given after substituting checksol so the \
            numerator should also substitute the value*)
            den =
            Times @@
            Select[List @@ Times @@ sys,
                MatchQ[#,
                    Power[_, _?(# >
                            1 &)]] &];(*higher pole must be cancelled by \
            numerator*)
            If[den =!= 1,

                Print["        higher power pole encountered, it should be \
                    cancelled by numerator: ", den];];
            tem = num/(den) // Cancel;
            num = Numerator[tem];
            den = (Times @@ sys)*Denominator[tem]/den;
            If[Head[den] =!= Times,

                Print[Style[
                        "        the numerator cancels most of the denominator. \
                        cut condition is not enough: ", Red], tem];
                Continue[],
                sys = List @@ den;
            ];
            temsys =
            sys // Flatten // DeleteCases[#, _?NumericQ] & //
            GatherBy[#, (FreeQ[#,
                        HoldPattern[x[_, var]] |
                        HoldPattern[x[var, _]]]) &] & //
            SortBy[#, (FreeQ[#,
                        HoldPattern[x[_, var]] |
                        HoldPattern[x[var, _]]]) &] &;
            If[OptionValue[deBug], Print["temsys: ", temsys]];
            If[Not@FreeQ[temsys[[1]], Power[Plus[__], 2],1], Print[" higher pole not cancelled: ", temsys[[1]]]; Throw[{}]];
            If[Length[temsys[[1]]] < 4,
                (*replace the quadratic conditions with linear ones*)
                tem = ResolveCondition[temsys[[1]], var, "num" -> num];
                temsys[[1]] = tem[[1]];
                temsys1 = Subsets[tem[[1]], {4}];(*cut equations*)

                temsys2 =
                Join[Drop[temsys, 1] // Flatten, tem[[2]]];(*constant terms*)
                replam = Join[replam, tem[[3]]];(*replacement rule*)
                num = num*tem[[4]];(*numerator*)

                Print[Style["        the cut condition has been resolved!",
                        Magenta], " sys: ", tem],
                temsys1 = Subsets[temsys[[1]], {4}];
                temsys2 = Drop[temsys, 1] // Flatten;
            ];
            Print[
                "        the condition of cuts can be further split into: ",
                ShowV2[temsys1]];
            Print["        the constant term is ", Times @@ temsys2];

            temnum = num;
            Do[
                sys = temsys1[[l]];

                sol = Solve[Thread@Equal[sys, 0], temvar][[1]] //
                Quiet;(*pick up 4 and solve them*)
                jacob = Jacob[sys, var, "outputlevel" -> 2];
                replam = Join[replam, {Rule[jacob[[1]], jacob[[2, 2]]]}];
                (*substitute solutions into the remaining expressions after \
                cut*)

                den = Join[
                    Complement[cutlist, subset[[i]]], {jacob[[1]],
                        jacob[[2, 1]]}, temsys2(*constant term*),
                    Complement[temsys[[1]], sys](*terms not cut*)];
                num = temnum;

                If[OptionValue[deBug], Print["den: ", den];
                    Print["num: ", num]];
                tem1 = DeleteCases[den, _?(! FreeQ[#, \[Lambda]] &)];
                tem2 = Cases[den, _?(! FreeQ[#, \[Lambda]] &)];

                tem1 = Join[tem1,
                    DeleteCases[
                        tem2, _?(!
                            FreeQ[#,
                                var] &)]];(*terms not relevant to square root of \
                current loop*)
                sqrt = Cases[tem2, _?(! FreeQ[#, var] &)] /. replam;

                tem2 = PerfectSquareOut /@ (sqrt /.
                    sol);(*square roots relevant to the current loop \
                momentum*)

                If[MemberQ[
                        tem2, {1,
                            0}],(*some square roots can be 0 under the solution*)
                    mark = 0;

                    Print[Style["        square root is 0", Magenta],
                        " be careful of the expression under square root: ",
                        sqrt],
                    mark = 1;(*if it is not 0,
                    the expression will be merged with the main part*)

                    If[Not@FreeQ[tem2[[All, 2]],
                            HoldPattern[x[_, var]] |
                            HoldPattern[
                                x[var, _]]],(*if some remaining expression for this \
                        loop momentum is not solved*)

                        Print[Style[
                                "        the loop momentum has not been totally solved: \
                                ", Red], Subscript[x, var], " sol: ", sol,
                            " remaining expression under square root: ", tem2];
                        Continue[];
                    ];
                    tem1 = Join[tem1, tem2[[All, 1]]];
                    tem3 = (tem2[[All, 2]] // DeleteCases[#, _?NumericQ] &);

                    If[tem3 =!= {},(*there are remaining terms under square \
                        roots after substituting the solution*)

                        tag = ({Cases[#, HoldPattern[x[a_, b_]] -> {a, b},
                                    Infinity] // Flatten // DeleteDuplicates,
                                Hash[#, "Expression"]}) & /@ tem3;

                        replam =
                        Join[replam,
                            Thread@Rule[Subscript[\[Lambda], #] & /@ tag, tem3]];
                        tem1 = Join[tem1, Subscript[\[Lambda], #] & /@ tag];
                    ];
                ];
                den = Times @@ tem1;
                tem = {num, den*mark} /. sol // Factor;
                If[tem === {0, 0},

                    Print[Style[
                            "        indeterminant encountered! the solving order is \
                            important: ", Pink]];

                    tem1 = Subsets[
                        sys, {3}];(*here we assume one cut less can save the 0/
                    0 danger*)
                    Do[

                        temsol =
                        Solve[Thread@Equal[tem1[[j]], 0], temvar][[1]] // Quiet;
                        If[mark === 0,(*when the square root is 0*)
                            tem2 = PerfectSquareOut /@ (sqrt /. temsol);
                            If[MemberQ[tem2, {1, 0}],
                                temmark = 0,
                                temmark = Times @@ (tem2[[All, 1]]);
                                tem3 = (tem2[[All, 2]] // DeleteCases[#, _?NumericQ] &);

                                If[tem3 =!= {},(*there are remaining terms under square \
                                    roots after substituting the solution*)

                                    tag = ({Cases[#, HoldPattern[x[a_, b_]] -> {a, b},
                                                Infinity] // Flatten // DeleteDuplicates,
                                            Hash[#, "Expression"]}) & /@ tem3;

                                    replam =
                                    Join[replam,
                                        Thread@Rule[Subscript[\[Lambda], #] & /@ tag, tem3]];
                                    temmark =
                                    temmark*(Times @@ (Subscript[\[Lambda], #] & /@ tag))
                                ];
                            ],
                            temmark = 1;
                        ];
                        tem = ({num, den*temmark} /. temsol // Factor);
                        If[tem === {0, 0} || MatchQ[tem, {_, 0}],
                            Continue[],

                            Print[Style["            one solving order identified: ",
                                    Pink], temsol];
                            tem = tem[[1]]/tem[[2]] // Factor;

                            If[tem ===
                                0 || (((Numerator[tem] /. sol) ===
                                        0) && ((Denominator[tem] /. sol) =!= 0)),
                                Print["        this cut is 0."];
                                Continue[]];(*this cut is 0*)

                            If[Not@FreeQ[tem,
                                    HoldPattern[x[_, var]] |
                                    HoldPattern[
                                        x[var, _]]],(*if some remaining expression for this \
                                loop momentum is not solved*)

                                Print[Style[
                                        "        the loop momentum has not been totally \
                                        solved: ", Red], Subscript[x, var], " sol: ", sol,
                                    " remaining {den,num}: ", {den*temmark, num},
                                    " num/den: ", tem];
                                Continue[];
                            ];
                            num1 = Numerator[tem];
                            den1 = Denominator[tem];

                            If[Head[num1] === Times, num1 = List @@ num1,
                                num1 = {num1}];

                            If[Head[den1] === Times, den1 = List @@ den1,
                                den1 = {den1}];

                            Print[Style["        the remaining expression is ", Blue],
                                TableForm[{Times @@ den1, Times @@ num1}]];

                            Sow[{den1 // DeleteCases[#, _?NumericQ] &,
                                    num1 // DeleteCases[#, _?NumericQ] &, replam,
                                    Complement[remain, {var}]}]
                        ];
                        , {j, 1, Length[tem1]}];
                    Continue[];
                ];
                If[tem[[2]] === 0, Print["        higher pole not canceled!"]; Throw[{}]];
                tem = tem[[1]]/tem[[2]] // Factor;

                If[Not@FreeQ[tem,
                        HoldPattern[x[_, var]] |
                        HoldPattern[
                            x[var, _]]],(*if some remaining expression for this \
                    loop momentum is not solved*)

                    Print[Style[
                            "        the loop momentum has not been totally solved: ",
                            Red], Subscript[x, var], " sol: ", sol,
                        " remaining {den,num}: ", {den, num}, " num/den: ", tem];
                    Continue[];
                ];

                If[tem === 0, Print["        this cut is 0."];
                    Continue[]];(*this cut is 0*)
                num1 = Numerator[tem];
                den1 = Denominator[tem];

                If[Head[num1] === Times, num1 = List @@ num1,
                    num1 = {num1}];

                If[Head[den1] === Times, den1 = List @@ den1,
                    den1 = {den1}];

                Print[Style["        the remaining expression is ", Blue],
                    TableForm[{Times @@ den1, Times @@ num1}]];

                Sow[{den1 // DeleteCases[#, _?NumericQ] &,
                        num1 // DeleteCases[#, _?NumericQ] &, replam,
                        Complement[remain, {var}]}]
                , {l, 1, Length[temsys1]}];

            , {i, 1, Length[subset]}];
    ][[2]];
    If[result =!= {}, Throw[result[[1]]], Throw[{}]];
];

ClearAll[ResolveOrder];(*resolve the solving order of loop momenta*)
Options[ResolveOrder] = {"order" -> 0};
ResolveOrder[den_, num_, loops_, OptionsPattern[]] :=
Module[{var, numlabel, denlabel, slist, order},
    numlabel =
    Cases[{#}, HoldPattern[x[a_, b_]] -> {a, b}, Infinity] & /@ num //
    Flatten[#, 1] &;
    denlabel =
    Cases[den, Subscript[\[Lambda], a_] :> (a // Flatten), Infinity];
    (*Print["numlabel: ",numlabel];
    Print["numlabel: ",denlabel];*)
    slist = Reap[
        Do[
            If[AnyTrue[denlabel, ContainsAll[#, numlabel[[j]]] &],
                Sow[numlabel[[j]]]]
            , {j, 1, Length[numlabel]}]
    ][[2]];
    If[slist === {},
        Print["       There may be no solvable order of variables:",
            "den: ", den, "num: ", num], slist = slist[[1]]];
    order =
    Table[{Count[FreeQ[#, loops[[i]]] & /@ num,
                False], -Count[FreeQ[#, loops[[i]]] & /@ slist,
                False], -Count[FreeQ[#, loops[[i]]] & /@ denlabel, False],
            loops[[i]]}, {i, 1, Length[loops]}] //
    SortBy[#, {First, #[[2]] &, #[[3]] &}] &;
    If[OptionValue["order"] == 0, Return[order[[All, -1]]],
        Return[order[[All, -1]] // Reverse]];
];

ClearAll[LeadingSingularities];
Options[LeadingSingularities] = {deBug -> False, "outputlevel" -> 2,
    "external" -> {1, 2, 3, 4}, "order" -> 0};
LeadingSingularities[integrand_, OptionsPattern[]] :=
Module[{graph, agraph, sgraph, edgeden, edgenum, loops, tem, pos,
        tem1, tem2, remain, k = 1, l, cutlist, numlist, temcut, temnum,
        jacob, replambda = {}, subset, temrep, ls},
    If[Head[Denominator[integrand]] === Plus ||
        Head[Numerator[integrand]] === Plus,
        Print["The denominator or numerator should be monomial!"];
        Return[$Failed]];
    edgeden =
    UndirectedEdge @@@ (Cases[Denominator[integrand],
            HoldPattern[x[_, _]], Infinity]);
    edgenum =
    UndirectedEdge @@@ (Cases[Numerator[integrand],
            HoldPattern[x[_, _]], Infinity]);
    graph =
    Graph[Join[edgeden, edgenum], VertexLabels -> "Name",
        VertexStyle -> Thread@Rule[OptionValue["external"], Red],
        EdgeStyle -> Thread@Rule[edgenum, Dashed]];
    (*Print["the graph: ",graph];*)
    Print["denom graph: ",
        Graph[edgeden, VertexLabels -> "Name",
            VertexStyle -> Thread@Rule[OptionValue["external"], Red]]];
    loops = Complement[VertexList[graph], OptionValue["external"]];
    Print["the loop variables are ", Subscript[x, #] & /@ loops];
    cutlist = (V2 /@ edgeden) /. {UndirectedEdge ->
        x};(*the candidated to be cut is set to denominators at first*)
    numlist =
    If[Head[Numerator[integrand]] === Times,
        List @@ Numerator[integrand], {Numerator[
                integrand]}] /. {HoldPattern[x[a_, b_]] :>
        V2[x[a, b]]};(*the numerator list records the numerators which \
    may be useful in the multivariate cut*)
    (*given an integrand,
    we first choose some one which can be integrated out directly*)
    tem = VertexDegree[graph, #] & /@ loops;
    If[Min[tem] < 4,
        Print["the input is wrong! degree of ",
            Subscript[x, #] & /@ (Position[tem, Min[tem], 1] // Flatten),
            " is not enough!"]; Return[$Failed],
        pos = Position[tem, 4, 1] // Flatten;
        If[pos === {},
            Print["no loop variable can be integrated out first!"];
            Return[$Failed]];
        tem1 =
        loops[[pos]];(*possible loop variables that can be directly \
        integrated out*)
        (*If[OptionValue[deBug],Print["tem1: ",tem1]];*)
        If[Length[pos] == 1,
            Print[Style["Step", 18], " 1: integrate ",
                Subscript[x, tem1[[1]]], " first."],
            agraph =
            VertexDelete[graph,
                OptionValue["external"]];(*graph with external points deleted*)
            (*check the connectivity among the remaining loop variables*)
            tem2 = {Length[
                    Intersection[VertexComponent[agraph, {#}, 1],
                        tem1]], #} & /@ tem1 // SortBy[#, First] &;
            (*then we select loop variables in above list to integrate it \
            out*)
            remain = tem2[[All, 2]];
            k = 1;
            (*If[OptionValue[deBug],Print["remain: ",remain]];*)
            tem1 = Reap[
                While[remain =!= {} && k < 5,
                    Sow[remain[[1]]];

                    remain =
                    Complement[remain,
                        VertexComponent[agraph, {remain[[1]]}, 1]];
                    k = k + 1;
                ]
            ][[2, 1]];
            Print[Style["Step", 18], " 1: integrate ",
                Subscript[x, #] & /@ tem1, " first."]
        ];
    ];
    (*next we integrate the loops selected out*)
    Do[
        tem = Select[cutlist, ! FreeQ[#, tem1[[i]]] &];
        If[Length[tem] =!= 4,
            Print["    something is wrong! the condition for ",
                Subscript[x, tem1[[i]]], " is not 4"]];
        cutlist = DeleteCases[cutlist, _?(MemberQ[tem, #] &)];
        jacob = Jacob[tem, tem1[[i]], "outputlevel" -> 2];
        AppendTo[replambda,
            Rule[jacob[[1]],
                jacob[[2, 2]]]];(*replacement rule for abbreviation*)
        cutlist = (FactorList[#][[All, 1]] & /@
            Join[cutlist, {jacob[[1]], jacob[[2, 1]]}]) // Flatten //
        DeleteCases[#, _?NumericQ] &;
        , {i, 1, Length[tem1]}];
    If[OptionValue["outputlevel"] == 1,
        Return[{cutlist, numlist, replambda}]];

    (*now we continue to integrate out loop variables one by one*)
    loops = Complement[loops, tem1];
    remain = loops;
    cutlist = {{cutlist, numlist, replambda, remain}};
    k = 2;
    While[remain =!= {} && k < 8,
        Print["    remaining loops: ", remain,
            " length of remaining term: ", Length[cutlist]];
        Print[Style["Step ", 18], k, " : cut the ",
            Switch[k, 2, "2nd", 3, "3rd", _, ToString[k] <> "-th"],
            " loop variable. "];
        tem2 = Reap[
            Do[
                temcut = cutlist[[l, 1]];
                temnum = cutlist[[l, 2]];
                remain = cutlist[[l, 4]];
                tem =
                Table[{Count[FreeQ[#, remain[[i]]] & /@ temcut, False],
                        remain[[i]]}, {i, 1, Length[remain]}] //
                SortBy[#,
                    First] &;(*count the number for every remaining loop*)
                Print[Style["the ", Orange, 15],
                    Switch[l, 1, "1st", 2, "2nd", 3, "3rd", _,
                        ToString[l] <> "-th"], " cut:"];
                If[Max[tem[[All, 1]]] < 4,
                    Print[Style["    the cut condition may be not enough!",
                            Magenta], " cutlist: ", cutlist[[l]]];];
                pos = FirstPosition[tem[[All, 1]], 4];
                If[pos === Missing["NotFound"],

                    tem = ResolveOrder[temcut, temnum, remain,
                        "order" -> OptionValue["order"]];(*in this case,
                    we order the loop momentum so that it can be solved in the \
                    next step*)

                    tem1 = CutOneLoop[temcut, temnum, tem[[1]], cutlist[[l, 3]],
                        remain, deBug -> OptionValue[deBug]];

                    If[tem1 === {},
                        Print[Style["    no cut detected for loop ", Red],
                            Subscript[x, tem[[1]]]]];
                    Sow[tem1];
                    remain = Complement[remain, {tem[[1]]}],

                    tem1 = CutOneLoop[temcut, temnum, tem[[pos[[1]], 2]],
                        cutlist[[l, 3]], remain, deBug -> OptionValue[deBug]];

                    If[tem1 === {},
                        Print[Style["    no cut detected for loop ", Red],
                            Subscript[x, tem[[pos[[1]], 2]]]]];
                    Sow[tem1];
                    remain = Complement[remain, {tem[[pos[[1]], 2]]}]
                ];
                , {l, 1, Length[cutlist]}]
        ][[2]];
        If[tem2 =!= {}, tem2 = Flatten[tem2[[1]], 1]];
        cutlist = tem2;
        Print["    number of cut got: ", Length[cutlist]];
        k = k + 1;
    ];
    If[Length[OptionValue["external"]] > 4, Return[cutlist]];
    Print[Style["Last Step: ", 18],
        " expressing the leading singularities with u and v. ", "u=",
        ShowV2[(V2[x[1, 2]]*V2[x[3, 4]])/(V2[x[1, 3]]*V2[x[2, 4]])], "v=",
        ShowV2[(V2[x[1, 4]]*V2[x[2, 3]])/(V2[x[1, 3]]*V2[x[2, 4]])]];
    ls = Reap[
        Do[
            temnum = (Times @@ cutlist[[i, 2]]) /. {V2[x[1, 2]] ->
                u*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[3, 4]],
                V2[x[1, 4]] -> v*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[2, 3]]};
            temrep =
            Thread@Rule[
                Keys[cutlist[[i,
                            3]]], (#[[1]]*
                    Sqrt[#[[2]]]) & /@ (PerfectSquareOut /@ (Values[
                            cutlist[[i, 3]]] /. {V2[x[1, 2]] ->
                            u*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[3, 4]],
                            V2[x[1, 4]] ->
                            v*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[2, 3]]}))];(*
            replacement for \[Lambda]s *)
            temcut = (Times @@ cutlist[[i, 1]] /. temrep) /. {V2[x[1, 2]] ->
                u*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[3, 4]],
                V2[x[1, 4]] -> v*V2[x[1, 3]]*V2[x[2, 4]]/V2[x[2, 3]]};
            If[temcut === 0, Print["    higher poles not canceled through Jacobian factor! ", cutlist[[i]]]; Continue[]];
            Sow[temnum/temcut // Factor]
            , {i, 1, Length[cutlist]}]
    ][[2]];
    If[ls =!= {},
        If[OptionValue["outputlevel"] != 2,
            Return[{ls[[1]], cutlist[[All, 3]]}], Return[ls[[1]]]];,
        Return[{}]];
];

(* =================================================================== *)
(*  AI-friendly wrapper                                                *)
(*                                                                     *)
(*  LeadingSingularityAssist runs the UNMODIFIED LeadingSingularities  *)
(*  algorithm and returns a structured Association suitable for        *)
(*  machine consumption: status, the leading singularities,            *)
(*  classified diagnostics (by the same colour severity used by the    *)
(*  human printer), milestones, and the full plain-text log.           *)
(*                                                                     *)
(*  RULE: this wrapper must NEVER alter the cut / solve / Jacobian     *)
(*  algorithm of LeadingSingularities. It only intercepts the          *)
(*  diagnostic Print stream and re-presents it. Any change to the      *)
(*  algorithm itself requires explicit approval from the user.         *)
(* =================================================================== *)

ClearAll[LSAssistColorQ, LSAssistStringify, LSAssistClassify,
    LSAssistBag, LSAssistCapturePrint, LSAssistExtractFeatures,
    LeadingSingularityAssist];

Options[LeadingSingularityAssist] = Options[LeadingSingularities];

(* colour predicate tolerant to integer/real components and to the    *)
(* held-symbol form (Red/Magenta/Pink)                                *)
LSAssistColorQ[c_, {r_?NumericQ, g_?NumericQ, b_?NumericQ}] :=
    MatchQ[c, HoldPattern[RGBColor[rr_, gg_, bb_]] /;
        Abs[N[rr] - r] < 0.02 && Abs[N[gg] - g] < 0.02 && Abs[N[bb] - b] < 0.02] ||
    (c === Red && r === 1 && g === 0 && b === 0) ||
    (c === Magenta && r === 1 && g === 0 && b === 1) ||
    (c === Pink && r === 1 && g === 0.5 && b === 0.5);

(* stringify a printed expression: drop Style wrappers, replace       *)
(* bulky Graph / MatrixForm objects by placeholders, truncate         *)
LSAssistStringify[expr_] := Module[{s},
    s = ToString[expr /. {
            HoldPattern[Style[e_, ___]] :> e,
            HoldPattern[Graph[___]] :> "<graph>",
            HoldPattern[MatrixForm[___]] :> "<matrix>"},
        InputForm];
    If[StringLength[s] > 300,
        StringTake[s, 300] <> " <...>", s]
];

(* classify a single Print call by the most severe colour it carries  *)
(* severity order: Error > Serious > Mild > Info > Plain              *)
LSAssistClassify[args_List] := Module[{colors},
    colors = Cases[Flatten[{args}, 1],
        HoldPattern[Style[_, col_]] :> col, Infinity];
    Which[
        AnyTrue[colors, LSAssistColorQ[#, {1, 0, 0}] &], "Error",
        AnyTrue[colors, LSAssistColorQ[#, {1, 0, 1}] &], "Serious",
        AnyTrue[colors, LSAssistColorQ[#, {1, 0.5, 0.5}] &], "Mild",
        colors =!= {}, "Info",
        True, "Plain"]
];

(* accumulator for captured diagnostic records. A plain list is used   *)
(* deliberately instead of Sow/Reap, because LeadingSingularities and  *)
(* CutOneLoop use Reap/Sow internally to collect cut results; using    *)
(* Sow here would corrupt those results and be swallowed by the        *)
(* algorithm's own Reap. Appending to a list avoids any interference.  *)
LSAssistBag = {};

(* Print replacement: append a structured record to LSAssistBag,      *)
(* return Null.                                                       *)
LSAssistCapturePrint[args___] := (
    LSAssistBag = Append[LSAssistBag,
        <|"Severity" -> LSAssistClassify[{args}],
          "Text" -> StringJoin[LSAssistStringify /@ {args}]|>];
    Null);

(* =================================================================== *)
(*  Feature extraction: higher poles (incl. double poles), elliptic    *)
(*                                                                     *)
(*  These features are printed by the algorithm as PLAIN text          *)
(*  (double/higher pole) or as CYAN Info (elliptic), so they are       *)
(*  NOT caught by the colour-based severity classifier above.          *)
(*  This function scans the record texts for specific keyword          *)
(*  patterns and returns dedicated flags + the relevant records so     *)
(*  an AI consumer can label the integrand without re-reading the      *)
(*  entire log.                                                        *)
(*                                                                     *)
(*  NOTE: a double pole is a higher pole of order 2, so double-pole    *)
(*  records are merged into the higher-pole category rather than       *)
(*  tracked separately.                                                *)
(* =================================================================== *)

LSAssistExtractFeatures[records_] := Module[{
        hpRecs, hpUncancelled,
        ellMainRecs, ellSqRecs, ellInfo},

    (* --- Higher pole (includes double pole) --- *)
    (* All plain (no colour). Five distinct prints, all merged here:   *)
    (*   1. "double pole find! checkps: <..> sol: <..>"  — the         *)
    (*      denominator contains a squared V2 factor (a pole of        *)
    (*      order 2). The algorithm then tries to cancel it against    *)
    (*      the numerator.                                             *)
    (*   2. "higher power pole encountered, it should be cancelled     *)
    (*      by numerator: <den>"  — a higher pole was found and the    *)
    (*      algorithm expects the numerator to cancel it.              *)
    (*   3. "higher pole not cancelled: <expr>"  → Throw[{}], case     *)
    (*      fails. The higher pole survived.                           *)
    (*   4. "higher pole not canceled!"  → Throw[{}], case fails.      *)
    (*   5. "higher poles not canceled through Jacobian factor!        *)
    (*      <cutlist>"  → Continue[], this cut is skipped at the       *)
    (*      final cross-ratio step.                                     *)
    (* We match both British "cancelled" and American "canceled".      *)
    hpRecs = Select[records,
        StringContainsQ[#["Text"], "double pole", IgnoreCase -> True] ||
        (StringContainsQ[#["Text"], "higher", IgnoreCase -> True] &&
         StringContainsQ[#["Text"], "pole", IgnoreCase -> True]) &];
    hpUncancelled = AnyTrue[hpRecs,
        StringContainsQ[#["Text"], "not cancel", IgnoreCase -> True] &];

    (* --- Possible elliptic cut --- *)
    (* Three consecutive CYAN prints appear when the solution is       *)
    (* insufficient after resolving square roots:                      *)
    (*   1. "original square root is: <expr>"                           *)
    (*   2. "the remaining square root is: <expr>"                      *)
    (*   3. "you may need to consider cutting two loops in the same     *)
    (*      time or this is a elliptic cut! cut list: <cutlist>"        *)
    (* The trigger is print 3. Prints 1-2 give the square-root context *)
    (* (the radicand of the elliptic curve). The "cut list" in print 3 *)
    (* identifies the cut that generates the elliptic curve.           *)
    ellMainRecs = Select[records,
        StringContainsQ[#["Text"], "elliptic", IgnoreCase -> True] ||
        StringContainsQ[#["Text"], "cutting two loops", IgnoreCase -> True] &];
    ellSqRecs = Select[records,
        StringContainsQ[#["Text"], "original square root is", IgnoreCase -> True] ||
        StringContainsQ[#["Text"], "remaining square root is", IgnoreCase -> True] &];
    ellInfo = Join[ellSqRecs, ellMainRecs];

    <|"HasHigherPole" -> hpRecs =!= {},
      "HigherPoleUncancelled" -> hpUncancelled,
      "HigherPoleRecords" -> hpRecs,
      "HasPossibleElliptic" -> ellMainRecs =!= {},
      "EllipticCutInfo" -> ellInfo|>
];

LeadingSingularityAssist[integrand_, OptionsPattern[]] :=
Module[{result, records, status, lsVal, nLS, warnings, infoRecs,
        loopVarRecs, orderRecs, milestones, fullLog, summary, features},
    (* capture diagnostics without altering the algorithm: only Print   *)
    (* is rebound. Quiet suppresses kernel messages; we do NOT use      *)
    (* Check, which would falsely report failure on the benign messages *)
    (* (Solve::incnst, Power::infy, ...) that the algorithm generates   *)
    (* during normal operation. Failure is detected from the return     *)
    (* value instead ($Failed / $Aborted / {} / list).                  *)
    LSAssistBag = {};
    Block[{Print = LSAssistCapturePrint},
        result = Quiet@LeadingSingularities[integrand,
            deBug -> OptionValue[deBug],
            "outputlevel" -> OptionValue["outputlevel"],
            "external" -> OptionValue["external"],
            "order" -> OptionValue["order"]];
    ];
    records = LSAssistBag;
    LSAssistBag = {};
    fullLog = StringRiffle[Map[#["Text"] &, records], "\n"];

    {status, lsVal} = Which[
        result === $Failed || result === $Aborted, {"Failed", {}},
        result === {}, {"Empty", {}},
        ListQ[result], {"Success", result},
        True, {"Unknown", {}}];
    nLS = If[ListQ[lsVal], Length[lsVal], 0];

    warnings = Select[records,
        MemberQ[{"Error", "Serious", "Mild"}, #["Severity"]] &];
    infoRecs = Select[records, #["Severity"] === "Info" &];

    loopVarRecs = Select[records,
        StringContainsQ[#["Text"], "loop variables are"] &];
    orderRecs = Select[records,
        StringContainsQ[#["Text"], "integrate"] &&
            ! StringContainsQ[#["Text"], "remaining"] &];
    milestones = Select[records,
        StringContainsQ[#["Text"],
            "Step" | "number of cut got" | "remaining loops" |
            "Last Step" | "the remaining expression is"] &];

    (* Extract structural features from the diagnostic trace:         *)
    (* higher poles (incl. double poles) and possible elliptic cuts.  *)
    (* These are printed as plain text or Cyan Info, so they are not  *)
    (* caught by the colour-based severity classifier.                *)
    features = LSAssistExtractFeatures[records];

    summary = "Status: " <> status <> If[status === "Success",
        " (" <> ToString[nLS] <> " leading singularities)", ""];
    If[features["HasHigherPole"],
        summary = summary <> If[features["HigherPoleUncancelled"],
            " [HigherPole-Uncancelled]", " [HigherPole]"]];
    If[features["HasPossibleElliptic"],
        summary = summary <> " [PossibleElliptic]"];

    <|"Status" -> status,
      "NumLeadingSingularities" -> nLS,
      "LeadingSingularities" -> lsVal,
      "Summary" -> summary,
      "LoopVariables" -> Map[#["Text"] &, loopVarRecs],
      "SolvingOrder" -> Map[#["Text"] &, orderRecs],
      "Milestones" -> Map[#["Text"] &, milestones],
      "HasHigherPole" -> features["HasHigherPole"],
      "HigherPoleUncancelled" -> features["HigherPoleUncancelled"],
      "HigherPoleRecords" -> features["HigherPoleRecords"],
      "HasPossibleElliptic" -> features["HasPossibleElliptic"],
      "EllipticCutInfo" -> features["EllipticCutInfo"],
      "Warnings" -> warnings,
      "Info" -> infoRecs,
      "FullLog" -> fullLog|>
];
