#!/usr/bin/env python3
"""
attribution.py - Per-strategy / per-symbol / per-magic P/L attribution for the
V4 multi-strategy EA, from the deals.csv emitted by analyze_report.py.

MT5's Deals table here has no Position-ID column, and exit deals carry only
"sl/tp ..." comments while entry deals carry the strategy name + magic, e.g.
  "United SuperEMA long #M940001", "WP Buy #M20260526".

We reconstruct trades with per-symbol FIFO matching: each closing ("out") deal
is matched against the oldest still-open ("in") deals of the same symbol,
splitting profit proportionally on partial closes. The realized P/L is
attributed to the opening strategy (and its magic). FIFO is an approximation
(the hedging tester may close out of order) but is reliable for ranking which
strategies/symbols are dead or net-negative.

Outputs (in the run dir):
  attribution_strategy.csv   strategy, magic, trades, wins, win_pct,
                             gross_profit, gross_loss, net_profit, profit_factor, swap
  attribution_symbol.csv     symbol, trades, net_profit, swap
  attribution.md             human-readable ranking
"""
import argparse
import csv
import os
import re
from collections import defaultdict, deque

_MAGIC_RE = re.compile(r"#M(\d+)")


def _num(s):
    if s is None:
        return 0.0
    s = str(s).replace("\u2212", "-").replace("\xa0", "").replace(" ", "").replace(",", "")
    try:
        return float(s)
    except ValueError:
        return 0.0


def _strategy_name(comment):
    c = (comment or "").strip()
    if not c:
        return "(blank)"
    return _MAGIC_RE.sub("", c).strip() or "(blank)"


def _magic(comment):
    m = _MAGIC_RE.search(comment or "")
    return m.group(1) if m else ""


def load_deals(path):
    with open(path, "r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _credit(strat, name, magic, profit, swap):
    s = strat[name]
    if not s["magic"]:
        s["magic"] = magic
    s["trades"] += 1
    s["swap"] += swap
    if profit >= 0:
        s["wins"] += 1
        s["gp"] += profit
    else:
        s["gl"] += profit


def attribute(rows):
    open_lots = defaultdict(deque)  # symbol -> deque([name, magic, remaining_vol])
    strat = defaultdict(lambda: {"magic": "", "trades": 0, "wins": 0,
                                 "gp": 0.0, "gl": 0.0, "swap": 0.0})
    sym = defaultdict(lambda: {"trades": 0, "net": 0.0, "swap": 0.0})

    for r in rows:
        direction = str(r.get("Direction", "")).lower()
        symbol = (r.get("Symbol") or "").strip()
        vol = _num(r.get("Volume"))
        if direction == "in":
            open_lots[symbol].append([_strategy_name(r.get("Comment")),
                                      _magic(r.get("Comment")), vol])
        elif direction == "out":
            profit = _num(r.get("Profit"))
            swap = _num(r.get("Swap"))
            q = open_lots[symbol]
            total = vol if vol > 0 else 0.0
            if total <= 0 or not q:
                name, magic = (q[0][0], q[0][1]) if q else ("(unmatched)", "")
                _credit(strat, name, magic, profit, swap)
            else:
                remaining = total
                while remaining > 1e-9 and q:
                    lot = q[0]
                    take = min(lot[2], remaining)
                    frac = take / total
                    _credit(strat, lot[0], lot[1], profit * frac, swap * frac)
                    lot[2] -= take
                    remaining -= take
                    if lot[2] <= 1e-9:
                        q.popleft()
            y = sym[symbol]
            y["trades"] += 1
            y["net"] += profit
            y["swap"] += swap

    return strat, sym


def write_outputs(out_dir, strat, sym):
    strat_path = os.path.join(out_dir, "attribution_strategy.csv")
    with open(strat_path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["strategy", "magic", "trades", "wins", "win_pct",
                    "gross_profit", "gross_loss", "net_profit", "profit_factor", "swap"])
        for name, d in sorted(strat.items(), key=lambda kv: kv[1]["gp"] + kv[1]["gl"]):
            net = d["gp"] + d["gl"]
            pf = (d["gp"] / abs(d["gl"])) if d["gl"] < 0 else (999.0 if d["gp"] > 0 else 0.0)
            wp = (100.0 * d["wins"] / d["trades"]) if d["trades"] else 0.0
            w.writerow([name, d["magic"], d["trades"], d["wins"], f"{wp:.1f}",
                        f"{d['gp']:.2f}", f"{d['gl']:.2f}", f"{net:.2f}",
                        f"{pf:.2f}", f"{d['swap']:.2f}"])

    sym_path = os.path.join(out_dir, "attribution_symbol.csv")
    with open(sym_path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["symbol", "trades", "net_profit", "swap"])
        for name, d in sorted(sym.items(), key=lambda kv: kv[1]["net"]):
            w.writerow([name, d["trades"], f"{d['net']:.2f}", f"{d['swap']:.2f}"])

    md_path = os.path.join(out_dir, "attribution.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# Per-strategy / per-symbol attribution (per-symbol FIFO match)\n\n")
        f.write("## Strategies (worst net first)\n\n")
        f.write("| strategy | magic | trades | win% | net | PF | swap |\n")
        f.write("|---|---|---:|---:|---:|---:|---:|\n")
        for name, d in sorted(strat.items(), key=lambda kv: kv[1]["gp"] + kv[1]["gl"]):
            net = d["gp"] + d["gl"]
            pf = (d["gp"] / abs(d["gl"])) if d["gl"] < 0 else (999.0 if d["gp"] > 0 else 0.0)
            wp = (100.0 * d["wins"] / d["trades"]) if d["trades"] else 0.0
            f.write(f"| {name} | {d['magic']} | {d['trades']} | {wp:.1f} | {net:.2f} | {pf:.2f} | {d['swap']:.2f} |\n")
        f.write("\n## Symbols (worst net first)\n\n")
        f.write("| symbol | trades | net | swap |\n")
        f.write("|---|---:|---:|---:|\n")
        for name, d in sorted(sym.items(), key=lambda kv: kv[1]["net"]):
            f.write(f"| {name} | {d['trades']} | {d['net']:.2f} | {d['swap']:.2f} |\n")
    print(f"attribution: {strat_path}\n             {sym_path}\n             {md_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out_dir", help="run dir containing deals.csv")
    args = ap.parse_args()
    deals = os.path.join(args.out_dir, "deals.csv")
    if not os.path.exists(deals):
        raise SystemExit(f"ERROR: {deals} not found")
    rows = load_deals(deals)
    strat, sym = attribute(rows)
    write_outputs(args.out_dir, strat, sym)
    n = sum(d["trades"] for d in strat.values())
    print(f"total closed legs attributed: {n}")


if __name__ == "__main__":
    main()
