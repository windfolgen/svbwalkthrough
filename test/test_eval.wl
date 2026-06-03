u = u; v = v; Y = Y;
add = ((-1 + z)^2*(-1 + zz)^2)/(v*(z - zz)^2);
zRoot = (-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 v);
zzRoot = (-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 v);

test = (add /. {z -> zRoot, zz -> zzRoot} // Simplify);
Print["Evaluated add: ", test];
