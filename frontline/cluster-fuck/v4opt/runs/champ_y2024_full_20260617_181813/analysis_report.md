# 📊 MT5 回测增强分析报告 — Champion#1 window 2024 (base1.5+cap3+MU)

**生成时间:** 2026-06-17 18:24:56

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2024.01.01 - 2024.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 5 452.20 |
| Gross Profit | 19 873.88 |
| Gross Loss | -14 421.68 |
| Profit Factor | 1.38 |
| Expected Payoff | 3.74 |
| Recovery Factor | 1.94 |
| Sharpe Ratio | 2.79 |
| Balance Drawdown Maximal | 2 784.22 (24.78%) |
| Equity Drawdown Maximal | 2 816.40 (24.99%) |
| Balance Drawdown Relative | 24.78% (2 784.22) |
| Equity Drawdown Relative | 29.29% (2 018.22) |
| Total Trades | 1459 |
| Short Trades (won %) | 619 (40.87%) |
| Long Trades (won %) | 840 (43.45%) |
| Profit Trades (% of total) | 618 (42.36%) |
| Loss Trades (% of total) | 841 (57.64%) |
| Largest profit trade | 813.74 |
| Largest loss trade | -408.04 |
| Average profit trade | 32.16 |
| Average loss trade | -16.77 |
| Maximum consecutive wins ($) | 8 (407.25) |
| Maximum consecutive losses ($) | 16 (-363.52) |
| Average position holding time | 6:46:07 |
| Maximal position holding time | 359:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Loss (sl) | 475 | 4.04 | 0.01 |
| Signal/Trailing/Time exit | 963 | 983.75 | 1.02 |
| Take-Profit (tp) | 21 | 4,785.32 | 227.87 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 5,452.20 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -119.33 | -119.33 |
| 2024.02 | 84.11 | -35.22 |
| 2024.03 | 1,325.67 | 1,290.45 |
| 2024.04 | 778.15 | 2,068.60 |
| 2024.05 | 1,289.76 | 3,358.36 |
| 2024.06 | 83.33 | 3,441.69 |
| 2024.07 | 2,268.33 | 5,710.02 |
| 2024.08 | 1,416.67 | 7,126.69 |
| 2024.09 | -565.63 | 6,561.06 |
| 2024.10 | -281.05 | 6,280.01 |
| 2024.11 | -544.55 | 5,735.46 |
| 2024.12 | -283.26 | 5,452.20 |

## 🔎 关键观察
- 最佳月份: **2024.07** (2,268.33 USD)
- 最差月份: **2024.09** (-565.63 USD)  ← 重点优化时间窗口
- 亏损月份数: 5 / 12
- 余额最大回撤: 2 784.22 (24.78%) | 净值最大回撤: 2 816.40 (24.99%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码