(* I26 in the original four-loop basis. Get this file and apply the result to
   [q,qb], where qb is the conjugate of q. The native chart has q in the upper
   half-plane and y(v)=q-qb. I[z,...,0] and f[3] use HyperlogProcedures
   conventions. Convert moving letters while symbolic for point evaluation. *)
Module[{p7, native, diagonal},
  p7 = Function[{z,zz}, (
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
-48*f[3]*I[z,1,0,1,1,0]
  )];
  native[u_,v_] := Module[{rho=u/v^2, x, lower, y, qp, qm},
    lower = 4/(1+Sqrt[1+4*Sqrt[rho]])^2;
    y = Sqrt[(1+x-rho*x^2)^2-4*x];
    qp = (1-x+rho*x^2+y)/2;
    qm = (1-x+rho*x^2-y)/2;
    Inactive[Integrate][p7[qp,qm]/y, {x,lower,v}]/(v*Sqrt[(1+v-u)^2-4*v])
  ];
  diagonal[q_] := Which[
    q==0 || q==1, Indeterminate,
    q^2>1, diagonal[1/q]/q^4,
    q==-1, With[{l=Log[2]}, 48*l*PolyLog[5,1/2]+48*l^2*PolyLog[4,1/2]
      -8*Zeta[2]*l^4-27*Zeta[3]^2/16-57*Zeta[5]*l/4+8*l^6/5],
    True, -p7[q,q]/(2*q*(1-q^2))
  ];
  Function[{q,qb}, With[{u=q*qb, v=(1-q)*(1-qb)},
    If[TrueQ[q==qb], diagonal[q],
      If[u<=1, native[u,v], native[1/u,v/u]/u^2,
        Piecewise[{{native[u,v],u<=1}},native[1/u,v/u]/u^2]]]
  ]]
]
