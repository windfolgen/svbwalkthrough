# Original basis I260. Assembled from the four-cut bootstrap of R260 and two I168 images.
I260Euclidean := proc(q,qb)
 local u,v,s,sb;
 u:=q*qb: v:=(1-q)*(1-qb): s:=q/(q-1): sb:=qb/(qb-1):
 (R260SVEuclidean(q,qb)+I168Euclidean(s,sb)+v*I168Euclidean(1-q,1-qb))/u
end proc:
