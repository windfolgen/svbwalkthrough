# Run from the repository root with HYPERLOG_DIR set to the library directory.
resultfile := cat(currentdir(), "/runs/fourloopI214/fourloopI214.mpl"):
currentdir(getenv("HYPERLOG_DIR")):
read "HyperlogProcedures":
kernelopts(numcpus=1):
read resultfile:

check214 := proc()
  local discriminant, kernels, k, j, forms, reference, curl,
        atoms, substitutions, assembled;
  discriminant := (1-z*zz)^2-4*(1-z)*(1-zz):
  kernels := [[-(z*zz-2*zz+1)/(z-1), -(z*zz-2*z+1)/(zz-1)],
              [ (z*zz+2*zz-3)/(z-1), -(z*zz+2*z-3)/(zz-1)]]:
  for k in kernels do
    if normal(2*discriminant*(diff(k[2],z)-diff(k[1],zz))
              -diff(discriminant,z)*k[2]+diff(discriminant,zz)*k[1]) <> 0 then
      error "a logarithmic letter has nonzero curl"
    end if:
  end do:
  forms := I214Differential(y):
  for j to 2 do
    reference := I214CA*kernels[1][j]+I214CM*kernels[2][j]:
    if normal(y*forms[j]-reference) <> 0 then error "differential normalization" end if:
  end do:
  curl := add(Differentiate([I214CA,I214CM][j],z,[z,zz])*kernels[j][2]
             -Differentiate([I214CA,I214CM][j],zz,[z,zz])*kernels[j][1],j=1..2):
  curl := expand(subs(f[3]^2=2*f[3,3],expand(curl))):
  atoms := [op(indets(curl,indexed))]:
  substitutions := [seq(atoms[j]=cat(atom,j),j=1..nops(atoms))]:
  if normal(subs(substitutions,curl)) <> 0 then error "nonzero exterior derivative" end if:
  for k in [I214P0,I214Pu,I214Pv] do
    if expand(k+subs({z=zz,zz=z},k)) <> 0 then error "numerator exchange parity" end if:
  end do:
  assembled := I214Euclidean(z,zz):
  if nops(indets(assembled,specfunc(anything,Int))) <> 1 then error "final quadrature" end if:
  printf("Verified the closed differential, exchange-odd rational numerators and one final integration.\n"):
end proc:
check214():
quit:
