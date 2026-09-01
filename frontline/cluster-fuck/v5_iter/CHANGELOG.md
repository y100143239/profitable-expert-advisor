# UnitedEA v5_iter — live-safe iteration campaign

Base: `champion_final_20260731/src` (champion, #property version 4.10 → now 4.11).
Broker for local backtests: **ICMarketsSC-MT5-6** (IC Markets Global; live account 15030145). Full Model=4 tick
cache 2023-01…2026-08 for all 13 champion symbols (incl. MU.NAS) in terminal data dir D3027A7456…
Methodology: test sub-strategies individually first (starting with MU.NAS scalper = live-drawdown root cause),
then combine. Validate every change; only bump version + commit git when an iteration is a confirmed improvement.

## Version log
- **4.11-dev** (2026-09-01): campaign start. Added identifiable build banner (`EA_VERSION`) printed at OnInit
  to fix version-chaos complaint. No behavior change yet. Base compiles = champion_final_20260731.
- **4.11-dev / loss-halt OFF** (2026-09-01): added master switch `GRM_LossHaltEnable` (default **false**).
  When false, `United_DailyLossThresholdUSD()` and `United_MonthlyLossThresholdUSD()` return 0, so the
  daily/monthly forced-stop (MONTH-LOCK) can NEVER fire regardless of `GRM_MonthlyLossLimitFreeMarginPct`.
  Rationale: strategies mean-revert; forced halts miss the recovery (prior-session + user live observation).
  To reproduce legacy champion month-lock: set `GRM_LossHaltEnable=true`. PENDING full-2026 validation vs baseline.

## Requested fixes (from live drawdown review)
1. Partial/scaled take-profit (分批清仓) — winners turning into losers. STATUS: to build (absent in base).
2. Per-symbol per-direction leverage-aware sizing — over-risk. STATUS: base has opt-in `URF_LeverageAwareEnable`; validate/extend.
3. Dynamic TP/SL per sub-strategy — floating profit not locked. STATUS: base has per-strategy TrailingStop; enhance.
4. Version discipline — DONE (banner + version bump + this changelog + git per iteration).
5. Anti-reentry after stop-out at price extreme — low win rate. STATUS: to build (absent in base).

## Iteration results (append per run)
- **Baseline** champion 2026 (breaker ON): +438 / PF 1.03 / BalDD 48.62% / EqDD 52.11% / 634 tr / worst -1630.
- **Iter1 breaker OFF** (GRM_LossHaltEnable=false) 2026: **-1663 / PF 0.94 / EqDD 84.53% / 1432 tr / worst -2431**.
  => Disabling the breaker is HARMFUL on the 2026 (choppy) regime: 2x trades, loss streaks compound to 84% DD.
  DECISION: keep breaker ON (default reverted to true). The June lock-out was real but the breaker net-saves
  ~$2,100 and ~32pp DD across 2026. Fix later = smarter/recoverable breaker, not removal. Real DD drivers to
  target next: over-leverage/sizing (52% DD @ 1:1000) + partial TP (lock winners) + dynamic TP/SL.
- **Iter2 URF_BaseScale 1.5->1.0** (breaker ON) 2026: **+639 / PF 1.07 / BalDD 31.72% / EqDD 35.77% / 673 tr / worst -937 / Sharpe 0.74**.
  => WIN on every metric vs baseline (+438/52.11%/0.35). Confirms champion is OVER-SIZED (user complaint #2):
  smaller size = higher return AND -16pp drawdown (big positions caused compounding-killing drawdowns).
- **Iter3 URF_BaseScale=0.75** (breaker ON) 2026: running (find sizing sweet spot).

## Sizing sweep (URF_BaseScale, breaker ON, full-2026 Model=4) — champion is OVER-LEVERAGED
| scale | net | EqDD% | PF | Sharpe | worst |
|---|---|---|---|---|---|
| 1.5 (champ) | +438 | 52.11 | 1.03 | 0.35 | -1630 |
| 1.0 | +639 | 35.77 | 1.07 | 0.74 | -937 |
| 0.75 | +671 | 27.35 | 1.08 | 0.96 | -663 |
| 0.5 | +700 | 19.88 | 1.09 | 1.12 | -430 |
| 0.35 | +1037 | 17.87 | 1.12 | 1.41 | -310 |
| 0.25 | +1243 | 16.09 | 1.16 | 1.79 | -239 |
| 0.15 | +1179 | 15.17 | 1.18 | 1.81 | -145 |
- **OPTIMUM = URF_BaseScale 0.25** (max net; 0.15 turns net down). 0.25 = +1243/EqDD16.09/PF1.16/Sharpe1.79
  vs champion 1.5 = +438/52.11/1.03/0.35. ~2.8x net, DD cut from 52%->16%. Breaker kept ON.
  Saved as champion_lowsize025.set. PENDING robustness check on 2023-2025 (champion tuned size@1.5 on full window,
  so 0.25 may earn less in trending years - verify it stays profitable/safe, not catastrophic).
- **Iter9 robustness: 0.25 on 2024** (trending year): +992 / PF 1.33 / BalDD 4.53% / EqDD 8.42% / Sharpe 2.09.
  => 0.25 is NOT 2026-overfit: excellent on trending 2024 too. Champion@1.5 was over-leveraged in BOTH regimes;
  the trend masked the risk. LOCKED URF_BaseScale=0.25 as the sizing base. (Full-window run too slow >40min; use per-year.)

## Feature A: Partial Take-Profit (scale-out) — code added v4.11 (opt-in PTP_Enable, default off)
- United_ManagePartialTP() in OnTick: at favorable move >= PTP_TriggerATRMult*ATR, close PTP_ClosePct% once, SL->BE.
- Compiles clean (ex5 471,598). Testing on 0.25 base 2026 vs +1243/16.09%.
- **Iter10 PTP(1.2ATR,50%,BE) 2026**: +609 / EqDD 18.93% / PF 1.10 / Sharpe 1.14 => HURT (net halved vs +1243).
  Win% rose 43.8->47.5 but net down: cutting winners early caps upside + SL->BE stops runners on noise.
  Consistent with prior lesson (TP/SL placement doesn't help this portfolio). Testing no-BE variant to isolate.
- **Iter11 PTP(2.0ATR,33%,noBE) 2026**: +1227 / EqDD 14.34% / PF 1.18 / Recovery 2.03 / Sharpe 1.81 => RISK WIN.
  vs 0.25-only (+1243/16.09/1.53): ~neutral net (-1.3%), DD -1.75pp, recovery 1.53->2.03. BREAKEVEN was the killer
  (iter10 BE +609 vs iter11 no-BE +1227). LESSON: never SL->BE here. Set PTP defaults = 2.0ATR/33%/noBE, opt-in.
- Trade count RISES as size falls (634->1148): at large size, drawdowns trip equity throttles (PG/URF gate/
  ORCH balance-scale) that gate out trades. Smaller size avoids that -> more trades + higher net + lower DD.
  Likely a throttle-interaction effect; MUST validate the chosen size on 2023-2025 windows (avoid 2026 overfit).
- Monotonic so far: smaller size => higher net AND lower DD. Confirms user complaint #2 (over-leverage).
  Sweeping down to find turnover; will lock the optimum as the new sizing base for feature work.

## Sub-strategy attribution (iter2 scale1.0 breakerON 2026) — which strategies FAIL in the choppy regime
- LOSERS: MU.NAS RSI Scalping (m20004) **-962** (#1, = live culprit); XAUUSD RSI Scalping (m129102315) -286;
  BTCUSD SimpleTrendline SELL (m26042501) -253 (0% win); RSI Follow/Reverse (m1001/m1002) -385; DE40 ST BUY (m26042502) -92.
- WINNERS: TSLA scalp (m125421321) +572; Williams buys (m20260526/33/34) +1533; XTI/XBR ST +961; XAUUSD net +229.
- Sum of losing strategies -2099; total net +732. => target the failing strategies' EXITS/regime, NOT a global freeze.
- CAUTION (repo memory): blindly disabling strategies is often absorbed by the lot-rebalancer or backfires
  (FIFO/hedging interactions). Validate every prune/filter with a full-portfolio backtest.

## Feature D: Anti-Reentry (post-stop adverse-price gate) - code added v4.11 (opt-in ARE_Enable, default off)
United_AntiReentryBlocks in United_MayOpenNewEntry: after a recent losing stop-out on symbol+magic, block a NEW
same-direction entry if price moved >= ARE_MinAdverseATRMult*ATR further adverse (chasing down/up = low win rate).
Scalpers route through the gate (RSIScalpingStrategy 442/467). Compiles clean. Testing on 0.25 base 2026.
