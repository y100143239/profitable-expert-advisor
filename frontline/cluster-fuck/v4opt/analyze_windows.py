"""Build a comprehensive multi-window performance + risk assessment.

Inputs:
  --full   <run_dir>   the full-period cold-start run (deals.csv + analysis_report.md)
  --window <run_dir>   repeatable; each cold-start window run
  --out    <md path>   output ASSESSMENT.md

From the FULL run's deal-by-deal balance curve it derives monthly / quarterly /
half-year / yearly SEGMENT performance and rolling-6-month worst window, plus
balance-drawdown per segment. For each cold-start WINDOW run it pulls the headline
real-tick metrics (net profit, PF, DD, win rate). Cold-start windows answer
"what if the EA is switched on at the start of this window with a fresh deposit".
"""
import argparse, csv, glob, os, re
from collections import OrderedDict

DEP = 3000.0

def num(s):
    s = (s or '').replace('\u202f', '').replace('\xa0', '').replace(' ', '').replace('\u2212', '-')
    if s in ('', '-'):
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0

def load_balance_curve(deals_csv):
    rows = list(csv.DictReader(open(deals_csv, encoding='utf-8')))
    curve = []  # (datetime_str, balance, profit_of_deal)
    for r in rows:
        if not r.get('Balance'):
            continue
        curve.append((r['Time'], num(r['Balance']), num(r.get('Profit')) + num(r.get('Swap')) + num(r.get('Commission'))))
    return curve

def ym(t):       # 'YYYY.MM.DD ...' -> 'YYYY-MM'
    return t[0:4] + '-' + t[5:7]
def yq(t):
    q = (int(t[5:7]) - 1)//3 + 1
    return f"{t[0:4]}-Q{q}"
def yh(t):
    h = 1 if int(t[5:7]) <= 6 else 2
    return f"{t[0:4]}-H{h}"
def yy(t):
    return t[0:4]

def segment(curve, keyfn):
    """net P/L and max balance-DD per segment key, plus start/end balance."""
    seg = OrderedDict()
    for t, b, p in curve:
        k = keyfn(t)
        if k not in seg:
            seg[k] = {'start_bal': None, 'end_bal': b, 'peak': b, 'dd': 0.0, 'pl': 0.0}
        d = seg[k]
        if d['start_bal'] is None:
            d['start_bal'] = b - p  # balance just before first deal of segment
        d['pl'] += p
        if b > d['peak']:
            d['peak'] = b
        d['dd'] = max(d['dd'], d['peak'] - b)
        d['end_bal'] = b
    return seg

def rolling_6mo_worst(curve):
    # month-end balances
    me = OrderedDict()
    for t, b, p in curve:
        me[ym(t)] = b
    months = list(me.items())
    worst = None
    for i in range(len(months)):
        j = i + 6
        if j < len(months):
            start_b = months[i][1]; end_b = months[j][1]
            ret = (end_b - start_b) / start_b * 100 if start_b else 0
            if worst is None or ret < worst[2]:
                worst = (months[i][0], months[j][0], ret)
    return worst

def overall_dd(curve):
    peak = -1e18; mdd = 0.0; mddpct = 0.0; minb = (None, 1e18)
    for t, b, p in curve:
        if b > peak:
            peak = b
        dd = peak - b
        if dd > mdd:
            mdd = dd; mddpct = dd/peak*100 if peak else 0
        if b < minb[1]:
            minb = (t, b)
    return mdd, mddpct, minb

