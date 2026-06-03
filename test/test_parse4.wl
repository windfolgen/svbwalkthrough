expr = v/(z-zz)^3;
primaryPoleOrder = 1;
pref = Simplify[expr * (z-zz)^primaryPoleOrder];
zRoot0 = 1/2 * (1 + u - v - Sqrt[-4u + (1+u-v)^2]);
zzRoot0 = 1/2 * (1 + u - v + Sqrt[-4u + (1+u-v)^2]);
pref2 = Simplify[pref /. {z -> zRoot0, zz -> zzRoot0}];
Print[pref2];
