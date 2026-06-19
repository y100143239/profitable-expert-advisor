# 📊 MT5 回测增强分析报告 — stability sm_q4_2024

**生成时间:** 2026-06-19 22:37:35

## 🧾 回测环境 (Setup)
| 项目 | 值 |
|---|---|
| title | Strategy Tester Report |
| Expert | main |
| Symbol | EURUSD |
| Period | H1 (2024.10.01 - 2024.12.31) |
| Currency | USD |
| Initial Deposit | 3 000.00 |
| Leverage | 1:1000 |

## 📈 核心回测指标 (Results)
| 指标 | 值 |
|---|---|
| Total Net Profit | -532.94 |
| Gross Profit | 187.51 |
| Gross Loss | -720.45 |
| Profit Factor | 0.26 |
| Expected Payoff | -9.52 |
| Recovery Factor | -0.87 |
| Sharpe Ratio | -5.00 |
| Balance Drawdown Maximal | 569.54 (18.76%) |
| Equity Drawdown Maximal | 614.26 (19.96%) |
| Balance Drawdown Relative | 18.76% (569.54) |
| Equity Drawdown Relative | 19.96% (614.26) |
| Total Trades | 56 |
| Short Trades (won %) | 7 (28.57%) |
| Long Trades (won %) | 49 (34.69%) |
| Profit Trades (% of total) | 19 (33.93%) |
| Loss Trades (% of total) | 37 (66.07%) |
| Largest profit trade | 40.11 |
| Largest loss trade | -115.12 |
| Average profit trade | 9.87 |
| Average loss trade | -19.26 |
| Maximum consecutive wins ($) | 4 (14.48) |
| Maximum consecutive losses ($) | 6 (-228.75) |
| Average position holding time | 5:38:03 |
| Maximal position holding time | 69:00:00 |

## 🚪 离场原因分布 (Exit Reason)
| 离场原因 | 笔数 | 净盈亏($) | 平均($) |
|---|---|---|---|
| Signal/Trailing/Time exit | 39 | -441.79 | -11.33 |
| Stop-Loss (sl) | 17 | -83.40 | -4.91 |

## 📅 年度盈亏 (Yearly P/L)
| 年份 | 净盈亏($) |
|---|---|
| 2024 | -532.94 |

## 🗓️ 月度盈亏分布 (Monthly P/L)
| 月份 | 净盈亏($) | 累计($) |
|---|---|---|
| 2024.10 | -225.09 | -225.09 |
| 2024.11 | -197.99 | -423.08 |
| 2024.12 | -109.86 | -532.94 |

## 🔎 关键观察
- 最佳月份: **2024.12** (-109.86 USD)
- 最差月份: **2024.10** (-225.09 USD)  ← 重点优化时间窗口
- 亏损月份数: 3 / 3
- 余额最大回撤: 569.54 (18.76%) | 净值最大回撤: 614.26 (19.96%)

## 📎 附件清单
- `deals.csv` — 完整逐笔成交订单
- `summary.csv` — 环境与统计指标
- `*ReportTester.html` — MT5 原始报告
- `*ReportTester.png` 等 — 资金曲线/持仓/MFE-MAE 图表
- `config.ini` / `*.set` — 本次回测参数
- `baseline.mq5` — 本次回测使用的源码