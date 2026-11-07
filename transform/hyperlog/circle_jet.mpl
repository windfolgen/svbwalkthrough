# Reciprocal-letter collision w*ww=1, holding ww fixed and w=1/ww-delta.
# The local expansion variable delta is named z in the returned expression.
CircleJet:=proc(expr,ord)
 local hol,shifted,jet;
 hol:=convertitoL(Convert(expr,i,[z,zz]),z,zz);
 shifted:=shuffleexpand(trafoh(subs(z=1/zz-z,hol),1/zz,L),L);
 jet:=seriesh(shifted,ord,z,L,1);
 jet:=subs(L[0]=circleLog,jet);
 jet:=convertLtoi(jet,z,zz);
 jet:=normali(jet,zz);
 jet:=normal(convertitoL(jet,z,zz));
 if pickindets(jet,L)<>{} or pickindets(jet,i)<>{} then
  error "Unresolved circle hyperlogarithm";
 end if;
 return expand(jet);
end proc:
ForbiddenCircleJet:=proc(jet,ord)
 local k,c,answer;
 answer:=0;
 for k from -2 to ord do
  c:=coeff(jet,z,k);
  if k<0 then answer:=answer+c*z^k;
  else answer:=answer+(c-subs(circleLog=0,c))*z^k;
  end if;
 end do;
 return normal(answer);
end proc:
