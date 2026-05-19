# Iter10E9 Portfolio Loss Throttle Validation - 2026-05-19

## Decision rule

Promotion candidate must stay causal and portfolio-level only:

- No hardcoded year/month/date protection.
- No symbol-specific, direction-specific, or magic-specific scoped protection for promotion.
- Runtime controls must be based on closed historical deals only.

User overfit constraint recorded: "限定品种和方向也有极大的过拟合风险，历史行情不代表未来行情".

## Candidate

Source: `frontline/cluster-fuck/_iter10e9_loss_cooldown_20260519`

Active parameters:

```text
GRM_ConsecutiveLossCooldownEnable=false
GRM_ConsecutiveLossLotThrottleEnable=false
GRM_MonthlyLossLotThrottleEnable=false
GRM_PortfolioLossCooldownEnable=false
GRM_PortfolioConsecutiveLossLotThrottleEnable=true
GRM_PortfolioConsecutiveLossCount=4
GRM_PortfolioConsecutiveLossLotThrottleFactor=0.80
GRM_PortfolioDailyLossLotThrottleEnable=false
GRM_PortfolioMonthlyLossLotThrottleEnable=false
```

## Gate results

| Window | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| weak2023 | `v4_archived_iter10e9_portfolio_cl4_f08_weak2023_20230101to20231130_20260519_091845` | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 |
| h2_2024 | `v4_archived_iter10e9_portfolio_cl4_f08_h2_2024_20240701to20241231_20260519_092213` | 391.41 | 383.39 (10.68%) | 553.99 (14.73%) | 1.19 | 0.71 | 957 |
| recent | `v4_archived_iter10e9_portfolio_cl4_f08_recent_20260401to20260512_20260519_092338` | 188.96 | 189.70 (6.27%) | 255.30 (7.66%) | 1.29 | 0.74 | 162 |
| is_2025 | `v4_archived_iter10e9_portfolio_cl4_f08_is_2025_20250501to20251130_20260519_092757` | 3061.13 | 411.41 (7.47%) | 542.25 (8.53%) | 1.56 | 5.65 | 1340 |
| full_2023_2026 | `20260519_092806_20230101to20260512` | 17523.84 | 1421.40 (7.41%) | 2655.50 (12.08%) | 1.38 | 6.60 | 8430 |

Full report recovery note: first local full `Report.html` was truncated by SCP reset. Re-copied remote `ReportTester.html` only; no MT5 process restart/kill was used. Recovered CSVs: `summary.csv`, `deals.csv` with 16860 deals reported in summary.

## Reference comparisons

## V2 baseline to current E9: main optimizations

V2 reference source: `frontline/cluster-fuck/_united-V2`. V2 was the original static multi-strategy portfolio: each strategy ran on fixed symbols/magic numbers, with limited broker-symbol portability and without the later portfolio-level causal risk governor. The current promoted version is E9 on the V4 code line: `frontline/cluster-fuck/_iter10e9_loss_cooldown_20260519`, committed as `aee7d40`.

Main optimization path from V2 to the current verified E9 baseline:

1. Broker-symbol robustness and reproducible deployment: V4 introduced `BrokerSymbolMapper.mqh` and normalized stock symbols such as `AAPL.NAS`, `NVDA.NAS`, and `TSLA.NAS`, reducing the V2 dependency on exact local broker symbol naming. The V4 deployment/replay scripts also produce prefixed report directories, making reproductions traceable and avoiding shared `report_history` collisions.
2. Strategy portfolio upgrade: the portfolio moved from V2's static strategy bundle toward the V4 multi-asset configuration with tuned defaults, added risk-aware orchestration, and validated strategy toggles. The early V4 baseline already lifted full-window net profit materially versus the old V2 comparison report while cutting total trade count.
3. Causal portfolio-level risk governor: E9 promotes only the non-overfit setting `GRM_PortfolioConsecutiveLossLotThrottleEnable=true`, `GRM_PortfolioConsecutiveLossCount=4`, `GRM_PortfolioConsecutiveLossLotThrottleFactor=0.80`. This reduces size after confirmed portfolio loss streaks using closed historical deals only. It deliberately avoids hardcoded dates, year/month filters, symbol-specific blocks, direction-specific blocks, and magic-specific promotion rules.
4. Validation discipline: candidates are gated across weak2023, h2_2024, recent, is_2025, and full_2023_2026. Rejected experiments remain documented as default-off diagnostics rather than silently becoming active rules.

Metric context: the old V2 comparison report (`ComparisonReport_20260510_192432.md`) used a slightly different end date and reports a single max-drawdown field, so it is directional rather than byte-for-byte comparable with the E9 MT5 `summary.csv` fields. Still, it captures the scale of the improvement.

| Window / source | Net Profit | Drawdown field | PF | Trades | Win rate | Interpretation |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| V2 static baseline, full 2023.01.01-2026.05.10 | 2747.85 | MaxDD 882.83 | n/a | 16736 | 22.47% | Original static portfolio had many low-quality trades and low win rate. |
| Early V4 baseline, full 2023.01.01-2026.05.12 | 11123.28 | Equity DD 2439.61 (18.71%) | 1.21 | 12332 | 41.83% | V4 strategy/symbol/orchestration upgrade improved profit and win rate before E9 risk throttle. |
| Current E9 CL4/F0.80, full 2023.01.01-2026.05.12 | 17523.84 | Equity DD 2655.50 (12.08%) | 1.38 | 8430 | 42.08% | Current verified baseline keeps higher profit quality with fewer trades and lower percentage equity DD than early V4. |
| V2 static baseline, recent 2026.04.01-2026.05.10 | -277.32 | MaxDD 647.76 | n/a | 704 | 21.16% | V2 struggled in the recent stress slice. |
| Current E9 CL4/F0.80, recent 2026.04.01-2026.05.12 | 188.96 | Equity DD 255.30 (7.66%) | 1.29 | 162 | 46.30% | E9 turns the recent slice positive while cutting churn and drawdown. |

