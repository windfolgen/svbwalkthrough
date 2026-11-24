"""Compare the direct paper-order svMPL fit with the earlier full radial GPL expression."""

import argparse
import json
from pathlib import Path
from shutil import which
import subprocess
from tempfile import TemporaryDirectory

package = Path(__file__).resolve().parent
old = package / "inputs"


def g(word, endpoint):
    return "i[" + ",".join([endpoint, *word, "0"]) + "]" if word else "1"


def radial_expression():
    terms = []
    words = json.loads((old / "scalar_kernel_gpl.json").read_text())["terms"]
    for k, w, c in words:
        for h in sorted({w, w.translate(str.maketrans("AB", "BA"))}):
            letters = [{"A": "1/z", "B": "1/zz", "0": "0"}[a] for a in h]
            terms.append(f"({c})*ell^{k}*" + g(letters, "1"))
    periods = json.loads((old / "scalar_kernel_period_terms.json").read_text())["terms"]
    for k, w, v, c in periods:
        for a, b in sorted({(w, v), (v, w)}):
            sign = (-1) ** (a.count("1") + b.count("1"))
            terms.append(f"({sign*c})*ell^{k}*f[3]*" + g(a, "z") + "*" + g(b, "zz"))
    return "+\n".join(terms)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--library", type=Path, default=Path.home() / "maple/HyperlogProcedures08"
    )
    p.add_argument("--maple", default=which("maple") or "maple")
    args = p.parse_args()
    with TemporaryDirectory() as name:
        script = Path(name) / "check.mpl"
        script.write_text(
            """restart:
currentdir("LIBRARY"):
read "HyperlogProcedures":kernelopts(numcpus=1):
read "PACKAGE/anc/fourloopI26.mpl":
ell:=i[z,0,0]+i[zz,0,0]:
old:=RADIAL:
original:=convertitoL(basisi(old,z,zz),z,zz):
direct:=convertPtoL(convertItoP(I26P7SV)):
delta:=expand(shuffleexpand(direct-original,[L,LL,f])):
printf("Exact function difference = %a\\n",delta):
for uv in [[3/10,2/5],[3/5,4/5],[47/100,93/100]] do
 a,b:=op(uv):q:=(1+a-b+sqrt((1+a-b)^2-4*a))/2:
 printf("P7(%a,%a) = %a\\n",a,b,evalf[16](I26P7Value(q,conjugate(q),23))):
end do:
quit:
""".replace("LIBRARY", str(args.library.resolve()))
            .replace("PACKAGE", str(package.parents[1]))
            .replace("RADIAL", radial_expression())
        )
        result = subprocess.run(
            [args.maple, "-q", str(script)], capture_output=True, text=True, check=True
        )
        print(result.stdout, end="")
        if (
            "Exact function difference = 0\n" not in result.stdout
            or "Error," in result.stdout + result.stderr
        ):
            raise SystemExit("Comparison failed")
