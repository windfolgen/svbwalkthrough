"""Check the solved kernel against unused OPE moments and the crossed wheel."""
import argparse
from collections import defaultdict
import json
from pathlib import Path
from zipfile import ZipFile

from flint import fmpq as Q
from bootstrap import HERE, common, kernel_target
from spectral import graph_series


def projections(folder):
    if folder:
        return [common.parse((folder/f"check_{tag}.txt").read_text().strip()) for tag in ("native","cross")]
    with ZipFile(HERE/"word_projections.zip") as archive:
        return [{tuple((key,n) for key,n in powers):Q(c)
                 for powers,c in json.loads(archive.read(f"check_{tag}.json"))} for tag in ("native","cross")]


def lower_loops(cap):
    tree = {(i,j,0):Q(1) for i in range(cap+1) for j in range(cap+1-i)}
    assert graph_series(cap,0,1)==tree
    box = {}
    for n in range(cap+1):
        for i in range(n+1):
            box[i,n-i,0], box[i,n-i,1] = Q(2,(n+1)**2), Q(-1,n+1)
    squared = defaultdict(Q)
    for (i,j,l),c in box.items():
        for (a,b,h),v in box.items():
            if i+j+a+b<=cap:
                squared[i+a,j+b,l+h] += c*v
    for zeta3 in (0,1):
        assert graph_series(cap,zeta3,2)==squared


def main(folder=None):
    lower_loops(10)
    native,cross = projections(folder)
    assert native == kernel_target(8)
    held = sum(max(dict(k).get('z',0),dict(k).get('zz',0))>5 for k in native)
    assert held==315
    # A wheel with four spokes gives F ~ -20*zeta(5)*log(v).
    linear_log = {k:c for k,c in cross.items() if dict(k).get("lg")==1
                  and dict(k).get("z",0)+dict(k).get("zz",0)==1}
    assert linear_log=={common.mon({x:1,"lg":1,"f[5]":1}):Q(20) for x in ("z","zz")}
    assert all(dict(k).get("lg",0)<3 for k in cross)
    # H_101 and H_011 have Y^m coefficients H_(m-1)^(2)/m and H_(m-1)/m^2.
    graph=graph_series(32,0)
    h1=h2=Q(0)
    for n in range(33):
        h1+=Q(1,n+1)
        h2+=Q(1,(n+1)**2)
        assert graph[0,n,4]==Q(2,3)*(h2/(n+2)-h1/(n+2)**2)
    print(f"Verified {held} new native coefficients, the crossed wheel, the quartic HPL boundary and both lower-loop normalizations.")


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--projections",type=Path,help="Read Maple's freshly expanded kernel")
    main(parser.parse_args().projections)