Bottom line: the main improvement over V2 is not a single entry tweak. It is the combination of broker-symbol normalization, V4 portfolio/orchestration upgrades, and a conservative causal portfolio loss-streak lot throttle. The verified E9 result preserves long-run profitability, improves recent-window survivability, and raises trade quality while staying within the anti-overfit promotion rule.

Full window vs Iter10E1 deep/full reference:

| Candidate | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Iter10E9 portfolio CL4/F0.80 | 17523.84 | 1421.40 (7.41%) | 2655.50 (12.08%) | 1.38 | 6.60 | 8430 |
| Iter10E1 deep/full | 18699.04 | 1699.68 (8.45%) | 2889.95 (12.52%) | 1.39 | 6.47 | 8432 |

weak2023 vs Iter10E1 deep/core reference:

| Candidate | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Iter10E9 portfolio CL4/F0.80 | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 |
| Iter10E1 deep/core | 520.10 | 631.18 (18.52%) | 653.92 (18.97%) | 1.14 | 0.80 | 1822 |

## Reproducibility

weak2023 replay2: `v4_archived_iter10e9_portfolio_cl4_f08_replay2_weak2023_20230101to20231130_20260519_104351`

Replay2 matched the first weak2023 run exactly:

- Total Net Profit: 527.85
- Balance Drawdown Maximal: 603.75 (17.83%)
- Equity Drawdown Maximal: 637.20 (18.55%)
- Profit Factor: 1.15
- Expected Payoff: 0.29
- Recovery Factor: 0.83
- Total Trades: 1821
- Total Deals: 3642

## Current-default source replay after input-comment/default promotion

Purpose: verify that moving `input` parameter comments from line tails to preceding lines, and promoting the CL4/F0.80 settings to source defaults, did not change strategy logic.

Current source: `frontline/cluster-fuck/_iter10e9_loss_cooldown_20260519`, commit lineage after `5be37f5`.

Compile check: current `main.mq5` compiled locally with MetaEditor: `Result: 0 errors, 0 warnings`.

Source input check:

```text
No input trailing comments remain.
GRM_Enable=true
GRM_PortfolioConsecutiveLossCount=4
GRM_PortfolioConsecutiveLossLotThrottleEnable=true
GRM_PortfolioConsecutiveLossLotThrottleFactor=0.80
```

Replay command shape: `frontline/run_v4_archived_repro.py --source-dir frontline/cluster-fuck/_iter10e9_loss_cooldown_20260519 --compile-source`, with no extra `--set` overrides. This validates the source defaults themselves.

| Window | Current-default report | Original Net | Current Net | Delta | Original Equity DD | Current Equity DD | PF | Trades | Win rate | Strategy-field diffs |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| weak2023 | `v4_archived_e9_current_defaults_repro_weak2023_20230101to20231130_20260519_212156` | 527.85 | 527.14 | -0.71 | 637.20 (18.55%) | 637.68 (18.57%) | 1.15 | 1821 | 39.59% | 0 / 3642 |
| recent | `v4_archived_e9_current_defaults_repro_recent_20260401to20260512_20260519_212315` | 188.96 | 188.96 | 0.00 | 255.30 (7.66%) | 255.31 (7.66%) | 1.29 | 162 | 46.30% | 0 / 324 |
| full_2023_2026 | `v4_archived_e9_current_defaults_repro_full_2023_2026_20230101to20260512_20260519_213938` | 17523.84 | 17515.53 | -8.31 | 2655.50 (12.08%) | 2657.47 (12.10%) | 1.38 | 8430 | 42.08% | 200 / 16860 |

Interpretation: weak2023 and recent are strategy-stream exact. The full-window differences match the earlier committed-code reproduction pattern: 100 trade pairs / 200 rows differ only at dynamic stock lot boundary levels after long-run balance/cost drift, while trade count, win rate, PF, and overall drawdown structure remain aligned. No signal/timing logic change is indicated by the input-comment/default promotion.

## Half-year stability windows after current-default promotion

Scorecard CSV: `frontline/cluster-fuck/report_history/e9_current_defaults_semester_scorecard_20260519.csv`

Family PnL CSV: `frontline/cluster-fuck/report_history/e9_current_defaults_semester_family_pnl_20260519.csv`

All windows were run from current E9 defaults with `--compile-source` and no extra `--set` overrides.

| Window | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Win rate | Expected Payoff | Profitable day % | Max loss-day streak |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2023H1 | `v4_archived_e9_current_defaults_semester_2023H1_20230101to20230630_20260519_214246` | 127.90 | 265.58 (7.84%) | 308.55 (8.98%) | 1.06 | 0.41 | 963 | 39.67% | 0.13 | 42.00% | 5 |
| 2023H2 | `v4_archived_e9_current_defaults_semester_2023H2_20230701to20231231_20260519_214451` | -124.61 | 330.59 (11.02%) | 325.49 (10.80%) | 0.93 | -0.38 | 992 | 38.61% | -0.13 | 34.78% | 7 |
| 2024H1 | `v4_archived_e9_current_defaults_semester_2024H1_20240101to20240630_20260519_214722` | 912.45 | 198.66 (5.44%) | 407.24 (10.14%) | 1.42 | 2.24 | 1125 | 41.60% | 0.81 | 43.20% | 9 |
| 2024H2 | `v4_archived_e9_current_defaults_semester_2024H2_20240701to20241231_20260519_215039` | 390.86 | 383.56 (10.69%) | 554.26 (14.73%) | 1.19 | 0.71 | 957 | 41.17% | 0.41 | 51.06% | 7 |
| 2025H1 | `v4_archived_e9_current_defaults_semester_2025H1_20250101to20250630_20260519_215531` | 902.05 | 383.02 (9.77%) | 386.56 (9.18%) | 1.20 | 2.33 | 1159 | 40.98% | 0.78 | 49.51% | 5 |
| 2025H2 | `v4_archived_e9_current_defaults_semester_2025H2_20250701to20251231_20260519_215907` | 3513.78 | 445.22 (7.82%) | 563.29 (8.61%) | 1.57 | 6.24 | 1504 | 43.88% | 2.34 | 47.69% | 6 |
| 2026H1_partial | `v4_archived_e9_current_defaults_semester_2026H1_partial_20260101to20260512_20260519_220218` | 1675.52 | 461.01 (10.26%) | 620.47 (12.53%) | 1.30 | 2.70 | 936 | 45.94% | 1.79 | 52.05% | 8 |

