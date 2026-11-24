# J112 = I112-I26 in the original basis.
I112Euclidean := proc(q,qb)
 I26Euclidean(q,qb)+subs({z=q,zz=qb},J112SV)
end proc:
