expr = I[z,0,0];
Print[expr /. {I[z,0,0]->Log[u]}];
expr2 = Expand[expr];
Print[expr2 /. {I[z,0,0]->Log[u]}];
expr3 = expr /. zrep0;
Print[expr3 /. {I[z,0,0]->Log[u]}];
