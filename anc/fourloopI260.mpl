# Original basis I260. Its four-cut candidate inherits the assumptions of R260.
I260Euclidean := proc(q,qb)
 local u,v,s,sb;
 u:=q*qb: v:=(1-q)*(1-qb): s:=q/(q-1): sb:=qb/(qb-1):
 (R260SVEuclidean(q,qb)+I168Euclidean(s,sb)+v*I168Euclidean(1-q,1-qb))/u
end proc:
