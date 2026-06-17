# 📊 MT5 回测增强分析报告 — Baseline with 20260617-1 params

**生成时间:** 2026-06-17 06:25:58

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | READY_EMACrossOverXAUUSD |
| Symbol | XAUUSD |
| Period | H1 (2023.01.01 - 2026.06.17) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -2 958.48 |
| Gross Profit | 2 137.87 |
| Gross Loss | -5 096.35 |
| Profit Factor | 0.42 |
| Expected Payoff | -3.28 |
| Recovery Factor | -0.88 |
| Sharpe Ratio | -4.31 |
| Balance Drawdown Maximal | 3 345.88 (98.77%) |
| Equity Drawdown Maximal | 3 356.68 (98.78%) |
| Balance Drawdown Relative | 98.77% (3 345.88) |
| Equity Drawdown Relative | 98.78% (3 356.68) |
| Total Trades | 903 |
| Short Trades (won %) | 366 (80.05%) |
| Long Trades (won %) | 537 (82.50%) |
| Profit Trades (% of total) | 736 (81.51%) |
| Loss Trades (% of total) | 167 (18.49%) |
| Largest profit trade | 166.14 |
| Largest loss trade | -2 582.44 |
| Average profit trade | 2.90 |
| Average loss trade | -29.80 |
| Maximum consecutive wins ($) | 23 (28.03) |
| Maximum consecutive losses ($) | 3 (-93.69) |
| Average position holding time | 1:21:19 |
| Maximal position holding time | 125:27:20 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Out (so) | 1 | -2,582.44 | -2,582.44 |
| Signal/Trailing/Time exit | 19 | -2,003.77 | -105.46 |
| Stop-Loss (sl) | 883 | 1,747.14 | 1.98 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 349.73 |
| 2024 | -1,075.68 |
| 2025 | -2,232.53 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 40.70 | 40.70 |
| 2023.02 | 33.42 | 74.12 |
| 2023.03 | 107.59 | 181.71 |
| 2023.04 | 51.67 | 233.38 |
| 2023.05 | -67.54 | 165.84 |
| 2023.09 | 32.88 | 198.72 |
| 2023.10 | 14.37 | 213.09 |
| 2023.11 | 31.98 | 245.07 |
| 2023.12 | 104.66 | 349.73 |
| 2024.01 | -8.37 | 341.36 |
| 2024.02 | 8.82 | 350.18 |
| 2024.03 | 37.22 | 387.40 |
| 2024.04 | -1,295.04 | -907.64 |
| 2024.05 | 55.19 | -852.45 |
| 2024.06 | 52.70 | -799.75 |
| 2024.07 | 10.26 | -789.49 |
| 2024.08 | -4.11 | -793.60 |
| 2024.09 | 11.91 | -781.69 |
| 2024.10 | 78.03 | -703.66 |
| 2024.11 | 20.09 | -683.57 |
| 2024.12 | -42.38 | -725.95 |
| 2025.01 | 2.00 | -723.95 |
| 2025.02 | 174.84 | -549.11 |
| 2025.03 | 64.93 | -484.18 |
| 2025.04 | -2,474.30 | -2,958.48 |

## 🔎 关键观察
- 最佳月份: **2025.02** (174.84 USD)
- 最差月份: **2025.04** (-2,474.30 USD)  ← 重点优化时间窗口
- 亏损月份数: 6 / 25
- 余额最大回撤: 3 345.88 (98.77%) | 净值最大回撤: 3 356.68 (98.78%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码