Stability summary:

- Positive windows: 6 / 7.
- Negative windows: 1 / 7, only 2023H2 at -124.61.
- Sum of independent half-year nets: 7397.95. This is not expected to equal the full-window net because each half-year restarts the account balance and therefore changes dynamic lot scaling.
- Median half-year net: 902.05.
- PF range: 0.93 to 1.57.
- Trades range: 936 to 1504.
- Max loss-day streak across half-year windows: 9 days.
- Worst day across windows: -284.57 in 2026H1_partial; best day: 899.59 in 2025H2.

Family contribution across half-year windows:

| Family | Net | Deals | Interpretation |
| --- | ---: | ---: | --- |
| XAU | 5748.02 | 9590 | Primary profit engine; positive in 6 of 7 half-year windows, slightly negative in 2023H2. |
| Stocks | 1082.93 | 1766 | Secondary contributor; weak in 2023H2, strong in 2024H1/2025/2026. |
| BTC | 785.76 | 578 | Concentrated positive contribution, mainly 2025H2. |
| FX | -52.33 | 332 | Small drag; low impact on portfolio total. |
| Index | -166.43 | 3006 | Persistent mild drag, offset by XAU/Stocks/BTC. |

Stability interpretation: E9 is not uniformly profitable in every half-year slice, but it is stable enough for the current promotion standard. The only losing half-year is shallow relative to later positive windows and to full-window profit. The main residual robustness risk is contribution concentration: XAU remains the dominant profit engine, and Index/FX are mild long-run drags. This supports keeping E9 as the current verified baseline while using future work for strategy/family-level signal quality improvements rather than adding date/symbol-specific hard blocks.

## Weak2023 throttle matrix

Completed causal portfolio-level variants:

| Variant | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| CL3/F0.80 | 536.84 | 616.60 (18.09%) | 640.44 (18.58%) | 1.15 | 0.84 | 1827 | Full window rejects promotion |
| CL4/F0.75 | -11.58 | 602.92 (17.81%) | 635.49 (18.50%) | 1.00 | -0.02 | 1675 | Reject |
| CL4/F0.80 | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 | Keep current candidate |
| CL4/F0.85 | 516.59 | 614.38 (18.14%) | 646.78 (18.83%) | 1.14 | 0.80 | 1826 | Reject, weaker than F0.80 |
| CL4/F0.90 | 515.31 | 616.47 (18.19%) | 647.34 (18.85%) | 1.14 | 0.80 | 1831 | Reject, weaker than F0.80 |
| CL4/F0.95 | 514.03 | 620.00 (18.28%) | 648.09 (18.87%) | 1.14 | 0.79 | 1823 | Reject, weaker than F0.80 |
| CL5/F0.80 | -27.19 | 620.83 (18.32%) | 650.65 (18.94%) | 0.99 | -0.04 | 1677 | Reject |

CL3/F0.80 looked interesting on weak2023 because it slightly improved net profit and recovery while keeping drawdown below the Iter10E1 weak2023 reference. It passed small-window continuation checks but failed promotion on the full window due lower long-run profit and materially worse equity drawdown.

CL3/F0.80 gate comparison vs CL4/F0.80:

| Window | CL4 Net | CL3 Net | CL4 Balance DD | CL3 Balance DD | CL4 Equity DD | CL3 Equity DD | CL4 Recovery | CL3 Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| weak2023 | 527.85 | 536.84 | 603.75 (17.83%) | 616.60 (18.09%) | 637.20 (18.55%) | 640.44 (18.58%) | 0.83 | 0.84 |
| h2_2024 | 391.41 | 386.84 | 383.39 (10.68%) | 381.90 (10.66%) | 553.99 (14.73%) | 553.65 (14.74%) | 0.71 | 0.70 |
| recent | 188.96 | 216.22 | 189.70 (6.27%) | 150.27 (4.99%) | 255.30 (7.66%) | 256.04 (7.61%) | 0.74 | 0.84 |
| is_2025 | 3061.13 | 3047.72 | 411.41 (7.47%) | 410.42 (7.48%) | 542.25 (8.53%) | 537.67 (8.49%) | 5.65 | 5.67 |

CL3/F0.80 full result:

| Variant | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| CL3/F0.80 | `v4_archived_iter10e9_portfolio_cl3_f08_full_2023_2026_20230101to20260512_20260519_123616` | 17138.30 | 1388.51 (7.40%) | 2506.45 (14.79%) | 1.39 | 6.84 | 8423 | Reject for promotion |
| CL4/F0.80 | `20260519_092806_20230101to20260512` | 17523.84 | 1421.40 (7.41%) | 2655.50 (12.08%) | 1.38 | 6.60 | 8430 | Keep current candidate |

Conclusion: CL4/F0.80 remains best for promotion among completed causal portfolio-level loss-throttle variants. CL4/F0.85 was rerun after account recovery and should not be promoted. CL3/F0.80 should not be promoted despite better recovery because it sacrifices long-run profit and worsens full-window equity drawdown percentage.

## Operational recovery note

