# 📊 MT5 回测增强分析报告 — Champion#1 window 2025 (base1.5+cap3+MU)

**生成时间:** 2026-06-17 18:39:39

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
| Total Net Profit | 9 206.59 |
| Gross Profit | 26 993.40 |
| Gross Loss | -17 786.81 |
| Profit Factor | 1.52 |
| Expected Payoff | 6.44 |
| Recovery Factor | 2.08 |
| Sharpe Ratio | 2.13 |
| Balance Drawdown Maximal | 2 284.67 (28.82%) |
| Equity Drawdown Maximal | 4 415.90 (29.68%) |
| Balance Drawdown Relative | 28.82% (2 284.67) |
| Equity Drawdown Relative | 30.22% (1 027.97) |
| Total Trades | 1430 |
| Short Trades (won %) | 529 (39.51%) |
| Long Trades (won %) | 901 (41.95%) |
| Profit Trades (% of total) | 587 (41.05%) |
| Loss Trades (% of total) | 843 (58.95%) |
| Largest profit trade | 6 564.35 |
| Largest loss trade | -672.68 |
| Average profit trade | 45.99 |
| Average loss trade | -20.83 |
| Maximum consecutive wins ($) | 9 (268.43) |
| Maximum consecutive losses ($) | 14 (-241.11) |
| Average position holding time | 7:41:40 |
| Maximal position holding time | 1061:58:59 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Loss (sl) | 604 | 269.46 | 0.45 |
| Signal/Trailing/Time exit | 809 | 1,089.29 | 1.35 |
| Take-Profit (tp) | 16 | 1,513.74 | 94.61 |
| end | 1 | 6,564.35 | 6,564.35 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2025 | 9,206.59 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2025.01 | -311.54 | -311.54 |
| 2025.02 | -232.53 | -544.07 |
| 2025.03 | 673.54 | 129.47 |
| 2025.04 | -213.71 | -84.24 |
| 2025.05 | -169.18 | -253.42 |
| 2025.06 | 208.11 | -45.31 |
| 2025.07 | -128.78 | -174.09 |
| 2025.08 | -99.69 | -273.78 |
| 2025.09 | -61.64 | -335.42 |
| 2025.10 | 4,113.07 | 3,777.65 |
| 2025.11 | -497.76 | 3,279.89 |
| 2025.12 | 5,926.70 | 9,206.59 |

## 🔎 关键观察
- 最佳月份: **2025.12** (5,926.70 USD)
- 最差月份: **2025.11** (-497.76 USD)  ← 重点优化时间窗口
- 亏损月份数: 8 / 12
- 余额最大回撤: 2 284.67 (28.82%) | 净值最大回撤: 4 415.90 (29.68%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码