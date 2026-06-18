"""Pinpoint the trades that drive the historical max balance drawdown.

Reads a run's deals.csv, reconstructs the running balance (already present),
finds the peak->trough max-DD window, and breaks down the realized losses in
that window by symbol and by entry-strategy (via FIFO comment carry).
Goal: identify which losses cause max DD so we can mitigate WITHOUT cutting
recoverable / profitable trades.
"""
import sys, csv, re
from collections import defaultdict, deque

def num(s):
    if s is None:
        return 0.0
    s = s.strip().replace('\u202f', '').replace('\xa0', '').replace(' ', '')
    s = s.replace('\u2212', '-')  # unicode minus
    if s in ('', '-'):
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0

def load(path):
    rows = []
    with open(path, encoding='utf-8') as f:
        r = csv.DictReader(f)
        for d in r:
            rows.append(d)
    return rows

def main(path):
    rows = load(path)
    # running balance curve from out deals (Balance col already running)
    bals = []
    for d in rows:
        b = num(d['Balance'])
        bals.append((d['Time'], b, d))
    # max drawdown over balance series
    peak = -1e18; peak_i = 0
    max_dd = 0.0; lo_i = hi_i = 0
    cur_peak_i = 0
    for i,(t,b,d) in enumerate(bals):
        if b > peak:
            peak = b; cur_peak_i = i
        dd = peak - b
        if dd > max_dd:
            max_dd = dd; hi_i = cur_peak_i; lo_i = i
    pt, pb, _ = bals[hi_i]
    lt, lb, _ = bals[lo_i]
    print(f"== File: {path}")
    print(f"Final balance: {bals[-1][1]:,.2f}")
    print(f"Max balance DD: {max_dd:,.2f}  ({max_dd/pb*100:.2f}% of peak {pb:,.2f})")
    print(f"  Peak  @ {pt}  bal={pb:,.2f}  (deal idx {hi_i})")
    print(f"  Trough@ {lt}  bal={lb:,.2f}  (deal idx {lo_i})")
    window = bals[hi_i+1:lo_i+1]
    print(f"  Deals in DD window: {len(window)}")

    # FIFO: carry entry strategy comment to out deal for attribution
    # open lots per symbol: deque of (volume, strat)
    books = defaultdict(deque)
    sym_loss = defaultdict(float); sym_prof = defaultdict(float)
    strat_loss = defaultdict(float); strat_prof = defaultdict(float)
    big = []  # (profit, time, symbol, strat, volume)
    def strat_of(comment):
        m = re.search(r'#M\d+', comment or '')
        # prefer the leading label before #M
        label = (comment or '').split('#M')[0].strip()
        return label if label else (comment or '').strip()

    in_window = set(range(hi_i+1, lo_i+1))
    for i, d in enumerate(rows):
        sym = d['Symbol']
        typ = d['Type']
        direction = d['Direction']
        vol = num(d['Volume'])
        profit = num(d['Profit']) + num(d['Swap']) + num(d['Commission'])
        comment = d['Comment']
        if direction == 'in':
            books[(sym, typ)].append((vol, strat_of(comment)))
        elif direction == 'out':
            # match against opposite side book
            opp = 'buy' if typ == 'sell' else 'sell'
            dq = books[(sym, opp)]
            remain = vol; strat = None
            while remain > 1e-9 and dq:
                ov, ostrat = dq[0]
                strat = strat or ostrat
                take = min(ov, remain)
                ov -= take; remain -= take
                if ov <= 1e-9:
                    dq.popleft()
                else:
                    dq[0] = (ov, ostrat)
            strat = strat or strat_of(comment)
            if i in in_window:
                if profit < 0:
                    sym_loss[sym] += profit; strat_loss[strat] += profit
                else:
                    sym_prof[sym] += profit; strat_prof[strat] += profit
                big.append((profit, d['Time'], sym, strat, vol))

    print("\n-- Realized P/L inside max-DD window, by SYMBOL --")
    syms = sorted(set(list(sym_loss)+list(sym_prof)), key=lambda s: sym_loss[s])
    for s in syms:
        print(f"  {s:12s} loss={sym_loss[s]:11,.2f}  prof={sym_prof[s]:10,.2f}  net={sym_loss[s]+sym_prof[s]:11,.2f}")

    print("\n-- Realized P/L inside max-DD window, by STRATEGY (FIFO entry comment) --")
    strs = sorted(set(list(strat_loss)+list(strat_prof)), key=lambda s: strat_loss[s])
    for s in strs[:25]:
        print(f"  {s[:38]:38s} loss={strat_loss[s]:11,.2f}  prof={strat_prof[s]:10,.2f}  net={strat_loss[s]+strat_prof[s]:11,.2f}")

    print("\n-- 15 single largest losing trades inside DD window --")
    big.sort(key=lambda x: x[0])
    for p,t,s,st,v in big[:15]:
        print(f"  {p:11,.2f}  {t}  {s:10s} vol={v:6.2f}  {st[:34]}")

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'runs/p5_wptrim_full_20260618_055424/deals.csv')
