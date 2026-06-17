# V4 Multi-Strategy EA — Optimization Result & Live-Trading Configuration

Working EA: `frontline/cluster-fuck/v4opt/ea/main.mq5` (+ `Strategies/`, `BrokerSymbolMapper.mqh`,
`MagicNumberHelpers.mqh`). Harness: `frontline/cluster-fuck/v4opt/` (`run_v4.py`, `make_ini.py`,
`attribution.py`). All backtests are **real-tick (Model 4)** on the remote `mt5-dev` podman
container, **$3000 deposit @ 1:1000**, period **2023.01.01 → 2026.06.17**.

## Champion #1 — recommended live configuration

Full-period backtest (`runs/compcap_full_20260617_162615`):

| Metric | Value |
|---|---|
| Net profit | **+$48,434** (≈16× on $3,000) |
| Equity drawdown (max) | **19.66%** |
| Balance drawdown (max) | 11.55% |
| Margin level (min) | **480%** (never near liquidation) |
| Sharpe | 1.92 |
| Recovery factor | 5.54 |
| Profit factor | 1.38 |
| Win rate | 43% |

### Key parameters (changes vs the archived V4 baseline)

| Input | Baseline | Champion #1 | Why |
|---|---|---|---|
| `ORCH_MaxBalanceScale` | 10.0 | **3.0** | **Primary drawdown lever.** Caps balance-compounding so lot sizes (and therefore absolute equity swings) do not grow 10× as the account grows. This is what brought equity DD from ~33% to ~20% while keeping ~16× profit. |
| `URF_Enable` | (new) | **true** | Enables the Unified Risk Facade (margin safety). |
| `URF_BaseScale` | (new, =2.5) | **1.5** | Flat exposure multiplier replacing the old reckless DD-reactive 2.5× scale-up. Lifts margin level to 480% (no-liquidation). |
| `URF_MaxMarginLoadPct` | (new) | 25.0 | Hard cap on used-margin / equity. |
| `URF_MinMarginLevelPct` | (new) | 300.0 | Hard margin-level floor; new exposure throttles to zero in a tight band above it. |
| `EnableRSIScalpingMU` / `LOT_RS_MU` | (new) | true / 10.0 | Added **MU.NAS** (Micron) RSI-scalper, magic 20004. Net +$25.6k over 337 trades; lifted Sharpe 1.98→2.02. |
| `PES_Enable` | (new) | false | Portfolio Equity Stop is implemented but disabled by default (reactive flatten did not help on this book — see findings). |

All other strategy/symbol inputs keep the archived V4 values (full 23-strategy book on
XAUUSD / EURUSD / AUDUSD / BTCUSD / AAPL.NAS / NVDA.NAS / TSLA.NAS / MU.NAS / DE40 etc).

## New risk code added (in `main.mq5`)

- **`United_RiskFacadeScale()`** — flat `URF_BaseScale` multiplier with a hard margin-load cap and
  a margin-level floor clamp (the no-liquidation guarantee). Replaces the blind DD-reactive
  `United_DynamicMarginScale()` at the single lot-sizing chokepoint (`g_CachedMarginScale`).
- **`United_PortfolioEquityStop()`** + cooldown — closes all EA positions on deep equity drawdown
  from the running peak, then pauses entries (`PES_*` inputs). Available but off by default.

## How to reproduce

```powershell
python frontline/cluster-fuck/v4opt/run_v4.py --tag champ_repro \
  --ea frontline/cluster-fuck/v4opt/ea/main.mq5 \
  --base-ini frontline/cluster-fuck/v4opt/ea/backtest_config.ini \
  --from 2023.01.01 --to 2026.06.17 --max-poll 360
```
(The champion parameters are already baked into `backtest_config.ini` defaults.)

## Per-year validation (each window resets to $3000 @ 1:1000)

| Window | Net | Equity DD | PF | Sharpe |
|---|---|---|---|---|
| Full 2023–2026 | +$48,434 | 19.66% | 1.38 | 1.92 |
| 2023 | −$195 (≈flat) | 40.3% | 0.97 | −0.28 |
| 2024 | +$5,452 | 25.0% | 1.38 | 2.79 |
| 2025 | +$9,207 | 29.7% | 1.52 | 2.13 |
| 2026 H1 | +$11,187 | 39.8% | 1.37 | 3.10 |

## Honest limitations (important for live use)

- **Per-year drawdown is higher than the full-period figure (25–40%).** The full-period 19.66%
  benefits from compounding: once the balance is large, a given dollar swing is a smaller
  *percentage*. On a fresh $3,000 each year the true risk is 25–40%. **Size live capital
  accordingly** and treat "≤20% DD" as a full-period, large-balance property, not a per-year one.
- **2023 was ≈break-even/slightly negative.** Some sub-strategies had no edge in that regime.
  Making every standalone year strongly positive needs deeper per-strategy work (regime-specific
  enable/disable, exit harmonization), which ini-level filters did not achieve.
- **Tested ini robustness filters did not help:** D1 trend-alignment veto cut profit and raised DD;
  consecutive/portfolio loss cooldowns cut profit ~36% for only a small PF gain. They are left
  disabled.

## Suggested next steps (not yet done)

1. **Market-closed session gate** — stock/index strategies (.NAS, DE40) attempt orders outside
   exchange hours → retcode 10018 log spam. Add `SymbolInfoSessionTrade()`-based gate in the
   orchestrator entry path.
2. **News guard** (NFP/CPI/FOMC) and **swap-aware close-before-rollover** — profit-neutral
   cleanups aligned with the original requirements.
3. **Per-strategy regime work** to lift 2023 and the win rate toward 50%.
