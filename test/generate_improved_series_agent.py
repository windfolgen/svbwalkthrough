import re

with open("series_agent/series_agent.wl", "r") as f:
    code = f.read()

def replace_func(match):
    name = match.group(1)
    
    # Determine missing factor and z-vars
    if "Inf" in name:
        zvar = "z"
        zzvar = "zz"
        z0 = "Infinity"
        missing = "1/u"
        zsub = "zz->1/u/z" if "InfP" not in name else "zz->v/u/z"
        zpow = "Power[z,a_/;(a<0)]:>Power[zz*u,-a]" if "InfP" not in name else "Power[z,a_/;(a<0)]:>Power[zz*u/v,-a]"
        fsub = "{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u]}" if "InfP" not in name else "{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],P[0]->-Log[u/v]}"
        zrep = "zrepInf" if "InfP" not in name else "zrepInfP"
        zmap = "{z->(1+u-v-Sqrt[-4 u+(-1-u+v)^2])/(2 u),zz->(1+u-v+Sqrt[-4 u+(-1-u+v)^2])/(2 u)}" if "InfP" not in name else "{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 u),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 u)}"
    elif "0" in name:
        zvar = "z"
        zzvar = "zz"
        z0 = "0"
        missing = "1" if "0P" not in name else "1/v"
        zsub = "zz->u/z" if "0P" not in name else "zz->u/z/v"
        zpow = "Power[z,a_/;(a<0)]:>Power[zz/u,-a]" if "0P" not in name else "Power[z,a_/;(a<0)]:>Power[zz*v/u,-a]"
        fsub = "{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u]}" if "0P" not in name else "{f[5]->Zeta[5],f[7]->Zeta[7],f[3]->Zeta[3],I[z,0,0]->Log[u/v]}"
        zrep = "zrep0" if "0P" not in name else "zrep0P"
        zmap = "{z->1/2 (1+u-Sqrt[-4 u+(1+u-v)^2]-v),zz->1/2 (1+u+Sqrt[-4 u+(1+u-v)^2]-v)}" if "0P" not in name else "{z->(-1+u+v-Sqrt[-4 u v+(-1+u+v)^2])/(2 v),zz->(-1+u+v+Sqrt[-4 u v+(-1+u+v)^2])/(2 v)}"
    elif "1" in name:
        zvar = "z1"
        zzvar = "zz1"
        z0 = "0"
        missing = "1/v" if "1P" not in name else "1"
        zsub = "zz1->u/v/(z1)" if "1P" not in name else "zz1->u/(z1)"
        zpow = "Power[z1,a_/;(a<0)]:>Power[(zz1)*v/u,-a]" if "1P" not in name else "Power[z1,a_/;(a<0)]:>Power[(zz1)/u,-a]"
        fsub = "{I[z,1,0]->Log[u/v],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}" if "1P" not in name else "{I[z,1,0]->Log[u],f[a_]:>Zeta[a],f[3,3]->Zeta[3]^2/2,f[3,5]->Zeta[3]Zeta[5]-f[5,3]}"
        zrep = "zrep1" if "1P" not in name else "zrep1P"
        zmap = "{z1->(1-u-Sqrt[(-1+u-v)^2-4 v]-v)/(2 v),zz1->(1-u+Sqrt[(-1+u-v)^2-4 v]-v)/(2 v)}" if "1P" not in name else "{z1->1/2 (-1-u+v-Sqrt[-4 v+(1-u+v)^2]),zz1->1/2 (-1-u+v+Sqrt[-4 v+(1-u+v)^2])}"
    
    pole_power = "2" if "2" in name else "1"
    
    if pole_power == "2":
        if missing != "1":
            missing = f"({missing})^2"
            
    extra_z1 = ""
    if zvar == "z1":
        extra_z1 = "test = test /. {-1+z->z1, -1+zz->zz1, z->z1+1, zz->zz1+1};\n"
        
    denom = f"({zvar}-{zzvar})" if pole_power == "1" else f"({zvar}-{zzvar})^2"
        
    new_code = f"""ClearAll[{name}];
Options[{name}]={{"additional"->1,"Yorder"->5}};
{name}[temp_,zrep_,OptionsPattern[]]:=Module[{{result,test,test1}},
result=Reap[Do[
test = temp[[i]] /. {fsub};
{extra_z1}test = test / {denom};
test = Normal[Series[test, {{{zvar}, {z0}, 8}}, {{{zzvar}, {z0}, 8}}]];
test = test /. {{{zsub}}} // Expand;
test = test /. {{{zpow}}};
test = test /. {zrep} /. {zmap} /. {{v->1-Y}} // Expand;
test = Expand[test * OptionValue["additional"] * ({missing})];

If[Head[test]===Plus,test=List@@test,test={{test}}];
test1=ParallelTable[Series[test[[j]],{{u,0,0}},{{Y,0,OptionValue["Yorder"]}},Assumptions->{{Y>0}}]//Normal//Expand,{{j,1,Length[test]}}];
Sow[test1//Total//Expand];
,{{i,1,Length[temp]}}]][[2]];
If[result=!={{}},Return[result[[1]]],Return[{{}}]];
];"""
    return new_code

pattern = re.compile(r"ClearAll\[(SeriesExpansion[a-zA-Z0-9]+)\];.*?If\[result=!={},Return\[result\[\[1\]\]\],Return\[{}\]\];\n\];", re.DOTALL)
new_code = pattern.sub(replace_func, code)

with open("improved_series_agent.wl", "w") as f:
    f.write(new_code)
