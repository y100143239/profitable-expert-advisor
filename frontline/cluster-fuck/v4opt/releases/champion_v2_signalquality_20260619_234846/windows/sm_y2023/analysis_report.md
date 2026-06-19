# 📊 MT5 回测增强分析报告 — stability sm_y2023

**生成时间:** 2026-06-19 21:29:51

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2023.01.01 - 2023.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 2 816.69 |
| Gross Profit | 8 271.45 |
| Gross Loss | -5 454.76 |
| Profit Factor | 1.52 |
| Expected Payoff | 3.49 |
| Recovery Factor | 1.56 |
| Sharpe Ratio | 2.33 |
| Balance Drawdown Maximal | 896.61 (23.35%) |
| Equity Drawdown Maximal | 1 806.64 (38.28%) |
| Balance Drawdown Relative | 23.35% (896.61) |
| Equity Drawdown Relative | 38.28% (1 806.64) |
| Total Trades | 806 |
| Short Trades (won %) | 216 (38.89%) |
| Long Trades (won %) | 590 (41.36%) |
| Profit Trades (% of total) | 328 (40.69%) |
| Loss Trades (% of total) | 478 (59.31%) |
| Largest profit trade | 1 504.25 |
| Largest loss trade | -193.32 |
| Average profit trade | 25.22 |
| Average loss trade | -11.12 |
| Maximum consecutive wins ($) | 7 (102.26) |
| Maximum consecutive losses ($) | 13 (-34.77) |
| Average position holding time | 13:31:04 |
| Maximal position holding time | 1335:58:59 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 540 | -782.41 | -1.45 |
| Stop-Loss (sl) | 248 | 611.28 | 2.46 |
| Take-Profit (tp) | 11 | 1,560.05 | 141.82 |
| end | 7 | 1,569.19 | 224.17 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | 2,816.69 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | -88.50 | -88.50 |
| 2023.02 | -243.47 | -331.97 |
| 2023.03 | 1,113.48 | 781.51 |
| 2023.04 | -154.71 | 626.80 |
| 2023.05 | -107.74 | 519.06 |
| 2023.06 | -122.60 | 396.46 |
| 2023.07 | -137.81 | 258.65 |
| 2023.08 | -98.14 | 160.51 |
| 2023.09 | -106.88 | 53.63 |
| 2023.10 | 33.53 | 87.16 |
| 2023.11 | 706.68 | 793.84 |
| 2023.12 | 2,022.85 | 2,816.69 |

## 🔎 关键观察
- 最佳月份: **2023.12** (2,022.85 USD)
- 最差月份: **2023.02** (-243.47 USD)  ← 重点优化时间窗口
- 亏损月份数: 8 / 12
- 余额最大回撤: 896.61 (23.35%) | 净值最大回撤: 1 806.64 (38.28%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码