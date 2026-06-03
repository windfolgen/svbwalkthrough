Get["ConformalWeight.m"];
uRule = u -> u/v; vRule = v -> 1/v; zRule = z -> z/(z-1); zzRule = zz -> zz/(zz-1);
zRoot = (-1+u+v-Sqrt[-4*u*v+(-1+u+v)^2])/(2*v);
zzRoot = (-1+u+v+Sqrt[-4*u*v+(-1+u+v)^2])/(2*v);
lsBase = v/(z-zz)^2;
transformed = Simplify[lsBase /. {uRule, vRule, zRule, zzRule}];
transformed = Simplify[transformed /. {z -> zRoot, zz -> zzRoot}];
Print["transformed: ", InputForm[transformed]];