RE = {
    'net': r'Total Net Profit\s*\|\s*([-\d  .,\u202f\u2212]+)',
    'pf': r'Profit Factor\s*\|\s*([-\d.]+)',
    'baldd': r'Balance Drawdown Maximal\s*\|\s*([^|]+)',
    'eqdd': r'Equity Drawdown Maximal\s*\|\s*([^|]+)',
    'eqddrel': r'Equity Drawdown Relative\s*\|\s*([^|]+)',
    'trades': r'Total Trades\s*\|\s*([-\d]+)',
    'winpct': r'Profit Trades \(% of total\)\s*\|\s*([^|]+)',
    'sharpe': r'Sharpe Ratio\s*\|\s*([-\d.]+)',
}
def parse_report(md):
    txt = open(md, encoding='utf-8').read()
    out = {}
    for k, pat in RE.items():
        m = re.search(pat, txt)
        out[k] = m.group(1).strip() if m else 'n/a'
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--full', required=True)
    ap.add_argument('--window', action='append', default=[])
    ap.add_argument('--auto-runs', default=None, help='glob window dirs from this runs/ dir')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    if a.auto_runs:
        order = ['w_year_2023', 'w_year_2024', 'w_year_2025', 'w_year_2026h',
                 'w_h1_2023', 'w_h2_2023', 'w_h1_2024', 'w_h2_2024',
                 'w_h1_2025', 'w_h2_2025', 'w_h1_2026']
        for pref in order:
            hits = sorted(glob.glob(os.path.join(a.auto_runs, pref + '_*')))
            if hits:
                a.window.append(hits[-1])
    print(f"windows to include: {len(a.window)}")

    full_deals = os.path.join(a.full, 'deals.csv')
    curve = load_balance_curve(full_deals)
    mdd, mddpct, minb = overall_dd(curve)
    r6 = rolling_6mo_worst(curve)
    full_rep = parse_report(os.path.join(a.full, 'analysis_report.md'))

    L = []
    L.append("# 冠军EA多窗口回测评估 (Champion EA Multi-Window Assessment)\n")
    L.append("Real-tick (every tick based on real ticks) backtests, deposit $3000 @ 1:1000.\n")
    L.append("## 1. 全量表现 (Full period 2023.01.01 - 2026.06.18)\n")
    L.append("| Metric | Value |\n|---|---|")
    L.append(f"| Net Profit | {full_rep['net']} |")
    L.append(f"| Profit Factor | {full_rep['pf']} |")
    L.append(f"| Sharpe | {full_rep['sharpe']} |")
    L.append(f"| Total Trades | {full_rep['trades']} |")
    L.append(f"| Win rate | {full_rep['winpct']} |")
    L.append(f"| Balance DD Maximal | {full_rep['baldd']} |")
    L.append(f"| Equity DD Maximal | {full_rep['eqdd']} |")
    L.append(f"| Equity DD Relative (worst %) | {full_rep['eqddrel']} |")
    L.append(f"| Min balance (principal floor) | {minb[1]:.2f} @ {minb[0]}  ({(DEP-minb[1])/DEP*100:.2f}% of $3000) |")
    if r6:
        L.append(f"| Worst rolling 6-month return | {r6[2]:.2f}%  ({r6[0]} -> {r6[1]}) |")
    L.append("")

    L.append("## 2. 年度盈亏 (Yearly segments, continuous run)\n")
    L.append("| Year | Net P/L | Return on seg-start | Max bal-DD in seg |\n|---|---|---|---|")
    for k, d in segment(curve, yy).items():
        ret = d['pl']/d['start_bal']*100 if d['start_bal'] else 0
        L.append(f"| {k} | {d['pl']:,.2f} | {ret:.1f}% | {d['dd']:,.2f} |")
    L.append("")

    L.append("## 3. 半年盈亏 (Half-year segments)\n")
    L.append("| Half | Net P/L | Return | Max bal-DD |\n|---|---|---|---|")
    for k, d in segment(curve, yh).items():
        ret = d['pl']/d['start_bal']*100 if d['start_bal'] else 0
        L.append(f"| {k} | {d['pl']:,.2f} | {ret:.1f}% | {d['dd']:,.2f} |")
    L.append("")

    L.append("## 4. 季度盈亏 (Quarterly segments)\n")
    L.append("| Quarter | Net P/L | Return | Max bal-DD |\n|---|---|---|---|")
    for k, d in segment(curve, yq).items():
        ret = d['pl']/d['start_bal']*100 if d['start_bal'] else 0
        L.append(f"| {k} | {d['pl']:,.2f} | {ret:.1f}% | {d['dd']:,.2f} |")
    L.append("")

    L.append("## 5. 月度盈亏 (Monthly segments)\n")
    L.append("| Month | Net P/L | Return | Max bal-DD |\n|---|---|---|---|")
    neg = 0
    for k, d in segment(curve, ym).items():
        ret = d['pl']/d['start_bal']*100 if d['start_bal'] else 0
        if d['pl'] < 0:
            neg += 1
        L.append(f"| {k} | {d['pl']:,.2f} | {ret:.1f}% | {d['dd']:,.2f} |")
    L.append("")

    L.append("## 6. 冷启动窗口 (Cold-start windows — fresh $3000 at each window start)\n")
    L.append("Directly tests live-start risk: worst case if you switch the EA on at the start of that window.\n")
    L.append("| Window | Net Profit | PF | Bal-DD | Eq-DD | Eq-DD Rel | Trades | WinRate |\n|---|---|---|---|---|---|---|---|")
    for w in a.window:
        tag = os.path.basename(w.rstrip('/\\'))
        rp = parse_report(os.path.join(w, 'analysis_report.md'))
        L.append(f"| {tag} | {rp['net']} | {rp['pf']} | {rp['baldd']} | {rp['eqdd']} | {rp['eqddrel']} | {rp['trades']} | {rp['winpct']} |")
    L.append("")

    months_total = len(segment(curve, ym))
    L.append("## 7. 风险点 (Risk assessment)\n")
    L.append(f"- 负盈利月份 (losing months): {neg} / {months_total}")
    L.append(f"- 全期最大净值回撤 (max equity DD): {full_rep['eqdd']}; 最差相对回撤 (worst relative): {full_rep['eqddrel']}")
    L.append(f"- 本金最低点 (principal floor): {minb[1]:.2f} ({(DEP-minb[1])/DEP*100:.2f}% below $3000) @ {minb[0]}")
    if r6:
        L.append(f"- 最差滚动半年 (worst rolling 6mo): {r6[2]:.2f}%")
    L.append("- 杠杆/保证金: 1:1000; URF margin facade OFF -> no built-in margin breaker. Never liquidated across 2023-2026 but a sharp adverse move at a low-equity start is the main tail risk.")
    L.append("- 回撤集中在2023本金积累期 (DD concentrated in the 2023 capital-building phase, near principal); the large 2026 drawdowns are profit-zone (cushioned by banked gains).")
    L.append("")
    open(a.out, 'w', encoding='utf-8').write("\n".join(L))
    print(f"wrote {a.out}  ({len(L)} lines)")

if __name__ == '__main__':
    main()
