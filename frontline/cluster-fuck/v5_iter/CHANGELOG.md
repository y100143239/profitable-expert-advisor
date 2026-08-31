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
