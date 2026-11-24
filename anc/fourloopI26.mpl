# HyperlogProcedures 0.8. Load with z and zz unassigned and as a conjugate pair.
# Weight-seven coefficient of the onefold for I26, with u=z*zz and v=(1-z)*(1-zz).
# The entries after z are outermost first. The final zero is the base point.
# In the paper's L notation reverse the intervening integration indices.
# Convert the analytic expression while the letters are symbolic before numerical evaluation.
I26P7SV :=
I[z,0,0,0,0,1,0,0,0]
+2*I[z,0,0,0,0,1,0,1,0]
-2*I[z,0,0,0,0,1,1,0,0]
-2*I[z,0,0,0,1,0,0,0,0]
+2*I[z,0,0,0,1,0,1,0,0]
+I[z,0,0,1,0,0,0,0,0]
+6*I[z,0,0,1,0,0,1,0,0]
-8*I[z,0,0,1,0,0,1,1,0]
-8*I[z,0,0,1,0,1,0,0,0]
+4*I[z,0,0,1,0,1,0,1,0]
+4*I[z,0,0,1,0,1,1,0,0]
+4*I[z,0,0,1,1,0,0,1,0]
-4*I[z,0,0,1,1,0,1,0,0]
-2*I[z,0,1,0,0,0,0,1,0]
+4*I[z,0,1,0,0,0,1,0,0]
-2*I[z,0,1,0,0,1,0,0,0]
+4*I[z,0,1,0,0,1,0,1,0]
-4*I[z,0,1,0,0,1,1,0,0]
+2*I[z,0,1,0,1,0,0,0,0]
-4*I[z,0,1,0,1,0,0,1,0]
+4*I[z,0,1,0,1,1,0,0,0]
-2*I[z,0,1,1,0,0,0,0,0]
-4*I[z,0,1,1,0,0,1,0,0]
+8*I[z,0,1,1,0,0,1,1,0]
+4*I[z,0,1,1,0,1,0,0,0]
-8*I[z,0,1,1,0,1,0,1,0]
-2*I[z,1,0,0,0,0,1,0,0]
-4*I[z,1,0,0,1,0,1,0,0]
+4*I[z,1,0,0,1,1,0,0,0]
+2*I[z,1,0,1,0,0,0,0,0]
-4*I[z,1,0,1,0,0,1,0,0]
+8*I[z,1,0,1,0,0,1,1,0]
+4*I[z,1,0,1,0,1,0,0,0]
-8*I[z,1,0,1,0,1,1,0,0]
-8*I[z,1,0,1,1,0,0,1,0]
+8*I[z,1,0,1,1,0,1,0,0]
+8*I[z,0,0,zz,0,0,1,1,0]
-8*I[z,0,0,zz,0,1,1,0,0]
-8*I[z,0,0,zz,1,0,0,1,0]
+8*I[z,0,0,zz,1,1,0,0,0]
-8*I[z,0,1,zz,0,0,1,1,0]
+8*I[z,0,1,zz,0,1,1,0,0]
+8*I[z,0,1,zz,1,0,0,1,0]
-8*I[z,0,1,zz,1,1,0,0,0]
-8*I[z,1,0,zz,0,0,1,1,0]
+8*I[z,1,0,zz,0,1,1,0,0]
+8*I[z,1,0,zz,1,0,0,1,0]
-8*I[z,1,0,zz,1,1,0,0,0]
+12*f[3]*I[z,0,0,1,0,0]
+24*f[3]*I[z,0,0,1,1,0]
-24*f[3]*I[z,0,1,1,0,0]
+24*f[3]*I[z,1,0,0,1,0]
+24*f[3]*I[z,1,0,1,0,0]
-48*f[3]*I[z,1,0,1,1,0]:

I26P7Ordinary := proc()
  option remember;
  Convert(I26P7SV,i,[z,zz])
end proc:

I26P7Value := proc(q,b,prec::posint:=20)
  Evaluate(subs([z=q,zz=b],I26P7Ordinary()),prec)
end proc:

# Characteristic rho=u/v^2. On 0<u<=1, y(x) has positive imaginary part
# between the regular real-diagonal endpoint and the physical upper root.
I26Native := proc(u,v)
 local rho,x0,x,y,qp,qm,d;
 rho:=u/v^2:
 x0:=4/(1+sqrt(1+4*sqrt(rho)))^2:
 y:=sqrt((1+x-rho*x^2)^2-4*x):
 qp:=(1-x+rho*x^2+y)/2: qm:=(1-x+rho*x^2-y)/2:
 d:=sqrt((1+v-u)^2-4*v):
 Int(subs({z=qp,zz=qm},I26P7SV)/y, x=x0..v)/(v*d)
end proc:

# Euclidean conjugate endpoints, including the inverse chart u>1.
I26Euclidean := proc(q,qb)
 local u,v,c,ell;
 u:=q*qb: v:=(1-q)*(1-qb):
 if evalb(q=qb) then
   if evalb(q=0) or evalb(q=1) then error "coincident external points" end if:
   if evalb(is(u>1)=true) then return I26Euclidean(1/qb,1/q)/u^2 end if:
   if evalb(q=-1) then
     ell:=ln(2):
     return 48*ell*polylog(5,1/2)+48*ell^2*polylog(4,1/2)
            -8*Zeta(2)*ell^4-27*Zeta(3)^2/16-57*Zeta(5)*ell/4+8*ell^6/5
   end if:
   return -subs({z=q,zz=qb},I26P7SV)/(2*q*(1-u))
 end if:
 c:=is(u<=1):
 if evalb(c=true) then return I26Native(u,v) end if:
 if evalb(c=false) then return I26Native(1/u,v/u)/u^2 end if:
 piecewise(u<=1,I26Native(u,v),I26Native(1/u,v/u)/u^2)
end proc:
