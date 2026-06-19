# 📊 MT5 回测增强分析报告 — stability sm_y2024

**生成时间:** 2026-06-19 21:36:33

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
| Total Net Profit | 5 823.87 |
| Gross Profit | 21 300.93 |
| Gross Loss | -15 477.06 |
| Profit Factor | 1.38 |
| Expected Payoff | 6.08 |
| Recovery Factor | 1.54 |
| Sharpe Ratio | 2.74 |
| Balance Drawdown Maximal | 3 470.45 (28.23%) |
| Equity Drawdown Maximal | 3 777.91 (30.07%) |
| Balance Drawdown Relative | 28.23% (3 470.45) |
| Equity Drawdown Relative | 30.07% (3 777.91) |
| Total Trades | 958 |
| Short Trades (won %) | 66 (54.55%) |
| Long Trades (won %) | 892 (42.26%) |
| Profit Trades (% of total) | 413 (43.11%) |
| Loss Trades (% of total) | 545 (56.89%) |
| Largest profit trade | 978.87 |
| Largest loss trade | -444.82 |
| Average profit trade | 51.58 |
| Average loss trade | -27.83 |
| Maximum consecutive wins ($) | 7 (484.97) |
| Maximum consecutive losses ($) | 17 (-300.48) |
| Average position holding time | 9:26:23 |
| Maximal position holding time | 359:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Loss (sl) | 360 | -858.48 | -2.38 |
| Signal/Trailing/Time exit | 582 | 1,006.27 | 1.73 |
| Take-Profit (tp) | 16 | 5,983.41 | 373.96 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | 5,823.87 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.01 | 375.87 | 375.87 |
| 2024.02 | 574.60 | 950.47 |
| 2024.03 | 1,979.29 | 2,929.76 |
| 2024.04 | 750.91 | 3,680.67 |
| 2024.05 | 1,402.38 | 5,083.05 |
| 2024.06 | -57.32 | 5,025.73 |
| 2024.07 | 2,269.29 | 7,295.02 |
| 2024.08 | 684.25 | 7,979.27 |
| 2024.09 | -523.98 | 7,455.29 |
| 2024.10 | -805.52 | 6,649.77 |
| 2024.11 | -560.89 | 6,088.88 |
| 2024.12 | -265.01 | 5,823.87 |

## 🔎 关键观察
- 最佳月份: **2024.07** (2,269.29 USD)
- 最差月份: **2024.10** (-805.52 USD)  ← 重点优化时间窗口
- 亏损月份数: 5 / 12
- 余额最大回撤: 3 470.45 (28.23%) | 净值最大回撤: 3 777.91 (30.07%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码