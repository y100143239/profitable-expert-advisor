# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h2_2025

**生成时间:** 2026-06-18 17:07:45

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2025.07.01 - 2025.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 15 272.80 |
| Gross Profit | 40 220.30 |
| Gross Loss | -24 947.50 |
| Profit Factor | 1.61 |
| Expected Payoff | 20.31 |
| Recovery Factor | 2.37 |
| Sharpe Ratio | 2.94 |
| Balance Drawdown Maximal | 5 579.26 (33.69%) |
| Equity Drawdown Maximal | 6 447.92 (34.23%) |
| Balance Drawdown Relative | 37.84% (1 369.86) |
| Equity Drawdown Relative | 43.56% (2 291.16) |
| Total Trades | 752 |
| Short Trades (won %) | 257 (41.25%) |
| Long Trades (won %) | 495 (44.24%) |
| Profit Trades (% of total) | 325 (43.22%) |
| Loss Trades (% of total) | 427 (56.78%) |
| Largest profit trade | 7 293.72 |
| Largest loss trade | -2 152.57 |
| Average profit trade | 123.75 |
| Average loss trade | -57.67 |
| Maximum consecutive wins ($) | 8 (157.46) |
| Maximum consecutive losses ($) | 9 (-92.29) |
| Average position holding time | 8:08:39 |
| Maximal position holding time | 1061:58:59 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Take-Profit (tp) | 9 | 1,847.28 | 205.25 |
| Stop-Loss (sl) | 332 | 2,155.31 | 6.49 |
| Signal/Trailing/Time exit | 410 | 4,299.74 | 10.49 |
| end | 1 | 7,293.72 | 7,293.72 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 15,272.80 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.07 | -239.24 | -239.24 |
| 2025.08 | -82.83 | -322.07 |
| 2025.09 | -304.38 | -626.45 |
| 2025.10 | 10,648.48 | 10,022.03 |
| 2025.11 | -1,249.70 | 8,772.33 |
| 2025.12 | 6,500.47 | 15,272.80 |

## 🔎 关键观察
- 最佳月份: **2025.10** (10,648.48 USD)
- 最差月份: **2025.11** (-1,249.70 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 6
- 余额最大回撤: 5 579.26 (33.69%) | 净值最大回撤: 6 447.92 (34.23%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码