# Run from the HyperlogProcedures 0.8 directory with maple -q <path-to-this-file>.
read "HyperlogProcedures":
edges := [[1,5],[1,6],[1,7],[2,5],[2,6],[2,8],[3,5],[3,7],[3,8],[5,6],[5,7],[6,8],[7,8]]:
uu := z*zz:
vv := (1-z)*(1-zz):
expected := table([1=72*f[3,3]/(uu*vv^2),4=441*f[7]/(8*uu*vv),7=441*f[7]/(8*uu^2*vv)]):
for omit in [1,4,7] do
    graph := {seq([convert(pair,set),1], pair in subsop(omit=NULL,edges))}:
    result := GraphicalFunction(graph,[1,3,2],4,0,[z,zz]):
    if normal(result-expected[omit]) <> 0 then
        error "unexpected graph value for omitted edge %1",edges[omit]
    end if:
    printf("Omit %a: %a\n",edges[omit],factor(result)):
end do:
quit:
