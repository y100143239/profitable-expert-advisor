#!/usr/bin/env python3
"""
analyze_report.py — Parse an MT5 Strategy Tester HTML report into:
  - deals.csv        (full deal-by-deal ledger)
  - summary.csv      (setup + all summary statistics, MT5-style)
  - analysis_report.md (enhanced human-readable analysis)

Usage:
  python analyze_report.py <report.html> <output_dir> [--label NAME]
"""
import sys, os, re, csv, html, argparse
from datetime import datetime

def strip_tags(s):
    s = re.sub(r'<[^>]+>', '', s)
    return html.unescape(s).strip()

def load(path):
    with open(path, 'rb') as f:
        data = f.read()
    if data[:2] == b'\xff\xfe':
        return data.decode('utf-16-le', errors='replace')
    if data[:2] == b'\xfe\xff':
        return data.decode('utf-16-be', errors='replace')
    if data[:3] == b'\xef\xbb\xbf':
        return data[3:].decode('utf-8', errors='replace')
    return data.decode('utf-8', errors='replace')

# ---------------------------------------------------------------- deals table
def parse_deals(raw):
    """Return list of dict rows for the Deals table."""
    # Locate the Deals header block
    m = re.search(r'<b>Deals</b>', raw)
    if not m:
        return []
    sub = raw[m.end():]
    # Column header row defines order
    cols = ['Time','Deal','Symbol','Type','Direction','Volume','Price',
            'Order','Commission','Swap','Profit','Balance','Comment']
    rows = []
    # Each data row: <tr ...><td>..</td>... ends at </tr>
    for tr in re.finditer(r'<tr[^>]*>(.*?)</tr>', sub, re.S):
        cells = re.findall(r'<td[^>]*>(.*?)</td>', tr.group(1), re.S)
        if len(cells) != 13:
            continue
        vals = [strip_tags(c) for c in cells]
        # Skip the header row repeated
        if vals[0] == 'Time':
            continue
        # Only accept rows whose first cell looks like a datetime
        if not re.match(r'\d{4}\.\d{2}\.\d{2}', vals[0]):
            continue
        rows.append(dict(zip(cols, vals)))
    return rows

def num(s):
    if s is None:
        return 0.0
    s = s.replace('\xa0', '').replace(' ', '').replace(',', '')
    try:
        return float(s)
    except ValueError:
        return 0.0

# ---------------------------------------------------------------- summary stats
def parse_summary(raw):
    """Extract the label:value statistics from the top summary block."""
    stats = {}
    # The summary cells come as: <td...>Label:</td>...<td...><b>VALUE</b></td>
    # Generic: capture "Word words:" followed by next bold value
    text = raw
    pattern = re.compile(
        r'([A-Za-z][A-Za-z0-9 ()%$,./_-]+?):\s*</td>\s*'
        r'(?:<td[^>]*>\s*)?(?:<b>)?\s*([-0-9][^<]*?)\s*(?:</b>)?\s*</td>', re.S)
    for mm in pattern.finditer(text):
        k = strip_tags(mm.group(1)).strip()
        v = strip_tags(mm.group(2)).strip()
        if k and k not in stats:
            stats[k] = v
    return stats

def parse_setup(raw):
    """Extract setup lines (Expert, Symbol, Period, broker, deposit...)."""
    setup = {}
    for key in ['Expert', 'Symbol', 'Period', 'Company', 'Currency',
                'Initial Deposit', 'Leverage']:
        m = re.search(re.escape(key) + r':\s*</td>\s*<td[^>]*>(?:<b>)?(.*?)(?:</b>)?</td>', raw, re.S)
        if m:
            setup[key] = strip_tags(m.group(1))
    # Broker line (first <b> in title area)
    mt = re.search(r'<title>(.*?)</title>', raw, re.S)
    if mt:
        setup['_title'] = strip_tags(mt.group(1))
    return setup

def parse_inputs(raw):
    m = re.search(r'Inputs:\s*</td>\s*<td[^>]*>(.*?)</td>', raw, re.S)
    if not m:
        return []
    block = m.group(1)
    parts = re.split(r'<br\s*/?>', block)
    return [strip_tags(p) for p in parts if strip_tags(p)]

# ---------------------------------------------------------------- analysis
def analyze(deals):
    """Per-comment net profit + monthly/yearly P/L + exit-reason breakdown."""
    by_comment = {}
    by_month = {}
    by_year = {}
    exit_reason = {}   # reason -> [count, net_profit]
    for d in deals:
        profit = num(d['Profit']) + num(d['Swap']) + num(d['Commission'])
        sym = d['Symbol']
        if d['Type'] == 'balance' or not sym:
            continue
        cmt = d['Comment'] or '(no comment)'
        key = re.sub(r'\s*#.*$', '', cmt)
        key = re.sub(r'\s+\d[\d. ]*$', '', key).strip() or cmt
        by_comment[key] = by_comment.get(key, 0.0) + profit
        mon = d['Time'][:7]   # YYYY.MM
        yr = d['Time'][:4]
        by_month[mon] = by_month.get(mon, 0.0) + profit
        by_year[yr] = by_year.get(yr, 0.0) + profit
        if d['Direction'] == 'out':
            c = (d['Comment'] or '').strip().lower()
            if c.startswith('sl'):
                reason = 'Stop-Loss (sl)'
            elif c.startswith('tp'):
                reason = 'Take-Profit (tp)'
            elif c.startswith('so'):
                reason = 'Stop-Out (so)'
            elif c == '':
                reason = 'Signal/Trailing/Time exit'
            else:
                reason = c.split()[0]
            r = exit_reason.setdefault(reason, [0, 0.0])
            r[0] += 1
            r[1] += profit
    return by_comment, by_month, by_year, exit_reason

def fmt(x):
    return f"{x:,.2f}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('report')
    ap.add_argument('outdir')
    ap.add_argument('--label', default='')
    args = ap.parse_args()

    raw = load(args.report)
    os.makedirs(args.outdir, exist_ok=True)

    deals = parse_deals(raw)
    summary = parse_summary(raw)
    setup = parse_setup(raw)
    inputs = parse_inputs(raw)

    # ---- deals.csv
    deals_csv = os.path.join(args.outdir, 'deals.csv')
    cols = ['Time','Deal','Symbol','Type','Direction','Volume','Price',
            'Order','Commission','Swap','Profit','Balance','Comment']
    with open(deals_csv, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for d in deals:
            w.writerow(d)

    # ---- summary.csv
    summary_csv = os.path.join(args.outdir, 'summary.csv')
    with open(summary_csv, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['Section', 'Key', 'Value'])
        for k, v in setup.items():
            w.writerow(['Setup', k, v])
        for k, v in summary.items():
            w.writerow(['Statistics', k, v])

    by_comment, by_month, by_year, exit_reason = analyze(deals)

    # ---- analysis_report.md
    md = os.path.join(args.outdir, 'analysis_report.md')
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    L = []
    L.append(f"# 📊 MT5 回测增强分析报告 — {args.label}")
    L.append(f"\n**生成时间:** {now}\n")

    L.append("## 🧾 回测环境 (Setup)")
    L.append("| 项目 | 值 |\n|---|---|")
    for k in ['_title','Expert','Symbol','Period','Currency','Initial Deposit','Leverage']:
        if k in setup:
            L.append(f"| {k.lstrip('_')} | {setup[k]} |")
    L.append("")

    L.append("## 📈 核心回测指标 (Results)")
    key_metrics = ['Total Net Profit','Gross Profit','Gross Loss','Profit Factor',
                   'Expected Payoff','Recovery Factor','Sharpe Ratio',
                   'Balance Drawdown Maximal','Equity Drawdown Maximal',
                   'Balance Drawdown Relative','Equity Drawdown Relative',
                   'Total Trades','Short Trades (won %)','Long Trades (won %)',
                   'Profit Trades (% of total)','Loss Trades (% of total)',
                   'Largest profit trade','Largest loss trade',
                   'Average profit trade','Average loss trade',
                   'Maximum consecutive wins ($)','Maximum consecutive losses ($)',
                   'Average position holding time','Maximal position holding time']
    L.append("| 指标 | 值 |\n|---|---|")
    for k in key_metrics:
        if k in summary:
            L.append(f"| {k} | {summary[k]} |")
    L.append("")

    # Exit reason breakdown (meaningful for single-strategy EA)
    L.append("## 🚪 离场原因分布 (Exit Reason)")
    L.append("| 离场原因 | 笔数 | 净盈亏($) | 平均($) |\n|---|---|---|---|")
    for reason, (cnt, p) in sorted(exit_reason.items(), key=lambda kv: kv[1][1]):
        avg = p / cnt if cnt else 0.0
        L.append(f"| {reason} | {cnt} | {fmt(p)} | {fmt(avg)} |")
    L.append("")

    # Yearly breakdown
    L.append("## 📅 年度盈亏 (Yearly P/L)")
    L.append("| 年份 | 净盈亏($) |\n|---|---|")
    for yr in sorted(by_year):
        L.append(f"| {yr} | {fmt(by_year[yr])} |")
    L.append("")

    # Monthly breakdown
    L.append("## 🗓️ 月度盈亏分布 (Monthly P/L)")
    L.append("| 月份 | 净盈亏($) | 累计($) |\n|---|---|---|")
    cum = 0.0
    for mon in sorted(by_month):
        cum += by_month[mon]
        L.append(f"| {mon} | {fmt(by_month[mon])} | {fmt(cum)} |")
    L.append("")

    # Worst/best months
    if by_month:
        worst = min(by_month.items(), key=lambda kv: kv[1])
        best = max(by_month.items(), key=lambda kv: kv[1])
        neg_months = [m for m, v in by_month.items() if v < 0]
        L.append("## 🔎 关键观察")
        L.append(f"- 最佳月份: **{best[0]}** ({fmt(best[1])} USD)")
        L.append(f"- 最差月份: **{worst[0]}** ({fmt(worst[1])} USD)  ← 重点优化时间窗口")
        L.append(f"- 亏损月份数: {len(neg_months)} / {len(by_month)}")
        eq = summary.get('Equity Drawdown Maximal', '')
        bal = summary.get('Balance Drawdown Maximal', '')
        L.append(f"- 余额最大回撤: {bal} | 净值最大回撤: {eq}")
        L.append("")

    L.append("## 📎 附件清单")
    L.append("- `deals.csv` — 完整逐笔成交订单")
    L.append("- `summary.csv` — 环境与统计指标")
    L.append("- `*ReportTester.html` — MT5 原始报告")
    L.append("- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表")
    L.append("- `config.ini` / `*.set` — 本次回测参数")
    L.append("- `baseline.mq5` — 本次回测使用的源码")

    with open(md, 'w', encoding='utf-8') as f:
        f.write('\n'.join(L))

    print(f"deals parsed   : {len(deals)}")
    print(f"summary keys   : {len(summary)}")
    print(f"sub-strategies : {len(by_comment)}")
    print(f"months         : {len(by_month)}")
    print(f"wrote: {deals_csv}")
    print(f"wrote: {summary_csv}")
    print(f"wrote: {md}")

if __name__ == '__main__':
    main()
