#!/usr/bin/env python3
"""
run_backtests.py  –  Multi-window backtest runner for EMACrossOver iter1
==========================================================================
Reuses the infrastructure from frontline/deploy_and_test_V4.py.

Runs the following time windows on the remote MT5 server:
  1. Monthly   : last 30 days
  2. Quarterly : last 90 days
  3. Semi-annual: last 180 days
  4. Annual    : last 365 days
  5. 2023 full year
  6. 2024 full year
  7. 2025 full year
  8. Full      : 2023-01-01 → today
  9. Worst-Q   : known hard quarter 2024-Q3 (Jul–Sep)
 10. Worst-H   : known volatile half 2024-H2 (Jul–Dec)

Usage:
    python run_backtests.py [--window <name>]   # run one window
    python run_backtests.py                     # run all windows

Prerequisites:
    - SSH key-based access to rits-student@192.168.1.83 (no password)
    - MetaEditor64 installed at LOCAL_METAEDITOR path
    - MT5 container running on remote server

Environment variable overrides (same as deploy_and_test_V4.py):
    MT5_CONTAINER_NAME, MT5_REMOTE_BASE_DIR, MT5_CONTAINER_BASE_DIR
    MT5_TESTER_LOGIN, MT5_TESTER_SERVER, MT5_TESTER_PASSWORD
"""

import subprocess
import sys
import time
import os
import re
import shutil
import argparse
from datetime import datetime, date, timedelta
from pathlib import Path

# ===========================================================================
# PATHS — edit if your environment differs
# ===========================================================================
THIS_DIR        = os.path.dirname(os.path.abspath(__file__))
FRONTLINE_DIR   = os.path.dirname(os.path.dirname(THIS_DIR))          # .../frontline
PROJECT_ROOT    = os.path.dirname(FRONTLINE_DIR)                        # repo root
CLUSTER_DIR     = os.path.dirname(THIS_DIR)                             # .../cluster-fuck

LOCAL_SOURCE_DIR   = THIS_DIR
LOCAL_BASE_INI     = os.path.join(THIS_DIR, "auto_tester_config.ini")
LOCAL_METAEDITOR   = r"C:\Users\82204\AppData\Roaming\MetaTrader 5\metaeditor64.exe"
HISTORY_BASE_DIR   = os.path.join(CLUSTER_DIR, "report_history")

SERVER             = "rits-student@192.168.1.83"
CONTAINER_NAME     = os.environ.get("MT5_CONTAINER_NAME", "mt5-dev")
SSH_OPTS           = "-o ServerAliveInterval=30 -o ServerAliveCountMax=5 -o ConnectTimeout=10"

REMOTE_BASE_DIR    = os.environ.get(
    "MT5_REMOTE_BASE_DIR",
    "/home/rits-student/podman/data/mt5/wine/drive_c/Program Files/MetaTrader 5"
)
CONTAINER_BASE_DIR = os.environ.get(
    "MT5_CONTAINER_BASE_DIR",
    "/data/mt5/wine/drive_c/Program Files/MetaTrader 5"
)

REMOTE_EXPERTS_DIR  = f"{REMOTE_BASE_DIR}/MQL5/Experts"
REMOTE_INI_PATH     = f"{REMOTE_BASE_DIR}/MQL5/auto_tester_config.ini"
REMOTE_REPORT_PATH  = f"{REMOTE_BASE_DIR}/ReportTester.html"
REMOTE_LOGS_DIR     = f"{REMOTE_BASE_DIR}/Tester/logs"

WINE_COMPILER       = r"C:\Program Files\MetaTrader 5\metaeditor64.exe"
WINE_TERMINAL       = r"C:\Program Files\MetaTrader 5\terminal64.exe"
WINE_MQ5            = r"C:\Program Files\MetaTrader 5\MQL5\Experts\_EMACrossOver_iter1_dynamic_20260617\main.mq5"
WINE_INI            = r"C:\Program Files\MetaTrader 5\MQL5\auto_tester_config.ini"

