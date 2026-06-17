#!/usr/bin/env python3
"""
make_ini.py - Generate a per-window MT5 tester .ini from the V4 base config.

Only the ASCII [Tester] header keys are rewritten (Expert/Report/FromDate/
ToDate/Deposit/Leverage/Symbol). The [TesterInputs] block is preserved
byte-for-byte because it contains non-ASCII (GBK) input identifiers that
MetaTrader must match exactly - any re-encoding would corrupt them.

The file is read/written as latin-1 (ISO-8859-1), a lossless 1:1 byte map
for single-byte ANSI content (verified: no BOM, no NUL bytes).
"""
import argparse

# Keys we are allowed to overwrite (all live in the ASCII [Tester] section).
TESTER_KEYS = ("Expert", "Report", "FromDate", "ToDate",
               "Deposit", "Leverage", "Symbol", "Period")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", required=True, help="base ini to clone")
    ap.add_argument("--out", required=True, help="output ini path")
    ap.add_argument("--expert")
    ap.add_argument("--report")
    ap.add_argument("--from", dest="from_date")
    ap.add_argument("--to", dest="to_date")
    ap.add_argument("--deposit")
    ap.add_argument("--leverage")
    ap.add_argument("--symbol")
    ap.add_argument("--period")
    ap.add_argument("--set", action="append", default=[],
                    help="override a [TesterInputs] key: KEY=VALUE (repeatable). "
                         "Only the leading value token before the first '||' is "
                         "replaced, preserving any optimize min/step/max/flag tail. "
                         "Intended for ASCII keys (e.g. Enable*); never targets "
                         "the non-ASCII identifier lines.")
    args = ap.parse_args()

    input_sets = {}
    for kv in args.set:
        if "=" not in kv:
            raise SystemExit(f"ERROR: --set expects KEY=VALUE, got: {kv}")
        k, v = kv.split("=", 1)
        k = k.strip()
        if not k.isascii():
            raise SystemExit(f"ERROR: refusing non-ASCII --set key: {k}")
        input_sets[k] = v

    overrides = {}
    if args.expert:    overrides["Expert"] = args.expert
    if args.report:    overrides["Report"] = args.report
    if args.from_date: overrides["FromDate"] = args.from_date
    if args.to_date:   overrides["ToDate"] = args.to_date
    if args.deposit:   overrides["Deposit"] = args.deposit
    if args.leverage:  overrides["Leverage"] = args.leverage
    if args.symbol:    overrides["Symbol"] = args.symbol
    if args.period:    overrides["Period"] = args.period

    with open(args.base, "r", encoding="latin-1", newline="") as f:
        text = f.read()

    lines = text.split("\n")
    section = None
    out = []
    seen = set()
    seen_inputs = set()
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped
            out.append(line)
            continue
        if section == "[Tester]" and "=" in line and not stripped.startswith(";"):
            key = line.split("=", 1)[0].strip()
            if key in overrides:
                # preserve trailing \r if present
                cr = "\r" if line.endswith("\r") else ""
                out.append(f"{key}={overrides[key]}{cr}")
                seen.add(key)
                continue
        if section == "[TesterInputs]" and "=" in line and not stripped.startswith(";"):
            key = line.split("=", 1)[0].strip()
            if key in input_sets:
                cr = "\r" if line.endswith("\r") else ""
                rhs = line.split("=", 1)[1]
                rhs = rhs[:-1] if rhs.endswith("\r") else rhs
                tail = ""
                if "||" in rhs:
                    tail = "||" + rhs.split("||", 1)[1]
                out.append(f"{key}={input_sets[key]}{tail}{cr}")
                seen_inputs.add(key)
                continue
        out.append(line)

    missing = [k for k in overrides if k not in seen]
    if missing:
        raise SystemExit(f"ERROR: keys not found in [Tester]: {missing}")
    missing_inputs = [k for k in input_sets if k not in seen_inputs]
    if missing_inputs:
        raise SystemExit(f"ERROR: keys not found in [TesterInputs]: {missing_inputs}")

    with open(args.out, "w", encoding="latin-1", newline="") as f:
        f.write("\n".join(out))
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
