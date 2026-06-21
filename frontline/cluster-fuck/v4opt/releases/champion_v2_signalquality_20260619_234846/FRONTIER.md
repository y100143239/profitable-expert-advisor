# Champion v2 — Return/Drawdown Frontier (3 versions for parallel demo)

All three versions share the **same EA (`ea/main.ex5`)** and the same validated
signal-quality logic (TrendAlign + Regime Quick-Exit + market-closed fix). They
differ **only** in two risk-dial inputs, so you switch between them just by
loading a different `.set` file — no recompile. Deposit **3000 USD**, leverage
**1:1000**.

| Version | `.set` to load | Risk dials | Full-period (2023→2026.06) | Cold-start drawdown |
|---|---|---|---|---|
| **Aggressive** (max return) | `champion_v2_aggressive.set` | `URF_Enable=false`, scale 10 | **$178,924** / PF 1.61 / DD 33% | **47–66%** (severe) |
| **Balanced** (champion) | `champion_v2.set` | `URF_Enable=true`, scale 10 | $120,168 / PF 1.58 / DD 30% | ≤ 38% |
| **Conservative** (low DD) | `champion_v2_conservative.set` | `URF_Enable=true`, scale 6 | $81,999 / PF 1.54 / **DD 27%** | ≤ 38% |

## Per-window net profit / equity-drawdown (fresh $3,000 each)

| Window | Aggressive | Balanced | Conservative |
|---|---|---|---|
| Full | $178,924 / 33% | $120,168 / 30% | $81,999 / 27% |
| 2023 | **−$202 / 58%** | +$2,817 / 38% | +$2,817 / 38% |
| 2024 | $6,214 / 39% | $5,824 / 30% | $5,824 / 30% |
| 2025 | $16,610 / 47% | $8,696 / 27% | $8,687 / 27% |
| 2026 H1 | $391 / **66%** | $1,896 / 37% | $1,895 / 37% |
| Q3-2023 (worst) | −$597 / 23% | −$471 / 18% | −$471 / 18% |
| Q4-2024 (worst) | −$427 / 19% | −$533 / 20% | −$533 / 20% |

## How the two dials work (important for selection)

- **`URF_Enable` governs cold-start drawdown.** ON (Balanced/Conservative) caps a
  fresh-$3,000 start to ≤ ~38% drawdown. OFF (Aggressive) removes that governor:
  full-period profit jumps +49%, but an unlucky entry can draw down 47–66% and
  2023 even ends slightly negative. This is the single biggest "can I stay online"
  factor.
- **`ORCH_MaxBalanceScale` governs full-period compounded profit/DD only.** The
  scale cap binds *after* the account compounds above the reference balance, so
  Conservative's **cold-start windows are identical to Balanced** — it only trims
  the full-period drawdown (30%→27%) and profit. It does not help a fresh start.

## Recommended use

- **Balanced** — default for a fresh live/demo account. Best risk-adjusted profile;
  88% of historical entry points profitable, bounded controlled losses.
- **Conservative** — if you want the smoothest full-period equity curve and can
  accept ~⅓ less profit; same cold-start safety as Balanced.
- **Aggressive** — only on an account that already has a profit buffer, or that you
  can psychologically tolerate 50%+ drawdowns on. Highest expectancy, but the deep
  cold-start drawdowns are exactly the kind that end live runs early.

> ⚠️ All three are high-leverage and show large drawdowns. The `.set` you choose
> sets your worst-case drawdown tolerance — pick the one whose drawdown column you
> can live through, then let it compound.
