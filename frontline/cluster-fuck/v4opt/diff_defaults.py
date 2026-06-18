"""Diff EA .mq5 input defaults vs the winning ini [TesterInputs].

Lists every input whose compiled default differs from the champion ini value,
so we can bake the winning config into the EA defaults for one-click live use.
"""
import re, sys

EA = sys.argv[1] if len(sys.argv) > 1 else 'ea/main.mq5'
INI = sys.argv[2] if len(sys.argv) > 2 else 'ea/backtest_config.ini'

# parse .mq5 input defaults: input <type> NAME = VALUE ;  (strip // comment)
ea_defaults = {}
inp_re = re.compile(r'^\s*input\s+(?:const\s+)?(\w+)\s+(\w+)\s*=\s*([^;]+);')
with open(EA, encoding='utf-8', errors='replace') as f:
    for line in f:
        m = inp_re.match(line)
        if m:
            typ, name, val = m.group(1), m.group(2), m.group(3).strip()
            ea_defaults[name] = (typ, val)

# parse ini [TesterInputs] NAME=value||default||min||max||flag  -> first field
ini_vals = {}
in_inputs = False
with open(INI, encoding='latin-1') as f:
    for line in f:
        s = line.strip()
        if s.startswith('['):
            in_inputs = (s.lower() == '[testerinputs]')
            continue
        if in_inputs and '=' in s:
            name, rest = s.split('=', 1)
            val = rest.split('||', 1)[0].strip()
            ini_vals[name.strip()] = val

def norm(typ, v):
    v = v.strip()
    if typ == 'bool':
        return 'true' if v.lower() in ('true', '1') else 'false'
    # numeric: compare as float when possible
    try:
        return ('%.6f' % float(v))
    except ValueError:
        return v

diffs = []
for name, ini_v in ini_vals.items():
    if name in ea_defaults:
        typ, ea_v = ea_defaults[name]
        if norm(typ, ea_v) != norm(typ, ini_v):
            diffs.append((name, typ, ea_v, ini_v))
    else:
        diffs.append((name, '?', '(no input default found)', ini_v))

print(f"EA inputs parsed: {len(ea_defaults)} | ini [TesterInputs]: {len(ini_vals)}")
print(f"DIFFERENCES (ini value != EA compiled default): {len(diffs)}\n")
for name, typ, ea_v, ini_v in diffs:
    print(f"  {name:42s} EA={ea_v:<28} INI={ini_v}")
