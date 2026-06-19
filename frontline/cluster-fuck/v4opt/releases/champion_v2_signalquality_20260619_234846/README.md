# Champion v2 — Signal-Quality EA (one-click live release)

Multi-strategy MetaTrader 5 Expert Advisor. This folder is a **self-contained,
frozen snapshot** of the current best configuration, ready for one-click live
deployment.

- **Commit lineage:** champion `0e4db57` (signal-quality + shadow-breaker) on branch `v4opt-champion`.
- **Designed for:** deposit **3000 USD**, leverage **1:1000**.
- **Symbols traded:** EURUSD, XAUUSD, BTCUSD, GER40/DE40, plus US stock CFDs (AAPL, NVDA, TSLA, MU) — see `champion_v2.set` `*_Symbol` / `Enable*` inputs.

> ⚠️ **High-leverage aggressive EA.** Backtests show ~30–38% equity drawdowns
> and lumpy returns. Only deploy capital you can afford to lose and read the
> risk section below.

---

## 1. One-click deployment

1. Copy the EA source (or the compiled `main.ex5`) into your terminal's
   `MQL5/Experts/` folder:
   - For source: copy `ea/main.mq5`, `ea/*.mqh` and the whole `ea/Strategies/`
     folder, keeping the relative layout, then compile `main.mq5` in MetaEditor.
   - For binary: copy `ea/main.ex5` directly (must match your terminal build).
2. Open a chart (any symbol/timeframe — the EA manages its own symbol list).
3. Drag the EA onto the chart. In the **Inputs** tab click **Load** and select
   `champion_v2.set` (the frozen default parameters).
4. Enable **Algo Trading**. Confirm the account is **1:1000 leverage** with a
   **3000 USD** balance for the calibrated behaviour.

The `.set` file encodes exactly the compiled defaults (verified to reproduce the
backtests). No manual tuning is required.

> 🛠️ **Compile note (Windows MAX_PATH):** if you compile `main.mq5` from *inside
> this deep archive folder*, MetaEditor may fail to open the `Strategies/*.mqh`
> includes because the full path exceeds Windows' 260-character limit (you would
> see spurious `undeclared identifier InitRSIScalping` errors). This is a path
> limit, **not** a code defect. Either use the shipped `ea/main.ex5` directly, or
> copy the `ea/` folder to a short path (e.g. `C:\MT5EA\`) before compiling. The
> source here is byte-identical to the validated champion (`main.mq5` SHA-256
> matches the source that compiled with 0 errors across all stability backtests).

---

## 2. What is configured by default

| Lever | Default | Purpose |
|---|---|---|
| `ORCH_MaxBalanceScale` | 10.0 | Position-size compounding cap (outsized-profit via leverage) |
| `ORCH_ReferenceBalance` | 3000 | Baseline balance for dynamic sizing |
| `URF_Enable` | true | Dynamic margin facade — governs cold-start drawdown |
| `GRM_TrendAlignEnable` | true | D1 regime filter — blocks counter-trend entries |
| `RQE_Enable` | true | **Regime Quick-Exit** — caps counter-trend runaway losses (0.25×ATR) |
| `GRM_MonthlyLossLimitFreeMarginPct` | 3.0 | Monthly-loss breaker (month-lock — most protective) |
| `GRM_MonthlyLossCooldownHours` | 0.0 | 0 = month-lock; >0 = re-arming cooldown (opt-in) |
| `VRP_Enable` | false | Virtual Recovery Probe (shadow-trading breaker) — opt-in |

Validated-off (kept default OFF because they hurt performance): circuit-breaker
(`CB_*`), position-monitor (`PM_*`), principal-guard (`PG_*`), session gate
(`SessGate_*`), `EnableRSIConsolidation`.

See `ASSESSMENT.md` for the full validation and rationale.

---

## 3. Risk profile (read before going live)

From the 26-window stability validation (`ASSESSMENT.md`):

- **Equity drawdown up to ~38%** on a badly-timed cold start. At 1:1000 this is
  margin-significant — do not over-allocate.
- **Lumpy returns** — roughly half the calendar months are losing months;
  profit concentrates into a few explosive months. Expect long flat/down grinds.
- **Cold-start grind** — the first 1–2 quarters after switching on can be flat
  or slightly negative before compounding engages.
- **Not for short horizons** — judge performance over ≥6–12 months; single
  quarters can be negative (worst observed single quarter ≈ −19%).

Losses in every tested window were **bounded and controlled** (stair-step
erosion, no blow-ups), but this is still an aggressive high-leverage system.

---

## 4. Reproducing the backtests

Backtests use MT5 real-tick (Model 4), deposit 3000, leverage 1:1000.
`ea/backtest_config.ini` is the authoritative tester config (its `[TesterInputs]`
match the compiled defaults). The `windows/` folder contains the archived
report + equity chart for the full period and each cold-start window.
