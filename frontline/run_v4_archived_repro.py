"""Run an archived V4 source snapshot, optionally recompiling main.ex5.

This is for forensic reproduction of report_history snapshots where the exact EX5
is part of the strategy identity.
"""
import argparse
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = ROOT / "cluster-fuck"
HISTORY = PROJECT_ROOT / "report_history"
DEFAULT_SOURCE_DIR = PROJECT_ROOT / "_repro_v4_iter10_best_20260517"
DEPLOY = ROOT / "deploy_and_test_V4.py"
PYTHON_EXE = r"C:\Users\82204\.conda\envs\mt5\python.exe"


def atomic_write(path, text):
    tmp = path.with_suffix(path.suffix + ".tmp")
    last_error = None
    for _ in range(10):
        try:
            tmp.write_text(text, encoding="utf-8")
            os.replace(str(tmp), str(path))
            return
        except PermissionError as exc:
            last_error = exc
            time.sleep(0.5)
    raise last_error


def patch_key(text, key, value):
    pattern = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
    if not pattern.search(text):
        raise RuntimeError(f"Missing key in ini: {key}")
    return pattern.sub(f"{key}={value}", text)


def patch_window(text, from_date, to_date):
    text = patch_key(text, "FromDate", from_date)
    text = patch_key(text, "ToDate", to_date)
    text = patch_key(text, "Symbol", "EURUSD")
    return text


def parse_period(summary_path):
    text = summary_path.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r"Period:,\s*\S+\s*\(([\d.]+)\s*-\s*([\d.]+)\)", text)
    if not match:
        return None, None
    return match.group(1), match.group(2)


def latest_new_dir(before, prefix=None):
    after = {path.name for path in HISTORY.iterdir() if path.is_dir()}
    new = after - before
    if prefix:
        new = {name for name in new if name.startswith(prefix + "_")}
    new = sorted(new)
    return HISTORY / new[-1] if new else None


def sanitize_report_prefix(value):
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("._-")


def parse_set(value):
    key, raw = value.split("=", 1)
    return key, raw


def run(source_dir, from_date, to_date, tag, label, set_values, reset_agents, compile_source):
    source_dir = source_dir.resolve()
    ini = source_dir / "auto_tester_config.ini"
    ex5 = source_dir / "main.ex5"
    if not ini.exists():
        raise RuntimeError(f"Missing ini: {ini}")
    if not ex5.exists():
        raise RuntimeError(f"Missing archived EX5: {ex5}")

    original = ini.read_text(encoding="utf-8", errors="ignore")
    before = {path.name for path in HISTORY.iterdir() if path.is_dir()}
    patched = patch_window(original, from_date, to_date)
    for key, value in set_values:
        patched = patch_key(patched, key, value)
    atomic_write(ini, patched)

    env = os.environ.copy()
    env["MT5_NO_EXPLORER"] = "1"
    env["PYTHONIOENCODING"] = "utf-8"
    env["PYTHONUTF8"] = "1"
    env["MT5_V4_LOCAL_SOURCE_DIR"] = str(source_dir)
    env["MT5_V4_LOCAL_INI_PATH"] = str(ini)
    if not compile_source:
        env["MT5_SKIP_LOCAL_COMPILE"] = "1"
        env["MT5_SKIP_REMOTE_COMPILE"] = "1"
    env["MT5_SKIP_CALENDAR_DEPLOY"] = "1"
    if reset_agents:
        env["MT5_RESET_LOCAL_TESTER_AGENTS"] = "1"

    report_prefix = sanitize_report_prefix(f"v4_archived_{tag}_{label}")
    env["MT5_REPORT_PREFIX"] = report_prefix
    log_path = ROOT / f"v4_archived_{tag}_{label}.log"
    try:
        print(f"\n=== RUN archived {tag}_{label} {from_date}->{to_date}", flush=True)
        print(f"source={source_dir}", flush=True)
        print(f"sets={dict(set_values)}", flush=True)
        with log_path.open("w", encoding="utf-8", errors="replace") as log:
            rc = subprocess.Popen([PYTHON_EXE, "-u", str(DEPLOY)], stdout=log, stderr=subprocess.STDOUT, cwd=str(ROOT.parent), env=env).wait()
    finally:
        atomic_write(ini, original)

    report_dir = latest_new_dir(before, report_prefix)
    if report_dir is None:
        print(f"FAIL rc={rc}: no new report dir; log={log_path}", flush=True)
        return 1
    summary = report_dir / "summary.csv"
    if not summary.exists():
        print(f"FAIL rc={rc}: missing summary.csv in {report_dir}; log={log_path}", flush=True)
        return 1
    actual_from, actual_to = parse_period(summary)
    if actual_from != from_date or actual_to != to_date:
        stale = HISTORY / f"STALE_v4_archived_{tag}_{label}_{datetime.now():%Y%m%d_%H%M%S}"
        report_dir.rename(stale)
        print(f"STALE requested={from_date}~{to_date} actual={actual_from}~{actual_to} -> {stale.name}", flush=True)
        return 2

    run_ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    target = HISTORY / f"v4_archived_{tag}_{label}_{from_date.replace('.', '')}to{to_date.replace('.', '')}_{run_ts}"
    if target.exists():
        target = HISTORY / f"v4_archived_{tag}_{label}_{from_date.replace('.', '')}to{to_date.replace('.', '')}_{run_ts}_dup"
    report_dir.rename(target)
    print(f"OK -> {target.name}", flush=True)
    return 0 if rc == 0 else rc


def main():
    parser = argparse.ArgumentParser(description="Run an archived V4 EX5 without recompiling.")
    parser.add_argument("--source-dir", default=str(DEFAULT_SOURCE_DIR))
    parser.add_argument("--from-date", default="2023.01.01")
    parser.add_argument("--to-date", default="2023.11.30")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--set", action="append", default=[], type=parse_set)
    parser.add_argument("--reset-agents", action="store_true")
    parser.add_argument("--compile-source", action="store_true", help="Compile source_dir/main.mq5 instead of using archived main.ex5.")
    args = parser.parse_args()
    return run(Path(args.source_dir), args.from_date, args.to_date, args.tag, args.label, args.set, args.reset_agents, args.compile_source)


if __name__ == "__main__":
    raise SystemExit(main())
