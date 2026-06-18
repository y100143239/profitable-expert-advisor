# 优化决策：稳定性分析 (Optimization Decision — Stability Analysis)

The greedy build (scale 10, URF off) was unstable across entry points: cold-start
equity drawdown ranged up to **69.6%** depending on when the EA is switched on.
We ran the identical 12-window cold-start battery (fresh $3000) on four configs to
find the lever. Real ticks, $3000 @ 1:1000.

## Frontier (11 cold-start windows + full period)

| Config | URF | Scale | Full net | Full DD | Cold-start WORST DD | Cold-start net CV | Profitable |
|---|---|---|---|---|---|---|---|
| Greedy | off | 10 | ~$187k | 32.8% | **69.6%** | 1.33 | 10/11 |
| Mid | off | 6 | ~$157k | 22.6% | **69.6%** | 1.32 | 10/11 |
| **Balanced (NEW DEFAULT)** | **on** | **6** | **~$74k** | **29.6%** | **39.6%** | **1.09** | 9/11 |
| Safer | on | 3 | ~$47k | 20.5% | 39.6% | 1.09 | 9/11 |

## 关键结论 (Key findings)

1. **`MaxBalanceScale` does NOT fix the live-start instability.** Cold-start windows
   begin at $3000 where the balance-scale factor is 1.0 — below both the 6× and 10×
   caps — so scale 6 and 10 behave identically there (worst DD 69.6% either way).
   The cap only tames the *full-period* drawdown after the account compounds past it.

2. **`URF_Enable` (the margin facade) is the stability lever.** Turning it on nearly
   **halves the worst cold-start drawdown (69.6% → 39.6%)** and tightens outcome
   variance (CV 1.33 → 1.09), because it throttles size as margin load rises — exactly
   in the early, fragile, low-equity phase.

3. **With URF on, raising the scale recovers profit at no stability cost.** scale6+URF
   gives the SAME cold-start stability as scale3+URF (worst 39.6%, CV 1.09) but **+56%
   more full-period profit** ($74k vs $47k). The two levers are independent:
   - URF on/off  → controls early / live-start drawdown
   - MaxBalanceScale → controls late / compounded profit

## 决定 (Decision — applied as new default)

**`URF_Enable=true` + `ORCH_MaxBalanceScale=6`** — the balanced config.
- Fixes the instability the analysis flagged: worst cold-start equity DD ~40% (vs ~70%).
- Keeps meaningful profit (~$74k full = ~25× the $3k deposit), PF 1.44.
- More consistent across entry points (9/11 windows profitable, lowest outcome variance).

## 可选档位 (Opt-in variants — change one input)
- **More profit, more risk:** `URF_Enable=true`, `ORCH_MaxBalanceScale=10` → more late
  compounding (~$100k+), same ~40% cold-start DD (URF still governs the early phase).
- **Maximum profit, unstable:** `URF_Enable=false`, `ORCH_MaxBalanceScale=10` (greedy)
  → ~$187k full but up to ~70% cold-start DD. Only with risk capital you can stomach.
- **Most conservative:** `URF_Enable=true`, `ORCH_MaxBalanceScale=3` (safer) → ~$47k,
  ~20% full DD.

## 下一步优化方向 (Next optimization directions)
- The residual instability (worst window still ~40% DD, 2/11 windows slightly negative)
  comes from 2023/early entries where the book is net-flat. Targeted fixes to the
  weakest 2023 sub-strategies (see attribution) could lift the worst windows without
  touching the strong 2024-2026 engine.
