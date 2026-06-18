# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_h1_2026

**生成时间:** 2026-06-18 17:12:27

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2026.01.01 - 2026.06.18) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | 2 183.57 |
| Gross Profit | 27 627.73 |
| Gross Loss | -25 444.16 |
| Profit Factor | 1.09 |
| Expected Payoff | 3.08 |
| Recovery Factor | 0.52 |
| Sharpe Ratio | 0.89 |
| Balance Drawdown Maximal | 3 718.60 (67.47%) |
| Equity Drawdown Maximal | 4 215.15 (69.59%) |
| Balance Drawdown Relative | 67.47% (3 718.60) |
| Equity Drawdown Relative | 69.59% (4 215.15) |
| Total Trades | 708 |
| Short Trades (won %) | 254 (41.34%) |
| Long Trades (won %) | 454 (48.46%) |
| Profit Trades (% of total) | 325 (45.90%) |
| Loss Trades (% of total) | 383 (54.10%) |
| Largest profit trade | 1 614.95 |
| Largest loss trade | -2 310.05 |
| Average profit trade | 85.01 |
| Average loss trade | -65.80 |
| Maximum consecutive wins ($) | 8 (347.34) |
| Maximum consecutive losses ($) | 9 (-1 430.78) |
| Average position holding time | 5:20:14 |
| Maximal position holding time | 243:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 309 | -2,419.11 | -7.83 |
| Take-Profit (tp) | 11 | 1,476.63 | 134.24 |
| Stop-Loss (sl) | 388 | 3,368.93 | 8.68 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2026 | 2,183.57 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2026.01 | -474.12 | -474.12 |
| 2026.02 | -475.84 | -949.96 |
| 2026.03 | 1,264.31 | 314.35 |
| 2026.04 | 2,388.23 | 2,702.58 |
| 2026.05 | -172.50 | 2,530.08 |
| 2026.06 | -346.51 | 2,183.57 |

## 🔎 关键观察
- 最佳月份: **2026.04** (2,388.23 USD)
- 最差月份: **2026.02** (-475.84 USD)  ← 重点优化时间窗口
- 亏损月份数: 4 / 6
- 余额最大回撤: 3 718.60 (67.47%) | 净值最大回撤: 4 215.15 (69.59%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码