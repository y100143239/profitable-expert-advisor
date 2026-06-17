# 📊 MT5 回测增强分析报告 — Champion#1 window 2023 (base1.5+cap3+MU)

**生成时间:** 2026-06-17 18:29:31

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
| Total Net Profit | -194.86 |
| Gross Profit | 5 926.42 |
| Gross Loss | -6 121.28 |
| Profit Factor | 0.97 |
| Expected Payoff | -0.21 |
| Recovery Factor | -0.12 |
| Sharpe Ratio | -0.28 |
| Balance Drawdown Maximal | 1 246.03 (33.61%) |
| Equity Drawdown Maximal | 1 661.58 (40.34%) |
| Balance Drawdown Relative | 33.61% (1 246.03) |
| Equity Drawdown Relative | 40.34% (1 661.58) |
| Total Trades | 933 |
| Short Trades (won %) | 420 (42.14%) |
| Long Trades (won %) | 513 (41.52%) |
| Profit Trades (% of total) | 390 (41.80%) |
| Loss Trades (% of total) | 543 (58.20%) |
| Largest profit trade | 289.94 |
| Largest loss trade | -270.80 |
| Average profit trade | 15.20 |
| Average loss trade | -11.03 |
| Maximum consecutive wins ($) | 7 (67.52) |
| Maximum consecutive losses ($) | 10 (-102.18) |
| Average position holding time | 9:24:55 |
| Maximal position holding time | 304:58:58 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 641 | -1,560.93 | -2.44 |
| end | 6 | 42.24 | 7.04 |
| Stop-Loss (sl) | 279 | 467.84 | 1.68 |
| Take-Profit (tp) | 7 | 986.93 | 140.99 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -194.86 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | -104.45 | -104.45 |
| 2023.02 | -118.43 | -222.88 |
| 2023.03 | 905.11 | 682.23 |
| 2023.04 | -185.07 | 497.16 |
| 2023.05 | -256.22 | 240.94 |
| 2023.06 | -111.83 | 129.11 |
| 2023.07 | -111.63 | 17.48 |
| 2023.08 | -95.62 | -78.14 |
| 2023.09 | -231.02 | -309.16 |
| 2023.10 | -89.74 | -398.90 |
| 2023.11 | -103.22 | -502.12 |
| 2023.12 | 307.26 | -194.86 |

## 🔎 关键观察
- 最佳月份: **2023.03** (905.11 USD)
- 最差月份: **2023.05** (-256.22 USD)  ← 重点优化时间窗口
- 亏损月份数: 10 / 12
- 余额最大回撤: 1 246.03 (33.61%) | 净值最大回撤: 1 661.58 (40.34%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码