MT5 command-line tester temporarily failed with `tester not started because the account is not specified`. The deploy script now injects `Login`/`Server` when `MT5_TESTER_LOGIN` and `MT5_TESTER_SERVER` are set, and its no-account fail-fast detector only checks log bytes written after the current test starts. A two-day smoke run succeeded after login state recovered:

- `v4_archived_iter10e9_account_smoke3_smoke_20231128to20231130_20260519_115759`
- Net Profit: 46.91
- Profit Factor: 2.23
- Total Trades: 36

## Monthly stability

Full window monthly stability:

- Months: 41
- Breakeven/profit months: 29
- Loss months: 12
- Breakeven rate: 70.7%
- Max loss streak: 5
- Worst month: 2025-05, pnl -529.98, ret -8.06%, closed DD 679.79 (10.14%)
- Second notable stress: 2026-02, pnl -415.51, ret -2.61%, closed DD 1067.19 (6.44%)
- Best month: 2026-01, pnl 4525.78, ret 39.72%

## Win-rate and sub-strategy experiments

User constraint added after the portfolio loss-throttle matrix: higher win rate should come from deeper entry/exit logic quality, not from simply reducing trade count. XAUUSD/BTCUSD trend-driven profit concentration is also a forward overfit risk because future symbol regimes are unknown.

Weak2023 baseline concentration by symbol under CL4/F0.80:

| Symbol | Trades | Win rate | Net | PF |
| --- | ---: | ---: | ---: | ---: |
| XAUUSD | 1108 | 40.88% | 527.24 | 1.24 |
| BTCUSD | 79 | 62.03% | 200.91 | 7.62 |
| TSLA.NAS | 70 | 24.29% | -108.52 | 0.82 |
| DE40 | 342 | 21.35% | -19.38 | 0.96 |
| AUDUSD | 31 | 35.48% | -20.46 | 0.55 |
| NVDA.NAS | 111 | 37.84% | -10.94 | 0.90 |

Interpretation: the weak2023 portfolio remains profitable mainly because XAUUSD and BTCUSD offset weak sub-strategies. This supports treating trend-dependence as a material robustness risk. It does not justify symbol-specific removal or direction-specific protections for promotion, but it does require regime-window checks and structural signal improvements.

Rejected win-rate / trade-reduction experiments:

| Experiment | Report | Net Profit | Equity DD Max | PF | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| Portfolio WR40/CD6 | weak2023 ad-hoc | 12.69 | n/a | n/a | n/a | 37.77% | Reject: cuts recovery winners |
| LossCooldown6 | weak2023 ad-hoc | 349.73 | 21.45% | n/a | n/a | 38.57% | Reject: worse equity DD and lower net |
| MaxSame2 | weak2023 ad-hoc | -344.53 | n/a | n/a | n/a | 36.57% | Reject: negative net |
| Symbol WR35/CD24 | weak2023 ad-hoc | -36.13 | n/a | n/a | n/a | 41.35% | Reject: negative net despite higher win rate |
| Symbol WR30/CD12 | weak2023 ad-hoc | -144.39 | n/a | n/a | n/a | 40.76% | Reject: negative net |
| RSI ordered bands | `v4_archived_iter10e9_rsi_band_guard_cl4_f08_weak2023_20230101to20231130_20260519_131145` | -56.20 | 671.37 (19.48%) | 0.98 | 1881 | 39.02% | Reject: structural idea hurt portfolio sequence and net |
| RSI closed-bar exit | `v4_archived_iter10e9_rsi_closed_exit_cl4_f08_weak2023_20230101to20231130_20260519_131650` | -24.90 | 671.21 (19.54%) | 0.99 | 1684 | 39.01% | Reject: fewer trades, no win-rate lift, negative net |
| SimpleTrendline slope >= 5 | `v4_archived_iter10e9_st_slope5_cl4_f08_weak2023_20230101to20231130_20260519_132155` | 78.96 | 641.60 (18.34%) | 1.02 | 1751 | 39.23% | Reject: mostly reduces trades and removes BTC/XAU winners |

Conclusion: reducing trading frequency is not a valid primary objective. A candidate must improve signal quality and robustness while preserving the EA's ability to compound frequent profitable opportunities. Current default-off experiment inputs (`RS_RequireOrderedBands`, `RS_UseClosedBarExit`, `ST_MinSlopePointsPerBar`) are retained only for controlled testing and are not enabled in the active baseline.

## Core objective attribution implementation

Implemented `frontline/analyze_core_objective_attribution.py` as the first step of the revised iteration plan. The script reads report folders or `deals.csv`, rebuilds FIFO closed segments, and writes per-window scorecards by strategy/magic/side, strategy, symbol/side, symbol, asset family, close month, close session, and weekday. It also reports closed-realized DD, max loss streak, XAU/BTC-family contribution share, and non-XAU/BTC-family net.

Generated baseline output root:

`frontline/cluster-fuck/report_history/core_objective_attribution_iter10e9_cl4_f08_20260519`

First CL4/F0.80 attribution overview:

| Window report | FIFO closed segments | Net | Win rate | Closed-realized DD | Recovery | XAU/BTC-family PnL share | Non-XAU/BTC-family Net |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `v4_archived_iter10e9_portfolio_cl4_f08_weak2023_20230101to20231130_20260519_091845` | 1971 | 527.85 | 39.57% | 603.74 | 0.87 | 127.84% | -146.97 |
| `v4_archived_iter10e9_portfolio_cl4_f08_h2_2024_20240701to20241231_20260519_092213` | 1036 | 391.41 | 42.08% | 383.39 | 1.02 | 71.44% | 111.80 |
| `v4_archived_iter10e9_portfolio_cl4_f08_recent_20260401to20260512_20260519_092338` | 170 | 188.96 | 46.47% | 189.60 | 1.00 | 88.85% | 21.07 |
| `v4_archived_iter10e9_portfolio_cl4_f08_is_2025_20250501to20251130_20260519_092757` | 1494 | 3061.13 | 42.90% | 411.12 | 7.45 | 88.38% | 355.85 |

Note: `FIFO closed segments` may differ from MT5 Strategy Tester's `Total Trades` when entries/exits are split. The weak2023 attribution confirms the concern: metals+crypto contribute more than total net profit, while non-XAU/BTC families are net negative. The worst weak2023 strategy/magic/side clusters include SimpleTrendline XAU short/long, TSLA RSI Scalping short, RSI Follow BUY, and NVDA RSI Scalping short. This supports the next implementation step: strategy-class exit-quality diagnostics, especially post-entry failure/scratch logic for SimpleTrendline, instead of another portfolio-level trade-reduction filter.

## SimpleTrendline exit-quality diagnostics and candidate

Implemented `frontline/analyze_exit_quality.py` to slice FIFO closed segments by hold-time buckets. Default filter is `SimpleTrendline`, with outputs by strategy/side, strategy/symbol/side, hold bucket, and candidate pain pockets.

Generated baseline diagnostic root:

`frontline/cluster-fuck/report_history/exit_quality_simpletrendline_iter10e9_cl4_f08_20260519`

Weak2023 baseline finding: SimpleTrendline pain is concentrated in early <=4h losses rather than 3d+ stuck trades.

| Weak2023 SimpleTrendline group | FIFO segments | Net | Win rate | Early <=4h loss PnL |
| --- | ---: | ---: | ---: | ---: |
| SimpleTrendline SELL #M26042503 short | 111 | -227.44 | 23.42% | -245.61 |
| SimpleTrendline BUY #M26042502 long | 180 | 4.90 | 20.56% | -237.37 |
| SimpleTrendline SELL #M26042502 short | 162 | -24.28 | 22.22% | -188.97 |
| SimpleTrendline BUY #M26042503 long | 105 | -105.01 | 40.95% | -114.73 |

Implemented a default-off SimpleTrendline early-failure exit candidate:

```text
ST_EarlyFailureExitEnable=false
ST_EarlyFailureMinHoldBars=1
ST_EarlyFailureMaxHoldHours=4
ST_EarlyFailureMinLossPoints=0.0
```

Logic: after at least `ST_EarlyFailureMinHoldBars` and before `ST_EarlyFailureMaxHoldHours`, close only if the current closed bar is losing versus entry price and has returned to the wrong side of the rebuilt trendline. This is causal and strategy-class based, with no date/month/symbol/direction fitting.

Compile result: `compile_st_early_failure.log` has `0 errors, 0 warnings`.

Weak2023 test result:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Expected Payoff | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| ST early failure 4h | `v4_archived_iter10e9_st_earlyfail4h_cl4_f08_weak2023_20230101to20231130_20260519_135310` | -18.02 | 586.13 (17.24%) | 632.92 (18.22%) | 0.99 | -0.01 | -0.03 | 1787 | 38.22% | Reject |
| ST early failure 4h loss>=100pts | `v4_archived_iter10e9_st_earlyfail4h_loss100_cl4_f08_weak2023_20230101to20231130_20260519_135739` | 5.22 | 559.51 (16.46%) | 585.12 (16.99%) | 1.00 | 0.00 | 0.01 | 1712 | 38.73% | Reject |

Post-test attribution: XAU ST short improved somewhat, but GER40 long, XAU ST long, BTC/crypto contribution, and portfolio sequence worsened. The 100-point minimum-loss neighbor reduced drawdown but still erased nearly all weak2023 profit. This confirms that naive early-failure exits still cut recovery paths and should not advance to H2/recent gates. The code remains default-off as a diagnostic/controlled-test knob only.

## RSI-family entry/exit and shorter-timeframe monitoring experiments

User observation: H1 execution may miss shorter-timeframe dynamics and therefore miss profitable opportunities. Code audit found that MT5 `OnTick()` does run on every tick, but several strategies gate their signal/exit logic on strategy timeframe new bars. In particular, `ProcessRSIMidPointHijack` returned immediately unless `RM_InpTimeframe` produced a new bar, so RSI Follow/Reverse exits were only checked on H1 bars under the baseline.

Implemented default-off diagnostic knobs:

```text
RS_UseReversalEscapeAllSymbols=false
RM_InpRSIFollowUseReentryBand=false
RM_InpIntrabarExitMonitorEnable=false
```

Compile checks:

- `compile_rs_escape_all.log`: 0 errors, 0 warnings.
- `compile_rm_reentry_band.log`: 0 errors, 0 warnings.
- `compile_rm_intrabar_exit.log`: 0 errors, 0 warnings.

