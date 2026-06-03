uRule = u -> u/v; vRule = v -> 1/v; zRule = z -> z/(z-1); zzRule = zz -> zz/(zz-1);
zRoot = (-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 v);
zzRoot = (-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 v);
zRootSeries = Normal[Series[zRoot /. {v -> 1-Y}, {u, 0, 7}, {Y, 0, 7}]];
Print[InputForm[zRootSeries]];
