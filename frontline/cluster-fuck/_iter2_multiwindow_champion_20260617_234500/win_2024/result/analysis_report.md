# 📊 MT5 回测增强分析报告 — Champion rl9 window 2024

**生成时间:** 2026-06-17 23:57:48

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2024.01.01 - 2025.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 834.94 |
| Gross Profit | 1 288.25 |
| Gross Loss | -453.31 |
| Profit Factor | 2.84 |
| Expected Payoff | 1.49 |
| Recovery Factor | 1.75 |
| Sharpe Ratio | 3.35 |
| Balance Drawdown Maximal | 56.96 (1.62%) |
| Equity Drawdown Maximal | 477.73 (15.83%) |
| Balance Drawdown Relative | 1.62% (56.96) |
| Equity Drawdown Relative | 15.83% (477.73) |
| Total Trades | 561 |
| Short Trades (won %) | 233 (79.40%) |
| Long Trades (won %) | 328 (79.57%) |
| Profit Trades (% of total) | 446 (79.50%) |
| Loss Trades (% of total) | 115 (20.50%) |
| Largest profit trade | 247.22 |
| Largest loss trade | -56.81 |
| Average profit trade | 2.89 |
| Average loss trade | -3.41 |
| Maximum consecutive wins ($) | 21 (28.65) |
| Maximum consecutive losses ($) | 4 (-0.38) |
| Average position holding time | 1:05:13 |
| Maximal position holding time | 43:44:08 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 8 | -74.74 | -9.34 |
| Stop-Loss (sl) | 553 | 970.31 | 1.75 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 834.94 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -17.74 | -17.74 |
| 2024.02 | -2.28 | -20.02 |
| 2024.03 | 87.14 | 67.12 |
| 2024.04 | 402.93 | 470.05 |
| 2024.05 | 21.80 | 491.85 |
| 2024.06 | 63.02 | 554.87 |
| 2024.07 | 80.26 | 635.13 |
| 2024.08 | 11.39 | 646.52 |
| 2024.09 | 52.45 | 698.97 |
| 2024.10 | 51.54 | 750.51 |
| 2024.11 | 54.81 | 805.32 |
| 2024.12 | 29.62 | 834.94 |

## 🔎 关键观察
- 最佳月份: **2024.04** (402.93 USD)
- 最差月份: **2024.01** (-17.74 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 12
- 余额最大回撤: 56.96 (1.62%) | 净值最大回撤: 477.73 (15.83%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码