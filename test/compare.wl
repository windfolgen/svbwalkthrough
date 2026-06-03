z1 = (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] - v) / (2 v);
z = (1 - u - Sqrt[(-1 + u - v)^2 - 4 v] + v) / (2 v);
Print["z1 = ", z1 // Expand];
Print["z = ", z // Expand];
Print["z - z1 = ", (z - z1) // Simplify];
