expr = v/(z-zz)^3;
primaryPoleOrder = 1;
pref = Simplify[expr * (z-zz)^primaryPoleOrder];
pref = pref /. {
  (z-zz)^2 -> ((1+u-v)^2 - 4u),
  (z-zz)^4 -> ((1+u-v)^2 - 4u)^2,
  (z-zz)^(-2) -> 1/((1+u-v)^2 - 4u),
  (z-zz)^(-4) -> 1/((1+u-v)^2 - 4u)^2
};
Print[pref];
