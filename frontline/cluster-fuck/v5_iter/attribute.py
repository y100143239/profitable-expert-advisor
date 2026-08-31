"""Attribute MT5 tester P&L to sub-strategies (by opening-deal magic/comment).

FIFO-matches in->out deals per symbol; the opening deal's comment carries the
strategy tag (#M<magic> + name). Aggregates net P&L, trade count, win-rate per
strategy and per symbol, and ranks the losers (the ones that "fail" in-regime).

Usage: python attribute.py <ReportTester.htm> [label]
"""
import re, sys, os
from collections import defaultdict, deque

def read_text(path):
    raw = open(path, "rb").read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    if b"\x00" in raw[:200]:
        return raw.decode("utf-16", errors="replace")
    return raw.decode("utf-8", errors="replace")

def num(s):
    s = (s or "").replace("\u00a0", "").replace("&nbsp;", "").replace(" ", "").replace(",", "").strip()
    if s in ("", "-"): return 0.0
    try: return float(s)
    except ValueError: return 0.0

def main(path, label=""):
    txt = read_text(path)
    rows = re.findall(r'<tr[^>]*>((?:<td[^>]*>.*?</td>)+)</tr>', txt, re.S)
    openq = defaultdict(deque)
    # per-strategy and per-symbol aggregates
    strat = defaultdict(lambda: [0, 0.0, 0, 0])   # count, net, wins, losses
    sym_ag = defaultdict(lambda: [0, 0.0])
    names = {}
    for r in rows:
        tds = re.findall(r'<td[^>]*>(.*?)</td>', r, re.S)
        if len(tds) < 13: continue
        cells = [re.sub(r'<[^>]+>', '', c).strip() for c in tds]
        direction = cells[4].lower()
        if direction not in ("in", "out"): continue
        sym = cells[2]; comment = cells[-1]
        if direction == "in":
            m = re.search(r'#M(\d+)', comment)
            magic = m.group(1) if m else "?"
            nm = re.sub(r'\s*#M\d+.*$', '', comment).strip() or "(no-tag)"
            names[magic] = nm
            openq[sym].append(magic)
        else:
            profit = num(cells[10]) + num(cells[9]) + num(cells[8])  # profit + swap + commission
            magic = openq[sym].popleft() if openq[sym] else "?"
            a = strat[magic]; a[0]+=1; a[1]+=profit
            if profit >= 0: a[2]+=1
            else: a[3]+=1
            s = sym_ag[sym]; s[0]+=1; s[1]+=profit

    print(f"=== SUB-STRATEGY ATTRIBUTION: {label} ===")
    print(f"{'magic':>12} {'name':28} {'trades':>7} {'net':>11} {'win%':>6}")
    for magic, (n, net, w, l) in sorted(strat.items(), key=lambda kv: kv[1][1]):
        wr = (100.0*w/n) if n else 0
        print(f"{magic:>12} {names.get(magic,'?')[:28]:28} {n:>7} {net:>11.2f} {wr:>5.1f}%")
    print(f"\n=== BY SYMBOL ===")
    for s, (n, net) in sorted(sym_ag.items(), key=lambda kv: kv[1][1]):
        print(f"  {s:10} n={n:>5} net={net:>11.2f}")
    tot = sum(v[1] for v in strat.values())
    losers = sum(v[1] for v in strat.values() if v[1] < 0)
    print(f"\n  TOTAL net={tot:.2f} | sum of losing strategies={losers:.2f}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
