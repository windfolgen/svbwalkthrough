Print["=== Running test_assoc.wl ==="];
Get["asym/asym_new.wl"];

(* 1. Test data: List-based record format *)
lengths1 = {2, 1};
tensor1 = {{m[1], m[2]}, {m[3]}};
tp1 = {expr1, tensor1};

lengths2 = {1, 1};
tensor2 = {{m[4]}, {m[5]}};
tp2 = {expr2, tensor2};

dummyListRecord = {
  {lengths1, tensor1, tp1},
  {lengths2, tensor2, tp2}
};

(* 2. Convert to Association using toAssoc *)
assocRecord = toAssoc[dummyListRecord];
Print["Original List Record: ", InputForm[dummyListRecord]];
Print["Converted Association Record: ", InputForm[assocRecord]];
Print["Is Association? ", AssociationQ[assocRecord]];

(* 3. Test FindTensor lookup on list record vs assoc record *)
targetTensor = {{idx[1], idx[2]}, {idx[3]}};

(* Old list-based lookup simulation *)
FindTensorOld[tensor_, record_] := Module[
  {tem, pos, rep},
  If[record === {}, Return[{False, {}}]];
  tem = Length /@ tensor;
  pos = Position[record[[All, 1]], tem, 1] // Flatten;
  If[pos === {}, Return[{False, {}}]];
  rep = Thread@Rule[
    record[[pos[[1]], 2]] /. {vc[a_, b_] :> b} // Flatten,
    tensor /. {vc[a_, b_] :> b} // Flatten
  ];
  Return[{True, rep, record[[pos[[1]], 3]] /. rep}]
];

resOld = FindTensorOld[targetTensor, dummyListRecord];
resNew = FindTensor[targetTensor, assocRecord];

Print["Old FindTensor Result: ", InputForm[resOld]];
Print["New FindTensor Result: ", InputForm[resNew]];
Print["Results match? ", SameQ[resOld, resNew]];

(* 4. Test Key lookup on missing key *)
missingTensor = {{idx[1]}, {idx[2]}, {idx[3]}};
resMissing = FindTensor[missingTensor, assocRecord];
Print["Missing Key Result: ", InputForm[resMissing]];

Print["=== Done test_assoc.wl ==="];
