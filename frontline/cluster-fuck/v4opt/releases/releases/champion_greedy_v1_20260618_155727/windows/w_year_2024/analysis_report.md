# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_year_2024

**生成时间:** 2026-06-18 16:31:42

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
| Total Net Profit | 6 289.56 |
| Gross Profit | 31 309.21 |
| Gross Loss | -25 019.65 |
| Profit Factor | 1.25 |
| Expected Payoff | 5.23 |
| Recovery Factor | 1.23 |
| Sharpe Ratio | 2.16 |
| Balance Drawdown Maximal | 4 997.31 (34.98%) |
| Equity Drawdown Maximal | 5 093.92 (35.46%) |
| Balance Drawdown Relative | 34.98% (4 997.31) |
| Equity Drawdown Relative | 43.87% (4 369.89) |
| Total Trades | 1203 |
| Short Trades (won %) | 451 (38.36%) |
| Long Trades (won %) | 752 (42.82%) |
| Profit Trades (% of total) | 495 (41.15%) |
| Loss Trades (% of total) | 708 (58.85%) |
| Largest profit trade | 1 651.09 |
| Largest loss trade | -1 067.17 |
| Average profit trade | 63.25 |
| Average loss trade | -34.59 |
| Maximum consecutive wins ($) | 8 (603.18) |
| Maximum consecutive losses ($) | 13 (-201.78) |
| Average position holding time | 7:32:33 |
| Maximal position holding time | 359:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 779 | -2,088.19 | -2.68 |
| Stop-Loss (sl) | 410 | 1,211.66 | 2.96 |
| Take-Profit (tp) | 14 | 7,699.28 | 549.95 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 6,289.56 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -147.54 | -147.54 |
| 2024.02 | 201.87 | 54.33 |
| 2024.03 | 1,873.49 | 1,927.82 |
| 2024.04 | 1,008.43 | 2,936.25 |
| 2024.05 | -211.38 | 2,724.87 |
| 2024.06 | 44.46 | 2,769.33 |
| 2024.07 | 3,702.32 | 6,471.65 |
| 2024.08 | 1,902.72 | 8,374.37 |
| 2024.09 | -339.33 | 8,035.04 |
| 2024.10 | -597.43 | 7,437.61 |
| 2024.11 | -843.48 | 6,594.13 |
| 2024.12 | -304.57 | 6,289.56 |

## 🔎 关键观察
- 最佳月份: **2024.07** (3,702.32 USD)
- 最差月份: **2024.11** (-843.48 USD)  ← 重点优化时间窗口
- 亏损月份数: 6 / 12
- 余额最大回撤: 4 997.31 (34.98%) | 净值最大回撤: 5 093.92 (35.46%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码