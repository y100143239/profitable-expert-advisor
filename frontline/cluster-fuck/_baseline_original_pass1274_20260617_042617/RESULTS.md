# BASELINE — Original EA (READY_EMACrossOverXAUUSD.mq5) + Pass 1274 params

## Configuration
- Source: frontline/READY_EMACrossOverXAUUSD.mq5 (compiled → baseline.ex5, 0 errors)
- Params (Pass 1274 manual optimum): slopeThreshold=85, TrailingStop=49.5, maxCrossoverTrades=38; all others at original defaults
- Modelling: Every tick based on real ticks (Model=4)
- Delays: Random delay (ExecutionMode=-1)
- Deposit: $3000 | Leverage: 1:500 | Symbol: XAUUSD H1
- Period: 2023.01.01 → 2026.06.17
- Run: mt5-dev container, completed 2026-06-17

## Results (BENCHMARK)
| Metric                     | Value              |
|----------------------------|--------------------|
| Total Net Profit           | +$109.72 (+3.66%)  |
| Gross Profit / Loss        | 2,066.39 / -1,956.67 |
| Profit Factor              | 1.06               |
| Expected Payoff            | 0.18               |
| Recovery Factor            | 0.10               |
| Sharpe Ratio               | 0.23               |
| Balance Drawdown Max       | 741.51 (19.65%)    |
| Equity Drawdown Max        | 1,136.19 (32.87%)  |
| Total Trades               | 606                |
| Win Rate                   | 464 (76.57%)       |
| Loss Trades                | 142 (23.43%)       |
| Short Trades (won %)        | 278 (74.46%)       |
| Long Trades (won %)         | 328 (78.35%)       |
| Largest profit / loss trade | 106.35 / -441.57  |
| Max consecutive losses     | 4 (-571.66)        |

## Interpretation
- High win rate (76.57%) but only marginally profitable (PF 1.06, +$109 over 3.5y).
- Equity drawdown is HIGH (32.87%) — main weakness to fix.
- This is the BENCHMARK to beat: iter EAs must reduce drawdown and raise profit while keeping win rate ≈76%.
