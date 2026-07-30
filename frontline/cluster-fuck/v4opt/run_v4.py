#!/usr/bin/env python3
"""
run_v4.py - One-command window runner for the V4 multi-strategy EA.

Pipeline per window:
  1. make_ini.py   -> per-window tester ini (Expert/Report/dates patched,
                      [TesterInputs] preserved byte-for-byte)
  2. run_iter.py   -> compile main.mq5 (+includes) locally, deploy to mt5-dev,
                      run real-tick backtest, download report html/png, run
                      analyze_report.py (deals.csv / summary.csv / analysis_report.md)
  3. attribution.py-> per-strategy / per-symbol P/L breakdown
  4. snapshot the exact EA source (main.mq5 + .mqh + Strategies/) into the run
     folder for later forensics

Usage:
  python run_v4.py --tag baseline_full --from 2023.01.01 --to 2026.06.17 \
                   [--ea <main.mq5>] [--base-ini <backtest_config.ini>] \
                                     [--label "..."] [--max-poll 300] [--deposit 3000] [--leverage 1000]

The default model is 1-minute OHLC (Model=1), with Playwright Graph monitoring.
Use --model 4 for the real-tick promotion pass after a quick result is accepted.
"""
import argparse
import datetime as _dt
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CF = os.path.dirname(HERE)                       # frontline/cluster-fuck
V4 = os.path.join(CF, "v4_archived_multiobj_full_dynamic_v2")
RUN_ITER = os.path.join(CF, "run_iter.py")
DEFAULT_EA = os.path.join(V4, "main.mq5")
DEFAULT_BASE_INI = os.path.join(V4, "backtest_config.ini")


def sh(cmd):
    print("+", " ".join(cmd))
    r = subprocess.run(cmd)
    if r.returncode != 0:
        raise SystemExit(f"command failed ({r.returncode}): {cmd}")


def snapshot_source(ea, out_dir):
    src_root = os.path.dirname(ea)
    dst = os.path.join(out_dir, "src")
    os.makedirs(dst, exist_ok=True)
    # main + sibling includes
    for name in os.listdir(src_root):
        p = os.path.join(src_root, name)
        if os.path.isfile(p) and name.lower().endswith((".mq5", ".mqh")):
            shutil.copy2(p, os.path.join(dst, name))
    # Strategies/
    strat = os.path.join(src_root, "Strategies")
    if os.path.isdir(strat):
        shutil.copytree(strat, os.path.join(dst, "Strategies"), dirs_exist_ok=True)
    print(f"source snapshot -> {dst}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", required=True)
    ap.add_argument("--from", dest="from_date", required=True)
    ap.add_argument("--to", dest="to_date", required=True)
    ap.add_argument("--ea", default=DEFAULT_EA)
    ap.add_argument("--base-ini", default=DEFAULT_BASE_INI)
    ap.add_argument("--label", default="")
    ap.add_argument("--max-poll", type=int, default=300)
    ap.add_argument("--deposit", default="3000")
    ap.add_argument("--leverage", default="1000")
    ap.add_argument("--symbol", default="EURUSD")
    ap.add_argument("--model", default="1", choices=["1", "4"],
                    help="1 = minute OHLC screening; 4 = real-tick promotion pass")
    ap.add_argument("--monitor-interval", type=int, default=1,
                    help="capture Graph screenshots every N polls; 0 disables monitoring")
    ap.add_argument("--monitor-interactive-auth", action="store_true",
                    help="prompt for noVNC credentials before starting MT5")
    ap.add_argument("--set", action="append", default=[],
                    help="override a [TesterInputs] key: KEY=VALUE (repeatable)")
    args = ap.parse_args()

    ts = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = os.path.join(HERE, "runs", f"{args.tag}_{ts}")
    os.makedirs(out_dir, exist_ok=True)

    report = f"{args.tag}_ReportTester"
    ex5_base = os.path.splitext(os.path.basename(args.ea))[0] + ".ex5"
    ini_path = os.path.join(out_dir, f"{args.tag}.ini")

    # 1. generate ini
    ini_cmd = [sys.executable, os.path.join(HERE, "make_ini.py"),
               "--base", args.base_ini, "--out", ini_path,
               "--expert", ex5_base, "--report", report,
               "--from", args.from_date, "--to", args.to_date,
               "--deposit", args.deposit, "--leverage", args.leverage,
               "--symbol", args.symbol, "--model", args.model]
    for kv in args.set:
        ini_cmd += ["--set", kv]
    sh(ini_cmd)

    # 2. compile + deploy + run + download + analyze
    label = args.label or f"{args.tag} {args.from_date}->{args.to_date}"
    run_cmd = [sys.executable, RUN_ITER,
        "--ea", args.ea, "--ini", ini_path, "--out", out_dir,
        "--report-name", report, "--label", label,
        "--max-poll", str(args.max_poll),
        "--monitor-interval", str(args.monitor_interval)]
    if args.monitor_interactive_auth:
        run_cmd.append("--monitor-interactive-auth")
    sh(run_cmd)

    # 3. attribution
    try:
        sh([sys.executable, os.path.join(HERE, "attribution.py"), out_dir])
    except SystemExit as e:
        print(f"WARN attribution skipped: {e}")

    # 4. source snapshot
    snapshot_source(args.ea, out_dir)

    print("\n==== WINDOW DONE ====")
    print("out:", out_dir)


if __name__ == "__main__":
    main()
