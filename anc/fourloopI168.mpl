# Original four-loop basis normalization. The common elliptic part is v*I26.
I168Euclidean := proc(q,qb)
 2*(1-q)*(1-qb)*I26Euclidean(q,qb)+subs({z=q,zz=qb},R168SV)
end proc:
