"""Aggregate the cold-start stability matrix (sm_* runs) for one config.

Reads each window's analysis_report.md -> net profit, max equity DD%, PF, win%.
Prints a table grouped by duration (quarter/half/year/full), dispersion stats,
worst windows, and the equity-curve PNG path for each window (for chart review).
"""
import glob, os, re, statistics as st

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, "runs")

GROUPS = {
    "FULL":      ["full"],
    "YEAR":      ["y2023", "y2024", "y2025", "y2026h"],
    "HALF":      ["h1_2023", "h2_2023", "h1_2024", "h2_2024", "h1_2025", "h2_2025", "h1_2026"],
    "QUARTER":   ["q1_2023", "q2_2023", "q3_2023", "q4_2023",
                  "q1_2024", "q2_2024", "q3_2024", "q4_2024",
                  "q1_2025", "q2_2025", "q3_2025", "q4_2025",
                  "q1_2026", "q2_2026"],
}

def num(s):
    s = (s or '').replace('\u202f', '').replace('\xa0', '').replace(' ', '').replace('\u2212', '-')
    try:
        return float(s)
    except ValueError:
        return float('nan')

def latest(base):
    hits = sorted(glob.glob(os.path.join(RUNS, f"sm_{base}_*")))
    return hits[-1] if hits else None

def parse(d):
    if not d or not os.path.exists(os.path.join(d, 'analysis_report.md')):
        return None
    txt = open(os.path.join(d, 'analysis_report.md'), encoding='utf-8').read()
    def g(pat):
        m = re.search(pat, txt)
        return m.group(1).strip() if m else ''
    png = sorted(glob.glob(os.path.join(d, '*ReportTester.png')))
    return {
        'dir': d,
        'net': num(g(r'Total Net Profit\s*\|\s*([-\d  .,\u202f\u2212]+)')),
        'pf': num(g(r'Profit Factor\s*\|\s*([-\d.]+)')),
        'eqdd': num(g(r'Equity Drawdown Maximal\s*\|\s*[^(]*\(([-\d.]+)%\)')),
        'win': num(g(r'Profit Trades \(% of total\)\s*\|\s*[^(]*\(([-\d.]+)%\)')),
        'png': png[0] if png else '',
    }

def main():
    print("# Cold-start stability matrix (current champion defaults, fresh $3000)\n")
    all_rows = []
    for grp, bases in GROUPS.items():
        print(f"## {grp}")
        print("| window | net $ | eqDD% | PF | win% | chart |")
        print("|---|---|---|---|---|---|")
        for base in bases:
            r = parse(latest(base))
            if not r:
                print(f"| {base} | MISSING | | | | |")
                continue
            all_rows.append((grp, base, r))
            print(f"| {base} | {r['net']:,.0f} | {r['eqdd']:.1f} | {r['pf']:.2f} | {r['win']:.1f} | {os.path.basename(r['png'])} |")
        print()

    # dispersion across cold-start windows (exclude FULL)
    cs = [r for grp, base, r in all_rows if grp != "FULL"]
    nets = [r['net'] for r in cs if r['net'] == r['net']]
    dds = [r['eqdd'] for r in cs if r['eqdd'] == r['eqdd']]
    pfs = [r['pf'] for r in cs if r['pf'] == r['pf']]
    print("## Dispersion across cold-start windows (excl. full)")
    if nets:
        pos = sum(1 for x in nets if x > 0)
        print(f"- windows: {len(nets)} | profitable: {pos}/{len(nets)} ({pos/len(nets)*100:.0f}%)")
        print(f"- net $: mean {st.mean(nets):,.0f} | median {st.median(nets):,.0f} | min {min(nets):,.0f} | max {max(nets):,.0f}")
        print(f"- eqDD%: mean {st.mean(dds):.1f} | median {st.median(dds):.1f} | min {min(dds):.1f} | max {max(dds):.1f}")
        print(f"- PF: mean {st.mean(pfs):.2f} | median {st.median(pfs):.2f} | min {min(pfs):.2f} | max {max(pfs):.2f}")
    # worst windows
    print("\n## Worst windows")
    worst_net = sorted(cs, key=lambda r: r['net'])[:5]
    worst_dd = sorted(cs, key=lambda r: -r['eqdd'])[:5]
    for r in worst_net:
        print(f"- LOW NET  {os.path.basename(r['dir'])}: net {r['net']:,.0f}, eqDD {r['eqdd']:.1f}%, PF {r['pf']:.2f}")
    for r in worst_dd:
        print(f"- HIGH DD  {os.path.basename(r['dir'])}: eqDD {r['eqdd']:.1f}%, net {r['net']:,.0f}, PF {r['pf']:.2f}")

if __name__ == "__main__":
    main()
