"""Run the same archived V4 MT5 backtest twice and compare core metrics."""
import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
HISTORY = ROOT / "cluster-fuck" / "report_history"
RUNNER = ROOT / "run_v4_archived_repro.py"

CORE_METRICS = {
    "period": ("period",),
    "net_profit": ("totalnetprofit", "totalnet profit", "total netprofit"),
    "balance_dd": ("balancedrawdownmaximal", "balance drawdownmaximal"),
    "equity_dd": ("equitydrawdownmaximal", "equity drawdownmaximal"),
    "profit_factor": ("profitfactor",),
    "recovery_factor": ("recoveryfactor",),
    "expected_payoff": ("expectedpayoff",),
    "total_trades": ("totaltrades",),
    "total_deals": ("totaldeals",),
    "profit_trades": ("profittrades", "profittradesoftotal"),
    "loss_trades": ("losstrades", "losstradesoftotal"),
    "win_rate": ("winrate",),
}

REQUIRED_METRICS = (
    "net_profit",
    "balance_dd",
    "equity_dd",
    "profit_factor",
    "recovery_factor",
    "expected_payoff",
    "total_trades",
    "total_deals",
    "win_rate",
)


def normalize_key(value):
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def metric_aliases():
    aliases = {}
    for metric, names in CORE_METRICS.items():
        for name in names:
            aliases[normalize_key(name)] = metric
    return aliases


ALIASES = metric_aliases()


def parse_summary(summary_path):
    metrics = {}
    with summary_path.open("r", encoding="utf-8-sig", errors="ignore", newline="") as handle:
        for row in csv.reader(handle):
            cells = [cell.strip() for cell in row]
            for index, cell in enumerate(cells):
                key = normalize_key(cell.rstrip(":"))
                if key not in ALIASES or index + 1 >= len(cells):
                    continue
                value = cells[index + 1].strip()
                if value:
                    metrics[ALIASES[key]] = value
    if "win_rate" not in metrics and "profit_trades" in metrics:
        match = re.search(r"\(([-+]?\d+(?:\.\d+)?)%\)", metrics["profit_trades"])
        if match:
            metrics["win_rate"] = match.group(1) + "%"
    return metrics


def parse_number(value):
    match = re.search(r"-?\d+(?:\.\d+)?", value.replace(",", ""))
    if not match:
        return None
    return float(match.group(0))


def latest_report_for_label(tag, label, from_date, to_date):
    prefix = f"v4_archived_{tag}_{label}_{from_date.replace('.', '')}to{to_date.replace('.', '')}_"
    matches = sorted(path for path in HISTORY.iterdir() if path.is_dir() and path.name.startswith(prefix))
    if not matches:
        raise RuntimeError(f"No report directory found for label={label}")
    return matches[-1]


def run_once(args, label):
    cmd = [
        sys.executable,
        "-u",
        str(RUNNER),
        "--source-dir",
        str(Path(args.source_dir).resolve()),
        "--from-date",
        args.from_date,
        "--to-date",
        args.to_date,
        "--tag",
        args.tag,
        "--label",
        label,
    ]
    for item in args.set:
        cmd.extend(["--set", item])
    if args.reset_agents:
        cmd.append("--reset-agents")
    if args.compile_source:
        cmd.append("--compile-source")

    print("RUN:", " ".join(f'"{part}"' if " " in part else part for part in cmd), flush=True)
    completed = subprocess.run(cmd, cwd=str(ROOT.parent), text=True, encoding="utf-8", errors="replace")
    if completed.returncode != 0:
        raise RuntimeError(f"Backtest failed for {label}, rc={completed.returncode}")
    report_dir = latest_report_for_label(args.tag, label, args.from_date, args.to_date)
    summary = report_dir / "summary.csv"
    deals = report_dir / "deals.csv"
    report = report_dir / "Report.html"
    missing = [str(path) for path in (summary, deals, report) if not path.exists() or path.stat().st_size <= 0]
    if missing:
        raise RuntimeError(f"Missing or empty artifacts for {label}: {missing}")
    metrics = parse_summary(summary)
    missing_metrics = [metric for metric in REQUIRED_METRICS if metric not in metrics]
    if missing_metrics:
        raise RuntimeError(f"Missing parsed metrics for {label}: {missing_metrics}; summary={summary}")
    return report_dir, metrics


def compare_metrics(first, second):
    diffs = []
    for metric in CORE_METRICS:
        left = first.get(metric, "")
        right = second.get(metric, "")
        if left == right:
            continue
        left_num = parse_number(left)
        right_num = parse_number(right)
        if left_num is not None and right_num is not None and abs(left_num - right_num) <= 0.01:
            continue
        diffs.append((metric, left, right))
    return diffs


def print_table(first_label, first, second_label, second):
    print("")
    print("| Metric | " + first_label + " | " + second_label + " |")
    print("| --- | ---: | ---: |")
    for metric in CORE_METRICS:
        print(f"| {metric} | {first.get(metric, '')} | {second.get(metric, '')} |")


def main():
    parser = argparse.ArgumentParser(description="Run a two-pass reproducibility gate for archived V4 MT5 backtests.")
    parser.add_argument("--source-dir", required=True)
    parser.add_argument("--from-date", default="2023.01.01")
    parser.add_argument("--to-date", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--label-prefix", required=True)
    parser.add_argument("--set", action="append", default=[])
    parser.add_argument("--reset-agents", action="store_true")
    parser.add_argument("--compile-source", action="store_true")
    args = parser.parse_args()

    first_label = f"{args.label_prefix}_repro1"
    second_label = f"{args.label_prefix}_repro2"
    first_dir, first_metrics = run_once(args, first_label)
    second_dir, second_metrics = run_once(args, second_label)

    print(f"\nREPORT_1={first_dir}")
    print(f"REPORT_2={second_dir}")
    print_table(first_label, first_metrics, second_label, second_metrics)

    diffs = compare_metrics(first_metrics, second_metrics)
    if diffs:
        print("\nREPRODUCIBILITY=FAIL")
        print("| Metric | repro1 | repro2 |")
        print("| --- | ---: | ---: |")
        for metric, left, right in diffs:
            print(f"| {metric} | {left} | {right} |")
        print("DECISION=ASK_USER")
        return 2

    print("\nREPRODUCIBILITY=PASS")
    print("DECISION=ELIGIBLE_FOR_BASELINE_COMPARISON")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
