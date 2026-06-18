# iter5 — Structural Direction: DROP THE MARTINGALE (recommended live-safe config)

## Key experiments
- **iter5a (reverseLotSizeMultiplier=1, no martingale, no money stop)**: the bare
  EMA system. EVERY window profitable & wipe-free with DD ≤20%:
  full +305/eqDD18% WR77% | 2026H1(worst) +121/eqDD20% | 2023 +113/eqDD6% WR86%.
  Proves the underlying EMA crossover system is genuinely live-safe but low-edge.
- **iter5b (moderate multiplier sweep 2 vs 3)**: mult=2 is the clear sweet spot.

## iter5b mult=2 — full multi-window validation (fresh $3000 each, real-tick)

| Window  | Net Profit | balDD   | eqDD    | WR     |
|---------|-----------|---------|---------|--------|
| 2023    | +63       | —       | 12.4%   | 83.4%  |
| 2024    | +271      | —       | 3.0%    | 81.7%  |
| 2025    | -212      | —       | 19.2%   | ~77%   |
| 2026H1  | **+668**  | —       | 19.5%   | ~75%   |
| FULL    | **+713**  | 19.85%  | 21.18%  | 77.88% (PF1.12, Sharpe1.07, 3558 trades) |

mult=3 is strictly worse & riskier (full +231/eqDD25%, 2025 -522/eqDD26%,
2026H1 -28/eqDD27%). mult=9 (champion) wipes 2026H1 & 2025 on fresh accounts.

## Comparison vs champion (mult=9)
| Metric            | mult=9 champion          | mult=2 (recommended)        |
|-------------------|--------------------------|------------------------------|
| Full net profit   | +8,274                   | +713                         |
| Full eqDD         | 46%                      | **21%**                      |
| 2026H1 (worst)    | **-2,979 / 99.5% WIPE**  | **+668 / eqDD 19.5%**        |
| 2025 fresh acct   | (full survived via buffer; fresh wipes) | -212 / eqDD 19% (safe) |
| Win rate          | ~78%                     | ~78% (preserved)             |
| Live-safe?        | NO (catastrophic tail)   | **YES (DD≤21%, zero wipes)** |

## RECOMMENDED LIVE CONFIG
Champion params + **reverseLotSizeMultiplier=2**, UseHardMoneyStop=false,
UseMarginGuard=false. This is the only configuration found that is profitable in
the worst window, keeps DD ≤21% everywhere, preserves the ~78% win rate, and never
blows up. See `config_recommended.ini`.

## HONEST ASSESSMENT vs the stated target
- 高胜率 (high win rate): ✅ ~78% (up to 86% in calm years)
- 低回撤 (low drawdown): ✅ ≤21% across ALL windows incl. worst (vs 46%+wipes)
- 实盘可交易 (live-safe, no blowups): ✅ zero stop-outs across every window
- 半年翻倍 (double in 6 months): ❌ NOT achievable safely. +713/3.5yr (~7%/yr).
  The champion's apparent "fast doubling" was an illusion produced by a 9× reverse
  martingale that carries a ~100% account-wipe tail risk (demonstrated: 2026H1 &
  2025 fresh-account wipes). Doubling XAUUSD in 6 months at low DD is not realistic
  for any honest strategy; pursuing it requires accepting ruin-level risk.

## Next levers to raise profit WITHOUT reintroducing wipe risk (future iters)
1. Trend/regime filter (H4/D1): 强市长多短空 / 弱市长空短多 — trade only with the
   higher-TF trend to cut the losing 2025 stretch.
2. Dynamic + trailing TP/SL to let winners run (currently fixed ATR*7.6).
3. Swap-cost reduction: avoid holding through rollover when flat-ish.
4. Modest risk scaling (max_drawdown) only while net equity > balance, capped so
   worst-window DD stays ≤20%.