# ===========================================================================
# TIME WINDOWS
# ===========================================================================
TODAY  = date.today()

def dt(d): return d.strftime("%Y.%m.%d")

WINDOWS = {
    "monthly":      (dt(TODAY - timedelta(days=30)),   dt(TODAY)),
    "quarterly":    (dt(TODAY - timedelta(days=90)),   dt(TODAY)),
    "semi-annual":  (dt(TODAY - timedelta(days=180)),  dt(TODAY)),
    "annual":       (dt(TODAY - timedelta(days=365)),  dt(TODAY)),
    "2023":         ("2023.01.01", "2023.12.31"),
    "2024":         ("2024.01.01", "2024.12.31"),
    "2025":         ("2025.01.01", "2025.12.31"),
    "full":         ("2023.01.01", dt(TODAY)),
    "worst-q3-2024":("2024.07.01", "2024.09.30"),   # Historically volatile quarter
    "worst-h2-2024":("2024.07.01", "2024.12.31"),   # Worst half-year period
}

# ===========================================================================
# UTILITY
# ===========================================================================
def _harden_ssh(cmd):
    if re.search(r"(^|\s)ssh\s+-n\s", cmd):
        return cmd
    return re.sub(r"(^|\s)ssh\s", r"\1ssh -n ", cmd, count=1)

def run(cmd, timeout=600, exit_on_error=True):
    cmd = _harden_ssh(cmd)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, shell=True,
                           encoding="utf-8", errors="replace", timeout=timeout)
    except subprocess.TimeoutExpired as e:
        print(f"⏱️  Timeout ({timeout}s): {cmd[:80]}…")
        class _R:
            returncode = 0; stdout = ""; stderr = ""
        return _R()
    if r.returncode != 0 and exit_on_error:
        print(f"❌ Error:\n  cmd: {cmd}\n  stderr: {r.stderr.strip()}\n  stdout: {r.stdout.strip()}")
        sys.exit(1)
    return r

def ssh(remote_cmd, timeout=300):
    return run(f'ssh {SSH_OPTS} -n {SERVER} "{remote_cmd}"', timeout=timeout)

def scp_to(local, remote, timeout=120):
    return run(f'scp {SSH_OPTS} -r "{local}" "{SERVER}:{remote}"', timeout=timeout)

def scp_from(remote, local, timeout=120):
    return run(f'scp {SSH_OPTS} -r "{SERVER}:{remote}" "{local}"', timeout=timeout)

# ===========================================================================
# COMPILE
# ===========================================================================
def compile_ea():
    source = os.path.join(LOCAL_SOURCE_DIR, "main.mq5")
    ex5    = os.path.join(LOCAL_SOURCE_DIR, "main.ex5")
    log    = os.path.join(LOCAL_SOURCE_DIR, "compile.log")

    if not os.path.exists(LOCAL_METAEDITOR):
        print(f"⚠️  MetaEditor not found: {LOCAL_METAEDITOR}")
        if os.path.exists(ex5):
            print("   Using existing main.ex5")
            return
        sys.exit(1)

    print("🔨 Compiling EA locally…")
    started = time.time()
    subprocess.run([LOCAL_METAEDITOR, f"/compile:{source}", "/log"],
                   capture_output=True, text=True, timeout=240)

    # Wait for EX5 to be refreshed
    deadline = time.time() + 20
    while time.time() < deadline:
        if os.path.exists(ex5) and os.path.getmtime(ex5) >= started - 2:
            break
        time.sleep(0.5)

    log_text = ""
    if os.path.exists(log):
        try:
            with open(log, "r", encoding="utf-16", errors="ignore") as f:
                log_text = f.read()
        except Exception:
            pass

    ok = "Result: 0 errors" in log_text
    if not ok or not os.path.exists(ex5) or os.path.getmtime(ex5) < started - 2:
        print("❌ Compilation failed!")
        if log_text:
            print("".join(log_text.splitlines(keepends=True)[-40:]))
        sys.exit(1)

    print(f"✅ Compiled: {ex5}")
    return ex5

