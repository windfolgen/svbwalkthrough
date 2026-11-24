restart:
currentdir(getenv("I26_SV_LIBRARY")):
read "HyperlogProcedures":kernelopts(numcpus=1):
read cat(getenv("I26_SV_WORK"),"/words.mpl"):
# Leading power of a single word at the native light cone.
light:=proc(A)
 local hol,sm;
 hol:=convertitoL(basisi(Convert(A,i,[z,zz]),zz,z),zz,z);
 sm:=seriesh(hol,0,zz,L,1);
 return expand(shuffleexpand(subs(L[0]=lg-LL[0],sm),[LL,f]))
end proc:
put:=proc(fd,K,v) fprintf(fd,"%d\t%a\n",K,v); fflush(fd) end proc:
sf:=proc(g) subs(I[z,0]=1,expand(ShuffleExpand(g,I))) end proc:
s1:=fopen(cat(getenv("I26_SV_WORK"),"/mirror.tsv"),WRITE):s2:=fopen(cat(getenv("I26_SV_WORK"),"/inv.tsv"),WRITE):
s3:=fopen(cat(getenv("I26_SV_WORK"),"/native.tsv"),WRITE):s4:=fopen(cat(getenv("I26_SV_WORK"),"/cross.tsv"),WRITE):
s5:=fopen(cat(getenv("I26_SV_WORK"),"/light.tsv"),WRITE):s6:=fopen(cat(getenv("I26_SV_WORK"),"/crosslight.tsv"),WRITE):
# Store one column per word: exchange and inversion residuals, two cusp
# expansions and the constrained logarithms in the two light-cone limits.
for k to nops(words) do
 A:=words[k]:
 put(s1,k,sf(A-StandardForm(subs([z=zz,zz=z],A),[z,zz]))):
 put(s2,k,sf(A+Transform(A,z=1/z,zz))):
 put(s3,k,expand(subs(I[z,0,0]=lg,Series(A,z=0,zz,5,5)))):
 ca:=sf(Transform(A,z=1-z,zz)):
 put(s4,k,expand(subs(I[z,0,0]=lg,Series(ca,z=0,zz,3,3)))):
 la:=light(A):put(s5,k,add(coeff(la,lg,h)*lg^h,h=3..7)):
 lb:=light(ca):put(s6,k,add(coeff(lb,lg,h)*lg^h,h=2..7)):
 if irem(k,20)=0 then printf("completed %a/%a; seconds %a, MB %a\n",k,nops(words),time(),kernelopts(bytesalloc)/10.^6) end if:
end do:
quit:
