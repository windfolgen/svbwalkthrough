restart:
currentdir(getenv("I29_LIBRARY")): read "HyperlogProcedures": kernelopts(numcpus=1):
work:=getenv("I29_WORK"): read cat(work,"/words.mpl"):
standard:=proc(g) subs(I[z,0]=1,expand(ShuffleExpand(g,I))) end proc:
for tag in ["mirror","crossing","native"] do
  fd[tag]:=fopen(cat(work,"/",tag,".tsv"),WRITE)
end do:
put:=proc(tag,k,v) fprintf(fd[tag],"%d\t%a\n",k,v); fflush(fd[tag]) end proc:
for k to nops(words) do
  A:=words[k]:
  put("mirror",k,standard(A-StandardForm(subs([z=zz,zz=z],A),[z,zz]))):
  put("crossing",k,standard(A-Transform(A,z=z/(z-1),zz))):
  put("native",k,expand(subs(I[z,0,0]=lg,Series(A,z=0,zz,5,5)))):
end do:
quit:
