# Iter10 E1 Monthly Loss 3pct Candidate

## Backup identity
- Source: `frontline/cluster-fuck/_united-V4`
- Backup: `frontline/cluster-fuck/_united-V4_iter10E1_monthlyLoss3pct_20260517`
- Candidate feature: E2 XAU stress gate plus global monthly realized loss entry gate.
- Candidate tester inputs: `GRM_Enable=true`, `GRM_XAUStressRegimeEnable=true`, `GRM_XAUStressMinATRPct=1.00`, `GRM_XAUStressMaxADX=26.0`, `GRM_MonthlyLossLimitFreeMarginPct=3.0`, `GRM_TrendAlignEnable=false`, `GRM_MagicMonthlyLossGateEnable=false`, `EnableSimpleTrendlineGER40=true`.

## Validation snapshot
- weak2023 2023.01.01-2023.11.30: NP 520.10, PF 1.14, EqDD 18.97%, trades 1822, monthly breakeven 4/11, worst month 2023-09 -137.67 (-4.51%).
- FULL 2023.01.01-2026.05.12: NP 18699.04, PF 1.39, EqDD 18.97%, trades 8432, monthly breakeven 29/41, worst month 2025-05 -528.97 (-8.03%).
- IS 2025.05.01-2025.11.30: NP 3081.19, PF 1.56, EqDD 11.29%, trades 1340.
- Dynamic RECENT 2026.04.01-2026.05.15: NP 102.54, PF 1.15, EqDD 7.72%, trades 178.

## Decision
- This is the strongest validated risk-control candidate so far.
- It is not a complete monthly breakeven solution because FULL monthly breakeven remains 29/41, matching E2.
- Keep as a backup candidate for risk-controlled mode; continue research toward dynamic lot reduction / strategy-class throttling to improve breakeven-month count.

## Rejected neighbors
- Global monthly loss 2.5%, 3.5%, and 4.0% did not beat 3.0% on weak2023.
- Per-magic hard-stop monthly loss gates were not promotable; they reduced recovery and did not improve breakeven-month count.
