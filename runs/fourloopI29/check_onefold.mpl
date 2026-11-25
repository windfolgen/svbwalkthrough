# Integrate the fitted svMPL at a Euclidean point, using rational arguments
# for HyperlogProcedures' individual function evaluations.
restart:
currentdir(getenv("I29_LIBRARY")): read "HyperlogProcedures": kernelopts(numcpus=1):
read getenv("I29_ANC"): Digits:=28:
q0:=7/20+I/4: r:=abs(1-q0): theta:=argument(conjugate(1-q0)):
for count in [12,20] do
  poly:=orthopoly[P](count,t): dpoly:=diff(poly,t):
  nodes:=[fsolve(poly,t)]: if nops(nodes)<>count then error "incomplete quadrature" end if:
  result:=0:
  for a in nodes do
    weight:=2/((1-a^2)*subs(t=a,dpoly)^2):
    q:=evalf(1-r*exp(-I*(1+a)*theta/2)):
    result:=result-weight*theta*Re(I29K7Value(q,conjugate(q),20))/(4*Im(q0)*abs(q0)*abs(q)):
  end do:
  result:=evalf(result):
  printf("%d nodes: I29/u = %.15f\n",count,result):
  if abs(result-142.993952659006)>10^(-11) then error "onefold and spectral value differ" end if:
end do:
quit:
