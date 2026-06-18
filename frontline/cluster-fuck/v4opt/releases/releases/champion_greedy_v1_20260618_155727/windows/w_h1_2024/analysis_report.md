# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h1_2024

**生成时间:** 2026-06-18 16:53:40

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2024.01.01 - 2024.06.30) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 2 769.22 |
| Gross Profit | 14 607.17 |
| Gross Loss | -11 837.95 |
| Profit Factor | 1.23 |
| Expected Payoff | 4.04 |
| Recovery Factor | 0.63 |
| Sharpe Ratio | 2.07 |
| Balance Drawdown Maximal | 2 009.74 (26.20%) |
| Equity Drawdown Maximal | 4 369.89 (43.87%) |
| Balance Drawdown Relative | 26.20% (2 009.74) |
| Equity Drawdown Relative | 43.87% (4 369.89) |
| Total Trades | 685 |
| Short Trades (won %) | 268 (40.30%) |
| Long Trades (won %) | 417 (43.17%) |
| Profit Trades (% of total) | 288 (42.04%) |
| Loss Trades (% of total) | 397 (57.96%) |
| Largest profit trade | 1 627.37 |
| Largest loss trade | -636.13 |
| Average profit trade | 50.72 |
| Average loss trade | -29.18 |
| Maximum consecutive wins ($) | 8 (603.18) |
| Maximum consecutive losses ($) | 13 (-201.78) |
| Average position holding time | 9:23:55 |
| Maximal position holding time | 359:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Loss (sl) | 221 | -403.54 | -1.83 |
| Signal/Trailing/Time exit | 456 | 513.17 | 1.13 |
| Take-Profit (tp) | 8 | 2,911.93 | 363.99 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 2,769.22 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | -147.54 | -147.54 |
| 2024.02 | 201.87 | 54.33 |
| 2024.03 | 1,873.49 | 1,927.82 |
| 2024.04 | 1,008.43 | 2,936.25 |
| 2024.05 | -211.38 | 2,724.87 |
| 2024.06 | 44.35 | 2,769.22 |

## 🔎 关键观察
- 最佳月份: **2024.03** (1,873.49 USD)
- 最差月份: **2024.05** (-211.38 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 6
- 余额最大回撤: 2 009.74 (26.20%) | 净值最大回撤: 4 369.89 (43.87%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码