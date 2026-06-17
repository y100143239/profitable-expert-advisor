# iter4 — Hard Money Stop: DECISIVE NEGATIVE RESULT

## What iter4 added (on top of iter3 margin guard)
1. `UseHardMoneyStop` / `reverseStopLossUSD` — a hard cap on aggregate floating
   loss (出现亏损后及时止损). Closes the whole book when floating P/L ≤ -cap.
2. **Critical bug fix in OnTick**: after a reverse trade, `crossoverTradeCount`
   is set to `maxCrossoverTrades+1`, which made `OnTick` **return early (line ~231)
   before ever calling `CheckPositions()`**. So a reverse position floated
   *completely unmanaged* until the next EMA crossover. The money stop (and all
   position management) was being skipped during the dangerous hold. Fixed by
   running the money-stop check at the very TOP of OnTick, every tick.
3. Robust lone-reverse close: replaced the fragile exact-equality test
   (`volume == minimumLotSize*reverseLotSizeMultiplier`, which the margin guard's
   clamping broke → the 2025 lone-float blowup) with `volume > baseLot*1.5`.

## Per-window results (fresh $3000 each), money stop ENFORCED

| Window  | stop=$500            | stop=$800            | champion (no stop)        |
|---------|----------------------|----------------------|---------------------------|
| 2023    | -358 / eqDD 18.0%    | -628 / eqDD 28.5%    | +217 / eqDD 43% (floats)  |
| 2024    | +1,346 / eqDD 14.4%  | (n/a)                | +835 / eqDD 16%           |
| 2025    | +459 / eqDD 22.3%    | (n/a)                | +681 / eqDD 19%           |
| 2026H1  | +658 / eqDD 23.3%    | +1,302 / eqDD 19.9%  | **-2,979 / DD99.5% WIPE** |
| 1100→2023 -831/36% ; 1100→2026H1 +127/39% (worse both ways)                   |

The money stop **prevents the 2025 and 2026H1 catastrophic wipes** and caps
per-window eqDD to ~18-23%. GOOD for safety. But:

## FULL RUN (compounded 2023→2026H1) — money stop KILLS the edge

| Config                          | Net Profit | balDD   | eqDD    | PF   |
|---------------------------------|-----------|---------|---------|------|
| stop NOT firing (OnTick bug)    | +3,826    | 20.0%   | 21.4%   | 1.35 |
| **stop=$500 enforced**          | **-403**  | 47.5%   | 51.4%   | 0.95 |
| **stop=$800 enforced**          | **-939**  | 43.9%   | 44.0%   | 0.90 |
| champion (no stop at all)       | +8,274    | 10.4%   | 46%     | 1.73 |

## DECISIVE CONCLUSION
The strategy's profitability **fundamentally depends on letting reverse-martingale
positions float and recover.** Any hard stop that actually fires converts winning
recoveries into realized losses → the compounded run goes NEGATIVE *and* DD gets
WORSE (realized losses cascade: stop → balance drops → new reverse → stop again).

The "+3,826 / eqDD21%" iter4 number was an **artifact of the OnTick early-return
bug** (stop silently skipped). Once the stop is genuinely enforced, the edge is gone.

**Safety and profitability are mutually exclusive for this 9× reverse-martingale.**
This — together with iter1 (close-all kills edge), iter2 (overfit spike), and iter3
(margin guard fixes one window, breaks another) — exhaustively proves the target
(low DD + live-safe + fast doubling) is **UNREACHABLE by tuning this structure.**

➡️ Next: structural redesign (iter5) — trend-following with REAL per-trade stops,
regime filter (强市长多短空 / 弱市长空短多), dynamic/trailing TP/SL. No martingale.
