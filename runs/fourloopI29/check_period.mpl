# Numerically test vanishing of the integral between the two real-diagonal endpoints at v=1/4.
restart:
currentdir(getenv("I29_LIBRARY")):read "HyperlogProcedures":
read getenv("I29_ANC"):
Digits:=25:kernelopts(numcpus=1):
for count in [12,20] do
 poly:=orthopoly[P](count,t): dp:=diff(poly,t): pts:=[fsolve(poly,t)]:
 val:=0: absolute:=0:
 for a in pts do
  q:=evalf(1-exp(-I*(1+a)*Pi/2)/2): weight:=Pi/((1-a^2)*subs(t=a,dp)^2):
  part:=evalf(weight*Re(I29K7Value(q,conjugate(q),19))/abs(q)):
  val:=val+part:absolute:=absolute+abs(part):
 end do:
 printf("%d nodes: signed %.18g absolute %.18g\n",count,val,absolute):
end do:
quit:
