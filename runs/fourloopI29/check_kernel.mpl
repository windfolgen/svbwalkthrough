restart:
currentdir(getenv("I29_LIBRARY")): read "HyperlogProcedures": kernelopts(numcpus=1):
work:=getenv("I29_WORK"): read getenv("I29_ANC"):
# Sum before specializing either moving letter. Short blocks bound the memory use.
ks:=convert(I29K7SV,list): native:=0: crossed:=0:
for j from 1 by 12 to nops(ks) do
  A:=add(ks[h],h=j..min(j+11,nops(ks))):
  native:=native+Series(A,z=0,zz,8,8):
  crossed:=crossed+Series(Transform(A,z=1-z,zz),z=0,zz,4,4):
end do:
writejet:=proc(tag,g) local fd;
  fd:=fopen(cat(work,"/check_",tag,".txt"),WRITE);
  fprintf(fd,"%a\n",expand(subs(I[z,0,0]=lg,g))); fclose(fd)
end proc:
writejet("native",native): writejet("cross",crossed):
quit:
