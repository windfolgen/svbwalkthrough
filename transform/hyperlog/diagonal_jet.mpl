# z=zz-delta with zz held fixed. Keep the diagonal logarithm as an
# independent symbol, normalize its coefficients to ordinary HPLs in zz.
DiagonalJet:=proc(expr,ord)
 local hol,shifted,jet;
 hol:=convertitoL(Convert(expr,i,[z,zz]),z,zz);
 shifted:=shuffleexpand(trafoh(subs(z=zz-z,hol),zz,L),L);
 jet:=seriesh(shifted,ord,z,L,1);
 jet:=subs(L[0]=diagonalLog,jet);
 jet:=convertLtoi(jet,z,zz);
 jet:=normali(jet,zz);
 jet:=normal(convertitoL(jet,z,zz));
 if pickindets(jet,L)<>{} or pickindets(jet,i)<>{} then
   error "Unresolved diagonal hyperlogarithm";
 end if;
 return expand(jet);
end proc:
ForbiddenDiagonalJet:=proc(jet,ord)
 local k,c,answer;
 answer:=0;
 for k from -2 to ord do
   c:=coeff(jet,z,k);
   if k<0 then answer:=answer+c*z^k;
   else answer:=answer+(c-subs(diagonalLog=0,c))*z^k;
   end if;
 end do;
 return normal(answer);
end proc:
