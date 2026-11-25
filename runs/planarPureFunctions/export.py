"""Write the exact P_i and the 32 sparse leading-singularity formulas in anc/."""
import argparse
from pathlib import Path
from zipfile import ZipFile, Path as ZipPath
import sympy as sp
from census import census

u,v,d,y,yC = sp.symbols("u v d y yC")
simple=(1/d,); odd_u=(1/d,1/(d*(u-1))); odd_v=(1/d,1/(d*(v-1)))
pair=(v/(d*(v-1)),v/d**2)
prefactors = [
 simple,(1/d,(u-v-1)/d**2),simple,odd_u,simple,odd_u,
 (1/(d*(1-u)),1/(d*(1-v)),1/(d*(1-u-v)),1/d**2),(v/d**2,),odd_v,
 (1/d,1/(d*(u-1)),1/(d*(v-1)),u/(d*y)),pair,
 (1/d,(1+v)/(d*(v-1)),(1-u+v)/d**2),
 (u/(d*(1-u)),u/(d*(1-u+v)),u/d**2),
 (1/d**2,u/d**2,v/d**2,1/(d*(u-1)),u/(d*(u-1)),-2*u/(d*y),2/(d*yC),-2/d,-2/d),
 (v/d**2,),simple,simple,(v/d**2,),(v/d**2,),simple,(v/(d*(v-1)),),(v/(d*(v-1)),),
 (1/d**2,),simple,pair,odd_v,
 (1/d,1/(d*(u-1)),u/(d*(u-v)),1/(d*(v-1)),1/d**2,u/d**2,v/d**2),
 simple,(u/d**2,),(v/d**2,1/d,v/(d*(u-v)),v/(d*(1-v)),2/d),pair,(u/d**2,)
]
extra = {"10.4":44,"14.6":44,"14.7":45,"30.5":46,"14.8":47,"14.9":48}
def matrix(data):
    terms = dict(data["fixed_basis"]["coefficients"])
    terms.update({s:{str(i):"1"} for s,i in extra.items()})
    rows = []
    for r, factors in enumerate(prefactors,1):
        row = {}
        for j,factor in enumerate(factors,1):
            for i,c in terms.pop(f"{r}.{j}").items():
                row[int(i)] = row.get(int(i),0) + sp.Rational(c)*factor
        rows.append({i:sp.factor(c) for i,c in sorted(row.items()) if c!=0})
    assert not terms and len(rows)==32
    return rows


def poly(vec):
    terms=[]
    for w,v in sorted(vec.items()):
        sign = '-' if v<0 else '+'
        c = '' if abs(v)==1 else str(abs(v))+'*'
        terms.append(sign+c+w)
    return '\n  '.join(terms).lstrip('+')


def export(work, dest):
    vecs=[]
    data=census(work,vecs)
    rows=matrix(data)
    def expr(c): return str(c).replace('**','^').replace(' ','')
    wl = ['''(* Pure functions and leading singularities for the 32 planar terms.
   Load with z, zz, u, v, d, y, yC and the package words unassigned.
   The two arguments of each function are the conjugate Euclidean endpoints.
   Continue the two algebraic primitives on the same sheets as y and yC. *)
Module[{directory=DirectoryName[$InputFileName], ext=FileExtension[$InputFileName],
 pure,singularities,read,scalar,primitive,scalarQ},
 read[name_]:=Get[FileNameJoin[{directory,"fourloop"<>name<>"."<>ext}]];
 scalar=read["I26"];
 primitive=Function@@{First[Cases[read["I214"],_Inactive[__],Infinity]] /. {z->Slot[1],zz->Slot[2]}};
 scalarQ[q_,b_,value_]:=(q-b)*(1-q)*(1-b)*value;
 pure={''']
    wl.append(',\n'.join('Function[{z,zz},\n  '+poly(vec)+']' for vec in vecs))
    wl.append(''',
 primitive, Function[{q,b},-primitive[1/b,1/q]],
 Function[{q,b},scalarQ[q,b,scalar[q,b]]],
 Function[{q,b},With[{t=q/(q-1),h=b/(b-1)},scalarQ[t,h,scalar[h,t]]]],
 Function[{q,b},scalarQ[1-q,1-b,scalar[1-b,1-q]]]};
 singularities={''')
    wl.append(',\n'.join('<|'+', '.join(f'{i}->{expr(c)}' for i,c in row.items())+'|>' for row in rows))
    wl.append('''};
 <|"P"->pure,"LeadingSingularities"->singularities|>
]
''')
    wolfram_source = '\n'.join(wl)
    for filename in (
        'fourloopPlanarPureBasis.m', 'fourloopPlanarPure.m', 'fourloopPlanarPure.txt', 'pure_function_basis.m',
    ):
        (dest/filename).write_text(wolfram_source)
    mp=['''# Read HyperlogProcedures and fourloopBootstrap.mpl dependencies first.
# PlanarP[i] is callable on two endpoints. PlanarLS[r] lists [i, l_ri].
# y and yC must continue with their corresponding algebraic primitives.
''']
    mp.extend(f'PlanarP[{i}]:=unapply(\n  '+poly(vec)+',z,zz):' for i,vec in enumerate(vecs,1))
    mp.append('''PlanarP[44]:=proc(q,b)
 local s,disc,ab;
 disc:=(1-z*zz)^2-4*(1-z)*(1-zz): ab:=I214Differential(sqrt(disc)):
 Int(subs({z=s*q,zz=s*b},q*ab[1]+b*ab[2]),s=0..1)
end proc:
PlanarP[45]:=(q,b)->-PlanarP[44](1/b,1/q):
PlanarP[46]:=(q,b)->(q-b)*(1-q)*(1-b)*I26Euclidean(q,b):
PlanarP[47]:=(q,b)->(q/(q-1)-b/(b-1))*(1-q/(q-1))*(1-b/(b-1))*I26Euclidean(b/(b-1),q/(q-1)):
PlanarP[48]:=(q,b)->(b-q)*q*b*I26Euclidean(1-b,1-q):''')
    mp.extend(f'PlanarLS[{r}]:=['+', '.join(f'[{i},{expr(c)}]' for i,c in row.items())+']:' for r,row in enumerate(rows,1))
    (dest/'fourloopPlanarPure.mpl').write_text('\n'.join(mp)+'\n')


if __name__ == "__main__":
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('work',type=Path)
    ap.add_argument('destination',type=Path)
    args=ap.parse_args()
    if args.work.is_dir():
        export(args.work,args.destination)
    else:
        with ZipFile(args.work) as archive:
            export(ZipPath(archive),args.destination)