# ===========================================================================
# UPLOAD EA FILES TO REMOTE SERVER
# ===========================================================================
def upload_ea():
    print("📤 Uploading EA to remote server…")
    expert_rel = "y100143239/profitable-expert-advisor/frontline/cluster-fuck/_EMACrossOver_iter1_dynamic_20260617"
    remote_ea_dir = f"{REMOTE_EXPERTS_DIR}/{expert_rel}"
    ssh(f"mkdir -p '{remote_ea_dir}'")

    for fname in ["main.mq5", "main.ex5"]:
        local_f = os.path.join(LOCAL_SOURCE_DIR, fname)
        if os.path.exists(local_f):
            scp_to(local_f, f"'{remote_ea_dir}/'")
    print("   ✅ EA files uploaded")

# ===========================================================================
# BUILD INI FOR ONE WINDOW
# ===========================================================================
def build_ini(window_name, from_date, to_date, report_path):
    with open(LOCAL_BASE_INI, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    content = re.sub(r"FromDate=.*",    f"FromDate={from_date}",  content)
    content = re.sub(r"ToDate=.*",      f"ToDate={to_date}",      content)
    content = re.sub(r"Report=.*",      f"Report={report_path}",  content)

    # Optional: inject login/server from environment
    tester_login    = os.environ.get("MT5_TESTER_LOGIN", "").strip()
    tester_server   = os.environ.get("MT5_TESTER_SERVER", "").strip()
    tester_password = os.environ.get("MT5_TESTER_PASSWORD", "").strip()
    if tester_login:
        content = re.sub(r"Login=.*\n?", f"Login={tester_login}\n", content)
    if tester_server:
        content = re.sub(r"Server=.*\n?", f"Server={tester_server}\n", content)
    if tester_password:
        content = re.sub(r"Password=.*\n?", f"Password={tester_password}\n", content)

    return content

# ===========================================================================
# RUN ONE BACKTEST WINDOW
# ===========================================================================
def run_window(window_name, from_date, to_date):
    ts         = datetime.now().strftime("%Y%m%d_%H%M%S")
    folder     = f"emacross_iter1_{window_name}_{ts}"
    target_dir = os.path.join(HISTORY_BASE_DIR, folder)
    os.makedirs(target_dir, exist_ok=True)

    print(f"\n{'='*65}")
    print(f"▶  Window: {window_name}  |  {from_date} → {to_date}")
    print(f"   Output: {target_dir}")
    print(f"{'='*65}")

    # Build and upload INI
    wine_report = f"C:\\Users\\kasm-user\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\{folder}.html"
    ini_content = build_ini(window_name, from_date, to_date, wine_report)
    local_temp_ini = os.path.join(target_dir, "backtest_config.ini")
    with open(local_temp_ini, "w", encoding="utf-8") as f:
        f.write(ini_content)

    scp_to(local_temp_ini, f"'{REMOTE_INI_PATH}'")

    # Run terminal on remote (inside container via podman exec)
    container_ini = f"{CONTAINER_BASE_DIR}/MQL5/auto_tester_config.ini"
    remote_cmd = (
        f"podman exec {CONTAINER_NAME} wine '{WINE_TERMINAL}' "
        f"'/config:{container_ini}' '/portable'"
    )
    print("🚀 Starting MT5 tester…")
    ssh(remote_cmd, timeout=7200)   # Up to 2 hours for real-tick full backtest

    # Download report
    print("📥 Downloading results…")
    local_report = os.path.join(target_dir, "Report.html")
    scp_from(f"'{REMOTE_REPORT_PATH}'", local_report, timeout=60)

    # Download tester logs
    local_log = os.path.join(target_dir, "tester.log")
    ssh_log_result = ssh(
        f"ls '{REMOTE_LOGS_DIR}'/*.log 2>/dev/null | tail -1", timeout=30
    )
    if ssh_log_result.stdout.strip():
        latest_log = ssh_log_result.stdout.strip()
        scp_from(f"'{latest_log}'", local_log, timeout=60)

    # Parse basic metrics from HTML report
    metrics = parse_report(local_report)
    print(f"\n📊 Results for {window_name}:")
    for k, v in metrics.items():
        print(f"   {k:30s}: {v}")

    return {"window": window_name, "from": from_date, "to": to_date,
            "folder": folder, **metrics}

# ===========================================================================
# PARSE REPORT HTML
# ===========================================================================
def parse_report(html_path):
    metrics = {}
    if not os.path.exists(html_path):
        metrics["status"] = "report_missing"
        return metrics
    try:
        with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
            html = f.read()

        patterns = {
            "Total Net Profit":      r"Total Net Profit[^<]*<[^>]+>([^<]+)",
            "Profit Factor":         r"Profit Factor[^<]*<[^>]+>([^<]+)",
            "Max Drawdown":          r"Maximal Drawdown[^<]*<[^>]+>([^<]+)",
            "Win Rate %":            r"Win Trades.*?(\d+\.\d+)%",
            "Total Trades":          r"Total Trades[^<]*<[^>]+>([^<]+)",
            "Sharpe Ratio":          r"Sharpe Ratio[^<]*<[^>]+>([^<]+)",
            "Recovery Factor":       r"Recovery Factor[^<]*<[^>]+>([^<]+)",
            "Expected Payoff":       r"Expected Payoff[^<]*<[^>]+>([^<]+)",
        }
        for name, pattern in patterns.items():
            m = re.search(pattern, html, re.IGNORECASE | re.DOTALL)
            metrics[name] = m.group(1).strip() if m else "n/a"
    except Exception as e:
        metrics["parse_error"] = str(e)
    return metrics

# ===========================================================================
# SAVE SUMMARY
# ===========================================================================
def save_summary(results, out_path):
    lines = ["EMACrossOver iter1 – Multi-Window Backtest Summary",
             "=" * 65, ""]
    for r in results:
        lines.append(f"Window: {r['window']}  ({r['from']} → {r['to']})")
        lines.append(f"  Folder: {r['folder']}")
        for k, v in r.items():
            if k not in ("window", "from", "to", "folder"):
                lines.append(f"  {k:30s}: {v}")
        lines.append("")
    text = "\n".join(lines)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"\n📋 Summary saved: {out_path}")
    print(text)

