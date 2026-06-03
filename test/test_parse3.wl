expr = v/(z-zz)^3;
primaryPoleOrder = 1;
pref = Simplify[expr * (z-zz)^primaryPoleOrder];
pref = pref /. Power[z-zz, n_Integer] :> (((1+u-v)^2 - 4u)^(n/2)) /; EvenQ[n];
pref = pref /. (z-zz)^2 -> ((1+u-v)^2 - 4u);
Print[pref];
