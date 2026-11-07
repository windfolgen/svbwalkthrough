# Ordinary iterated-integral expansion, with the two logarithms kept separate.
OrderedHyperlogJet:=proc(expr,n,m)
 local hol,small,answer;
 hol:=convertitoL(basisi(Convert(expr,i,[z,zz]),zz,z),zz,z);
 small:=seriesh(hol,m,zz,L,1);
 small:=subs(L[0]=barLog,small);
 if pickindets(small,L)<>{} then error "Unexpanded small-coordinate hyperlog" end if;
 answer:=seriesh(small,n,z,LL,1);
 answer:=expand(subs(LL[0]=zLog,answer));
 if pickindets(answer,LL)<>{} or pickindets(answer,i)<>{} then
  error "Unexpanded large-coordinate hyperlog";
 end if;
 return answer;
end proc:
