# 📊 MT5 回测增强分析报告 — iter13 champion WORST window 2024.06-09

**生成时间:** 2026-06-17 11:48:07

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | EMACrossOver_V5 |
| Symbol | XAUUSD |
| Period | H1 (2024.06.01 - 2024.09.01) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -420.51 |
| Gross Profit | 111.27 |
| Gross Loss | -531.78 |
| Profit Factor | 0.21 |
| Expected Payoff | -15.02 |
| Recovery Factor | -0.85 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 422.42 (14.08%) |
| Equity Drawdown Maximal | 492.80 (16.28%) |
| Balance Drawdown Relative | 14.08% (422.42) |
| Equity Drawdown Relative | 16.28% (492.80) |
| Total Trades | 28 |
| Short Trades (won %) | 15 (33.33%) |
| Long Trades (won %) | 13 (38.46%) |
| Profit Trades (% of total) | 10 (35.71%) |
| Loss Trades (% of total) | 18 (64.29%) |
| Largest profit trade | 52.74 |
| Largest loss trade | -55.65 |
| Average profit trade | 11.13 |
| Average loss trade | -29.41 |
| Maximum consecutive wins ($) | 3 (61.48) |
| Maximum consecutive losses ($) | 5 (-90.39) |
| Average position holding time | 12:29:55 |
| Maximal position holding time | 46:28:21 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Stop-Loss (sl) | 23 | -461.84 | -20.08 |
| Signal/Trailing/Time exit | 5 | 43.79 | 8.76 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | -420.51 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.06 | -119.76 | -119.76 |
| 2024.07 | -190.94 | -310.70 |
| 2024.08 | -109.81 | -420.51 |

## 🔎 关键观察
- 最佳月份: **2024.08** (-109.81 USD)
- 最差月份: **2024.07** (-190.94 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 3
- 余额最大回撤: 422.42 (14.08%) | 净值最大回撤: 492.80 (16.28%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码