import csv
import math
import re
import sys
from collections import defaultdict, deque
from datetime import datetime
from pathlib import Path


def resolve_deals_path(path):
    if path.is_file():
        return path
    direct = path / "deals.csv"
    if direct.exists():
        return direct
    matches = sorted(path.rglob("deals.csv"), key=lambda item: item.stat().st_mtime, reverse=True)
    if matches:
        return matches[0]
    raise FileNotFoundError(f"deals.csv not found under {path}")


def parse_money(value):
    if value is None or value == "":
        return 0.0
    return float(str(value).replace(" ", "").replace(",", ""))


def parse_time(value):
    return datetime.strptime(value, "%Y.%m.%d %H:%M:%S")


def magic_from_comment(comment):
    match = re.search(r"#M(\d+)", comment or "")
    return match.group(1) if match else ""


def group_sum(trades, key_func):
    grouped = defaultdict(lambda: {
        "net": 0.0,
        "profit": 0.0,
        "loss": 0.0,
        "n": 0,
        "vol": 0.0,
        "wins": 0,
        "max_loss": 0.0,
        "max_win": 0.0,
    })
    for trade in trades:
        key = key_func(trade)
        net = trade["net"]
        group = grouped[key]
        group["net"] += net
        group["n"] += 1
        group["vol"] += trade["volume"]
        group["max_loss"] = min(group["max_loss"], net)
        group["max_win"] = max(group["max_win"], net)
        if net >= 0:
            group["profit"] += net
            group["wins"] += 1
        else:
            group["loss"] += net
    return grouped


def profit_factor(group):
    return math.inf if group["loss"] == 0 else group["profit"] / abs(group["loss"])


def print_group(title, rows, limit, reverse=True):
    print(f"\n{title}")
    for key, group in sorted(rows.items(), key=lambda item: item[1]["net"], reverse=reverse)[:limit]:
        win_rate = group["wins"] / group["n"] * 100.0 if group["n"] else 0.0
        print(
            f"{key} net={group['net']:,.2f} pf={profit_factor(group):.2f} "
            f"n={group['n']} wr={win_rate:.1f}% vol={group['vol']:,.2f} "
            f"maxL={group['max_loss']:,.2f} maxW={group['max_win']:,.2f}"
        )


def print_stability_summary(trades, by_month, by_day):
    if not trades:
        print("\nSTABILITY SUMMARY")
        print("no reconstructed closed trades")
        return

    first_trade = min(trade["close_time"] for trade in trades)
    last_trade = max(trade["close_time"] for trade in trades)
    active_months = len(by_month)
    active_days = len(by_day)
    total_net = sum(trade["net"] for trade in trades)
    month_n = [group["n"] for group in by_month.values()]
    day_n = [group["n"] for group in by_day.values()]
    profitable_months = sum(1 for group in by_month.values() if group["net"] > 0.0)
    losing_months = sum(1 for group in by_month.values() if group["net"] < 0.0)
    sorted_month_net = sorted((group["net"] for group in by_month.values()), reverse=True)
    top3_months = sum(sorted_month_net[:3])
    top5_months = sum(sorted_month_net[:5])
    total_abs_month = sum(abs(group["net"]) for group in by_month.values())
    top3_abs = sum(sorted((abs(group["net"]) for group in by_month.values()), reverse=True)[:3])

    print("\nSTABILITY SUMMARY")
    print(f"date_span={first_trade.date()} to {last_trade.date()}")
    print(f"closed_trades={len(trades)} active_months={active_months} active_days={active_days}")
    print(f"avg_trades_per_month={len(trades) / active_months:.1f} min_month_trades={min(month_n)} max_month_trades={max(month_n)}")
    print(f"avg_trades_per_active_day={len(trades) / active_days:.1f} min_day_trades={min(day_n)} max_day_trades={max(day_n)}")
    print(f"profitable_months={profitable_months} losing_months={losing_months} month_win_rate={profitable_months / active_months * 100.0:.1f}%")
    if total_net != 0.0:
        print(f"top3_month_net_share={top3_months / total_net * 100.0:.1f}% top5_month_net_share={top5_months / total_net * 100.0:.1f}%")
    if total_abs_month != 0.0:
        print(f"top3_abs_month_concentration={top3_abs / total_abs_month * 100.0:.1f}%")
    thin_months = sorted((month for month, group in by_month.items() if group["n"] < 20))
    print("thin_months_lt20_trades=" + (", ".join(thin_months[:20]) if thin_months else "none"))