Weak2023 test results:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Expected Payoff | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RS reversal escape all symbols | `v4_archived_iter10e9_rs_escape_all_cl4_f08_weak2023_20230101to20231130_20260519_140715` | -33.91 | 622.91 (18.39%) | 638.15 (18.57%) | 0.99 | -0.02 | -0.05 | 1699 | 38.79% | Reject |
| RS ordered bands | `v4_archived_iter10e9_rs_ordered_bands_cl4_f08_weak2023_20230101to20231130_20260519_141122` | -56.20 | 624.81 (18.46%) | 671.37 (19.48%) | 0.98 | -0.03 | -0.08 | 1881 | 39.02% | Reject |
| RM Follow exit level 50 | `v4_archived_iter10e9_rm_follow_exit50_cl4_f08_weak2023_20230101to20231130_20260519_141522` | 13.39 | 556.59 (16.49%) | 546.11 (16.15%) | 1.00 | 0.01 | 0.02 | 1826 | 39.43% | Reject |
| RM Follow exit level 46 | `v4_archived_iter10e9_rm_follow_exit46_cl4_f08_weak2023_20230101to20231130_20260519_141904` | 223.36 | 593.09 (17.41%) | 602.95 (17.48%) | 1.07 | 0.13 | 0.37 | 1726 | 39.22% | Reject |
| RM Follow reentry band | `v4_archived_iter10e9_rm_reentry_band_cl4_f08_weak2023_20230101to20231130_20260519_142437` | 443.64 | 693.94 (20.51%) | 742.24 (21.53%) | 1.11 | 0.22 | 0.60 | 2047 | 39.72% | Reject |
| RM intrabar exit monitor | `v4_archived_iter10e9_rm_intrabar_exit_cl4_f08_weak2023_20230101to20231130_20260519_143158` | 3.06 | 627.14 (18.49%) | 632.59 (18.36%) | 1.00 | 0.00 | 0.00 | 1958 | 38.10% | Reject |
| RM timeframe M15 numeric | `v4_archived_iter10e9_rm_m15num_cl4_f08_weak2023_20230101to20231130_20260519_144026` | 85.70 | 614.06 (17.02%) | 612.71 (16.94%) | 1.02 | 0.04 | 0.14 | 1957 | 37.51% | Reject |
| RM timeframe M30 numeric | `v4_archived_iter10e9_rm_m30num_cl4_f08_weak2023_20230101to20231130_20260519_144346` | -232.00 | 616.99 (18.76%) | 635.71 (19.15%) | 0.93 | -0.14 | -0.36 | 1629 | 38.80% | Reject |

Findings:

- The chart timeframe is not the direct bottleneck because `OnTick()` dispatches every tick. The bottleneck is strategy-level new-bar gating and the selected signal timeframe.
- Applying tick-level H1 current-bar exits was too noisy. It improved some RM-family rows but damaged portfolio sequence and major XAU/BTC contributors.
- Directly replacing the RM H1 signal with M15/M30 closed bars also failed. M15 reduced drawdown somewhat but erased most profit; M30 turned negative.
- A prior `RM_InpTimeframe=PERIOD_M15` test reproduced baseline exactly because tester enum inputs use numeric values (`15` for M15, `30` for M30, `16385` for H1). Use numeric timeframe values in future automated tests.

Conclusion: shorter-timeframe dynamics are a valid optimization direction, but not as a wholesale replacement for H1 signal timing and not with tick-level current H1 bar exits. The next viable line is default-off lower-timeframe confirmation/quality filters for H1 signals, using closed M5/M15 bars to confirm momentum or reject noisy reversals before entry, while preserving H1 as the primary regime signal.

Implemented a default-off lower-timeframe confirmation candidate for RSI Follow entries:

```text
RM_InpLTFConfirmEnable=false
RM_InpLTFConfirmTimeframe=PERIOD_M15
RM_InpLTFConfirmRSIPeriod=14
RM_InpLTFConfirmBuyMin=50.0
RM_InpLTFConfirmSellMax=50.0
```

Logic: H1 remains the primary RSI Follow signal timeframe. When enabled, a BUY entry requires the previous closed M15 RSI to be at or above `RM_InpLTFConfirmBuyMin`; a SELL entry requires the previous closed M15 RSI to be at or below `RM_InpLTFConfirmSellMax`. This tests lower-timeframe confirmation without using an unclosed current bar and without replacing the H1 regime signal.

Compile result: `compile_rm_ltf_confirm.log` has 0 errors and 0 warnings.

Weak2023 threshold neighbors:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RM LTF M15 RSI 50/50 | `v4_archived_iter10e9_rm_ltf_m15_rsi50_cl4_f08_weak2023_20230101to20231130_20260519_145052` | 532.22 | 603.28 (17.85%) | 649.59 (18.87%) | 1.15 | 0.82 | 1808 | 39.82% | Continue outer-window check, not promoted |
| RM LTF M15 RSI 48/52 | `v4_archived_iter10e9_rm_ltf_m15_rsi48_52_cl4_f08_weak2023_20230101to20231130_20260519_145441` | 530.02 | 605.55 (17.91%) | 651.86 (18.94%) | 1.15 | 0.81 | 1809 | 39.80% | Reject, worse than 50/50 |
| RM LTF M15 RSI 55/45 | `v4_archived_iter10e9_rm_ltf_m15_rsi55_45_cl4_f08_weak2023_20230101to20231130_20260519_145801` | -75.15 | 633.42 (18.65%) | 684.88 (19.83%) | 0.98 | -0.11 | 1577 | 39.51% | Reject |

Attribution for 50/50: `RSI Follow BUY #M1001 long` improved from -74.26 net, 32.56% win rate, PF 0.1169 to -36.67 net, 40.00% win rate, PF 0.1951. This confirms that closed M15 confirmation improves the target weak entry bucket. However, portfolio sequence effects worsened SimpleTrendline/SuperEMA/RSIConsolidation buckets enough to increase equity drawdown.

Outer-window check for 50/50:

| Window | Candidate report | Candidate Net | Baseline Net | Candidate Equity DD | Baseline Equity DD | Decision |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| weak2023 | `v4_archived_iter10e9_rm_ltf_m15_rsi50_cl4_f08_weak2023_20230101to20231130_20260519_145052` | 532.22 | 527.85 | 649.59 (18.87%) | 637.20 (18.55%) | Reject: higher equity DD |
| h2_2024 | `v4_archived_iter10e9_rm_ltf_m15_rsi50_cl4_f08_h2_2024_20240701to20241231_20260519_150150` | 427.39 | 391.41 | 582.99 (15.51%) | 553.99 (14.73%) | Reject: higher equity DD |
| recent | `v4_archived_iter10e9_rm_ltf_m15_rsi50_cl4_f08_recent_20260401to20260512_20260519_150323` | 171.39 | 188.96 | 255.30 (7.69%) | 255.30 (7.66%) | Reject: lower net |

