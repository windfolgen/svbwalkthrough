lsBase = v / (z-zz)^2;
uRule = u -> u/v;
vRule = v -> 1/v;
zRule = z -> z/(z-1);
zzRule = zz -> zz/(zz-1);

transformed = Simplify[lsBase /. {uRule, vRule, zRule, zzRule}];
Print["Transformed: ", transformed];

transformed2 = Simplify[transformed /. {u -> z*zz, v -> (1-z)*(1-zz)}];
Print["Expressed in z,zz: ", transformed2];
