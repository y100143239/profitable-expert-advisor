# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h1_2025

**生成时间:** 2026-06-18 17:03:34

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2025.01.01 - 2025.06.30) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 408.77 |
| Gross Profit | 10 512.39 |
| Gross Loss | -10 103.62 |
| Profit Factor | 1.04 |
| Expected Payoff | 0.63 |
| Recovery Factor | 0.19 |
| Sharpe Ratio | 0.39 |
| Balance Drawdown Maximal | 1 496.02 (35.19%) |
| Equity Drawdown Maximal | 2 109.17 (41.34%) |
| Balance Drawdown Relative | 35.19% (1 496.02) |
| Equity Drawdown Relative | 41.34% (2 109.17) |
| Total Trades | 646 |
| Short Trades (won %) | 233 (38.63%) |
| Long Trades (won %) | 413 (39.95%) |
| Profit Trades (% of total) | 255 (39.47%) |
| Loss Trades (% of total) | 391 (60.53%) |
| Largest profit trade | 1 201.68 |
| Largest loss trade | -869.50 |
| Average profit trade | 41.23 |
| Average loss trade | -25.48 |
| Maximum consecutive wins ($) | 9 (478.59) |
| Maximum consecutive losses ($) | 14 (-384.71) |
| Average position holding time | 7:18:24 |
| Maximal position holding time | 284:47:05 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 384 | -1,222.12 | -3.18 |
| end | 3 | 39.14 | 13.05 |
| Take-Profit (tp) | 6 | 770.81 | 128.47 |
| Stop-Loss (sl) | 253 | 962.01 | 3.80 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 408.77 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -416.77 | -416.77 |
| 2025.02 | -314.23 | -731.00 |
| 2025.03 | 1,478.94 | 747.94 |
| 2025.04 | -372.91 | 375.03 |
| 2025.05 | -351.08 | 23.95 |
| 2025.06 | 384.82 | 408.77 |

## 🔎 关键观察
- 最佳月份: **2025.03** (1,478.94 USD)
- 最差月份: **2025.01** (-416.77 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 6
- 余额最大回撤: 1 496.02 (35.19%) | 净值最大回撤: 2 109.17 (41.34%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码