# ===========================================================================
# MAIN
# ===========================================================================
def main():
    parser = argparse.ArgumentParser(description="Multi-window backtest runner for EMACrossOver iter1")
    parser.add_argument("--window", default=None, choices=list(WINDOWS.keys()),
                        help="Run only one named window (default: all)")
    parser.add_argument("--skip-compile", action="store_true",
                        help="Skip local compilation, use existing main.ex5")
    parser.add_argument("--skip-upload", action="store_true",
                        help="Skip upload (EA already on server)")
    args = parser.parse_args()

    print("=" * 65)
    print("  EMACrossOver iter1 – Multi-Window Backtest Runner")
    print("=" * 65)

    if not args.skip_compile:
        compile_ea()

    if not args.skip_upload:
        upload_ea()

    windows_to_run = {args.window: WINDOWS[args.window]} if args.window else WINDOWS

    results = []
    for name, (f, t) in windows_to_run.items():
        try:
            r = run_window(name, f, t)
            results.append(r)
        except Exception as e:
            print(f"⚠️  Window '{name}' failed: {e}")
            results.append({"window": name, "from": f, "to": t,
                            "folder": "", "status": f"ERROR: {e}"})

    summary_path = os.path.join(HISTORY_BASE_DIR, f"emacross_iter1_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
    save_summary(results, summary_path)

    print("\n✅ All windows complete.")

if __name__ == "__main__":
    main()
