# Auxiliary integrals in the Gram decomposition. Both endpoints transform together.
I38Euclidean := proc(q,qb)
 R260Ladder(q,qb,1)*R260Ladder(q,qb,3)-R260Ladder(q,qb,2)^2/3
end proc:

R260Lb := proc(q,qb)
 q*qb/((1-q)*(1-qb))*R260Ladder(q/(q-1),qb/(qb-1),2)^2
end proc:

R260Lc := proc(q,qb)
 (1-q)*(1-qb)*R260Ladder(1-q,1-qb,2)^2
end proc:

R260GramG := proc(q,qb)
 2*subs({z=q,zz=qb},I214Pv)
end proc:

R260GramH := proc(q,qb)
 local u,v;
 u:=q*qb: v:=(1-q)*(1-qb):
 R260GramM(q,qb)-subs({z=q/(q-1),zz=qb/(qb-1)},R168SV)
 -v*subs({z=1-q,zz=1-qb},R168SV)+R260Lb(q,qb)+R260Lc(q,qb)-v*(1+u-v)*I38Euclidean(q,qb)
end proc:

R260GramK := proc(q,qb)
 R260GramH(q,qb)-((1-q)*(1-qb))^2*I38Euclidean(q,qb)
end proc:

R260GramY0 := proc(q,qb)
 R260GramM(q,qb)-2*(I214Euclidean(q,qb)+I214Euclidean(1/qb,1/q))
end proc:

R260GramT0 := proc(q,qb)
 local u,v;
 u:=q*qb: v:=(1-q)*(1-qb):
 R260GramY0(q,qb)+R260Lb(q,qb)+R260Lc(q,qb)-v*(1+u-v)*I38Euclidean(q,qb)
end proc:

R260GramCa := proc(q,qb)
 q*qb*I260Euclidean(q,qb)-R260Lb(q,qb)-R260Lc(q,qb)
end proc:
