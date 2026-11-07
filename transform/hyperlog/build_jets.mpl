# Reusable Maple/Hyperlog producer for the weighted series provider.
# Required environment: SVB_PACKAGE_ROOT, SVB_HYPERLOG_DIR,
# SVB_BASIS_FILE (Maple list), SVB_OUTPUT_DIRECTORY.
# Optional: SVB_MODE=e0|e1|einf|diagonal|circle|inversion,
# SVB_ATOM_INDICES=[1,2,...], SVB_ATOM_TIMEOUT=180.
RequiredSetting:=proc(name)
 local value;
 value:=getenv(name);
 if not type(value,string) or value="" or value="false" then
  error "Missing environment setting %1",name;
 end if;
 return value;
end proc:
packageRoot:=RequiredSetting("SVB_PACKAGE_ROOT"):
hyperlogDir:=RequiredSetting("SVB_HYPERLOG_DIR"):
basisFile:=RequiredSetting("SVB_BASIS_FILE"):
outDir:=RequiredSetting("SVB_OUTPUT_DIRECTORY"):
currentdir(hyperlogDir):
read "HyperlogProcedures":kernelopts(numcpus=1):
read cat(packageRoot,"/transform/hyperlog/ordered_hyperlog_jet.mpl"):
read cat(packageRoot,"/transform/hyperlog/diagonal_jet.mpl"):
read cat(packageRoot,"/transform/hyperlog/circle_jet.mpl"):
atoms:=parse(FileTools[Text][ReadFile](basisFile)):
mode:=getenv("SVB_MODE"):
if not type(mode,string) or mode="" or mode="false" then mode:="e0" end if:
indicesText:=getenv("SVB_ATOM_INDICES"):
if type(indicesText,string) and indicesText<>"" and indicesText<>"false" then
 selected:=parse(indicesText):
else selected:=[seq(k,k=1..nops(atoms))]:end if:
atomTimeout:=180:
timeoutText:=getenv("SVB_ATOM_TIMEOUT"):
if type(timeoutText,string) and timeoutText<>"" and timeoutText<>"false" then atomTimeout:=parse(timeoutText) end if:
failures:=[]:
for atomIndex in selected do
 try
  if mode="e0" then result:=timelimit(atomTimeout,OrderedHyperlogJet(atoms[atomIndex],8,3)):
  elif mode="e1" then result:=timelimit(atomTimeout,OrderedHyperlogJet(Transform(atoms[atomIndex],z=1+z,zz),8,3)):
  elif mode="einf" then result:=timelimit(atomTimeout,OrderedHyperlogJet(Transform(atoms[atomIndex],z=1/z,zz),8,3)):
  elif mode="diagonal" then result:=timelimit(atomTimeout,DiagonalJet(atoms[atomIndex],3)):
  elif mode="circle" then result:=timelimit(atomTimeout,CircleJet(atoms[atomIndex],3)):
  elif mode="inversion" then result:=timelimit(atomTimeout,ShuffleExpand(Transform(atoms[atomIndex],z=1/z,zz),I)):
  else error "Unsupported mode %1",mode end if:
  FileTools[Text][WriteFile](cat(outDir,"/atom_",atomIndex,".txt"),convert(result,string)):
  printf("DONE %s %d\n",mode,atomIndex):
 catch:
  failures:=[op(failures),atomIndex]:
  printf("FAILED %s %d %a\n",mode,atomIndex,[lastexception]):
 end try:
end do:
FileTools[Text][WriteFile](cat(outDir,"/status.json"),cat("{\"requested\":",nops(selected),",\"failed\":",convert(failures,string),"}\n")):
quit:
