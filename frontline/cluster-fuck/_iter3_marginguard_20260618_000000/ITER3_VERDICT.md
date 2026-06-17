# iter3 — Margin Guard: INSUFFICIENT (fixed one window, broke another)

## What iter3 added
`MarginSafeLot()` — clamps the 9× reverse lot at OPEN time so post-trade margin
level ≥ `minMarginLevelPct` (300%) and margin load ≤ `maxMarginLoadPct` (25%),
implementing the user's hard margin constraints. Reverse trade is skipped if it
can't be opened safely.

## Per-window results (fresh $3000 each)

| Window  | iter3 (margin guard)        | champion (no guard)        |
|---------|------------------------------|----------------------------|
| 2023    | +194 / balDD 4.2% / eqDD 43.5% | +217 / eqDD 43%          |
| 2024    | +274 / balDD 10.5% / eqDD 18.5% | +835 / eqDD 16%         |
| 2025    | **-2,993 / DD 99.8% WIPE**   | +681 / eqDD 19%            |
| 2026H1  | +579 / balDD 18.6% / eqDD 19.3% (WIPE FIXED) | -2,979 / WIPE |
| FULL    | +4,447 / balDD 12% / eqDD 43.3% / PF1.45 | +8,274 / eqDD 46% |

## Verdict: REJECTED
The margin guard **fixed the 2026H1 fast-move wipe** but **introduced a NEW wipe
in 2025**: clamping the lot below `minimumLotSize*reverseLotSizeMultiplier` broke
the EA's fragile exact-equality lone-position auto-close, so a clamped lone reverse
floated for 3 days into a margin stop-out ("so 11.81%", balance → $6.35).

Root cause: lot-capping at OPEN cannot stop a HELD position from floating into a
stop-out as equity erodes. Two distinct wipe modes (fast-move vs lone-float) — no
single lot cap fixes both. Carried the lone-close fix forward into iter4.
