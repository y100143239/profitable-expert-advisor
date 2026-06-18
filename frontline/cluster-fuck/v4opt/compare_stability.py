"""Compare cold-start stability between two variants (e.g. greedy w_ vs safer sv_).

For each base window it reads both variants' analysis_report.md (net profit, max
equity DD%, PF, win rate) and prints a side-by-side table plus stability stats
across the cold-start windows (yearly + half-year; the full-period run is shown
but excluded from the dispersion stats).
"""
import argparse, glob, os, re, statistics as st

BASES = ['year_2023', 'year_2024', 'year_2025', 'year_2026h',
         'h1_2023', 'h2_2023', 'h1_2024', 'h2_2024',
         'h1_2025', 'h2_2025', 'h1_2026']
FULL = 'full_2023_2026'

def num(s):
    s = (s or '').replace('\u202f', '').replace('\xa0', '').replace(' ', '').replace('\u2212', '-')
    try:
        return float(s)
    except ValueError:
        return float('nan')

def latest(runs, prefix, base):
    hits = sorted(glob.glob(os.path.join(runs, f"{prefix}{base}_*")))
    return hits[-1] if hits else None

def parse(d):
    if not d:
        return None
    txt = open(os.path.join(d, 'analysis_report.md'), encoding='utf-8').read()
    def g(pat):
        m = re.search(pat, txt)
        return m.group(1).strip() if m else ''
    net = num(g(r'Total Net Profit\s*\|\s*([-\d  .,\u202f\u2212]+)'))
    pf = num(g(r'Profit Factor\s*\|\s*([-\d.]+)'))
    eqdd = g(r'Equity Drawdown Maximal\s*\|\s*[^(]*\(([-\d.]+)%\)')
    win = g(r'Profit Trades \(% of total\)\s*\|\s*[^(]*\(([-\d.]+)%\)')
    return {'net': net, 'pf': pf, 'eqdd': num(eqdd), 'win': num(win)}

def stab(vals):
    v = [x for x in vals if x == x]  # drop nan
    if not v:
        return {}
    return {'n': len(v), 'mean': st.mean(v), 'median': st.median(v),
            'std': st.pstdev(v) if len(v) > 1 else 0.0,
            'min': min(v), 'max': max(v)}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--runs', default='runs')
    ap.add_argument('--a-prefix', default='w_')
    ap.add_argument('--b-prefix', default='sv_')
    ap.add_argument('--a-name', default='GREEDY')
    ap.add_argument('--b-name', default='SAFER')
    ap.add_argument('--out', default=None)
    a = ap.parse_args()

    L = []
    def out(s=''):
        L.append(s)

    out(f"# Stability comparison: {a.a_name} ({a.a_prefix}) vs {a.b_name} ({a.b_prefix})\n")
    out(f"Cold-start windows, fresh $3000. Net = net profit; DD = max equity DD %.\n")
    out(f"| Window | {a.a_name} Net | {a.a_name} DD% | {a.a_name} PF | {a.b_name} Net | {a.b_name} DD% | {a.b_name} PF |")
    out("|---|---|---|---|---|---|---|")
    A, B = {}, {}
    for base in [FULL] + BASES:
        ra = parse(latest(a.runs, a.a_prefix, base))
        rb = parse(latest(a.runs, a.b_prefix, base))
        A[base], B[base] = ra, rb
        def f(r, k, p=''):
            if not r or r[k] != r[k]:
                return 'n/a'
            return (f"{r[k]:,.0f}" if k == 'net' else f"{r[k]:.2f}") + p
        out(f"| {base} | {f(ra,'net')} | {f(ra,'eqdd')} | {f(ra,'pf')} | {f(rb,'net')} | {f(rb,'eqdd')} | {f(rb,'pf')} |")
    out('')

    # dispersion across cold-start windows (exclude full)
    for name, D in [(a.a_name, A), (a.b_name, B)]:
        nets = [D[b]['net'] for b in BASES if D[b]]
        dds = [D[b]['eqdd'] for b in BASES if D[b]]
        pfs = [D[b]['pf'] for b in BASES if D[b]]
        sn, sd = stab(nets), stab(dds)
        prof = sum(1 for x in nets if x > 0)
        out(f"## {name} stability across {len(nets)} cold-start windows")
        out(f"- profitable windows: {prof}/{len(nets)}")
        if sn:
            cv = sn['std']/abs(sn['mean']) if sn['mean'] else float('nan')
            out(f"- net profit: mean {sn['mean']:,.0f}, median {sn['median']:,.0f}, std {sn['std']:,.0f}, CV {cv:.2f}, min {sn['min']:,.0f}, max {sn['max']:,.0f}")
        if sd:
            out(f"- max equity DD%: mean {sd['mean']:.1f}, median {sd['median']:.1f}, WORST {sd['max']:.1f}, best {sd['min']:.1f}")
        out(f"- worst-PF window: {min(pfs):.2f}" if pfs else '')
        out('')

    text = "\n".join(L)
    print(text)
    if a.out:
        open(a.out, 'w', encoding='utf-8').write(text)
        print(f"\nwrote {a.out}")

if __name__ == '__main__':
    main()
