# From the repository root, set HYPERLOG_DIR to the HyperlogProcedures 0.8 directory.
ancDirectory := FileTools:-JoinPath([currentdir(), "anc"]):
currentdir(getenv("HYPERLOG_DIR")):
read "HyperlogProcedures":
read FileTools:-JoinPath([ancDirectory, "fourloopBootstrap.mpl"]):
ReadFourLoopBootstrap(ancDirectory):

# Two calls to an inert integral create distinct local integration variables.
# Give each bound variable the same unused name before testing equality.
renameIntegral := proc(integral)
 local variable;
 variable := lhs(op(2,integral)):
 subs(variable=ancIntegrationVariable,integral)
end proc:
verifyZero := proc(expression, name)
 if expand(subsindets(expression,specfunc(anything,Int),renameIntegral)) <> 0 then
   error "failed %1", name
 end if
end proc:

checkBasis := proc()
 local q,b,u,v,s,sb,scalar,i168,rem260;
 q:=2/5+sqrt(-1)/5: b:=conjugate(q):
 u:=q*b: v:=(1-q)*(1-b): s:=q/(q-1): sb:=b/(b-1):
 scalar:=I26Euclidean(q,b):
 if nops(indets(scalar,specfunc(anything,Int))) <> 1 then error "I26 quadrature" end if:
 verifyZero(I26Euclidean(1/b,1/q)-u^2*scalar,"I26 inversion"):
 verifyZero(I26Euclidean(2,2)-I26Euclidean(1/2,1/2)/16,"I26 diagonal inversion"):
 verifyZero(I112Euclidean(q,b)-scalar-subs({z=q,zz=b},J112SV),"I112 normalization"):
 i168:=I168Euclidean(q,b):
 verifyZero(i168-2*v*scalar-subs({z=q,zz=b},R168SV),"I168 normalization"):
 rem260:=R260SVEuclidean(q,b):
 verifyZero(u*I260Euclidean(q,b)-rem260-I168Euclidean(s,sb)-v*I168Euclidean(1-q,1-b),"I260 normalization"):
 verifyZero(R260GramK(q,b)-R260GramH(q,b)+v^2*I38Euclidean(q,b),"Gram fishnet"):
 verifyZero(R260GramH(q,b)-rem260-2*(I214Euclidean(q,b)+I214Euclidean(1/b,1/q)),"Gram subtraction"):
 verifyZero(R260GramM(q,b)-R260GramM(1/q,1/b),"Gram inversion"):
 printf("Verified the scalar quadrature, basis normalizations, crossed arguments and Gram identities.\n")
end proc:
checkBasis():
quit:
