import re

with open("audit_agent/audit_agent.wl", "r") as f:
    content = f.read()

new_logic = """  If[bestFile === None,
    AppendTo[checks, Association["Status"->"PASS", "Check"->"preseries-mpl-caches", "Message"->"No MPL files required for this basis."]];
  ,
    mplPrefix = StringReplace[FileBaseName[bestFile], ".m" -> ""];
    If[StringContainsQ[mplPrefix, "fourloop"],
      suffixes = {
        {"e0", "_inuv"}, {"e0", "_inuvp"},
        {"e1", "_inuv"}, {"e1", "_inuvp"},
        {"einf", "_inuv"}, {"einf", "_inuvp"}
      };
    ,
      suffixes = {
        {"e0", ""}, {"e1", ""}, {"einf", ""}
      };
    ];
    Do[
      sfxSuffix = s[[2]];
      ext = s[[1]] <> sfxSuffix <> ".txt";"""

content = re.sub(
    r"  If\[bestFile === None,[\s\S]*?ext = s\[\[1\]\] <> sfxSuffix <> \"\.txt\";",
    new_logic,
    content
)

with open("audit_agent/audit_agent.wl", "w") as f:
    f.write(content)
