Get["original_series_agent.wl"];

z0_orig = (Power[1/2*(1 + u - Sqrt[-4 u + (1 + u - v)^2] - v), 1]  /. {v -> 1 - Y} // Expand);
zz0_orig = (Power[1/2*(1 + u + Sqrt[-4 u + (1 + u - v)^2] - v), 1] /. {v -> 1 - Y} // Expand);

z0_new = 1/2 * (1 + u - Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y} // Expand;
zz0_new = 1/2 * (1 + u + Sqrt[-4 u + (1 + u - v)^2] - v) /. {v -> 1 - Y} // Expand;

Print["Diff 0: ", (z0_orig - z0_new) // Simplify, ", ", (zz0_orig - zz0_new) // Simplify];

z0p_orig = (Power[1/2*(1 + u - Sqrt[-4 u + (-1 + u + v)^2] + v), 1]  /. {v -> 1 - Y} // Expand);
zz0p_orig = (Power[1/2*(1 + u + Sqrt[-4 u + (-1 + u + v)^2] + v), 1] /. {v -> 1 - Y} // Expand);

z0p_new = (-1 + u + v - Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y} // Expand;
zz0p_new = (-1 + u + v + Sqrt[-4 u v + (-1 + u + v)^2]) / (2 v) /. {v -> 1 - Y} // Expand;

Print["Diff 0P: ", (z0p_orig - z0p_new) // Simplify, ", ", (zz0p_orig - zz0p_new) // Simplify];
