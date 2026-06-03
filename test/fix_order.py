with open("generate_series_agent.py", "r") as f:
    code = f.read()

code = code.replace("      el = el /. {v -> 1 - Y};\n      el = el /. zrepSer;\n", "      el = el /. {{v -> 1 - Y}};\n      el = el /. zrepSer;\n")

with open("generate_series_agent.py", "w") as f:
    f.write(code)
