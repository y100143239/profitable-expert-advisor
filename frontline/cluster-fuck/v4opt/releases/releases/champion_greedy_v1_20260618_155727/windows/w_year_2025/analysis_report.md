# 📊 MT5 回测增强分析报告 — champion defaults cold-start w_year_2025

**生成时间:** 2026-06-18 16:41:00

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
| Total Net Profit | 17 782.75 |
| Gross Profit | 55 389.42 |
| Gross Loss | -37 606.67 |
| Profit Factor | 1.47 |
| Expected Payoff | 13.62 |
| Recovery Factor | 2.50 |
| Sharpe Ratio | 2.10 |
| Balance Drawdown Maximal | 6 142.21 (32.92%) |
| Equity Drawdown Maximal | 7 100.23 (33.42%) |
| Balance Drawdown Relative | 39.23% (1 689.73) |
| Equity Drawdown Relative | 44.16% (2 770.71) |
| Total Trades | 1306 |
| Short Trades (won %) | 458 (39.74%) |
| Long Trades (won %) | 848 (42.22%) |
| Profit Trades (% of total) | 540 (41.35%) |
| Loss Trades (% of total) | 766 (58.65%) |
| Largest profit trade | 8 266.22 |
| Largest loss trade | -2 421.63 |
| Average profit trade | 102.57 |
| Average loss trade | -48.47 |
| Maximum consecutive wins ($) | 9 (478.59) |
| Maximum consecutive losses ($) | 14 (-384.71) |
| Average position holding time | 7:56:35 |
| Maximal position holding time | 1061:58:59 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Take-Profit (tp) | 14 | 2,935.13 | 209.65 |
| Signal/Trailing/Time exit | 741 | 3,181.07 | 4.29 |
| Stop-Loss (sl) | 550 | 3,881.75 | 7.06 |
| end | 1 | 8,266.22 | 8,266.22 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 17,782.75 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -416.77 | -416.77 |
| 2025.02 | -314.23 | -731.00 |
| 2025.03 | 1,478.94 | 747.94 |
| 2025.04 | -372.91 | 375.03 |
| 2025.05 | -351.08 | 23.95 |
| 2025.06 | 353.95 | 377.90 |
| 2025.07 | -156.78 | 221.12 |
| 2025.08 | -97.19 | 123.93 |
| 2025.09 | -481.84 | -357.91 |
| 2025.10 | 12,169.65 | 11,811.74 |
| 2025.11 | -1,387.63 | 10,424.11 |
| 2025.12 | 7,358.64 | 17,782.75 |

## 🔎 关键观察
- 最佳月份: **2025.10** (12,169.65 USD)
- 最差月份: **2025.11** (-1,387.63 USD)  ← 重点优化时间窗口
- 亏损月份数: 8 / 12
- 余额最大回撤: 6 142.21 (32.92%) | 净值最大回撤: 7 100.23 (33.42%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码