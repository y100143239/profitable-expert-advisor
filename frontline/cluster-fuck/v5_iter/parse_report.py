"""Parse an MT5 Strategy Tester HTML report (UTF-16, Chinese locale) into clean metrics.

Usage: python parse_report.py <ReportTester.htm> [label]
Prints a one-line summary and appends to results.csv next to the report.
"""
import re, sys, os, csv

CN = {
    "总净盈利": "net_profit",
    "盈利因子": "profit_factor",
    "最大结余亏损": "balance_dd",
    "最大净值亏损": "equity_dd",
    "交易总计": "trades",
    "最大 亏损交易": "worst_trade",
    "最大 获利交易": "best_trade",
    "预期收益": "expected_payoff",
    "夏普比率": "sharpe",
    "采收率": "recovery_factor",
    "盈利交易 (% 全部)": "win_trades",
    "亏损交易 (% 全部)": "loss_trades",
}

def read_text(path):
    raw = open(path, "rb").read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    if b"\x00" in raw[:200]:
        return raw.decode("utf-16", errors="replace")
    return raw.decode("utf-8", errors="replace")

def main(path, label=""):
    txt = read_text(path)
    pairs = {}
    for m in re.finditer(r'<td[^>]*>([^<]{2,40}:)</td>\s*<td[^>]*><b>([^<]+)</b>', txt):
        pairs[m.group(1).strip().rstrip(":")] = m.group(2).strip()
    out = {"label": label}
    for cn, key in CN.items():
        out[key] = pairs.get(cn, "")
    # split "234.46 (7.53%)" -> value + pct
    def pct(v):
        m = re.search(r'\(([-\d.]+)%\)', v)
        return m.group(1) if m else ""
    out["balance_dd_pct"] = pct(out.get("balance_dd", ""))
    out["equity_dd_pct"] = pct(out.get("equity_dd", ""))
    # print concise
    print(f"LABEL: {label}")
    print(f"  Net Profit     : {out['net_profit']}")
    print(f"  Profit Factor  : {out['profit_factor']}")
    print(f"  Balance DD max : {out['balance_dd']}")
    print(f"  Equity  DD max : {out['equity_dd']}")
    print(f"  Trades         : {out['trades']}")
    print(f"  Win / Loss     : {out['win_trades']} / {out['loss_trades']}")
    print(f"  Worst trade    : {out['worst_trade']}")
    print(f"  Sharpe / Recov : {out['sharpe']} / {out['recovery_factor']}")
    # append to results.csv
    d = os.path.dirname(os.path.abspath(path))
    rc = os.path.join(d, "..", "results.csv")
    rc = os.path.normpath(rc)
    cols = ["label","net_profit","profit_factor","balance_dd","equity_dd","trades",
            "win_trades","loss_trades","worst_trade","sharpe","recovery_factor"]
    exists = os.path.exists(rc)
    with open(rc, "a", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        if not exists: w.writeheader()
        w.writerow(out)
    print(f"  -> appended to {rc}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