Decision: do not promote RM LTF M15 RSI confirmation. The concept is directionally useful for the specific RSI Follow BUY weakness, but the simple midpoint threshold does not improve the full portfolio objective. Keep the inputs default-off. A future variant should use lower-timeframe confirmation as a score or soft delay instead of a hard entry filter, or combine it with strategy-specific sequence-impact checks before promotion.

Follow-up bounded-delay test:

```text
RM_InpLTFConfirmMaxDelayBars=0  # default, no expiry
```

Implemented a default-off expiry bound so an RSI Follow setup waiting for M15 confirmation can be discarded after `RM_InpLTFConfirmMaxDelayBars` H1 bars. This was meant to avoid stale H1 setups entering too late after the lower-timeframe confirmation finally appears.

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RM LTF M15 RSI 50/50 max delay 3 | `v4_archived_iter10e9_rm_ltf_m15_rsi50_delay3_cl4_f08_weak2023_20230101to20231130_20260519_151041` | -123.73 | 679.92 (20.11%) | 735.15 (21.36%) | 0.97 | -0.17 | 1849 | 39.16% | Reject |

Decision: the bounded-delay variant is worse than both baseline and the unbounded 50/50 confirmation. Do not promote. The small weak2023 improvement from unbounded 50/50 appears to depend on waiting longer for confirmation, but that behavior still fails portfolio-level drawdown and recent-window checks. Keep `RM_InpLTFConfirmMaxDelayBars=0` by default and treat the whole LTF confirmation family as experimental only.

## Weak2023 as stress-regime objective

User hypothesis: 2023 may be an adverse market regime for this EA. If a generic, causal rule can improve win rate and profit in weak2023 without damaging other windows, it may be more robust than optimizing only on favorable years.

This is a valid stress-testing frame, with one guardrail: weak2023 is an evaluation gate, not a date/month training label. Promotion must still avoid hardcoded years/months, symbol/direction scoping, future leakage, and simple trade-count reduction. A candidate should pass weak2023 first, then h2_2024, recent, is_2025, and finally the full 2023-2026 window.

Weak2023 internal monthly structure shows the weakness is regime-specific rather than uniformly bad:

| Month | Net | Win rate | PF | Expected payoff | Max loss streak |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2023-01 | -99.30 | 41.95% | 0.74 | -0.48 | 9 |
| 2023-02 | -97.06 | 35.88% | 0.73 | -0.57 | 8 |
| 2023-03 | 400.56 | 43.96% | 1.64 | 1.34 | 11 |
| 2023-04 | 143.55 | 37.89% | 1.66 | 0.89 | 24 |
| 2023-05 | -124.98 | 35.19% | 0.25 | -2.31 | 7 |
| 2023-06 | -94.52 | 34.27% | 0.67 | -0.66 | 13 |
| 2023-07 | -97.90 | 34.78% | 0.30 | -1.42 | 14 |
| 2023-08 | -35.93 | 38.37% | 0.91 | -0.14 | 16 |
| 2023-09 | -125.53 | 31.82% | 0.37 | -1.43 | 14 |
| 2023-10 | 198.68 | 41.67% | 1.47 | 0.69 | 12 |
| 2023-11 | 460.28 | 43.04% | 2.33 | 1.94 | 9 |

Interpretation: the next optimization should look for causal market-state features that distinguish the loss pockets from the recovery months, such as weak trend persistence, high volatility with low ADX, or lower-timeframe disagreement. The recent LTF tests already showed real signal in RSI Follow BUY, but hard blocking and bounded waiting damaged portfolio sequence. The next higher-probability experiment is therefore soft scoring or lot scaling under adverse signal quality, not another binary entry filter.

Operational note: an attempted weak2023 test of the existing generic `GRM_TrendAlignEnable=true` D1 EMA200 alignment filter produced an empty STALE report due `tester agent authorization error` in `Terminal.log`, so no strategy conclusion was recorded from that run.

Implemented next default-off candidate: RM RSI Follow LTF soft scaling.

```text
RM_InpLTFSoftScaleEnable=false
RM_InpLTFSoftScaleWeakLotFactor=0.70
```

Logic: RSI Follow still takes the H1 setup. If soft scaling is enabled and the previous closed lower-timeframe RSI does not pass the same confirmation threshold used by `RM_InpLTFConfirmBuyMin`/`RM_InpLTFConfirmSellMax`, the Follow entry lot is reduced by `RM_InpLTFSoftScaleWeakLotFactor` instead of blocking the trade. Missing LTF data does not force a scale-down. This preserves the recovery paths that hard filters damaged while still lowering exposure on weak lower-timeframe alignment.

Implementation files:

- `main.mq5`: added soft-scale inputs.
- `Strategies/RSIMidPointHijackStrategy.mqh`: added LTF handle sharing and Follow-only scaled lot calculation.
- `auto_tester_config.ini` and `.template`: added default-off tester inputs.

Compile result: `compile_rm_ltf_softscale.log` has 0 errors and 0 warnings.

Validation status: blocked by current MT5 tester agent authorization. A two-day smoke with `RM_InpLTFSoftScaleEnable=true` generated `STALE_v4_archived_iter10e9_softscale_smoke_smoke_20260519_153101` with an empty 1970 report; `Terminal.log` showed `tester agent authorization error`. No strategy conclusion should be drawn from this smoke. Once tester auth recovers, run weak2023 first with CL4/F0.80 plus `RM_InpLTFSoftScaleEnable=true`, then only continue to h2_2024/recent/is_2025/full if weak2023 improves net/win rate or drawdown without obvious trade-count collapse.

Recovery action: per the operational rule, restarted only `mt5-dev` and cleared stale `Tester/Agent-127.0.0.1-*` cache under the container MT5 tester directory. A follow-up two-day smoke succeeded:

