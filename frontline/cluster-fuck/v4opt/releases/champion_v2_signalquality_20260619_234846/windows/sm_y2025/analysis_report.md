# 📊 MT5 回测增强分析报告 — stability sm_y2025

**生成时间:** 2026-06-19 21:46:18

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2025.01.01 - 2025.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 8 696.00 |
| Gross Profit | 29 625.84 |
| Gross Loss | -20 929.84 |
| Profit Factor | 1.42 |
| Expected Payoff | 8.73 |
| Recovery Factor | 1.99 |
| Sharpe Ratio | 3.12 |
| Balance Drawdown Maximal | 3 630.98 (23.69%) |
| Equity Drawdown Maximal | 4 378.97 (27.24%) |
| Balance Drawdown Relative | 23.69% (3 630.98) |
| Equity Drawdown Relative | 30.86% (2 723.43) |
| Total Trades | 996 |
| Short Trades (won %) | 80 (63.75%) |
| Long Trades (won %) | 916 (41.38%) |
| Profit Trades (% of total) | 430 (43.17%) |
| Loss Trades (% of total) | 566 (56.83%) |
| Largest profit trade | 2 463.68 |
| Largest loss trade | -1 276.96 |
| Average profit trade | 68.90 |
| Average loss trade | -36.50 |
| Maximum consecutive wins ($) | 10 (780.56) |
| Maximum consecutive losses ($) | 11 (-258.48) |
| Average position holding time | 9:04:10 |
| Maximal position holding time | 339:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Take-Profit (tp) | 11 | 1,596.25 | 145.11 |
| Stop-Loss (sl) | 476 | 1,757.78 | 3.69 |
| Signal/Trailing/Time exit | 509 | 5,614.23 | 11.03 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 8,696.00 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -241.63 | -241.63 |
| 2025.02 | -265.90 | -507.53 |
| 2025.03 | 861.61 | 354.08 |
| 2025.04 | -193.98 | 160.10 |
| 2025.05 | -145.15 | 14.95 |
| 2025.06 | 537.10 | 552.05 |
| 2025.07 | -117.41 | 434.64 |
| 2025.08 | -183.77 | 250.87 |
| 2025.09 | 2,587.41 | 2,838.28 |
| 2025.10 | 7,012.31 | 9,850.59 |
| 2025.11 | -607.45 | 9,243.14 |
| 2025.12 | -547.14 | 8,696.00 |

## 🔎 关键观察
- 最佳月份: **2025.10** (7,012.31 USD)
- 最差月份: **2025.11** (-607.45 USD)  ← 重点优化时间窗口
- 亏损月份数: 8 / 12
- 余额最大回撤: 3 630.98 (23.69%) | 净值最大回撤: 4 378.97 (27.24%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码