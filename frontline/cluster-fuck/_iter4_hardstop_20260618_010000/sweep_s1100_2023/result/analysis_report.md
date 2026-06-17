# 📊 MT5 回测增强分析报告 — sweep 1100 2023

**生成时间:** 2026-06-18 01:09:24

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | ea |
| Symbol | XAUUSD |
| Period | H1 (2023.01.01 - 2024.01.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -830.84 |
| Gross Profit | 438.73 |
| Gross Loss | -1 269.57 |
| Profit Factor | 0.35 |
| Expected Payoff | -4.95 |
| Recovery Factor | -0.69 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 1 197.85 (35.73%) |
| Equity Drawdown Maximal | 1 209.76 (36.09%) |
| Balance Drawdown Relative | 35.73% (1 197.85) |
| Equity Drawdown Relative | 36.09% (1 209.76) |
| Total Trades | 168 |
| Short Trades (won %) | 65 (78.46%) |
| Long Trades (won %) | 103 (81.55%) |
| Profit Trades (% of total) | 135 (80.36%) |
| Loss Trades (% of total) | 33 (19.64%) |
| Largest profit trade | 103.47 |
| Largest loss trade | -1 197.39 |
| Average profit trade | 3.25 |
| Average loss trade | -37.81 |
| Maximum consecutive wins ($) | 21 (47.85) |
| Maximum consecutive losses ($) | 2 (-1 197.77) |
| Average position holding time | 1:59:04 |
| Maximal position holding time | 47:32:30 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 2 | -1,239.26 | -619.63 |
| Stop-Loss (sl) | 166 | 430.29 | 2.59 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2023 | -830.84 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2023.01 | 29.12 | 29.12 |
| 2023.02 | -14.78 | 14.34 |
| 2023.03 | 99.26 | 113.60 |
| 2023.04 | 158.47 | 272.07 |
| 2023.05 | 18.55 | 290.62 |
| 2023.09 | 25.31 | 315.93 |
| 2023.10 | 9.32 | 325.25 |
| 2023.11 | 17.52 | 342.77 |
| 2023.12 | -1,173.61 | -830.84 |

## 🔎 关键观察
- 最佳月份: **2023.04** (158.47 USD)
- 最差月份: **2023.12** (-1,173.61 USD)  ← 重点优化时间窗口
- 亏损月份数: 2 / 9
- 余额最大回撤: 1 197.85 (35.73%) | 净值最大回撤: 1 209.76 (36.09%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码