- `v4_archived_iter10e9_softscale_smoke_after_restart_smoke_20231128to20231130_20260519_154024`

Weak2023 validation after recovery:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RM LTF soft scale 50/50 factor 0.70 | `v4_archived_iter10e9_rm_ltf_softscale07_cl4_f08_weak2023_20230101to20231130_20260519_154422` | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 | 39.59% | No-op; identical deals hash to baseline |
| RM LTF soft scale 55/45 factor 0.70 | `v4_archived_iter10e9_rm_ltf_softscale55_45_f07_cl4_f08_weak2023_20230101to20231130_20260519_154913` | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 | 39.59% | No-op; identical deals hash to baseline |
| RM LTF soft scale 55/45 unknown-as-weak factor 0.70 | `v4_archived_iter10e9_rm_ltf_softscale55_45_unknownweak_f07_cl4_f08_weak2023_20230101to20231130_20260519_155535` | 527.85 | 603.75 (17.83%) | 637.20 (18.55%) | 1.15 | 0.83 | 1821 | 39.59% | No-op; identical deals hash to baseline |

Diagnosis: all baseline weak2023 RSI Follow entries are already volume `0.01`. On this account/symbol, soft lot scaling cannot reduce exposure below the broker minimum, so the normalized trade stream remains identical. Keep the soft-scale code default-off as a reusable hook for accounts/symbols with larger minimum-free lot headroom, but do not promote it for the current Iter10E9 CL4/F0.80 candidate. The next viable weak2023 direction should affect exit management or signal timing rather than lot scaling for RM Follow.

Implemented isolated Iter10E11 candidate from E9: RM RSI Follow lower-timeframe adverse exit.

```text
RM_InpLTFFollowExitEnable=false
RM_InpLTFFollowExitTimeframe=PERIOD_M15
RM_InpLTFFollowExitRSIPeriod=14
RM_InpLTFFollowExitBuyMax=45.0
RM_InpLTFFollowExitSellMin=55.0
RM_InpLTFFollowExitMinHoldBars=2
RM_InpLTFFollowExitMaxProfit=0.0
```

Logic: Follow-only exit, closed M15 RSI only, after a minimum hold, and only while the position is not profitable. This tested whether lower-timeframe adverse movement could improve exit timing without changing H1 entry logic or lot size.

Compile result: `compile_e11_ltf_follow_exit.log` has 0 errors and 0 warnings.

Weak2023 result:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RM Follow M15 adverse exit 45/55 hold>=2 | `v4_archived_iter10e11_rm_ltf_follow_exit_m15_45_55_h2_weak2023_20230101to20231130_20260519_163313` | -51.27 | 637.73 (19.35%) | 608.04 (18.41%) | 0.99 | -0.08 | 1989 | 38.51% | Reject |

Decision: reject E11. The exit reduced equity drawdown slightly versus baseline but destroyed net profit, PF, recovery, and win rate while increasing trade count. This is not a valid promotion path. The failure suggests the M15 adverse threshold cuts too many recoverable Follow positions; the next exit-management test should target no-progress/scratch behavior rather than immediate adverse RSI reversal.

Implemented isolated Iter10E13 candidate from E9: RM RSI Follow no-progress scratch exit.

```text
RM_InpRSIFollowNoProgressExitEnable=false
RM_InpRSIFollowNoProgressMinHoldBars=4
RM_InpRSIFollowNoProgressMaxHoldBars=0
RM_InpRSIFollowNoProgressMinFavorablePoints=150.0
RM_InpRSIFollowNoProgressMaxProfit=0.0
```

Logic: track the current RSI Follow ticket's maximum favorable movement in points. If enabled, after the minimum hold time, close only when the position has never reached the configured favorable-point threshold and current profit is not above `RM_InpRSIFollowNoProgressMaxProfit`. This tests no-progress/scratch behavior rather than immediate adverse lower-timeframe reversal.

Compile result: `compile_e13_rm_noprogress_exit.log` has 0 errors and 0 warnings.

Operational fix: report folders now support `MT5_REPORT_PREFIX`, and `run_v4_archived_repro.py` filters new report directories by its own `v4_archived_<tag>_<label>` prefix. This avoids ambiguous timestamp-only folders when another container or runner writes to the shared `report_history` root.

Clean weak2023 result after prefixed rerun on `mt5-dev`:

| Candidate | Report | Net Profit | Balance DD Max | Equity DD Max | PF | Expected Payoff | Recovery | Trades | Win rate | Decision |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| RM Follow no-progress H4 favorable>=150 | `v4_archived_iter10e13_rm_noprogress_h4_fav150_prefixed_weak2023_20230101to20231130_20260519_165509` | 74.10 | 600.59 (17.69%) | 621.44 (18.09%) | 1.02 | 0.04 | 0.12 | 1941 | 38.85% | Reject |

Decision: reject E13. It modestly lowers drawdown versus the CL4/F0.80 baseline but sacrifices most weak2023 profit and recovery, while increasing trade count. This confirms that the current no-progress threshold still cuts too many positions that later recover or contribute to sequence quality. Do not run outer-window gates for this parameter set.

## Rejected lines

The following tested lines are not promotion candidates because they rely on symbol/direction scoping and are overfit-prone under the current rule:

- `TSLA.NAS,XAUUSD` scoped soft throttle weak2023.
- `TSLA.NAS` scoped soft throttle weak2023.
- Any use of `GRM_ConsecutiveLossSymbolContains`, `GRM_ConsecutiveLossSide`, or magic-filtered scoped settings for promotion.

## Status

Iter10E9 portfolio CL4/F0.80 is reproducible on weak2023, remains best in the completed causal weak2023 matrix, and improves drawdown/recovery versus Iter10E1 while giving up some full-window net profit. It is a valid next candidate for further promotion checks, not yet a final live-promotion approval.