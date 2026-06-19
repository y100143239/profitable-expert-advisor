# Champion v2 — Stability Assessment & Validation

Config: champion `0e4db57`, EA defaults (this archive). Backtests: MT5 real-tick
(Model 4), deposit **3000 USD**, leverage **1:1000**, 2023.01.01 → 2026.06.19.

## 1. Full-period result

| Metric | Value |
|---|---|
| Total Net Profit | **$120,168** (≈ 40× on $3,000) |
| Profit Factor | **1.58** |
| Equity Drawdown (max) | **30.1%** |
| Win rate (trades) | 42.7% |
| Total trades | ~3,300 |

Equity curve: slow cold-start grind through 2023, then sustained compounding
through 2024–2026 (`windows/rel_full/*ReportTester.png`).

## 2. Yearly cold-start (fresh $3,000 each year)

| Year | Net $ | Eq DD% | PF |
|---|---|---|---|
| 2023 | +2,817 | 38.3 | 1.52 |
| 2024 | +5,824 | 30.1 | 1.38 |
| 2025 | +8,696 | 27.2 | 1.42 |
| 2026 H1 | +1,896 | 37.1 | 1.21 |

**Every full-year entry is profitable.**

## 3. Entry-time robustness (25 cold-start windows: year + half + quarter)

- **22 / 25 (88%) profitable.**
- Dispersion: net mean $2,102 / median $790 / min −$533 / max $8,696.
- Equity DD: mean 25.0% / median 25.5% / min 12.5% / max 38.3%.
- PF: median 1.34 / min 0.20 / max 2.33.

**Three losing windows — all single quarters, all bounded:**

| Window | Net $ | Eq DD% | PF | Chart shape |
|---|---|---|---|---|
| Q3 2023 | −471 | 18.1 | 0.20 | controlled stair-step down, no blow-up |
| Q4 2024 | −533 | 20.0 | 0.26 | controlled stair-step down, no blow-up |
| Q2 2025 | −34 | 25.1 | 0.97 | flat / break-even |

Worst single-window loss ≈ **−19% of principal**. No window blew up the account.

## 4. Monthly consistency (from the full run)

- 42 months: **20 winning / 22 losing**, but winners vastly outsize losers (PF 1.58).
- Best month: **2026.01 +$45,232**. Worst month: **2025.11 −$4,025**.
- Returns are **lumpy** — concentrated in a few explosive months (2025.09 +$14k,
  2025.10 +$32k, 2026.01 +$45k). Most months are small.

## 5. Why this configuration (validation trail)

- **Leverage kept high** (`ORCH_MaxBalanceScale=10`) with `URF_Enable` as dynamic
  control — outsized profit via leverage, not a hard cap. scale 10 vs 6 = +43% full profit, same cold-start DD.
- **Regime trend-align filter on** — blocks counter-trend entries; full $73.7k→$81.9k, flipped 2023 from red to green.
- **Regime Quick-Exit on (0.25×ATR)** — caps counter-trend runaways; +2.2% net,
  lower DD, higher win-rate, principal windows unharmed.
- **Strategy pruning rejected** — removing the worst attribution-PF sub-strategies
  crashed net −90% (they are net-positive via FIFO hedging/lot-feeding). Never
  prune by per-strategy PF in this multi-strategy FIFO EA.
- **Monthly breaker = month-lock** — validated as the *most protective* mode for
  the 2023 bad regime. Relaxing it (timed cooldown / off) or the shadow-probe (VRP)
  all worsened 2023 principal (DD 38%→47–60%); any within-month resumption books
  more losses in a uniformly-bad year. VRP and cooldown are implemented but kept
  **opt-in (off)**.
- **Equity-feedback guards off** — circuit-breaker / position-monitor / principal-guard
  all validated harmful (death-spiral / profit destruction) and default OFF.

## 6. Live-readiness verdict

**Conditionally live-ready.** Stable and positive across the large majority of
entry times (88%), every yearly entry green, with bounded controlled losses and
no blow-up risk — meets "稳定可实盘" for an aggressive high-leverage EA, **provided**
the operator accepts ~30–38% equity drawdowns, lumpy monthly returns, and a
possible flat/down cold-start grind in the first 1–2 quarters.

The current champion is confirmed as the **best available configuration**; this
validation produced no change to it.