def main():
    report_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("v4_archived_multiobj_full_dynamic_v2_20230101to20260526")
    deals_path = resolve_deals_path(report_dir)

    rows = []
    trades = []
    open_positions = defaultdict(deque)
    active_volume_by_symbol = defaultdict(float)
    active_total_volume = 0.0
    max_active = (0.0, None, {})

    with deals_path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            if not row.get("Time"):
                continue
            deal_time = parse_time(row["Time"])
            symbol = row["Symbol"]
            deal_type = row["Type"]
            direction = row["Direction"]
            volume = parse_money(row["Volume"])
            profit = parse_money(row["Profit"])
            commission = parse_money(row["Commission"])
            swap = parse_money(row["Swap"])
            balance = parse_money(row["Balance"])
            comment = row["Comment"]
            rows.append((deal_time, symbol, deal_type, direction, volume, profit, commission, swap, balance, comment))

            if direction == "in" and symbol:
                open_positions[(symbol, deal_type)].append({
                    "time": deal_time,
                    "volume": volume,
                    "magic": magic_from_comment(comment),
                    "comment": comment,
                })
                active_volume_by_symbol[symbol] += volume
                active_total_volume += volume
            elif direction == "out" and symbol:
                open_side = "sell" if deal_type == "buy" else "buy"
                remaining = volume
                matched = []
                queue = open_positions[(symbol, open_side)]
                while remaining > 1e-9 and queue:
                    opened = queue[0]
                    take = min(remaining, opened["volume"])
                    matched.append((take, opened))
                    opened["volume"] -= take
                    remaining -= take
                    if opened["volume"] <= 1e-9:
                        queue.popleft()

                active_volume_by_symbol[symbol] -= volume
                active_total_volume -= volume
                net = profit + commission + swap
                if matched:
                    total_matched = sum(take for take, _ in matched)
                    for take, opened in matched:
                        fraction = take / total_matched if total_matched else 1.0 / len(matched)
                        trades.append({
                            "close_time": deal_time,
                            "open_time": opened["time"],
                            "symbol": symbol,
                            "side": open_side,
                            "volume": take,
                            "magic": opened["magic"],
                            "comment": opened["comment"],
                            "net": net * fraction,
                            "hold_hours": (deal_time - opened["time"]).total_seconds() / 3600.0,
                        })
                else:
                    trades.append({
                        "close_time": deal_time,
                        "open_time": None,
                        "symbol": symbol,
                        "side": open_side,
                        "volume": volume,
                        "magic": "",
                        "comment": comment,
                        "net": net,
                        "hold_hours": 0.0,
                    })

            if active_total_volume > max_active[0]:
                max_active = (active_total_volume, deal_time, dict(active_volume_by_symbol))

    peak_balance = -math.inf
    peak_time = None
    max_drawdown = (0.0, None, None, 0.0, 0.0)
    for deal_time, _symbol, _deal_type, _direction, _volume, _profit, _commission, _swap, balance, _comment in rows:
        if balance > peak_balance:
            peak_balance = balance
            peak_time = deal_time
        drawdown = peak_balance - balance
        if drawdown > max_drawdown[0]:
            max_drawdown = (drawdown, peak_time, deal_time, peak_balance, balance)

    by_symbol = group_sum(trades, lambda trade: trade["symbol"])
    by_side = group_sum(trades, lambda trade: (trade["symbol"], trade["side"]))
    by_magic = group_sum(trades, lambda trade: (trade["symbol"], trade["magic"], trade["comment"].split("#M")[0].strip()[:42]))
    by_month = group_sum(trades, lambda trade: trade["close_time"].strftime("%Y-%m"))
    by_day = group_sum(trades, lambda trade: trade["close_time"].strftime("%Y-%m-%d"))

    print("REPORT PROFILE")
    print(f"report_dir={report_dir}")
    print(f"deals_path={deals_path}")
    print(f"reconstructed_closed_trades={len(trades)}")
    print(
        "max_realized_balance_dd="
        f"{max_drawdown[0]:,.2f} from {max_drawdown[1]} peak={max_drawdown[3]:,.2f} "
        f"to {max_drawdown[2]} balance={max_drawdown[4]:,.2f}"
    )
    print(f"max_simultaneous_lots_proxy={max_active[0]:,.2f} at {max_active[1]}")
    print("active_symbol_lots_at_max=" + str(sorted(max_active[2].items(), key=lambda item: -item[1])[:10]))

    print_stability_summary(trades, by_month, by_day)
    print_group("BY SYMBOL", by_symbol, 20)
    print_group("BY SYMBOL SIDE", by_side, 30)
    print_group("TOP STRATEGY/MAGIC", by_magic, 25)
    print_group("WORST STRATEGY/MAGIC", by_magic, 25, reverse=False)
    print_group("BEST MONTHS", by_month, 15)
    print_group("WORST MONTHS", by_month, 15, reverse=False)
    print_group("BEST DAYS", by_day, 15)
    print_group("WORST DAYS", by_day, 20, reverse=False)


if __name__ == "__main__":
    main()