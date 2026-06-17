import argparse
import csv
import math
from datetime import datetime, timedelta
from pathlib import Path


def parse_money(value):
    if value is None or value == "":
        return 0.0
    return float(str(value).replace(" ", "").replace(",", ""))


def parse_time(value):
    return datetime.strptime(value, "%Y.%m.%d %H:%M:%S")


def resolve_deals_path(path):
    path = Path(path)
    if path.is_file():
        return path
    direct = path / "deals.csv"
    if direct.exists():
        return direct
    raise FileNotFoundError(f"deals.csv not found: {path}")


def load_balance_rows(deals_path):
    rows = []
    with deals_path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            if not row.get("Time") or not row.get("Balance"):
                continue
            rows.append((parse_time(row["Time"]), parse_money(row["Balance"])))
    return rows


def max_drawdown(rows):
    peak_balance = -math.inf
    peak_time = None
    best = (0.0, None, None, 0.0, 0.0)
    for row_time, balance in rows:
        if balance > peak_balance:
            peak_balance = balance
            peak_time = row_time
        drawdown = peak_balance - balance
        if drawdown > best[0]:
            best = (drawdown, peak_time, row_time, peak_balance, balance)
    return best


def max_rolling_drawdown(rows, days):
    best = (0.0, None, None, 0.0, 0.0)
    for start_index, (start_time, _start_balance) in enumerate(rows):
        end_time = start_time + timedelta(days=days)
        peak_balance = -math.inf
        peak_time = None
        for row_time, balance in rows[start_index:]:
            if row_time > end_time:
                break
            if balance > peak_balance:
                peak_balance = balance
                peak_time = row_time
            drawdown = peak_balance - balance
            if drawdown > best[0]:
                best = (drawdown, peak_time, row_time, peak_balance, balance)
    return best


def format_window(best, pad_days):
    drawdown, peak_time, trough_time, peak_balance, trough_balance = best
    if peak_time is None or trough_time is None:
        return {
            "dd": drawdown,
            "peak_time": "",
            "trough_time": "",
            "peak_balance": peak_balance,
            "trough_balance": trough_balance,
            "from_date": "",
            "to_date": "",
        }
    return {
        "dd": drawdown,
        "peak_time": peak_time.strftime("%Y-%m-%d %H:%M:%S"),
        "trough_time": trough_time.strftime("%Y-%m-%d %H:%M:%S"),
        "peak_balance": peak_balance,
        "trough_balance": trough_balance,
        "from_date": (peak_time - timedelta(days=pad_days)).strftime("%Y.%m.%d"),
        "to_date": (trough_time + timedelta(days=pad_days)).strftime("%Y.%m.%d"),
    }


def main():
    parser = argparse.ArgumentParser(description="Extract yearly realized balance drawdown windows from MT5 deals.csv.")
    parser.add_argument("path", help="Report directory or deals.csv path")
    parser.add_argument("--rolling-days", type=int, default=30)
    parser.add_argument("--pad-days", type=int, default=7)
    args = parser.parse_args()

    rows = load_balance_rows(resolve_deals_path(args.path))
    years = sorted({row_time.year for row_time, _balance in rows})
    print("year,kind,dd,peak_time,peak_balance,trough_time,trough_balance,from_date,to_date")
    for year in years:
        year_rows = [(row_time, balance) for row_time, balance in rows if row_time.year == year]
        for kind, best in (
            ("full_year", max_drawdown(year_rows)),
            (f"rolling_{args.rolling_days}d", max_rolling_drawdown(year_rows, args.rolling_days)),
        ):
            item = format_window(best, args.pad_days)
            print(
                f"{year},{kind},{item['dd']:.2f},{item['peak_time']},{item['peak_balance']:.2f},"
                f"{item['trough_time']},{item['trough_balance']:.2f},{item['from_date']},{item['to_date']}"
            )


if __name__ == "__main__":
    main()