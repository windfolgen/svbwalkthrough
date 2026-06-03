z0p_orig = Power[1/2*(1 + u - Sqrt[-4 u + (-1 + u + v)^2] + v), 1]  /. {v -> 1 - Y} // Expand;
zz0p_orig = Power[1/2*(1 + u + Sqrt[-4 u + (-1 + u + v)^2] + v), 1] /. {v -> 1 - Y} // Expand;

z0p_new = (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y} // Expand;
zz0p_new = (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y} // Expand;

Print["z0p_orig = ", z0p_orig];
Print["z0p_new = ", z0p_new];
