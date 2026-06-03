with open("generate_series_agent.py", "r") as f:
    code = f.read()

code = code.replace("el = temp[[i]] /. pre_sub;", "el = temp[[i]] /. {pre_sub};")
code = code.replace("el = el /. zz_sub;", "el = el /. {zz_sub};")
code = code.replace("el = el /. neg_sub;", "el = el /. {neg_sub};")

with open("generate_series_agent.py", "w") as f:
    f.write(code)
