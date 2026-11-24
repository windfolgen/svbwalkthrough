# Fully normalized svMPL coefficient vectors in each external ordering.
# PURE_OUTPUT contains slots.mpl. HYPERLOG_DIR points to HyperlogProcedures 0.8.
dest:=getenv("PURE_OUTPUT"):
currentdir(getenv("HYPERLOG_DIR")): read "HyperlogProcedures":
kernelopts(numcpus=1): read cat(dest,"/slots.mpl"):
maps:=[z,1-z,1/z,z/(z-1),1/(1-z),(z-1)/z]: undo:=[1,2,3,4,6,5]: maps:=map(normal,maps):
at:=proc(e,m) eval(e,{z=m,zz=subs(z=zz,m)}) end proc:
tidy:=proc(e) subsindets(e,specindex(I),t->I[op(map(normal,[op(t)]))]) end proc:
change:=proc(h,m) if m=z then return h end if: Transform(h,z=m,zz) end proc:
localpieces:=proc(h) local term,t,ep,k,parts,j,keys,x:
 parts:=table(): for j to 6 do parts[j]:=[] end do:
 for term in [op(expand(h))] do
   keys:=indets(term,specindex(I)):
   if nops(keys)>1 then error "unexpected product in extracted svMPL vector" end if:
   if keys={} then k:=1 else
     ep:=normal(op(1,op(keys))): if ep=zz then ep:=z end if:
     if not member(ep,maps,'k') then error "unexpected endpoint %1",ep end if:
   end if:
   parts[k]:=[op(parts[k]),term]:
 end do:
 [seq( StandardForm(tidy(at(add(x,x in parts[j]),maps[undo[j]])),[z,zz]),j=1..6)]
end proc:
canonical:=proc(h,m) local parts,j:
 parts:=localpieces(h): expand(add(change(parts[j],normal(subs(z=m,maps[j]))),j=1..6))
end proc:
writevec:=proc(row,j,h) local fh,term,coeff,marks,basis,k,terms:
 fh:=fopen(cat(dest,"/v_",ch,"_",row,"_",j,".tsv"),WRITE):
 if h=0 then error "zero slot %1", [row,j] end if:
 terms:=expand(h): if type(terms,`+`) then terms:=[op(terms)] else terms:=[terms] end if:
 for term in terms do
   if type(term,rational) then coeff:=term elif type(term,`*`) then
     coeff:=mul(k,k in select(type,[op(term)],rational)) else coeff:=1 end if:
   basis:=term/coeff:
   if not type(coeff,rational) then error "non-rational coefficient" end if:
   fprintf(fh,"%a\t%a\n",basis,coeff):
 end do:
 fclose(fh):
end proc:
# Resolve the native conjugations once. Then transport the complete function
# (including its regularized boundary periods) to each of the six charts.
for r in [seq(k,k=1..13),seq(k,k=15..32),0] do
 for j from 1 while assigned(slot[r,j]) do
  h:=canonical(slot[r,j],z):
  for ch to 6 do writevec(r,j,change(h,maps[ch])) end do:
  printf("Completed row %d sector %d in all six charts\n",r,j):
 end do:
end do:
lad:=j->I[z,0$j,1,0$(j-1),0]-I[z,0$(j-1),1,0$j,0]:
sq:=StandardForm(lad(2)^2,[z,zz]):
if expand(sq-slot[15,1])<>0 or expand(change(sq,1-z)-slot[32,1])<>0
   or expand(StandardForm(lad(1)*lad(3)-lad(2)^2/3,[z,zz])-slot[19,1])<>0 then
 error "Ladder and square-fishnet normalization" end if:
for ch to 6 do writevec(0,2,change(sq,maps[ch])) end do:
quit:
